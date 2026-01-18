import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiEmailServiceProvider = Provider<AiEmailService>((ref) {
  return AiEmailService();
});

class AiEmailService {
  Future<String> generateEmail({
    required String type,
    required String tone,
    required String context,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (context.isEmpty) {
      return 'Prosím, zadajte kontext pre vygenerovanie e-mailu.';
    }

    // Mock response generation based on type
    switch (type) {
      case 'reminder':
        return _generateReminder(tone, context);
      case 'quote':
        return _generateQuote(tone, context);
      case 'intro':
        return _generateIntro(tone, context);
      default:
        return 'Nepodporovaný typ e-mailu.';
    }
  }

  String _generateReminder(String tone, String context) {
    if (tone == 'formal') {
      return '''
Vážený klient,

dovoľujeme si Vás upozorniť na neuhradenú faktúru, ktorej splatnosť vypršala. 

Detaily: $context

Prosíme o úhradu čo najskôr. V prípade, že ste platbu už zrealizovali, ignorujte prosím túto správu.

S pozdravom,
Váš tím
''';
    } else {
      return '''
Ahoj,

len priateľské pripomenutie k neuhradenej faktúre: $context.

Asi sa na to v návale práce zabudlo, budem rád ak sa na to pozrieš keď budeš mať chvíľu.

Vďaka!
''';
    }
  }

  String _generateQuote(String tone, String context) {
    return '''
Dobrý deň,

na základe Vášho dopytu ($context) Vám posielame nezáväznú cenovú ponuku.

Sme pripravení začať pracovať ihneď po schválení.

S pozdravom,
BizAgent
''';
  }

  String _generateIntro(String tone, String context) {
    return '''
Dobrý deň,

rád by som Vám predstavil naše služby v oblasti: $context.

Verím, že by sme vedeli nájsť priestor na vzájomnú spoluprácu.

S pozdravom,
''';
  }
}
