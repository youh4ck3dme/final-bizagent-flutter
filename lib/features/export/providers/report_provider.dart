import '../../invoices/providers/invoices_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../models/report_model.dart';
import '../models/export_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_provider.g.dart';

@riverpod
class ReportController extends _$ReportController {
  @override
  AsyncValue<ReportData?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> generateReport(ExportPeriod period) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final invoices = ref.read(invoicesProvider).value ?? [];
      final expenses = ref.read(expensesProvider).value ?? [];

      final filteredInvoices = invoices.where(
        (inv) =>
            inv.dateIssued.isAfter(
              period.from.subtract(const Duration(seconds: 1)),
            ) &&
            inv.dateIssued.isBefore(period.to.add(const Duration(seconds: 1))),
      );

      final filteredExpenses = expenses.where(
        (ex) =>
            ex.date.isAfter(period.from.subtract(const Duration(seconds: 1))) &&
            ex.date.isBefore(period.to.add(const Duration(seconds: 1))),
      );

      double totalIncome = 0;
      double totalVatIncome = 0;
      final Map<double, double> vatIncomeBreakdown = {};
      final Map<String, double> clientTotals = {};

      for (var inv in filteredInvoices) {
        totalIncome += inv.grandTotalEur;
        // inv.totalVat is in original currency
        totalVatIncome += (inv.totalVat / inv.exchangeRate);

        inv.vatBreakdown.forEach((rate, amount) {
          final amountEur = amount / inv.exchangeRate;
          vatIncomeBreakdown[rate] =
              (vatIncomeBreakdown[rate] ?? 0) + amountEur;
        });

        clientTotals[inv.clientName] =
            (clientTotals[inv.clientName] ?? 0) + inv.grandTotalEur;
      }

      double totalExpenses = 0;
      double totalVatExpenses = 0;
      final Map<double, double> vatExpenseBreakdown = {};
      final Map<String, double> vendorTotals = {};

      for (var ex in filteredExpenses) {
        totalExpenses += ex.amountInEur;
        // Použiť reálne DPH dáta ak sú dostupné
        final vat = (ex.vatAmount ?? 0.0) / ex.exchangeRate;
        totalVatExpenses += vat;

        // Breakdown podľa sadzby
        if (ex.vatRate != null && ex.vatAmount != null) {
          final vatEur = ex.vatAmount! / ex.exchangeRate;
          vatExpenseBreakdown[ex.vatRate!] =
              (vatExpenseBreakdown[ex.vatRate!] ?? 0) + vatEur;
        }

        vendorTotals[ex.vendorName] =
            (vendorTotals[ex.vendorName] ?? 0) + ex.amountInEur;
      }

      final sortedExpenses = vendorTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final sortedClients = clientTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return ReportData(
        from: period.from,
        to: period.to,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        totalVatIncome: totalVatIncome,
        totalVatExpenses: totalVatExpenses,
        vatIncomeBreakdown: vatIncomeBreakdown,
        vatExpenseBreakdown: vatExpenseBreakdown,
        topExpenses: sortedExpenses
            .take(5)
            .map((e) => ReportItem(label: e.key, amount: e.value))
            .toList(),
        topClients: sortedClients
            .take(5)
            .map((e) => ReportItem(label: e.key, amount: e.value))
            .toList(),
      );
    });
  }
}
