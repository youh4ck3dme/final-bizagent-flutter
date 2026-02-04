import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/core/demo_mode/demo_data_generator.dart';
import 'package:bizagent/core/demo_mode/demo_scenarios.dart';
import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/proactive/widgets/proactive_alerts_widget.dart';
import 'package:bizagent/features/receipt_detective/screens/receipt_detective_screen.dart';

/// Golden testy pre UI regression. Spusti s --update-goldens pri zmene layoutu.
void main() {
  group('Golden Tests - AI UI', () {
    testWidgets('ProactiveAlertsWidget matches golden', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith(
              (ref) => Stream.value(
                DemoDataGenerator.generateExpenses(DemoScenario.standard),
              ),
            ),
            invoicesProvider.overrideWith(
              (ref) => Stream.value(
                DemoDataGenerator.generateInvoices(DemoScenario.standard),
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: BizTheme.slovakBlue),
            ),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: ProactiveAlertsWidget(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ProactiveAlertsWidget),
        matchesGoldenFile('goldens/proactive_alerts_widget.png'),
      );
    });

    testWidgets('ReceiptDetectiveScreen with suggestions matches golden', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith(
              (ref) => Stream.value(
                DemoDataGenerator.generateExpenses(DemoScenario.receiptMissing),
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: BizTheme.slovakBlue),
            ),
            home: const ReceiptDetectiveScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ReceiptDetectiveScreen),
        matchesGoldenFile('goldens/receipt_detective_screen.png'),
      );
    });
  });
}
