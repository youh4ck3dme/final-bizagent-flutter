import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/demo_mode/demo_data_generator.dart';
import 'package:bizagent/core/demo_mode/demo_scenarios.dart';
import 'package:bizagent/features/proactive/services/proactive_alerts_service.dart';
import 'package:bizagent/features/receipt_detective/services/receipt_detective_service.dart';

/// Performance benchmarks pre AI funkcie (CI/CD ready).
void main() {
  group('Performance Benchmarks', () {
    test('prediction (alert generation) under 500ms', () async {
      final service = ProactiveAlertsService();
      final expenses = DemoDataGenerator.generateExpenses(
        DemoScenario.standard,
      );
      final invoices = DemoDataGenerator.generateInvoices(
        DemoScenario.standard,
      );
      final stopwatch = Stopwatch()..start();
      service.generateAlerts(
        invoices: invoices,
        expenses: expenses,
        taxResult: null,
        currentBalance: 5000,
        reserveBalance: 1000,
      );
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: 'Alert generation should complete under 500ms',
      );
    });

    test('receipt detective getAllSuggestions under 500ms', () async {
      final service = ReceiptDetectiveService();
      final expenses = DemoDataGenerator.generateExpenses(
        DemoScenario.receiptMissing,
      );
      final stopwatch = Stopwatch()..start();
      service.getAllSuggestions(expenses: expenses);
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: 'Receipt Detective suggestions should complete under 500ms',
      );
    });

    test('large dataset (1000 expenses) alert generation under 2s', () async {
      final service = ProactiveAlertsService();
      final expenses = DemoDataGenerator.generateLargeExpenseDataset(1000);
      final invoices = DemoDataGenerator.generateInvoices(
        DemoScenario.standard,
      );
      final stopwatch = Stopwatch()..start();
      service.generateAlerts(
        invoices: invoices,
        expenses: expenses,
        taxResult: null,
      );
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Large dataset alert generation under 2s',
      );
    });

    test('large dataset (1000 expenses) receipt detective under 1s', () async {
      final service = ReceiptDetectiveService();
      final expenses = DemoDataGenerator.generateLargeExpenseDataset(1000);
      final stopwatch = Stopwatch()..start();
      service.getAllSuggestions(expenses: expenses);
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Receipt Detective on 1000 expenses under 1s',
      );
    });
  });
}
