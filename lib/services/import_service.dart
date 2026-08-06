import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:eprobe/controllers/app_configs.dart';
import 'package:eprobe/database/db.dart';
import 'package:eprobe/services/drive_backup_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class ImportService {
  final DB _db = DB.instance;

  static const String validAppIdentifier = "eprobe_app";

  Future<bool> importDatasetsFromFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'eprobe'],
    );

    if (result == null || result.files.single.path == null) {
      return false;
    }

    final file = File(result.files.single.path!);
    return await importDatasetsFromZip(file);
  }

  Future<bool> importDatasetsFromZip(File zipFile) async {
    Directory? unzippedDir;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();

      unzippedDir = Directory('${tempDir.path}/unzipped_${DateTime.now().millisecondsSinceEpoch}');
      await unzippedDir.create(recursive: true);

      const String defaultImagePath = 'assets/images/standard_fish.png';

      // 1. Descompactação do arquivo
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File('${unzippedDir.path}/$filename');
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          await Directory('${unzippedDir.path}/$filename').create(recursive: true);
        }
      }

      // 2. Validação da presença do data.json
      final jsonFile = File('${unzippedDir.path}/data.json');
      if (!await jsonFile.exists()) {
        throw const FormatException("Arquivo data.json não encontrado no pacote.");
      }

      final jsonString = await jsonFile.readAsString();
      final dynamic decodedPackage = jsonDecode(jsonString);

      // 3. Validação dos Metadados/Assinatura do Pacote
      _validatePackageSignature(decodedPackage);

      final List<dynamic> datasetsList = decodedPackage['datasets'];

      final db = await _db.getDatabase;

      // Obtém ou cria a sessão ativa
      final List<Map<String, dynamic>> sessions = await db.query('measurement_session', limit: 1);
      String sessionId;
      if (sessions.isEmpty) {
        sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";
        await db.insert('measurement_session', {
          'id': sessionId,
          'name': 'Sessão Padrão',
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        sessionId = sessions.first['id'];
      }

      // 4. Transação com Validação de Esquema e Integridade de Imagens
      await db.transaction((txn) async {
        for (var datasetItem in datasetsList) {
          if (!_isValidDataset(datasetItem)) {
            throw const FormatException("Estrutura do Dataset é inválida ou faltam campos obrigatórios.");
          }

          final Map<String, dynamic> datasetMap = datasetItem;
          final String datasetId = datasetMap['id'];
          String? relativeImageName = datasetMap['image_path'];
          String? localImagePath;

          // Validação e Cópia da Imagem Fpísica
          if (relativeImageName != null && relativeImageName.isNotEmpty) {
            final sourceImage = File('${unzippedDir!.path}/images/$relativeImageName');
            if (await sourceImage.exists()) {
              final permanentImagePath = '${appDocDir.path}/imported_${DateTime.now().millisecondsSinceEpoch}_$relativeImageName';
              await sourceImage.copy(permanentImagePath);
              localImagePath = permanentImagePath;
            } 
          }

          // Inserção do Dataset
          await txn.insert(
            'dataset',
            {
              'id': datasetId,
              'name': datasetMap['name'],
              'image_path': localImagePath ?? defaultImagePath,
              'session_id': sessionId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Inserção dos Pontos
          final pointsList = datasetMap['points'] as List;
          for (var pointItem in pointsList) {
            if (!_isValidPoint(pointItem)) {
              throw const FormatException("Estrutura do Ponto de Medição é inválida.");
            }

            final Map<String, dynamic> pointMap = pointItem;
            final String pointId = pointMap['id'];

            await txn.insert(
              'measurement_point',
              {
                'id': pointId,
                'label': pointMap['label'] ?? '',
                'x': pointMap['x'] ?? 0.0,
                'y': pointMap['y'] ?? 0.0,
                'timestamp': pointMap['timestamp'] ?? DateTime.now().toIso8601String(),
                'dataset_id': datasetId,
                'metadata': pointMap['metadata'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            // Inserção das Medições
            final measurementsList = pointMap['measurements'] as List;
            for (var measItem in measurementsList) {
              if (!_isValidMeasurement(measItem)) {
                throw const FormatException("Estrutura da Medição de Dados é inválida.");
              }

              final Map<String, dynamic> measMap = measItem;

              await txn.insert(
                'measurement_data',
                {
                  'id': measMap['id'],
                  'point_id': pointId,
                  'real': jsonEncode(measMap['real']),
                  'imag': jsonEncode(measMap['imag']),
                  'freq': jsonEncode(measMap['freq']),
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      });

      _triggerBackgroundSync();
      return true;
    } catch (e) {
      debugPrint("[CRITICAL] Error on importing dataset: $e");
      return false;
    } finally {
      // Garante a limpeza do diretório temporário
      if (unzippedDir != null && await unzippedDir.exists()) {
        await unzippedDir.delete(recursive: true);
      }
    }
  }


  void _validatePackageSignature(dynamic package) {
    if (package is! Map<String, dynamic>) {
      throw const FormatException("O pacote JSON não possui uma estrutura de objeto válida.");
    }
    if (package['app_identifier'] != validAppIdentifier) {
      throw const FormatException("O arquivo não pertence ao aplicativo eProbe.");
    }
    if (!package.containsKey('datasets') || package['datasets'] is! List) {
      throw const FormatException("A lista de datasets está ausente ou malformada.");
    }
  }

  bool _isValidDataset(dynamic item) {
    if (item is! Map<String, dynamic>) return false;
    return item.containsKey('id') &&
        item.containsKey('name') &&
        item.containsKey('points') &&
        item['points'] is List;
  }

  bool _isValidPoint(dynamic item) {
    if (item is! Map<String, dynamic>) return false;
    return item.containsKey('id') &&
        item.containsKey('x') &&
        item.containsKey('y') &&
        item.containsKey('measurements') &&
        item['measurements'] is List;
  }

  bool _isValidMeasurement(dynamic item) {
    if (item is! Map<String, dynamic>) return false;
    return item.containsKey('id') &&
        item.containsKey('real') &&
        item.containsKey('imag') &&
        item.containsKey('freq');
  }

  void _triggerBackgroundSync() async {
    final configs = AppConfigs();
    if (configs.isDriveBackupEnabled) {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signInSilently();
      if (account != null) {
        DriveBackupService.uploadBackup(account);
      }
    }
  }
}