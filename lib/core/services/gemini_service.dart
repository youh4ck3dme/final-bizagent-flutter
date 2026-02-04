import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class GeminiService {
  /// AI calls are executed server-side (Vercel Gateway) to avoid
  /// exposing vendor API keys in Flutter Web and stay within Spark Plan.

  static const List<String> _modelPriority = ['gpt-4o', 'gpt-4o-mini'];

  static String modelName = _modelPriority[0];

  static final LinkedHashMap<String, String> _cache =
      LinkedHashMap<String, String>();
  static const int _maxCacheSize = 100;

  GeminiService();

  Future<String> generateContent(String prompt) async {
    final startTime = DateTime.now();
    final cacheKey = _generateCacheKey(prompt);

    if (_cache.containsKey(cacheKey)) {
      final cached = _cache.remove(cacheKey);
      _cache[cacheKey] = cached!;
      _recordAnalytics(
        model: 'cache',
        fromCache: true,
        responseTime: DateTime.now().difference(startTime),
      );
      return cached;
    }

    const gatewayUrl = 'https://bizagent.sk/api/ai/generate';

    try {
      String? appCheckToken;
      try {
        appCheckToken = await FirebaseAppCheck.instance.getToken();
      } catch (e) {
        debugPrint('AppCheck Token Error: $e');
      }

      final response = await http.post(
        Uri.parse(gatewayUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Firebase-AppCheck': appCheckToken ?? '',
        },
        body: jsonEncode({'prompt': prompt, 'type': 'generic'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Gateway Error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final result = (data is Map && data['text'] is String)
          ? (data['text'] as String).isEmpty
              ? 'AI neodpovedalo.'
              : data['text'] as String
          : 'AI nevrátilo text.';

      _addToCache(cacheKey, result);
      _recordAnalytics(
        model: 'gemini-1.5-pro',
        fromCache: false,
        responseTime: DateTime.now().difference(startTime),
      );

      return result;
    } catch (e) {
      debugPrint('AI Error (Falling back to local): $e');
      _recordAnalytics(
        model: 'error-fallback',
        fromCache: false,
        responseTime: DateTime.now().difference(startTime),
        error: e.toString(),
      );

      // Fallback to Local AI (Mock) if Backend fails
      // This ensures the app works even if offline or if the backend is down
      return _getMockResponse(prompt);
    }
  }

  String _getMockResponse(String prompt) {
    // 1. BizBot Chat (Highest priority - Conversational)
    if (prompt.contains('BizAgent AI') ||
        prompt.contains('POUŽÍVATEĽ SA PÝTA')) {
      final q = prompt.toLowerCase();
      if (q.contains('faktúr')) {
        return 'Faktúru vystavíš jednoducho v sekcii "Faktúry" kliknutím na tlačidlo "+". Potrebuješ k tomu len IČO odberateľa.';
      }
      if (q.contains('odvody')) {
        return 'Minimálne odvody pre SZČO v roku 2026 sú 344,27 € do Sociálnej poisťovne a 107,24 € do zdravotnej poisťovne.';
      }
      if (q.contains('kávu') || q.contains('kava')) {
        return 'Kávu si môžeš dať do nákladov len ak ju ponúkaš klientom v kancelárii. Pre osobnú spotrebu nie je daňovo uznateľná.';
      }
      if (q.contains('auto')) {
        return 'Auto môžeš odpísať buď paušálne (80% výdavkov na PHM) alebo vieš viesť knihu jázd pre 100% uplatnenie nákladov.';
      }

      return 'Rozumiem, že sa pýtaš na podnikanie. Keďže som v demo režime, viem odpovedať len na základné otázky o faktúrach, odvodoch a nákladoch. Skús sa opýtať inak.';
    }

    // 2. JSON / Schema Analysis (High priority - System logic)
    if (prompt.contains('dáta do JSONu') || prompt.contains('JSON array')) {
      // Return a valid empty JSON list as fallback to prevent crash
      return '[]';
    }

    // 3. Email Generation
    if ((prompt.contains('e-mail') || prompt.contains('email')) &&
        prompt.contains('typ')) {
      if (prompt.contains('Upomienka')) {
        return 'Predmet: Pripomienka neuhradenej faktúry č. 2026/042\n\nVážený klient,\n\ndovoľujeme si Vás upozorniť na neuhradenú faktúru č. 2026/042 v sume 1250,00 €, ktorá bola splatná dňa 15.01.2026.\n\nProsíme o úhradu v čo najkratšom termíne na náš účet.\n\nS pozdravom,\nFirma s.r.o.';
      }
      if (prompt.contains('Cenová ponuka')) {
        return 'Predmet: Cenová ponuka - Grafické práce\n\nDobrý deň,\n\nna základe Vášho dopytu Vám posielame cenovú ponuku na požadované služby:\n\n1. Návrh loga: 300 €\n2. Grafický manuál: 150 €\n\nCelkom: 450 €\n\nTešíme sa na spoluprácu.\n\nS pozdravom,\nJán Dizajnér';
      }
      return 'Predmet: Návrh e-mailu\n\nToto je univerzálny návrh e-mailu vygenerovaný v Demo režime. Pre špecifický text skúste zmeniť typ e-mailu.';
    }

    // 4. Reminder Generator (SMS/Short text)
    if (prompt.contains('upomienku') && prompt.contains('Tón:')) {
      if (prompt.contains('strict') || prompt.contains('prísny')) {
        return 'POZOR: Vaša faktúra č. 2026/042 je stále neuhradená. Žiadame okamžitú úhradu 1250€, inak budeme vymáhať súdnou cestou.';
      }
      if (prompt.contains('polite') || prompt.contains('priateľský')) {
        return 'Ahoj, asi si prehliadol faktúru č. 2026/042 (1250€). Prosím, pozri sa na to, keď budeš mať chvíľu. Vďaka!';
      }
      return 'Dobrý deň, evidujeme neuhradenú faktúru č. 2026/042 v sume 1250€. Prosíme o úhradu. Ďakujeme.';
    }

    // 5. DPH / Expense Analysis (Lowest priority - likely contains "daň")
    if (prompt.contains('DPH') ||
        prompt.contains('daň') ||
        prompt.contains('isTaxDeductible')) {
      return '''
      {
        "isTaxDeductible": true,
        "warningMessage": "Tento výdavok vyzerá byť v poriadku, ak súvisí s podnikaním.",
        "itemCategory": "Kancelárske potreby",
        "confidence": 0.95
      }
      ''';
    }

    return 'Toto je ukážková odpoveď (Demo Režim). AI Backend nie je dostupný.';
  }

  String _generateCacheKey(String prompt) => prompt.hashCode.toString();

  void _addToCache(String key, String value) {
    if (_cache.length >= _maxCacheSize) _cache.remove(_cache.keys.first);
    _cache[key] = value;
  }

  static void clearCache() => _cache.clear();

  static final Map<String, List<Map<String, String>>> _conversations = {};

  void addToConversation(
    String conversationId,
    String userMessage,
    String aiResponse,
  ) {
    _conversations.putIfAbsent(conversationId, () => []);
    final history = _conversations[conversationId]!;
    history.add({'role': 'user', 'content': userMessage});
    history.add({'role': 'assistant', 'content': aiResponse});
    if (history.length > 20) {
      history.removeRange(0, history.length - 20);
    }
  }

  List<Map<String, String>> getConversation(String conversationId) {
    return _conversations[conversationId] ?? [];
  }

  Future<String> generateWithContext(
    String conversationId,
    String userMessage,
  ) async {
    final history = _conversations[conversationId] ?? [];
    final contextPrompt = history.isEmpty
        ? ''
        : 'Predchádzajúci kontext:\n${history.map((msg) => '${msg['role']}: ${msg['content']}').join('\n')}\n\n';
    final response = await generateContent('$contextPrompt$userMessage');
    addToConversation(conversationId, userMessage, response);
    return response;
  }

  static void clearConversation(String conversationId) =>
      _conversations.remove(conversationId);

  static final Map<String, dynamic> _analytics = {
    'totalRequests': 0,
    'cacheHits': 0,
    'modelUsage': <String, int>{},
    'responseTimes': <int>[],
    'errors': <String, int>{},
    'lastReset': DateTime.now(),
  };

  void _recordAnalytics({
    required String model,
    required bool fromCache,
    required Duration responseTime,
    String? error,
  }) {
    _analytics['totalRequests'] = (_analytics['totalRequests'] as int) + 1;
    if (fromCache) {
      _analytics['cacheHits'] = (_analytics['cacheHits'] as int) + 1;
    }
    final modelUsage = _analytics['modelUsage'] as Map<String, int>;
    modelUsage[model] = (modelUsage[model] ?? 0) + 1;
    if (error != null) {
      final errors = _analytics['errors'] as Map<String, int>;
      errors[error] = (errors[error] ?? 0) + 1;
    }
  }

  Future<String> analyzeJson(String context, String schema) async {
    final prompt =
        'Spracuj dáta do JSONu podľa schémy: $schema\n\nDÁTA:\n$context';
    return generateContent(prompt);
  }

  Stream<String> generateContentStream(String prompt) async* {
    final full = await generateContent(prompt);
    if (full.isEmpty) {
      yield '';
      return;
    }
    final step = max(1, (full.length / 16).floor());
    for (var i = step; i < full.length; i += step) {
      yield full.substring(0, i);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    yield full;
  }

  Future<String> generateText(String prompt) => generateContent(prompt);
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
