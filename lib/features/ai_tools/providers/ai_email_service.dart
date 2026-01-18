import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/config/api_config.dart';

final aiEmailServiceProvider = Provider<AiEmailService>((ref) {
  return AiEmailService();
});

class AiEmailService {
  late final GenerativeModel? _model;

  AiEmailService() {
    if (ApiConfig.hasGeminiKey) {
      _model = GenerativeModel(
        model: ApiConfig.geminiModel,
        apiKey: ApiConfig.geminiApiKey,
      );
    } else {
      _model = null;
    }
  }

  Future<String> generateEmail({
    required String type,
    required String tone,
    required String context,
  }) async {
    // Ak nemáme API key, vrátime inštrukciu pre developera/užívateľa
    if (_model == null) {
      return '⚠️ Gemini API kľúč chýba.\n\nPre aktiváciu AI funkcií:\n1. Získajte kľúč na aistudio.google.com\n2. Nastavte GEMINI_API_KEY (viď firebase_gemini_setup.md)';
    }

    if (context.isEmpty) {
      return 'Prosím, zadajte kontext pre vygenerovanie e-mailu.';
    }

    try {
      final prompt = _buildPrompt(type, tone, context);
      final response = await _model!.generateContent([Content.text(prompt)]);
      
      return response.text ?? 'Nepodarilo sa vygenerovať odpoveď (prázdny text).';
    } catch (e) {
      return 'Chyba pri komunikácii s AI: $e';
    }
  }

  String _buildPrompt(String type, String tone, String context) {
    return '''
Úloha: Napíš profesionálny firemný e-mail v slovenskom jazyku.

Parametre:
- Typ správy: $_getReadableType(type)
- Tón komunikácie: $tone
- Kontext/Detaily: "$context"

Požiadavky:
- Použij spisovnú slovenčinu.
- Dodržuj štruktúru: Oslovenie, Jadro správy, Záver, Podpis.
- Buď stručný ale zdvorilý.
- Ak ide o upomienku, buď profesionálny.
    ''';
  }

  String _getReadableType(String type) {
    switch (type) {
      case 'reminder': return 'Upomienka k platbe';
      case 'quote': return 'Cenová ponuka';
      case 'intro': return 'Predstavenie služieb';
      default: return type;
    }
  }
}
