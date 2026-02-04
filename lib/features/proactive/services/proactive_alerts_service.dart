import 'package:flutter/material.dart';
import '../../invoices/models/invoice_model.dart';
import '../../expenses/models/expense_model.dart';
import '../../tax/providers/tax_thermometer_service.dart';
import '../models/proactive_alert_model.dart';

/// Generuje proaktívne alerty: prediktívne, daňový stratég, anomálie.
/// "Váš digitálny CFO, ktorý nikdy nespí."
class ProactiveAlertsService {
  ProactiveAlertsService();

  static const int daysAheadForPredictive = 5;
  static const double quarterExpenseGapThreshold = 500.0;
  static const double vatWarningThreshold = 0.8; // 80% limitu

  List<ProactiveAlert> generateAlerts({
    required List<InvoiceModel> invoices,
    required List<ExpenseModel> expenses,
    required TaxThermometerResult? taxResult,
    double? currentBalance,
    double? reserveBalance,
  }) {
    final alerts = <ProactiveAlert>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Prediktívne: faktúra o X dní + nízký zostatok
    final unpaidSent = invoices.where(
      (i) =>
          i.status == InvoiceStatus.sent || i.status == InvoiceStatus.overdue,
    );
    for (final inv in unpaidSent) {
      final daysUntilDue = inv.dateDue.difference(today).inDays;
      if (daysUntilDue >= 0 && daysUntilDue <= daysAheadForPredictive) {
        final hasLowBalance = currentBalance != null &&
            reserveBalance != null &&
            currentBalance < inv.totalAmount &&
            (currentBalance + reserveBalance) >= inv.totalAmount;
        alerts.add(
          ProactiveAlert(
            id: 'predictive-inv-${inv.id}',
            type: ProactiveAlertType.predictive,
            title: 'O $daysUntilDue dní splatnosť faktúry',
            body: hasLowBalance
                ? 'Faktúra ${inv.number} ~€${inv.totalAmount.toStringAsFixed(0)}. Na účte máš €${currentBalance.toStringAsFixed(0)}. Odporúčam presunúť €${(inv.totalAmount - currentBalance).toStringAsFixed(0)} z rezervy.'
                : 'Faktúra ${inv.number} (~€${inv.totalAmount.toStringAsFixed(0)}) splatná ${inv.dateDue.day}.${inv.dateDue.month}.${inv.dateDue.year}.',
            actionLabel: 'Detail faktúry',
            actionRoute: '/invoices',
            dueDate: inv.dateDue,
            amount: inv.totalAmount,
            icon: Icons.notifications_active,
            color: Colors.orange,
            createdAt: now,
          ),
        );
      }
    }

    // 2. Daňový stratég: do konca kvartálu chýba X € vo výdavkoch
    final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
    final quarterExpenses = expenses
        .where(
          (e) => e.date.isAfter(quarterStart.subtract(const Duration(days: 1))),
        )
        .fold<double>(0.0, (s, e) => s + e.amount);
    // Jednoduchý cieľ: aspoň 20% z predpokladaných výdavkov (mock: 2500€ za kvartál)
    const quarterExpenseTarget = 2500.0;
    final gap = quarterExpenseTarget - quarterExpenses;
    if (gap >= quarterExpenseGapThreshold) {
      final taxSavingHint = (gap * 0.19).toStringAsFixed(0); // ~19% daň
      alerts.add(
        ProactiveAlert(
          id: 'tax-strategist-quarter',
          type: ProactiveAlertType.taxStrategist,
          title: 'Daňový stratég',
          body:
              'Do konca kvartálu ti chýba €${gap.toStringAsFixed(0)} vo výdavkoch. Kúp teraz potreby (notebook, softvér) – ušetríš cca €$taxSavingHint na daniach.',
          actionLabel: 'Pridať výdavok',
          actionRoute: '/create-expense',
          amount: gap,
          secondaryAmount: double.tryParse(taxSavingHint),
          icon: Icons.savings_outlined,
          color: Colors.green,
          createdAt: now,
        ),
      );
    }

    // 3. DPH limit (daňový teplomer)
    if (taxResult != null && taxResult.isWarning) {
      alerts.add(
        ProactiveAlert(
          id: 'tax-vat-warning',
          type: ProactiveAlertType.taxStrategist,
          title: 'Blížiš sa k limitu DPH',
          body:
              'Obrat za 12 mesiacov je ${(taxResult.percentage * 100).toStringAsFixed(0)}% limitu (49 790 €). Zváž pripravu na registráciu DPH.',
          actionLabel: 'Daňový prehľad',
          actionRoute: '/analytics',
          amount: taxResult.currentTurnover,
          secondaryAmount: taxResult.threshold,
          icon: Icons.warning_amber_rounded,
          color: Colors.amber,
          createdAt: now,
        ),
      );
    }

    return alerts;
  }
}
