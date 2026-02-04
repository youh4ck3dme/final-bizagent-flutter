import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/core/demo_mode/demo_data_generator.dart';
import 'package:bizagent/core/demo_mode/demo_scenarios.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/proactive/widgets/proactive_alerts_widget.dart';
import 'package:bizagent/features/proactive/models/proactive_alert_model.dart';

/// E2E testy pre Proaktívny AI účtovník (predikcie, daňové odporúčania, anomálie).
void main() {
  group('AI Accountant E2E Tests', () {
    List<dynamic> demoOverrides(DemoScenario scenario) {
      return [
        expensesProvider.overrideWith(
          (ref) => Stream.value(DemoDataGenerator.generateExpenses(scenario)),
        ),
        invoicesProvider.overrideWith(
          (ref) => Stream.value(DemoDataGenerator.generateInvoices(scenario)),
        ),
      ];
    }

    testWidgets('displays proactive section with predictions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: demoOverrides(DemoScenario.standard).cast(),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ProactiveAlertsWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Proaktívny AI účtovník'), findsOneWidget);
      expect(find.byType(ProactiveAlertsWidget), findsOneWidget);
    });

    testWidgets('shows tax recommendation in tax_optimization scenario', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: demoOverrides(DemoScenario.taxOptimization).cast(),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ProactiveAlertsWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Proaktívny AI účtovník'), findsOneWidget);
      expect(find.textContaining('Daňový'), findsWidgets);
      expect(find.textContaining('ušetríš'), findsWidgets);
    });

    testWidgets('shows anomaly-style content in anomaly_detection scenario', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: demoOverrides(DemoScenario.anomalyDetection).cast(),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ProactiveAlertsWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Proaktívny AI účtovník'), findsOneWidget);
    });

    testWidgets('alert cards display amount when present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: demoOverrides(DemoScenario.standard).cast(),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ProactiveAlertsWidget()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('€'), findsWidgets);
    });
  });

  group('AI Accountant - Demo alerts data', () {
    test('generateProactiveAlerts returns correct structure for standard', () {
      final alerts = DemoDataGenerator.generateProactiveAlerts(
        DemoScenario.standard,
      );
      expect(alerts, isNotEmpty);
      expect(alerts.first.type, ProactiveAlertType.predictive);
      expect(alerts.first.title, contains('splatnosť'));
    });

    test(
      'generateProactiveAlerts for tax_optimization contains savings hint',
      () {
        final alerts = DemoDataGenerator.generateProactiveAlerts(
          DemoScenario.taxOptimization,
        );
        expect(alerts, isNotEmpty);
        expect(alerts.any((a) => a.secondaryAmount != null), isTrue);
      },
    );
  });
}
