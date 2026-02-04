import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/receipt_detective/services/receipt_detective_service.dart';
import 'package:bizagent/features/receipt_detective/models/reconstructed_suggestion_model.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';

void main() {
  group('ReceiptDetectiveService', () {
    late ReceiptDetectiveService service;

    setUp(() {
      service = ReceiptDetectiveService();
    });

    test('returns empty list when no expenses', () {
      final list = service.getAllSuggestions(expenses: []);
      expect(list, isEmpty);
    });

    test('returns empty list when all expenses have receipts', () {
      final expenses = [
        ExpenseModel(
          id: 'e1',
          userId: 'u1',
          vendorName: 'Tesco',
          description: 'nákup',
          amount: 47.80,
          date: DateTime.now(),
          receiptUrls: ['https://example.com/receipt.jpg'],
        ),
      ];
      final list = service.getAllSuggestions(expenses: expenses);
      expect(list, isEmpty);
    });

    test('returns suggestions for expenses without receipt', () {
      final expenses = [
        ExpenseModel(
          id: 'e1',
          userId: 'u1',
          vendorName: 'Tesco Lamač',
          description: 'nákup',
          amount: 47.80,
          date: DateTime(2026, 1, 15),
          receiptUrls: [],
        ),
      ];
      final list = service.getAllSuggestions(expenses: expenses);
      expect(list.length, 1);
      expect(list.first.source, ReconstructedSource.noReceipt);
      expect(list.first.amount, 47.80);
      expect(list.first.vendorHint, 'Tesco Lamač');
      expect(list.first.expenseId, 'e1');
      expect(list.first.confidence, 70);
    });

    test('sorts suggestions by date descending', () {
      final expenses = [
        ExpenseModel(
          id: 'e1',
          userId: 'u1',
          vendorName: 'A',
          description: '',
          amount: 10,
          date: DateTime(2026, 1, 1),
          receiptUrls: [],
        ),
        ExpenseModel(
          id: 'e2',
          userId: 'u1',
          vendorName: 'B',
          description: '',
          amount: 20,
          date: DateTime(2026, 1, 10),
          receiptUrls: [],
        ),
      ];
      final list = service.getAllSuggestions(expenses: expenses);
      expect(list.length, 2);
      expect(
        list.first.date.isAfter(list.last.date) ||
            list.first.date.isAtSameMomentAs(list.last.date),
        isTrue,
      );
    });
  });
}
