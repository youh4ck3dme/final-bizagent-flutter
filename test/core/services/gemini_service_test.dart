import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/gemini_service.dart';

void main() {
  group('GeminiService Stability Tests', () {
    test('Should use stable "gemini-pro" model', () {
      // strict check to ensure we never accidentally revert to 'gemini-1.5-flash' or other betas
      expect(GeminiService.modelName, equals('gemini-pro'));
    });

    test('Should reject empty API keys gracefully', () async {
      final service = GeminiService(apiKey: '');
      final result = await service.generateContent('Hello');
      expect(result, contains('Chyba: Gemini API kľúč nie je platný'));
    });
    
    test('Should reject developer placeholder keys', () async {
      final service = GeminiService(apiKey: 'DEVELOPER_API_KEY');
      final result = await service.generateContent('Hello');
      expect(result, contains('Chyba: Gemini API kľúč nie je platný'));
    });
  });
}
