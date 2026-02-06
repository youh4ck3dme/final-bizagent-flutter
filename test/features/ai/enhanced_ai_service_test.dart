import 'dart:io';
import 'package:bizagent/core/services/enhanced_ai_service.dart';
import 'package:bizagent/core/services/gemini_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Create a mock for GeminiService to control its behavior if needed
// For this test we can also just use the real GeminiService since it has internal fallsbacks
@GenerateNiceMocks([MockSpec<GeminiService>()])
import 'enhanced_ai_service_test.mocks.dart';

void main() {
  late EnhancedAIService enhancedAIService;
  late MockGeminiService mockGeminiService;

  setUp(() {
    mockGeminiService = MockGeminiService();
    enhancedAIService = EnhancedAIService(mockGeminiService);
  });

  group('EnhancedAIService Tests', () {
    test('analyzeReceipt returns valid receipt data structure', () async {
      // Arrange
      final dummyFile = File('test_receipt.jpg');

      // We expect the mock/fallback behavior from GeminiService
      // Since we mocked GeminiService, we need to stub the method or use the real one.
      // Let's use the REAL GeminiService to test the actual fallback logic we wrote.
      final realGeminiService = GeminiService();
      final realEnhancedService = EnhancedAIService(realGeminiService);

      // Act
      // We create a dummy file just to pass the file existence check if any,
      // but readAsBytes in the service will fail if file doesn't exist.
      // The service catches the error and returns {'error': ...} OR the mock data depending on implementation.
      // Looking at my implementation: it tries readAsBytes inside try-catch.
      // So I need a real file or I need to mock the file reading.
      // Actually, verifying the *Service* logic is better done with Mocks to not depend on filesystem/network.

      when(mockGeminiService.analyzeReceiptImage(any)).thenAnswer((_) async => {
        "vendor": "Tesco Stores SR",
        "total": 45.80,
        "confidence": 0.95
      });

      final result = await enhancedAIService.analyzeReceipt(dummyFile);

      // Assert
      expect(result['vendor'], 'Tesco Stores SR');
      expect(result['total'], 45.80);
      expect(result['confidence'], 0.95);
    });

    test('askBizBot returns fallback message on error', () async {
      // Arrange
      when(mockGeminiService.generateContent(any)).thenThrow(Exception('Network Error'));

      // Act
      final response = await enhancedAIService.askBizBot('How do I pay taxes?');

      // Assert
      expect(response, contains('Ospravedlňujem sa'));
    });

    test('generateRevenueForecast returns mock forecast', () async {
       final result = await enhancedAIService.generateRevenueForecast([]);

       expect(result['trend'], 'up');
       expect(result['forecast_next_month'], 2500.0);
    });
  });
}
