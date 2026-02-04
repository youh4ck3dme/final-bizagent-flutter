import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';

void main() {
  group('ExpenseModel VAT Tests', () {
    test('calculate baseAmount correctly when vatAmount is provided', () {
      final expense = ExpenseModel(
        id: '1',
        userId: 'u1',
        vendorName: 'Test Vendor',
        description: 'Test',
        amount: 120.0,
        date: DateTime.now(),
        vatAmount: 20.0,
        vatRate: 0.20,
      );

      expect(expense.baseAmount, 100.0);
    });

    test('calculate baseAmount correctly when vatAmount is null', () {
      final expense = ExpenseModel(
        id: '1',
        userId: 'u1',
        vendorName: 'Test Vendor',
        description: 'Test',
        amount: 120.0,
        date: DateTime.now(),
        vatAmount: null,
        vatRate: null,
      );

      expect(expense.baseAmount, 120.0);
    });

    test('toMap and fromMap should preserve VAT data', () {
      final original = ExpenseModel(
        id: '1',
        userId: 'u1',
        vendorName: 'Test Vendor',
        description: 'Test',
        amount: 120.0,
        date: DateTime.now(),
        vatAmount: 20.0,
        vatRate: 0.20,
      );

      final map = original.toMap();
      final decoded = ExpenseModel.fromMap(map, '1');

      expect(decoded.vatAmount, 20.0);
      expect(decoded.vatRate, 0.20);
      expect(decoded.baseAmount, 100.0);
    });
  });
}
