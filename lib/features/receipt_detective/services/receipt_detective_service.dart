import '../../expenses/models/expense_model.dart';
import '../models/reconstructed_suggestion_model.dart';

/// "Bloček Detective" – rekonštrukcia stratených dokladov z fragmentov.
/// Navrhuje výdavky z: výdavkov bez účtenky, (budúcnosť: banka, GPS, email, fotky).
class ReceiptDetectiveService {
  ReceiptDetectiveService();

  /// Kandidáti na rekonštrukciu: výdavky bez priloženej účtenky.
  List<ReconstructedExpenseSuggestion> suggestionsFromExpensesWithoutReceipt(
    List<ExpenseModel> expenses,
  ) {
    final withoutReceipt = expenses.where(
      (e) =>
          e.receiptUrls.isEmpty &&
          (e.thumbnailUrl == null || e.thumbnailUrl!.isEmpty),
    );
    return withoutReceipt
        .map(
          (e) => ReconstructedExpenseSuggestion(
            id: 'no-receipt-${e.id}',
            amount: e.amount,
            date: e.date,
            vendorHint: e.vendorName,
            description: e.description.isNotEmpty ? e.description : null,
            source: ReconstructedSource.noReceipt,
            confidence: 70,
            expenseId: e.id,
          ),
        )
        .toList();
  }

  /// Všetky návrhy (zatiaľ len z výdavkov bez účtenky; neskôr + bank, geo, email).
  List<ReconstructedExpenseSuggestion> getAllSuggestions({
    required List<ExpenseModel> expenses,
  }) {
    final list = <ReconstructedExpenseSuggestion>[];
    list.addAll(suggestionsFromExpensesWithoutReceipt(expenses));
    return list..sort((a, b) => b.date.compareTo(a.date));
  }
}
