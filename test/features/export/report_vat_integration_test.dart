import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/export/providers/report_provider.dart';
import 'package:bizagent/features/export/models/export_models.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'dart:async';

void main() {
  group('ReportController Integration Tests (Sprint 1 VAT)', () {
    test(
      'generateReport aggregates VAT from both Invoices and Expenses correctly',
      () async {
        final now = DateTime.now();
        final container = ProviderContainer(
          overrides: [
            invoicesProvider.overrideWith(
              (ref) => Stream.value([
                InvoiceModel(
                  id: 'inv1',
                  userId: 'u1',
                  number: '2026/001',
                  clientName: 'Client A',
                  dateIssued: now,
                  dateDue: now.add(const Duration(days: 14)),
                  createdAt: now,
                  items: [
                    InvoiceItemModel(
                      title: 'Item',
                      amount: 100,
                      vatRate: 0.20,
                    ), // 20 VAT
                  ],
                  totalAmount: 120.0,
                  status: InvoiceStatus.paid,
                ),
              ]),
            ),
            expensesProvider.overrideWith(
              (ref) => Stream.value([
                ExpenseModel(
                  id: 'ex1',
                  userId: 'u1',
                  vendorName: 'Vendor B',
                  description: 'Expense with VAT',
                  amount: 120.0,
                  date: now,
                  vatAmount: 20.0,
                  vatRate: 0.20,
                ),
                ExpenseModel(
                  id: 'ex2',
                  userId: 'u1',
                  vendorName: 'Vendor C',
                  description: 'Expense without VAT',
                  amount: 50.0,
                  date: now,
                  vatAmount: null,
                  vatRate: null,
                ),
              ]),
            ),
          ],
        );

        final period = ExportPeriod(
          from: now.subtract(const Duration(days: 1)),
          to: now.add(const Duration(days: 1)),
        );

        // Wait for data state
        final invCompleter = Completer<void>();
        container.listen(invoicesProvider, (prev, next) {
          if (next.hasValue) invCompleter.complete();
        }, fireImmediately: true);

        final expCompleter = Completer<void>();
        container.listen(expensesProvider, (prev, next) {
          if (next.hasValue) expCompleter.complete();
        }, fireImmediately: true);

        await Future.wait([
          invCompleter.future.timeout(const Duration(seconds: 5)),
          expCompleter.future.timeout(const Duration(seconds: 5)),
        ]);

        await container
            .read(reportControllerProvider.notifier)
            .generateReport(period);

        final report = container.read(reportControllerProvider).value;

        expect(report, isNotNull);
        expect(report!.totalIncome, 120.0);
        expect(report.totalExpenses, 170.0);
        expect(report.totalVatIncome, 20.0);
        expect(report.totalVatExpenses, 20.0);

        expect(report.vatExpenseBreakdown[0.20], 20.0);
        expect(report.vatIncomeBreakdown[0.20], 20.0);

        container.dispose();
      },
    );
  });
}
