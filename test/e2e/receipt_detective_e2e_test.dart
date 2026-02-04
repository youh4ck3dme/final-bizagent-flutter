import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/core/demo_mode/demo_data_generator.dart';
import 'package:bizagent/core/demo_mode/demo_scenarios.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/receipt_detective/screens/receipt_detective_screen.dart';
import 'package:bizagent/features/receipt_detective/models/reconstructed_suggestion_model.dart';

/// E2E testy pre Bloček Detective – rekonštrukcia dokladov.
void main() {
  group('Receipt Detective E2E Tests', () {
    testWidgets('shows suggestions when demo expenses without receipt', (
      tester,
    ) async {
      final expenses = DemoDataGenerator.generateExpenses(
        DemoScenario.receiptMissing,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith((ref) => Stream.value(expenses)),
          ],
          child: const MaterialApp(home: ReceiptDetectiveScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bloček Detective'), findsOneWidget);
      expect(find.textContaining('Žiadne návrhy'), findsNothing);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('shows empty state when no expenses without receipt', (
      tester,
    ) async {
      final expenses = DemoDataGenerator.generateExpenses(
        DemoScenario.taxOptimization,
      );
      final onlyWithReceipt =
          expenses.where((e) => e.receiptUrls.isNotEmpty).toList();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith(
              (ref) => Stream.value(onlyWithReceipt),
            ),
          ],
          child: const MaterialApp(home: ReceiptDetectiveScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bloček Detective'), findsOneWidget);
      expect(find.textContaining('Žiadne návrhy'), findsOneWidget);
    });

    testWidgets('suggestion card shows confidence and amount', (tester) async {
      final suggestions = DemoDataGenerator.generateReconstructedSuggestions(
        DemoScenario.receiptMissing,
      );
      expect(suggestions, isNotEmpty);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith(
              (ref) => Stream.value(
                DemoDataGenerator.generateExpenses(DemoScenario.receiptMissing),
              ),
            ),
          ],
          child: const MaterialApp(home: ReceiptDetectiveScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('€'), findsWidgets);
    });

    test('confidence label and isAcceptableForTax are correct', () {
      final high = ReconstructedExpenseSuggestion(
        id: '1',
        amount: 100,
        date: DateTime.now(),
        vendorHint: 'Test',
        source: ReconstructedSource.bank,
        confidence: 90,
      );
      expect(high.confidenceLabel, 'Vysoká');
      expect(high.isAcceptableForTax, isTrue);

      final low = ReconstructedExpenseSuggestion(
        id: '2',
        amount: 50,
        date: DateTime.now(),
        vendorHint: 'Test',
        source: ReconstructedSource.noReceipt,
        confidence: 60,
      );
      expect(low.confidenceLabel, 'Nízka');
      expect(low.isAcceptableForTax, isFalse);
    });
  });
}
