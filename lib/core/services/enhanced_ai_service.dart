import 'package:bizagent/core/services/gemini_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// Placeholder for future Vercel API base URL - currently using direct GeminiService as fallback
const String kAIBaseUrl = 'https://api.bizagent.live/api/ai';

class EnhancedAIService {
  final GeminiService _geminiService;
  // TODO: Add Auth Service for secure API calls

  EnhancedAIService(this._geminiService);

  // 🧠 Phase 1: Enhanced BizBot Strategy
  Future<String> askBizBot(String query, {List<Map<String, dynamic>>? context}) async {
    // 1. Try Vercel Function (Server-side AI)
    try {
      // Logic to call server-side function will go here
      // For now, fallback to direct client-side Gemini 1.5/2.5
      return await _geminiService.generateContent(query);
    } catch (e) {
      // Fallback
      return "Ospravedlňujem sa, ale momentálne neviem spracovať tvoju požiadavku. Skús to prosím neskôr.";
    }
  }

  // 👁️ Phase 2: Vision Analysis (Receipt Detective 2.0)
  Future<Map<String, dynamic>> analyzeReceipt(File imageFile) async {
    // Will use Gemini Vision to extract JSON
    return _geminiService.analyzeReceiptImage(imageFile);
  }

  // 🔮 Phase 3: Predictive Intelligence
  Future<Map<String, dynamic>> generateRevenueForecast(List<dynamic> historicalData) async {
    // Mock implementation for UI testing
    await Future.delayed(const Duration(seconds: 2));
    return {
      'forecast_next_month': 2500.0,
      'trend': 'up',
      'confidence': 0.85
    };
  }
}

final enhancedAIServiceProvider = Provider<EnhancedAIService>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return EnhancedAIService(geminiService);
});
