import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/receipt_detective/screens/receipt_detective_screen.dart';
import 'package:bizagent/features/receipt_detective/providers/receipt_detective_provider.dart';
import 'package:bizagent/features/receipt_detective/models/reconstructed_suggestion_model.dart';

void main() {
  group('ReceiptDetectiveScreen', () {
    testWidgets('shows empty state when no suggestions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            receiptDetectiveSuggestionsProvider.overrideWith(
              (ref) => const AsyncValue.data([]),
            ),
          ],
          child: const MaterialApp(home: ReceiptDetectiveScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bloček Detective'), findsOneWidget);
      expect(find.textContaining('Žiadne návrhy'), findsOneWidget);
    });

    testWidgets('shows list when provider has suggestions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            receiptDetectiveSuggestionsProvider.overrideWith((ref) {
              return AsyncValue.data([
                ReconstructedExpenseSuggestion(
                  id: '1',
                  amount: 47.80,
                  date: DateTime(2026, 1, 15),
                  vendorHint: 'Tesco',
                  source: ReconstructedSource.noReceipt,
                  confidence: 70,
                ),
              ]);
            }),
          ],
          child: const MaterialApp(home: ReceiptDetectiveScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bloček Detective'), findsOneWidget);
      expect(find.text('Tesco'), findsOneWidget);
      expect(find.textContaining('47.80'), findsOneWidget);
    });
  });
}
