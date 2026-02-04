import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../models/reconstructed_suggestion_model.dart';
import '../services/receipt_detective_service.dart';

final receiptDetectiveServiceProvider = Provider<ReceiptDetectiveService>((
  ref,
) {
  return ReceiptDetectiveService();
});

/// Návrhy Bloček Detective – rekonštrukcia dokladov z fragmentov.
final receiptDetectiveSuggestionsProvider =
    Provider<AsyncValue<List<ReconstructedExpenseSuggestion>>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final service = ref.watch(receiptDetectiveServiceProvider);

  return expensesAsync.when(
    data: (expenses) {
      final list = service.getAllSuggestions(expenses: expenses);
      return AsyncValue.data(list);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
