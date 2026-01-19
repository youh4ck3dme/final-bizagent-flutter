import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/ai_tools/screens/ai_tools_screen.dart';
import 'package:bizagent/core/services/ocr_service.dart';
import 'package:image_picker/image_picker.dart';

// Mock OcrService
class MockOcrService extends OcrService {
  @override
  Future<ParsedReceipt?> scanReceipt(ImageSource source) async {
    return ParsedReceipt(
      totalAmount: '15.50',
      date: '20.03.2024',
      vendorId: '12345678',
      originalText: 'Mock Receipt Text',
    );
  }
}

void main() {
  testWidgets('AiToolsScreen displays parsed receipt data',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ocrServiceProvider.overrideWithValue(MockOcrService()),
        ],
        child: const MaterialApp(
          home: AiToolsScreen(),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('AI Nástroje'), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);

    // Simulate functionality (Since we can't easily click camera in test without mocking ImagePicker platform,
    // we might need to rely on the service override or structure the code for easier testing.
    // However, pressing the button triggers _scan which calls our mock service.)

    // Tap generic "Kamera" button
    await tester.tap(find.text('Kamera'));
    await tester.pump(); // Start scanning
    await tester.pump(const Duration(
        seconds: 1)); // Finish scanning (mock is instant, but just in case)

    // Verify fields are populated
    expect(find.text('15.50'), findsOneWidget);
    expect(find.text('20.03.2024'), findsOneWidget);
    expect(find.text('12345678'), findsOneWidget);

    // Verify "Show Full Text" contains original text
    expect(find.text('Zobraziť celý text'), findsOneWidget);
  });
}
