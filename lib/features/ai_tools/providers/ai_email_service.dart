import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiEmailServiceProvider = Provider<AiEmailService>((ref) {
  return AiEmailService();
});

class AiEmailService {
  AiEmailService();

  Future<String> generateEmail({
    required String type,
    required String tone,
    required String context,
  }) async {
    if (context.isEmpty) {
      return 'Prosím, zadajte kontext pre vygenerovanie e-mailu.';
    }

    try {
      // Volanie zabezpečenej Cloud Function
      // Funkcia beží na serveri a má bezpečný prístup k API kľúču
      final callable = FirebaseFunctions.instance.httpsCallable('generateEmail');
      
      final result = await callable.call({
        'type': _getReadableType(type),
        'tone': tone,
        'context': context,
      });

      final data = result.data as Map<String, dynamic>;
      return data['text'] as String? ?? 'Nepodarilo sa získať text.';
      
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function Error: ${e.code} - ${e.message}');
      return 'Chyba servera: ${e.message}';
    } catch (e) {
      debugPrint('General Error: $e');
      return 'Nepodarilo sa spojiť so serverom. Skontrolujte pripojenie.';
    }
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
