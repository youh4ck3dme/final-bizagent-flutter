import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/proactive/services/proactive_alerts_service.dart';
import 'package:bizagent/features/proactive/models/proactive_alert_model.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/tax/providers/tax_thermometer_service.dart';

void main() {
  group('ProactiveAlertsService', () {
    late ProactiveAlertsService service;

    setUp(() {
      service = ProactiveAlertsService();
    });

    test('returns tax strategist when no expenses (quarter gap)', () {
      final alerts = service.generateAlerts(
        invoices: [],
        expenses: [],
        taxResult: null,
      );
      // S 0 výdavkami je „gap“ 2500 € → daňový stratég
      expect(alerts, isNotEmpty);
      expect(
        alerts.any((a) => a.type == ProactiveAlertType.taxStrategist),
        isTrue,
      );
    });

    test('generates predictive alert for invoice due in 5 days', () {
      final dueIn5 = DateTime.now().add(const Duration(days: 5));
      final invoices = [
        InvoiceModel(
          id: 'inv1',
          userId: 'u1',
          number: '2026/001',
          clientName: 'Client',
          clientAddress: 'Addr',
          clientIco: null,
          clientDic: null,
          dateIssued: DateTime.now(),
          dateDue: dueIn5,
          items: [],
          totalAmount: 340,
          status: InvoiceStatus.sent,
          createdAt: DateTime.now(),
        ),
      ];
      final alerts = service.generateAlerts(
        invoices: invoices,
        expenses: [],
        taxResult: null,
      );
      expect(alerts.length, greaterThanOrEqualTo(1));
      final predictive =
          alerts.where((a) => a.type == ProactiveAlertType.predictive).toList();
      expect(predictive, isNotEmpty);
      expect(predictive.first.title, contains('dní'));
      expect(predictive.first.amount, 340);
    });

    test('generates tax strategist alert when quarter expenses gap >= 500', () {
      final alerts = service.generateAlerts(
        invoices: [],
        expenses: [], // 0 expenses -> gap = 2500
        taxResult: null,
      );
      final taxAlerts = alerts
          .where((a) => a.type == ProactiveAlertType.taxStrategist)
          .toList();
      expect(taxAlerts, isNotEmpty);
      expect(taxAlerts.first.body, contains('kvartál'));
    });

    test('generates VAT warning when tax result is warning', () {
      final taxResult = TaxThermometerResult(currentTurnover: 45000);
      expect(taxResult.isWarning, isTrue);
      final alerts = service.generateAlerts(
        invoices: [],
        expenses: List.generate(
          20,
          (i) => ExpenseModel(
            id: 'e$i',
            userId: 'u1',
            vendorName: 'V',
            description: 'd',
            amount: 100,
            date: DateTime.now(),
          ),
        ),
        taxResult: taxResult,
      );
      final vatAlert = alerts
          .where((a) => a.body.contains('DPH') || a.body.contains('limitu'))
          .toList();
      expect(vatAlert, isNotEmpty);
    });
  });
}
