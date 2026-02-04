import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bizagent/features/analytics/providers/expense_insights_provider.dart';
import 'package:bizagent/features/analytics/services/expense_insights_service.dart';
import 'package:bizagent/features/analytics/models/expense_insight_model.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/models/expense_category.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';

// Mock classes
class MockExpenseInsightsService extends Mock
    implements ExpenseInsightsService {
  List<ExpenseModel>? capturedExpenses;

  @override
  Future<List<ExpenseInsight>> analyzeExpenses(
    List<ExpenseModel> expenses,
  ) async {
    capturedExpenses = expenses;

    if (expenses.isEmpty) return [];

    return [
      ExpenseInsight(
        id: '1',
        title: 'Test Insight',
        description: 'Mock insight for testing',
        icon: Icons.lightbulb,
        color: Colors.blue,
        potentialSavings: 100.0,
        priority: InsightPriority.medium,
        category: 'optimization',
        createdAt: DateTime.now(),
      ),
    ];
  }
}

void main() {
  late MockExpenseInsightsService mockService;
  const testUser = UserModel(id: 'test-user', email: 'test@test.com');

  setUp(() {
    mockService = MockExpenseInsightsService();
  });

  group('ExpenseInsightsProvider', () {
    test('should provide insights when expenses are available', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(testUser)),
          expenseInsightsServiceProvider.overrideWithValue(mockService),
          expensesProvider.overrideWith((ref) => Stream.value([
            ExpenseModel(
              id: '1',
              userId: 'test-user',
              vendorName: 'Test Vendor',
              description: 'Test expense',
              amount: 50.0,
              date: DateTime.now(),
              category: ExpenseCategory.fuel,
            ),
          ])),
        ],
      );
      addTearDown(container.dispose);

      // We use AsyncValue matching instead of .future to be sure
      AsyncValue<List<ExpenseInsight>>? captured;
      container.listen(expenseInsightsProvider, (prev, next) {
        captured = next;
      }, fireImmediately: true);

      // Wait for data with a timeout
      final stopWatch = Stopwatch()..start();
      while ((captured == null || captured!.isLoading) && stopWatch.elapsedMilliseconds < 5000) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      expect(captured?.hasValue, isTrue);
      expect(captured!.asData!.value, isNotEmpty);
      expect(captured!.asData!.value.first.title, 'Test Insight');
    });

    test('should handle empty expenses list', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(testUser)),
          expenseInsightsServiceProvider.overrideWithValue(mockService),
          expensesProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      AsyncValue<List<ExpenseInsight>>? captured;
      container.listen(expenseInsightsProvider, (prev, next) {
        captured = next;
      }, fireImmediately: true);

      final stopWatch = Stopwatch()..start();
      while ((captured == null || captured!.isLoading) && stopWatch.elapsedMilliseconds < 5000) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      expect(captured?.hasValue, isTrue);
      expect(captured!.asData!.value, isEmpty);
    });

    test('should handle expenses loading state', () async {
      final completer = Completer<List<ExpenseModel>>();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(testUser)),
          expenseInsightsServiceProvider.overrideWithValue(mockService),
          expensesProvider.overrideWith((ref) => Stream.fromFuture(completer.future)),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(expenseInsightsProvider);
      expect(state.isLoading, isTrue);

      completer.complete([]);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('should handle expenses error state', () async {
      final controller = StreamController<List<ExpenseModel>>();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(testUser)),
          expenseInsightsServiceProvider.overrideWithValue(mockService),
          expensesProvider.overrideWith((ref) => controller.stream),
        ],
      );

      // Emit error
      controller.addError('Test error');

      // Wait for the provider to catch it
      AsyncValue? captured;
      container.listen(expenseInsightsProvider, (prev, next) {
        captured = next;
      }, fireImmediately: true);

      final stopWatch = Stopwatch()..start();
      while ((captured == null || captured!.isLoading) && stopWatch.elapsedMilliseconds < 2000) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      expect(captured?.hasError, isTrue);

      await controller.close();
      container.dispose();
    });
  });
}
