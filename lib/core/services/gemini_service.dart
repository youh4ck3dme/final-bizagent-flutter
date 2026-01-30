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

  static const List<String> _modelPriority = [
    'gpt-4o',
    'gpt-4o-mini',
  ];

  static String modelName = _modelPriority[0];

  static final LinkedHashMap<String, String> _cache = LinkedHashMap<String, String>();
  static const int _maxCacheSize = 100;

  GeminiService();

  Future<String> generateContent(String prompt) async {
    final startTime = DateTime.now();
    final cacheKey = _generateCacheKey(prompt);

    if (_cache.containsKey(cacheKey)) {
      final cached = _cache.remove(cacheKey);
      _cache[cacheKey] = cached!;
      _recordAnalytics(model: 'cache', fromCache: true, responseTime: DateTime.now().difference(startTime));
      return cached;
    }

    const gatewayUrl = 'https://bizagent.sk/api/ai/generate';

    try {
      final appCheckToken = await FirebaseAppCheck.instance.getToken();

      final response = await http.post(
        Uri.parse(gatewayUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Firebase-AppCheck': appCheckToken ?? '',
        },
        body: jsonEncode({
          'prompt': prompt,
          'type': 'generic',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gateway Error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final result = (data is Map && data['text'] is String)
          ? (data['text'] as String).isEmpty ? 'AI neodpovedalo.' : data['text'] as String
          : 'AI nevrátilo text.';

      _addToCache(cacheKey, result);
      _recordAnalytics(model: 'gemini-1.5-pro', fromCache: false, responseTime: DateTime.now().difference(startTime));

      return result;
    } catch (e) {
      debugPrint('AI Error: $e');
      _recordAnalytics(model: 'error', fromCache: false, responseTime: DateTime.now().difference(startTime), error: e.toString());
      return 'AI Offline: Skúste to neskôr.';
    }
  }

  String _generateCacheKey(String prompt) => prompt.hashCode.toString();

  void _addToCache(String key, String value) {
    if (_cache.length >= _maxCacheSize) _cache.remove(_cache.keys.first);
    _cache[key] = value;
  }

  static void clearCache() => _cache.clear();

  static final Map<String, List<Map<String, String>>> _conversations = {};
  static const int _maxConversationHistory = 10;

  void addToConversation(String conversationId, String userMessage, String aiResponse) {
    _conversations.putIfAbsent(conversationId, () => []);
    final history = _conversations[conversationId]!;
    history.add({'role': 'user', 'content': userMessage});
    history.add({'role': 'assistant', 'content': aiResponse});
    if (history.length > _maxConversationHistory * 2) {
      history.removeRange(0, history.length - _maxConversationHistory * 2);
    }
  }

  Future<String> generateWithContext(String conversationId, String userMessage) async {
    final history = _conversations[conversationId] ?? [];
    final contextPrompt = history.isEmpty ? '' : 'Predchádzajúci kontext:\n${history.map((msg) => '${msg['role']}: ${msg['content']}').join('\n')}\n\n';
    final response = await generateContent('$contextPrompt$userMessage');
    addToConversation(conversationId, userMessage, response);
    return response;
  }

  static void clearConversation(String conversationId) => _conversations.remove(conversationId);

  static final Map<String, dynamic> _analytics = {
    'totalRequests': 0,
    'cacheHits': 0,
    'modelUsage': <String, int>{},
    'responseTimes': <int>[],
    'errors': <String, int>{},
    'lastReset': DateTime.now(),
  };

  void _recordAnalytics({required String model, required bool fromCache, required Duration responseTime, String? error}) {
    _analytics['totalRequests'] = (_analytics['totalRequests'] as int) + 1;
    if (fromCache) _analytics['cacheHits'] = (_analytics['cacheHits'] as int) + 1;
    final modelUsage = _analytics['modelUsage'] as Map<String, int>;
    modelUsage[model] = (modelUsage[model] ?? 0) + 1;
    if (error != null) {
      final errors = _analytics['errors'] as Map<String, int>;
      errors[error] = (errors[error] ?? 0) + 1;
    }
  }

  Future<String> analyzeJson(String context, String schema) async {
    final prompt = 'Spracuj dáta do JSONu podľa schémy: $schema\n\nDÁTA:\n$context';
    return generateContent(prompt);
  }

  Stream<String> generateContentStream(String prompt) async* {
    final full = await generateContent(prompt);
    if (full.isEmpty) { yield ''; return; }
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
