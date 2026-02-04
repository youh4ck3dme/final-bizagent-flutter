import 'dart:convert';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

class GoogleDriveService {
  static const _scopes = [
    'email',
    'profile',
    'https://www.googleapis.com/auth/drive.file',
  ];

  static const _folderName = 'BizAgent Backups';

  // Use the same Client ID as in AuthRepository
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '542280140779-c5m14rqpih1j9tmf9km52aq1684l9qjd.apps.googleusercontent.com',
    scopes: _scopes,
  );

  drive.DriveApi? _driveApi;

  // Initialize and check connection
  Future<bool> connect() async {
    try {
      // Try silent sign-in to retrieve existing session
      var googleUser = await _googleSignIn.signInSilently();

      // If not signed in (and strict is false), try interactive sign in?
      // Usually UI button triggers signIn(), but service should ideally use existing creds.
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) return false;

      final auth.AuthClient? client = await _googleSignIn.authenticatedClient();
      if (client == null) return false;

      _driveApi = drive.DriveApi(client);
      return true;
    } catch (e) {
      debugPrint('Google Drive Connect Error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    await _googleSignIn.disconnect();
    _driveApi = null;
  }

  // Get or Create Root backup folder
  Future<String?> _getBackupFolderId() async {
    if (_driveApi == null) throw Exception('Drive API not initialized');

    try {
      // Check if folder exists
      final fileList = await _driveApi!.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and name = '$_folderName' and trashed = false",
        $fields: "files(id, name)",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }

      // Create folder if not exists
      final folder = drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi!.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      debugPrint('Error getting backup folder: $e');
      return null;
    }
  }

  // Upload Backup
  Future<void> uploadBackup(String jsonContent, String fileName) async {
    if (_driveApi == null) await connect();
    if (_driveApi == null) throw Exception('Cannot connect to Google Drive');

    final folderId = await _getBackupFolderId();
    if (folderId == null) throw Exception('Could not access backup folder');

    final file = drive.File()
      ..name = fileName
      ..parents = [folderId]
      ..mimeType = 'application/json';

    final media = drive.Media(
      Stream.value(utf8.encode(jsonContent)),
      utf8.encode(jsonContent).length,
    );

    await _driveApi!.files.create(file, uploadMedia: media);
    debugPrint('Backup uploaded successfully: $fileName');
  }

  // List Backups
  Future<List<drive.File>> listBackups() async {
    if (_driveApi == null) await connect();
    if (_driveApi == null) return [];

    try {
      final folderId = await _getBackupFolderId();
      if (folderId == null) return [];

      final fileList = await _driveApi!.files.list(
        q: "'$folderId' in parents and trashed = false and mimeType = 'application/json'",
        orderBy: "createdTime desc",
        $fields: "files(id, name, createdTime, size)",
      );

      return fileList.files ?? [];
    } catch (e) {
      debugPrint('Error listing backups: $e');
      return [];
    }
  }

  // Download Backup
  Future<String?> downloadBackup(String fileId) async {
    if (_driveApi == null) await connect();
    if (_driveApi == null) return null;

    try {
      final drive.Media media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }
      return utf8.decode(dataStore);
    } catch (e) {
      debugPrint('Error downloading backup: $e');
      return null;
    }
  }
}

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService();
});
