import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart'; // Importe archive.dart em vez de archive_io.dart
import 'package:eprobe/database/db.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  final DB _db = DB.instance;
  static const String appIdentifier = "eprobe_app";
  static const int exportSchemaVersion = 1;

  Future<String?> _generateExportPackage(Set<String> datasetIds) async {
    if (datasetIds.isEmpty) return null;

    final db = await _db.getDatabase;
    List<Map<String, dynamic>> datasetsList = [];
    List<File> imagesToZip = [];

    for (String id in datasetIds) {
      final datasetMap = await db.query('dataset', where: 'id = ?', whereArgs: [id]);
      if (datasetMap.isEmpty) continue;

      Map<String, dynamic> datasetJson = Map<String, dynamic>.from(datasetMap.first);

      String? imagePath = datasetJson['image_path'];
      if (imagePath != null && imagePath.isNotEmpty) {
        File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          imagesToZip.add(imageFile);
          datasetJson['image_path'] = p.basename(imagePath);
        } else {
          datasetJson['image_path'] = null;
        }
      }

      final pointsMap = await db.query('measurement_point', where: 'dataset_id = ?', whereArgs: [id]);
      List<Map<String, dynamic>> pointsJsonList = [];

      for (var pointRow in pointsMap) {
        Map<String, dynamic> pointJson = Map<String, dynamic>.from(pointRow);
        String pointId = pointRow['id'].toString();

        final measurementsMap = await db.query('measurement_data', where: 'point_id = ?', whereArgs: [pointId]);

        List<Map<String, dynamic>> measurementsJsonList = measurementsMap.map((m) {
          return {
            'id': m['id'],
            'real': jsonDecode((m['real'] ?? '[]').toString()),
            'imag': jsonDecode((m['imag'] ?? '[]').toString()),
            'freq': jsonDecode((m['freq'] ?? '[]').toString()),
          };
        }).toList();

        pointJson['measurements'] = measurementsJsonList;
        pointsJsonList.add(pointJson);
      }

      datasetJson['points'] = pointsJsonList;
      datasetsList.add(datasetJson);
    }

    if (datasetsList.isEmpty) return null;

    final Map<String, dynamic> exportPackage = {
      'app_identifier': appIdentifier,
      'schema_version': exportSchemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'datasets': datasetsList,
    };

    // 1. Cria o objeto Archive em memória
    final archive = Archive();

    // 2. Adiciona o data.json à raiz do pacote
    String jsonString = const JsonEncoder.withIndent('  ').convert(exportPackage);
    List<int> jsonBytes = utf8.encode(jsonString);
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

    // 3. Adiciona as imagens dentro de /images
    for (var imageFile in imagesToZip) {
      List<int> imgBytes = await imageFile.readAsBytes();
      String filename = p.basename(imageFile.path);
      archive.addFile(ArchiveFile('images/$filename', imgBytes.length, imgBytes));
    }

    // 4. Codifica o arquivo ZIP completo em memória
    final zipData = ZipEncoder().encode(archive);

    // 5. Salva no disco com writeAsBytes (garante que a escrita é física e finalizada antes de avançar)
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFilePath = '${tempDir.path}/eprobe_export_$timestamp.zip';
    
    final outputFile = File(zipFilePath);
    await outputFile.writeAsBytes(zipData, flush: true); // flush: true força o SO a descarregar no disco imediatamente

    return zipFilePath;
  }

  /// Compartilhar via apps externos
  Future<bool> shareDatasets(Set<String> datasetIds) async {
    final zipFilePath = await _generateExportPackage(datasetIds);
    if (zipFilePath == null) return false;

    final result = await Share.shareXFiles(
      [XFile(zipFilePath, mimeType: 'application/zip')],
      text: 'eProbe data export',
    );

    return result.status == ShareResultStatus.success;
  }

  /// Salvar em Downloads / Memória
  Future<bool> saveDatasetsToDevice(Set<String> datasetIds) async {
    final zipFilePath = await _generateExportPackage(datasetIds);
    if (zipFilePath == null) return false;

    final tempFile = File(zipFilePath);
    final fileName = 'eprobe_export_${DateTime.now().millisecondsSinceEpoch}.eprobe';

    try {
      final bytes = await tempFile.readAsBytes();

      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Salvar Exportação:',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['eprobe', 'zip'],
        bytes: bytes,
      );

      if (outputFile == null) return false;

      final targetFile = File(outputFile);
      if (!await targetFile.exists()) {
        await targetFile.writeAsBytes(bytes, flush: true);
      }

      return true;
    } catch (e) {
      return false;
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}