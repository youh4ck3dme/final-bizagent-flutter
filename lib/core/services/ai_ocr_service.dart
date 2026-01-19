import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ocr_service.dart';

final aiOcrServiceProvider = Provider<AiOcrService>((ref) {
  return AiOcrService();
});

class AiOcrService {
  AiOcrService();

  Future<ParsedReceipt?> refineWithAi(String rawText,
      {String? imagePath}) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('analyzeReceipt');

      final result = await callable.call({
        'text': rawText,
      });

      final data = result.data as Map<String, dynamic>;

      return ParsedReceipt(
        totalAmount: data['suma']?.toString(),
        date: data['datum']?.toString(),
        vendorId: data['ico']?.toString(),
        originalText: rawText,
        imagePath: imagePath,
      );
    } catch (e) {
      debugPrint('AI OCR Error: $e');
      // Fallback to null - the caller should handle it or use regex result
      return null;
    }
  }
}
