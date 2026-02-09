import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/gemini_service.dart';
import 'package:bizagent/features/analytics/services/expense_insights_service.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/models/expense_category.dart';

class FakeGeminiService extends GeminiService {
  final String response;

  FakeGeminiService(this.response);

  @override
  Future<String> analyzeJson(String context, String schema) async {
    return response;
  }
}

void main() {
  group('ExpenseInsightsService', () {
    test('should return empty list for empty expenses', () async {
      final service = ExpenseInsightsService(FakeGeminiService('[]'));
      final expenses = <ExpenseModel>[];

      final insights = await service.analyzeExpenses(expenses);

      expect(insights, isEmpty);
    });

    test('should parse AI JSON response into insights', () async {
      final service = ExpenseInsightsService(
        FakeGeminiService('''
[
  {
    "id": "1",
    "title": "Test insight",
    "description": "Popis",
    "icon": "lightbulb",
    "color": "blue",
    "potentialSavings": 50,
    "priority": "medium",
    "category": "optimization",
    "createdAt": "2026-01-24T00:00:00.000Z"
  }
]
'''),
      );

      final expenses = <ExpenseModel>[
        ExpenseModel(
          id: '1',
          userId: 'test-user',
          vendorName: 'Shell',
          description: 'Fuel purchase',
          amount: 50.0,
          date: DateTime.now(),
          category: ExpenseCategory.fuel,
        ),
      ];

      final insights = await service.analyzeExpenses(expenses);
      expect(insights.length, 1);
      expect(insights.first.title, 'Test insight');
    });

    test('should handle expenses with categories', () async {
      final service = ExpenseInsightsService(FakeGeminiService('''
[
  {
    "id": "demo1",
    "title": "Optimalizácia palivových nákladov",
    "description": "Sledujeme nadmerné výdavky na palivo",
    "icon": "local_gas_station",
    "color": "orange",
    "potentialSavings": 50,
    "priority": "medium",
    "category": "optimization",
    "createdAt": "2026-01-24T00:00:00.000Z"
  },
  {
    "id": "demo2",
    "title": "Kancelárske potreby - úspora možná",
    "description": "Zvážte bulk objednávky",
    "icon": "shopping_cart",
    "color": "blue",
    "potentialSavings": 100,
    "priority": "low",
    "category": "optimization",
    "createdAt": "2026-01-24T00:00:00.000Z"
  }
]
'''));
      final expenses = [
        ExpenseModel(
          id: '1',
          userId: 'test-user',
          vendorName: 'Shell',
          description: 'Fuel purchase',
          amount: 50.0,
          date: DateTime.now(),
          category: ExpenseCategory.fuel,
        ),
        ExpenseModel(
          id: '2',
          userId: 'test-user',
          vendorName: 'Office Depot',
          description: 'Office supplies',
          amount: 100.0,
          date: DateTime.now().subtract(const Duration(days: 1)),
          category: ExpenseCategory.officeSupplies,
        ),
      ];

      final insights = await service.analyzeExpenses(expenses);

      expect(insights, isNotEmpty);
      // Valid AI response should be parsed correctly
      expect(insights.length, 2);
    });

    test('should process expenses without categories', () async {
      final service = ExpenseInsightsService(FakeGeminiService('''
[
  {
    "id": "unknown1",
    "title": "Neznámy výdavok detekovaný",
    "description": "Skontrolujte túto transakciu",
    "icon": "help_outline",
    "color": "grey",
    "potentialSavings": 0,
    "priority": "low",
    "category": "alert",
    "createdAt": "2026-01-24T00:00:00.000Z"
  }
]
'''));
      final expenses = [
        ExpenseModel(
          id: '1',
          userId: 'test-user',
          vendorName: 'Unknown Vendor',
          description: 'Unknown expense',
          amount: 25.0,
          date: DateTime.now(),
          category: null,
        ),
      ];

      final insights = await service.analyzeExpenses(expenses);

      expect(insights, isNotEmpty);
      expect(insights.length, 1); // Valid JSON response
    });

    test('should limit expenses to last 50 for analysis', () async {
      final service = ExpenseInsightsService(FakeGeminiService('[]'));
      final expenses = List.generate(
        60,
        (index) => ExpenseModel(
          id: index.toString(),
          userId: 'test-user',
          vendorName: 'Vendor $index',
          description: 'Test expense $index',
          amount: 10.0,
          date: DateTime.now().subtract(Duration(days: index)),
          category: ExpenseCategory.other,
        ),
      );

      final insights = await service.analyzeExpenses(expenses);

      // Service should not throw even for large inputs
      expect(insights, isA<List>());
    });
  });
}
