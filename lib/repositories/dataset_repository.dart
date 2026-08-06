// lib/repositories/dataset_repository.dart
import 'dart:convert';
import 'package:eprobe/controllers/app_configs.dart';
import 'package:eprobe/database/db.dart';
import 'package:eprobe/models/dataset.dart';
import 'package:eprobe/models/measurement_point.dart';
import 'package:eprobe/services/drive_backup_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DatasetRepository {
  final DB _db = DB.instance;

  Future<List<DataSet>> getDatasetsFromCurrentSession() async {
    return await _db.getDataSetsFromCurrentSession();
  }

  Future<void> deleteDatasets(Set<String> datasetIds) async {
    final db = await _db.getDatabase;
    await db.transaction((txn) async {
      for (String id in datasetIds) {
        await txn.delete('dataset', where: 'id = ?', whereArgs: [id]);
      }
    });

    _triggerBackgroundSync();
  }

  Future<void> createDataset({
    required String name,
    required String imagePath,
  }) async {
    final db = await _db.getDatabase;
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

    final String newDatasetId = "fish_${DateTime.now().millisecondsSinceEpoch}";
    await db.insert('dataset', {
      'id': newDatasetId,
      'name': name,
      'image_path': imagePath,
      'session_id': sessionId,
    });

    _triggerBackgroundSync();
  }
    
  Future<void> saveMeasurementPoint({
    required String datasetId,
    required String label,
    required double x,
    required double y,
    required MeasurementPoint measurement,
  }) async {
    final db = await _db.getDatabase;
    final String pointId = "point_${DateTime.now().millisecondsSinceEpoch}";
    final String measurementId = "meas_${DateTime.now().millisecondsSinceEpoch}";

    await db.transaction((txn) async {
      await txn.insert('measurement_point', {
        'id': pointId,
        'label': label,
        'x': x,
        'y': y,
        'timestamp': DateTime.now().toIso8601String(),
        'dataset_id': datasetId,
        'metadata': null,
      });

      await txn.insert('measurement_data', {
        'id': measurementId,
        'point_id': pointId,
        'real': jsonEncode(measurement.real),
        'imag': jsonEncode(measurement.imag),
        'freq': jsonEncode(measurement.freq),
      });
    });

    _triggerBackgroundSync();

  }

  Future<void> deletePoint(String pointId) async {
    final db = await _db.getDatabase;
    await db.delete('measurement_point', where: 'id = ?', whereArgs: [pointId]);

    _triggerBackgroundSync();
  }
}

void _triggerBackgroundSync() async {
      final configs = AppConfigs();
      // Só sincroniza se a opção estiver ativada
      if (configs.isDriveBackupEnabled) {
        final googleSignIn = GoogleSignIn();
        final account = await googleSignIn.signInSilently();
        if (account != null) {
          // Envia os dados atualizados para a nuvem em background
          DriveBackupService.uploadBackup(account);
        }
      }
    }