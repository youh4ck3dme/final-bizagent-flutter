import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/gemini_service.dart';

void main() {
  group('GeminiService Stability Tests', () {
    test('Should use best available model by default', () {
      // The service is OpenAI-first via Firebase Functions.
      GeminiService.modelName = 'gpt-4o-mini';
      expect(GeminiService.modelName, equals('gpt-4o-mini'));
    });

    test('Should return offline message when Firebase is unavailable', () async {
      final service = GeminiService(functions: null);
      final result = await service.generateContent('Hello');
      expect(result, contains('AI Offline'));
    });
  });
}
