import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Integrity test: critical app structure, routes, and Share extension support.
/// Run: flutter test test/integrity/app_integrity_test.dart
void main() {
  group('App Integrity', () {
    test('app_router has /create-expense and sharedImagePath handling', () {
      final file = File('lib/core/router/app_router.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(
        content.contains("path: '/create-expense'"),
        isTrue,
        reason: 'Missing /create-expense route',
      );
      expect(
        content.contains('sharedImagePath'),
        isTrue,
        reason: 'Router must pass sharedImagePath to CreateExpenseScreen',
      );
      expect(
        content.contains("extra['sharedImagePath']"),
        isTrue,
        reason: 'Router must read sharedImagePath from extra',
      );
    });

    test('OcrService has scanReceiptFromPath for Share intent', () {
      final file = File('lib/core/services/ocr_service.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(
        content.contains('scanReceiptFromPath'),
        isTrue,
        reason: 'OcrService must have scanReceiptFromPath for shared images',
      );
      expect(
        content.contains('InputImage.fromFilePath(path)'),
        isTrue,
        reason: 'Must use file path for shared image OCR',
      );
    });

    test('CreateExpenseScreen accepts sharedImagePath and processes it', () {
      final file = File(
        'lib/features/expenses/screens/create_expense_screen.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(
        content.contains('sharedImagePath'),
        isTrue,
        reason: 'CreateExpenseScreen must have sharedImagePath parameter',
      );
      expect(
        content.contains('_processSharedImage'),
        isTrue,
        reason: 'Must process shared image on init',
      );
    });

    test('ScaffoldWithNavBar wires Share intent to create-expense', () {
      final file = File('lib/shared/widgets/scaffold_with_navbar.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(
        content.contains('ReceiveSharingIntent'),
        isTrue,
        reason: 'Shell must use receive_sharing_intent',
      );
      expect(
        content.contains("'/create-expense'"),
        isTrue,
        reason: 'Share intent must navigate to create-expense',
      );
      expect(
        content.contains("'sharedImagePath'"),
        isTrue,
        reason: 'Must pass sharedImagePath in extra',
      );
    });

    test('Android manifest has Share intent filters and singleTask', () {
      final file = File('android/app/src/main/AndroidManifest.xml');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(
        content.contains('android.intent.action.SEND'),
        isTrue,
        reason: 'Must declare SEND intent for images',
      );
      expect(
        content.contains('image/*'),
        isTrue,
        reason: 'Must accept image/* MIME',
      );
      expect(
        content.contains('singleTask'),
        isTrue,
        reason: 'singleTask required for Share intent reuse',
      );
    });

    test(
      'Router has expected critical paths (bank-import, export, create-expense)',
      () {
        final file = File('lib/core/router/app_router.dart');
        final content = file.readAsStringSync();
        expect(content.contains("path: '/bank-import'"), isTrue);
        expect(content.contains("path: '/export'"), isTrue);
        expect(content.contains("path: '/create-expense'"), isTrue);
      },
    );
  });
}
