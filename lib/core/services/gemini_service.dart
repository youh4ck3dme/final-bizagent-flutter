import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  final String _apiKey;
  late final GenerativeModel _model;

  static const String modelName = 'gemini-pro';

  GeminiService({required String apiKey}) : _apiKey = apiKey {
    _model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
    );
  }

  Future<String> generateContent(String prompt) async {
    if (_apiKey == 'DEVELOPER_API_KEY' || _apiKey.trim().isEmpty || _apiKey == 'test_key') {
      return 'Chyba: Gemini API kľúč nie je platný. Prosím, pridajte platný kľúč cez --dart-define=GEMINI_API_KEY=vaš_kľúč.';
    }

    try {
      debugPrint('Gemini API executing with key length: ${_apiKey.length}');
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      debugPrint('Gemini API success: ${response.text?.substring(0, 20)}...');
      return response.text ?? 'AI nevrátilo žiadny text.';
    } on GenerativeAIException catch (e) {
      debugPrint('Gemini AI Exception: ${e.message}');
      if (e.message.contains('quota')) {
        return 'Dosiahli ste limit bezplatných dopytov (Quota Exceeded). Skúste to neskôr.';
      }
      return 'AI Chyba: ${e.message}';
    } catch (e) {
      return 'Neočakávaná chyba: $e';
    }
  }

  // Alias for backward compatibility if needed
  Future<String> generateText(String prompt) => generateContent(prompt);

  Future<String> analyzeJson(String context, String schema) async {
    final prompt = '''
      Si expert na slovenské účtovníctvo a biznis asistenciu.
      Spracuj nasledujúci kontext a vráť výsledok ako PURE JSON (bez markdown blokov) podľa schémy: $schema
      
      KONTEXT:
      $context
    ''';
    
    return generateContent(prompt);
  }
}

// Securely load from environment: flutter run --dart-define=GEMINI_API_KEY=your_key
final _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyD8Fq8rFgPA42Y5J_G-8cZ4RAfRGCt0zuw');

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: _apiKey);
});
