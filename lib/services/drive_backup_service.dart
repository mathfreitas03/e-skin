import 'dart:io';
import 'package:eprobe/controllers/language_handler.dart';
import 'package:eprobe/database/db.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Representa a escolha do usuário ao resolver um conflito de sincronização
enum SyncDecision {
  useLocal,
  useCloud,
  cancel,
}

/// Representa os metadados de um arquivo de backup
class BackupMetadata {
  final DateTime lastModified;
  final int fileSize;

  BackupMetadata({
    required this.lastModified,
    required this.fileSize,
  });
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class DriveBackupService {
  static const String _backupFileName = 'eprobe_backup.db';

  /// Obtém a API do Drive autenticada via authHeaders do usuário logado
  static Future<drive.DriveApi> _getDriveApi(GoogleSignInAccount googleUser) async {
    final authHeaders = await googleUser.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    return drive.DriveApi(authenticateClient);
  }

  /// Retorna o caminho do arquivo de banco de dados SQLite local
  static Future<File> _getLocalDbFile() async {
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'eprobe.db');
    return File(dbPath);
  }

  /// Obtém metadados do arquivo local (Data em UTC e tamanho em bytes)
  static Future<BackupMetadata?> getLocalMetadata() async {
    try {
      final file = await _getLocalDbFile();
      if (!await file.exists()) return null;

      final lastModified = (await file.lastModified()).toUtc();
      final length = await file.length();

      return BackupMetadata(lastModified: lastModified, fileSize: length);
    } catch (e) {
      debugPrint("Erro ao ler metadados locais: $e");
      return null;
    }
  }

  /// Obtém metadados do arquivo salvo na pasta oculta do app no Google Drive
  static Future<BackupMetadata?> getCloudMetadata(GoogleSignInAccount googleUser) async {
    try {
      final driveApi = await _getDriveApi(googleUser);
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName' and trashed = false",
        $fields: 'files(id, modifiedTime, size)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return null;
      }

      final file = fileList.files!.first;
      final modifiedTime = file.modifiedTime ?? DateTime.now();
      final size = int.tryParse(file.size ?? '0') ?? 0;

      return BackupMetadata(
        lastModified: modifiedTime.toUtc(),
        fileSize: size,
      );
    } catch (e) {
      debugPrint("Erro ao obter metadados da nuvem: $e");
      return null;
    }
  }

  /// Envia o banco de dados local para o Google Drive (Sobrescreve se já existir)
  static Future<bool> uploadBackup(GoogleSignInAccount googleUser) async {
    try {
      final driveApi = await _getDriveApi(googleUser);
      final dbFile = await _getLocalDbFile();

      if (!await dbFile.exists()) return false;

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName' and trashed = false",
      );

      final media = drive.Media(
        dbFile.openRead(),
        await dbFile.length(),
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final existingFileId = fileList.files!.first.id!;
        await driveApi.files.update(
          drive.File(modifiedTime: DateTime.now().toUtc()),
          existingFileId,
          uploadMedia: media,
        );
      } else {
        final driveFile = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder']
          ..modifiedTime = DateTime.now().toUtc();

        await driveApi.files.create(
          driveFile,
          uploadMedia: media,
        );
      }

      return true;
    } catch (e) {
      debugPrint("Erro ao fazer upload do backup: $e");
      return false;
    }
  }

  /// Baixa o backup do Google Drive e sobrescreve o banco de dados local
  static Future<bool> restoreBackup(GoogleSignInAccount googleUser) async {
    try {
      final driveApi = await _getDriveApi(googleUser);

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName' and trashed = false",
      );

      if (fileList.files == null || fileList.files!.isEmpty) return false;

      final fileId = fileList.files!.first.id!;
      final drive.Media fileMedia = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      await DB.instance.closeAndReset();
      final dbFile = await _getLocalDbFile();

      final List<int> dataBytes = [];
      await for (final data in fileMedia.stream) {
        dataBytes.addAll(data);
      }

      await dbFile.writeAsBytes(dataBytes);
      await DB.instance.getDatabase;
      
      return true;
    } catch (e) {
      debugPrint("Erro ao restaurar backup: $e");
      return false;
    }
  }

  /// Lógica principal de sincronização com resolução de conflitos
  static Future<void> performSyncWithDecision(
    BuildContext context,
    GoogleSignInAccount googleUser, {
    required Function(String) onStatusMessage,
  }) async {
    final localMeta = await getLocalMetadata();
    final cloudMeta = await getCloudMetadata(googleUser);

    // Caso 1: Não há backup nem local nem na nuvem
    if (localMeta == null && cloudMeta == null) {
      onStatusMessage("No data.");
      return;
    }

    
    // Caso 2: Não há backup na nuvem -> faz upload automático dos dados locais
    if (cloudMeta == null) {
      onStatusMessage("Uploading data to Google Drive");
      final ok = await uploadBackup(googleUser);
      onStatusMessage(ok ? "Success" : "Failed to send backup.");
      return;
    }

    // Caso 3: Não há banco de dados local -> baixa o backup da nuvem automaticamente
    if (localMeta == null) {
      onStatusMessage("Restoring remote data");
      final ok = await restoreBackup(googleUser);
      onStatusMessage(ok ? "Remote Backup restored" : "Failed to restore backup.");
      return;
    }

    // Caso 4: Ambas as fontes existem. Compara a diferença de horário.
    final difference = localMeta.lastModified.difference(cloudMeta.lastModified).abs();

    if (difference.inMinutes < 1) {
      onStatusMessage("Data is already synchronized.");
      return;
    }

    // Conflito Detectado: Exibe a caixa de diálogo
    if (!context.mounted) return;

    final SyncDecision? decision = await _showConflictDialog(context, localMeta, cloudMeta);

    if (decision == SyncDecision.useLocal) {
      onStatusMessage("Backup updated");
      final ok = await uploadBackup(googleUser);
      onStatusMessage(ok ? "Cloud updated" : "Cloud update failed.");
    } else if (decision == SyncDecision.useCloud) {
      onStatusMessage("Restoring remote data");
      final ok = await restoreBackup(googleUser);
      onStatusMessage(ok ? "Database restored" : "Failed to restore date.");
    } else {
      onStatusMessage("Synchronization cancelled.");
    }
  }

  /// Exibe a janela de diálogo comparando Local vs Nuvem
  static Future<SyncDecision?> _showConflictDialog(
    BuildContext context,
    BackupMetadata local,
    BackupMetadata cloud,
  ) {
    String formatDate(DateTime dt) {
      final localDt = dt.toLocal();
      return "${localDt.day.toString().padLeft(2, '0')}/${localDt.month.toString().padLeft(2, '0')}/${localDt.year}, ${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}";
    }

    String formatSize(int bytes) {
      if (bytes < 1024) return "$bytes B";
      if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    }

    return showDialog<SyncDecision>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text(LanguageHandler().translate("sincronization_conflict"), style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              LanguageHandler().translate("drive_choose_warning"),
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Opção 1: Arquivo Local
            InkWell(
              onTap: () => Navigator.pop(ctx, SyncDecision.useLocal),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue.shade50,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android, size: 30, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(LanguageHandler().translate('keep_local_data'), style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("${LanguageHandler().translate("modified")}: ${formatDate(local.lastModified)}", style: const TextStyle(fontSize: 12)),
                          Text("${LanguageHandler().translate("size")}: ${formatSize(local.fileSize)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Opção 2: Arquivo da Nuvem
            InkWell(
              onTap: () => Navigator.pop(ctx, SyncDecision.useCloud),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_download, size: 30, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(LanguageHandler().translate('download_from_google_drive'), style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("${LanguageHandler().translate('modified')}: ${formatDate(cloud.lastModified)}", style: const TextStyle(fontSize: 12)),
                          Text("${LanguageHandler().translate('size')}: ${formatSize(cloud.fileSize)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, SyncDecision.cancel),
            child: Text(LanguageHandler().translate('cancel')),
          ),
        ],
      ),
    );
  }
}