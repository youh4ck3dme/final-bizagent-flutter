import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bizagent/features/backup/services/backup_service.dart';
import 'package:bizagent/features/backup/services/google_drive_service.dart';
import 'package:bizagent/core/services/local_persistence_service.dart';

// Mock Classes (Manual for speed)
class MockGoogleDriveService extends Mock implements GoogleDriveService {
  String? uploadedContent;
  String? uploadedName;

  @override
  Future<void> uploadBackup(String jsonContent, String fileName) async {
    uploadedContent = jsonContent;
    uploadedName = fileName;
  }

  @override
  Future<String?> downloadBackup(String fileId) async {
    // Return a valid JSON backup
    return jsonEncode({
      'version': 1,
      'invoices': {
        'inv1': {'amount': 100},
      },
      'expenses': {
        'exp1': {'amount': 50},
      },
      'settings': {'dark_mode': true},
    });
  }
}

class MockPersistenceService extends Mock implements LocalPersistenceService {
  Map<dynamic, dynamic> invoicesMap = {
    'inv1': {'amount': 100},
  };
  Map<dynamic, dynamic> expensesMap = {
    'exp1': {'amount': 50},
  };
  Map<dynamic, dynamic> settingsMap = {'theme': 'dark'};

  @override
  Map<dynamic, dynamic> getInvoicesMap() => invoicesMap;

  @override
  Map<dynamic, dynamic> getExpensesMap() => expensesMap;

  @override
  Map<dynamic, dynamic> getSettingsMap() => settingsMap;

  bool restoredInvoices = false;
  bool restoredExpenses = false;
  bool restoredSettings = false;

  @override
  Future<void> restoreInvoices(Map<dynamic, dynamic> data) async {
    restoredInvoices = true;
  }

  @override
  Future<void> restoreExpenses(Map<dynamic, dynamic> data) async {
    restoredExpenses = true;
  }

  @override
  Future<void> restoreSettings(Map<dynamic, dynamic> data) async {
    restoredSettings = true;
  }
}

void main() {
  late BackupService backupService;
  late MockGoogleDriveService mockDrive;
  late MockPersistenceService mockPersistence;

  setUp(() {
    mockDrive = MockGoogleDriveService();
    mockPersistence = MockPersistenceService();
    backupService = BackupService(mockPersistence, mockDrive);
  });

  test('backupNow creates correct JSON and calls upload', () async {
    await backupService.backupNow();

    expect(mockDrive.uploadedName, contains('bizagent_backup_'));
    expect(mockDrive.uploadedContent, isNotNull);

    final data = jsonDecode(mockDrive.uploadedContent!);
    expect(data['version'], 1);
    expect(data['invoices'], {
      'inv1': {'amount': 100},
    });
    expect(data['expenses'], {
      'exp1': {'amount': 50},
    });
    expect(data['settings'], {'theme': 'dark'});
  });

  test('restore downloads and parses data correctly', () async {
    await backupService.restore('fake_id');

    expect(mockPersistence.restoredInvoices, true);
    expect(mockPersistence.restoredExpenses, true);
    expect(mockPersistence.restoredSettings, true);
  });
}
