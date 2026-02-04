import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/core/demo_mode/demo_data_generator.dart';
import 'package:bizagent/core/demo_mode/demo_mode_service.dart';
import 'package:bizagent/core/demo_mode/demo_scenarios.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/proactive/widgets/proactive_alerts_widget.dart';
import 'package:bizagent/features/receipt_detective/screens/receipt_detective_screen.dart';

/// Integračný E2E – demo mode + AI účtovník + Bloček Detective v jednom flow.
void main() {
  group('Full Flow E2E', () {
    testWidgets('demo mode provides data for both AI widgets', (tester) async {
      final demo = DemoModeService.instance;
      demo.activateDemoMode(DemoScenario.standard);

      final expenses = demo.getDemoExpenses();
      final invoices = demo.getDemoInvoices();
      expect(expenses, isNotEmpty);
      expect(invoices, isNotEmpty);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith((ref) => Stream.value(expenses)),
            invoicesProvider.overrideWith((ref) => Stream.value(invoices)),
          ],
          child: MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (_) => const Scaffold(
                    body: SingleChildScrollView(child: ProactiveAlertsWidget()),
                  ),
              '/receipt-detective': (_) => const ReceiptDetectiveScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Proaktívny AI účtovník'), findsOneWidget);

      demo.deactivateDemoMode();
    });

    test('DemoDataGenerator produces valid data for all scenarios', () {
      for (final scenario in DemoScenario.values) {
        final expenses = DemoDataGenerator.generateExpenses(scenario);
        final invoices = DemoDataGenerator.generateInvoices(scenario);
        final suggestions = DemoDataGenerator.generateReconstructedSuggestions(
          scenario,
        );
        final alerts = DemoDataGenerator.generateProactiveAlerts(scenario);

        expect(expenses, isNotEmpty);
        expect(invoices, isNotEmpty);
        expect(suggestions, isNotNull);
        expect(alerts, isNotNull);
        expect(
          expenses.every(
            (e) => e.id.isNotEmpty && e.userId == DemoDataGenerator.demoUserId,
          ),
          isTrue,
        );
        expect(
          invoices.every((i) => i.number.isNotEmpty && i.totalAmount > 0),
          isTrue,
        );
      }
    });

    test('DemoModeService triple-tap toggles demo mode', () {
      final demo = DemoModeService.instance;
      demo.deactivateDemoMode();
      expect(demo.isDemoMode, isFalse);

      demo.recordLogoTap();
      demo.recordLogoTap();
      demo.recordLogoTap();
      expect(demo.isDemoMode, isTrue);

      demo.recordLogoTap();
      demo.recordLogoTap();
      demo.recordLogoTap();
      expect(demo.isDemoMode, isFalse);
    });

    test('generateLargeExpenseDataset returns requested count', () {
      final list = DemoDataGenerator.generateLargeExpenseDataset(1000);
      expect(list.length, 1000);
      expect(list.first.userId, DemoDataGenerator.demoUserId);
    });
  });
}
