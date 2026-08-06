import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path_provider/path_provider.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  GoogleSignInAccount? _currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    return _currentUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    _currentUser ??= await _googleSignIn.signInSilently();
    _currentUser ??= await _googleSignIn.signIn();
    if (_currentUser == null) return null;

    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) return null;

    return drive.DriveApi(httpClient);
  }

  /// Realiza o Upload do banco SQLite local para a nuvem
  Future<bool> uploadBackup(File dbFile) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final media = drive.Media(
        dbFile.openRead(),
        await dbFile.length(),
      );

      // Verifica se o arquivo de backup já existe no AppData
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'eprobe_backup.db'",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Atualiza o backup existente
        final fileId = fileList.files!.first.id!;
        await driveApi.files.update(
          drive.File(),
          fileId,
          uploadMedia: media,
        );
      } else {
        // Cria um novo backup
        final driveFile = drive.File()
          ..name = 'eprobe_backup.db'
          ..parents = ['appDataFolder'];

        await driveApi.files.create(
          driveFile,
          uploadMedia: media,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao fazer upload para o Google Drive: $e');
      return false;
    }
  }

  /// Restaura o arquivo de banco de dados do Google Drive
  Future<File?> restoreBackup() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'eprobe_backup.db'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint('Nenhum backup encontrado no Google Drive.');
        return null;
      }

      final fileId = fileList.files!.first.id!;
      final drive.Media fileMedia = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/restored_eprobe.db');

      final List<int> dataBytes = [];
      await for (var data in fileMedia.stream) {
        dataBytes.addAll(data);
      }

      await localFile.writeAsBytes(dataBytes);
      return localFile;
    } catch (e) {
      debugPrint('Erro ao restaurar do Google Drive: $e');
      return null;
    }
  }
}