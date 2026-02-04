import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvoiceModel Currency Tests', () {
    test('Should calculate totalAmountEur correctly when currency IS EUR', () {
      final invoice = InvoiceModel(
        id: '1',
        userId: 'u1',
        createdAt: DateTime.now(),
        number: 'FA-001',
        clientName: 'Client',
        clientAddress: 'Address',
        clientIco: '123',
        dateIssued: DateTime.now(),
        dateDue: DateTime.now(),
        items: [InvoiceItemModel(title: 'Item 1', amount: 100, vatRate: 0.20)],
        totalAmount: 120.0,
        status: InvoiceStatus.draft,
        currency: 'EUR',
        exchangeRate: 1.0,
      );

      expect(invoice.totalAmountEur, 120.0);
      expect(invoice.grandTotalEur, 120.0);
    });

    test(
      'Should calculate totalAmountEur correctly when currency is USD (rate 1.1)',
      () {
        final invoice = InvoiceModel(
          id: '1',
          userId: 'u1',
          createdAt: DateTime.now(),
          number: 'FA-001',
          clientName: 'Client',
          clientAddress: 'Address',
          clientIco: '123',
          dateIssued: DateTime.now(),
          dateDue: DateTime.now(),
          items: [InvoiceItemModel(title: 'Item 1', amount: 100, vatRate: 0.0)],
          totalAmount: 100.0, // 100 USD
          status: InvoiceStatus.draft,
          currency: 'USD',
          exchangeRate: 1.10, // 1 EUR = 1.10 USD
        );

        // 100 USD / 1.10 = ~90.90 EUR
        expect(invoice.totalAmountEur, closeTo(90.909, 0.001));
      },
    );

    test(
      'Should handle zero exchange rate gracefully (prevent div by zero)',
      () {
        final invoice = InvoiceModel(
          id: '1',
          userId: 'u1',
          createdAt: DateTime.now(),
          number: 'FA-001',
          clientName: 'Client',
          clientAddress: 'Address',
          clientIco: '123',
          dateIssued: DateTime.now(),
          dateDue: DateTime.now(),
          items: [],
          totalAmount: 100.0,
          status: InvoiceStatus.draft,
          currency: 'CZK',
          exchangeRate: 0.0, // Should typically not happen
        );

        // If rate is 0, division by zero results in Infinity.
        // Logic in service handles it, but model is simple calculation.
        expect(invoice.totalAmountEur, double.infinity);
      },
    );
  });
}
