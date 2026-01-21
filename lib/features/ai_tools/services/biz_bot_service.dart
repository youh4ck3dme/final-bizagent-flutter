import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../expenses/models/expense_category.dart';
import '../../settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class BizBotService {
  final GeminiService _gemini;
  final Ref _ref;

  BizBotService(this._gemini, this._ref);

  Future<String> ask(String question) async {
    final context = await _prepareContext();
    
    final systemPrompt = '''
Si BizAgent AI - inteligentný asistent pre slovenských podnikateľov. 
Máš prístup k aktuálnym finančným údajom používateľa (uvedené nižšie).
Tvojou úlohou je stručne a profesionálne odpovedať na otázky týkajúce sa jeho podnikania, daní a výdavkov v slovenčine.

AKTUÁLNY KONTEXT POUŽÍVATEĽA:
$context

PRAVIDLÁ:
1. Odpovedaj v slovenčine.
2. Buď vecný a presný.
3. Ak nepoznáš odpoveď na základe dát, priznaj to a navrhni všeobecnú radu pre slovenské prostredie.
4. Nikdy neuvádzaj fiktívne čísla, ak nie sú v kontexte.
''';

    return await _gemini.generateContent('$systemPrompt\n\nPOUŽÍVATEĽ SA PÝTA: $question');
  }

  Future<String> _prepareContext() async {
    final settings = _ref.read(settingsProvider).valueOrNull;
    final invoices = _ref.read(invoicesProvider).valueOrNull ?? [];
    final expenses = _ref.read(expensesProvider).valueOrNull ?? [];

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    final monthInvoices = invoices.where((i) => i.dateIssued.isAfter(monthStart)).toList();
    final monthExpenses = expenses.where((e) => e.date.isAfter(monthStart)).toList();

    double totalInvoiced = monthInvoices.fold(0, (sum, i) => sum + i.totalAmount);
    double totalExpenses = monthExpenses.fold(0, (sum, e) => sum + e.amount);

    final currency = NumberFormat.currency(symbol: '€', locale: 'sk_SK');

    return '''
Firma: ${settings?.companyName ?? 'Neznáma'}
IČO: ${settings?.companyIco ?? '-'}
Platca DPH: ${settings?.isVatPayer ?? false ? 'Áno' : 'Nie'}

ŠTATISTIKA ZA TENTO MESIAC (${DateFormat('MMMM yyyy', 'sk').format(now)}):
- Celkovo vyfakturované: ${currency.format(totalInvoiced)}
- Celkové výdavky: ${currency.format(totalExpenses)}
- Počet faktúr: ${monthInvoices.length}
- Počet výdavkov: ${monthExpenses.length}

POSLEDNÉ TRANSAKCIE:
${monthExpenses.take(5).map((e) => "- ${e.vendorName}: ${currency.format(e.amount)} (${e.category?.displayName})").join('\n')}
''';
  }
}

final bizBotServiceProvider = Provider<BizBotService>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  return BizBotService(gemini, ref);
});
