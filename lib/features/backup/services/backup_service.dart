import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_persistence_service.dart';
import 'google_drive_service.dart';

class BackupService {
  final LocalPersistenceService _persistence;
  final GoogleDriveService _driveService;

  BackupService(this._persistence, this._driveService);

  Future<void> backupNow() async {
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'version': 1,
      'invoices': _persistence.getInvoicesMap(),
      'expenses': _persistence.getExpensesMap(),
      'settings': _persistence.getSettingsMap(),
    };

    // Use a custom encoder to handle complex objects if necessary (Hive mostly uses primitives/Maps)
    final jsonContent = jsonEncode(data, toEncodable: _toEncodable);
    final fileName =
        'bizagent_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    await _driveService.uploadBackup(jsonContent, fileName);
  }

  Future<void> restore(String fileId) async {
    final jsonContent = await _driveService.downloadBackup(fileId);
    if (jsonContent == null) return;

    final data = jsonDecode(jsonContent) as Map<String, dynamic>;

    if (data.containsKey('invoices')) {
      await _persistence.restoreInvoices(Map.from(data['invoices']));
    }
    if (data.containsKey('expenses')) {
      await _persistence.restoreExpenses(Map.from(data['expenses']));
    }
    if (data.containsKey('settings')) {
      await _persistence.restoreSettings(Map.from(data['settings']));
    }
  }

  // Helper to handle types not directly supported by jsonEncode (like DateTime in Hive)
  Object? _toEncodable(Object? object) {
    if (object is DateTime) {
      return object.toIso8601String();
    }
    return object;
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final persistence = ref.watch(localPersistenceServiceProvider);
  final driveService = ref.watch(googleDriveServiceProvider);
  return BackupService(persistence, driveService);
});
