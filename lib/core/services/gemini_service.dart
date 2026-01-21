import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeminiService {
  final String _apiKey;
  late final GenerativeModel _model;

  GeminiService({required String apiKey}) : _apiKey = apiKey {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> generateContent(String prompt) async {
    if (_apiKey == 'DEVELOPER_API_KEY' || _apiKey.isEmpty) {
      return 'Chyba: API kľúč nie je nastavený. Prosím, nastavte GEMINI_API_KEY.';
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'AI nevrátilo žiadny text.';
    } on GenerativeAIException catch (e) {
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
final _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'DEVELOPER_API_KEY');

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: _apiKey);
});
