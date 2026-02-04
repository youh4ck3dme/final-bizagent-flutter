import 'package:intl/intl.dart';

class ReportData {
  final DateTime from;
  final DateTime to;
  final double totalIncome;
  final double totalExpenses;
  final double totalVatIncome;
  final double totalVatExpenses;
  final Map<double, double> vatIncomeBreakdown;
  final Map<double, double> vatExpenseBreakdown;
  final List<ReportItem> topExpenses;
  final List<ReportItem> topClients;

  ReportData({
    required this.from,
    required this.to,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalVatIncome,
    required this.totalVatExpenses,
    required this.vatIncomeBreakdown,
    required this.vatExpenseBreakdown,
    required this.topExpenses,
    required this.topClients,
  });

  double get netProfit => totalIncome - totalExpenses;
  double get vatBalance => totalVatIncome - totalVatExpenses;

  String get periodString =>
      '${DateFormat('dd.MM.yyyy').format(from)} - ${DateFormat('dd.MM.yyyy').format(to)}';
}

class ReportItem {
  final String label;
  final double amount;
  final double? percentage;

  ReportItem({required this.label, required this.amount, this.percentage});
}
