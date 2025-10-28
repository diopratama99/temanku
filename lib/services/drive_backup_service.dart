import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Service untuk backup dan restore data ke Google Drive
/// Only requires internet during backup/restore operations
class DriveBackupService {
  static const List<String> _scopes = [drive.DriveApi.driveFileScope];

  /// Upload file CSV ke Google Drive
  /// Returns file ID if success, null if failed
  Future<String?> uploadToGoogleDrive({
    required File file,
    required String fileName,
    required GoogleSignInAccount googleUser,
  }) async {
    try {
      // Get auth headers dari Google Sign-In
      final authHeaders = await googleUser.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);

      final driveApi = drive.DriveApi(authenticateClient);

      // Check if backup folder exists
      var folderId = await _getOrCreateBackupFolder(driveApi);
      if (folderId == null) {
        return null;
      }

      // Create file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..description =
            'Temanku App Backup - ${DateTime.now().toIso8601String()}';

      // Upload file
      final media = drive.Media(file.openRead(), file.lengthSync());
      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      return response.id;
    } catch (e) {
      print('Error uploading to Drive: $e');
      return null;
    }
  }

  /// Restore file dari Google Drive
  /// Returns file content as bytes, null if failed
  Future<List<int>?> downloadFromGoogleDrive({
    required String fileId,
    required GoogleSignInAccount googleUser,
  }) async {
    try {
      final authHeaders = await googleUser.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // Download file
      final response =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      // Read stream to bytes
      final bytes = <int>[];
      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
      }

      return bytes;
    } catch (e) {
      print('Error downloading from Drive: $e');
      return null;
    }
  }

  /// List backup files dari Google Drive
  Future<List<drive.File>> listBackupFiles({
    required GoogleSignInAccount googleUser,
  }) async {
    try {
      final authHeaders = await googleUser.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // Get backup folder ID
      final folderId = await _getOrCreateBackupFolder(driveApi);
      if (folderId == null) return [];

      // List files in backup folder
      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and trashed=false",
        orderBy: 'modifiedTime desc',
        spaces: 'drive',
        $fields: 'files(id, name, createdTime, modifiedTime, size)',
      );

      return fileList.files ?? [];
    } catch (e) {
      print('Error listing backup files: $e');
      return [];
    }
  }

  /// Delete backup file dari Google Drive
  Future<bool> deleteBackupFile({
    required String fileId,
    required GoogleSignInAccount googleUser,
  }) async {
    try {
      final authHeaders = await googleUser.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      await driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      print('Error deleting backup file: $e');
      return false;
    }
  }

  /// Get or create "Temanku Backups" folder
  Future<String?> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    try {
      // Search for existing folder
      final folderList = await driveApi.files.list(
        q: "name='Temanku Backups' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        return folderList.files!.first.id;
      }

      // Create new folder
      final folder = drive.File()
        ..name = 'Temanku Backups'
        ..mimeType = 'application/vnd.google-apps.folder'
        ..description = 'Backup folder for Temanku financial app';

      final createdFolder = await driveApi.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      print('Error creating backup folder: $e');
      return null;
    }
  }
}

/// Custom HTTP client for Google APIs
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
  }
}
