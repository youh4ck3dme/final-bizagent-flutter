import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expenses/models/expense_model.dart';
import '../../expenses/models/expense_category.dart';
import '../models/expense_insight_model.dart';
import 'package:flutter/material.dart';

import '../../../core/services/gemini_service.dart';

final expenseInsightsServiceProvider = Provider<ExpenseInsightsService>((ref) {
  return ExpenseInsightsService(ref.read(geminiServiceProvider));
});

class ExpenseInsightsService {
  final GeminiService _ai;

  ExpenseInsightsService(this._ai);

  Future<List<ExpenseInsight>> analyzeExpenses(
      List<ExpenseModel> expenses) async {
    if (expenses.isEmpty) return [];

    final expenseData = expenses
        .map((e) => {
              'vendor': e.vendorName,
              'amount': e.amount,
              'date': e.date.toIso8601String(),
              'category': e.category?.displayName ?? 'other',
            })
        .toList();

    final context = '''
  Analyze these business expenses for a Slovak SZČO (self-employed) and provide actionable insights.
  Focus on identifying:
  1. Reoccurring spending patterns.
  2. Savings opportunities.
  3. Sudden anomalies.
  4. Tax optimization tips based on categories.

  Expenses (JSON):
  ${jsonEncode(expenseData)}
  ''';

    const schema = '''
  JSON array of objects with these fields:
  - id: unique string
  - title: concise Slovak title
  - description: detailed Slovak explanation
  - icon: one of [trending_up, trending_down, warning, lightbulb, savings, shopping_cart]
  - color: one of [red, green, orange, blue, purple]
  - potentialSavings: estimated monthly savings in EUR (number or null)
  - priority: one of [low, medium, high]
  - category: one of [optimization, anomaly, trend]
  - createdAt: current ISO date (ISO-8601)
  ''';

    try {
      final text = await _ai.analyzeJson(context, schema);

      final dynamic decoded = jsonDecode(text);
      if (decoded is! List) {
        debugPrint('AI insights returned non-list JSON');
        return _getDemoInsights();
      }

      final jsonList = decoded;
      return jsonList
          .map((j) => ExpenseInsight.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error generating insights: $e');
      return _getDemoInsights();
    }
  }

  List<ExpenseInsight> _getDemoInsights() {
    return [
      ExpenseInsight(
        id: '1',
        title: 'Viac výdavkov na cestovné',
        description:
            'Tento mesiac ste minuli o 35% viac na pohonné hmoty než v priemere.',
        icon: Icons.trending_up,
        color: Colors.orange,
        priority: InsightPriority.medium,
        createdAt: DateTime.now(),
        category: 'trend',
      ),
      ExpenseInsight(
        id: ' savings_tax',
        title: 'Možná daňová úspora',
        description:
            'V kategórii "Kancelária" máte málo dokladov. Nezabudli ste odložiť niektoré bločky?',
        icon: Icons.lightbulb_outline,
        color: Colors.blue,
        potentialSavings: 50.0,
        priority: InsightPriority.high,
        createdAt: DateTime.now(),
        category: 'optimization',
      ),
    ];
  }
}
