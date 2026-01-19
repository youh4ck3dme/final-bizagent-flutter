import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../../shared/widgets/biz_card.dart';

class CashflowAnalyticsScreen extends ConsumerWidget {
  const CashflowAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytika Cashflow'),
      ),
      body: (invoicesAsync.isLoading || expensesAsync.isLoading)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainChart(context, invoicesAsync.value ?? [],
                      expensesAsync.value ?? []),
                  const SizedBox(height: 24),
                  _buildCategoryBreakdown(context, expensesAsync.value ?? []),
                  const SizedBox(height: 24),
                  _buildProfitLossCard(context, invoicesAsync.value ?? [],
                      expensesAsync.value ?? []),
                ],
              ),
            ),
    );
  }

  Widget _buildMainChart(
      BuildContext context, List<dynamic> invoices, List<dynamic> expenses) {
    return BizCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Príjmy vs Výdavky (6 mesiacov)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 5000, // Dynamic max would be better
                barGroups: _generateBarGroups(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'Maj',
                          'Jun'
                        ];
                        return Text(titles[value.toInt() % titles.length],
                            style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('Príjmy', Colors.green),
              const SizedBox(width: 16),
              _legendItem('Výdavky', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    // Mock data for demo
    return List.generate(6, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
              toY: 2000 + (i * 300.0), color: Colors.green, width: 12),
          BarChartRodData(
              toY: 1500 + (i * 200.0), color: Colors.red, width: 12),
        ],
      );
    });
  }

  Widget _buildCategoryBreakdown(BuildContext context, List<dynamic> expenses) {
    return BizCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rozdelenie výdavkov',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                      color: Colors.blue,
                      value: 40,
                      title: 'Služby',
                      radius: 50,
                      titleStyle:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                  PieChartSectionData(
                      color: Colors.orange,
                      value: 30,
                      title: 'Nákup',
                      radius: 50,
                      titleStyle:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                  PieChartSectionData(
                      color: Colors.purple,
                      value: 20,
                      title: 'Doprava',
                      radius: 50,
                      titleStyle:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                  PieChartSectionData(
                      color: Colors.grey,
                      value: 10,
                      title: 'Iné',
                      radius: 50,
                      titleStyle:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ],
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossCard(
      BuildContext context, List<dynamic> invoices, List<dynamic> expenses) {
    final totalIncome = invoices.fold(0.0, (sum, i) => sum + i.totalAmount);
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final profit = totalIncome - totalExpense;

    return Container(
      decoration: BoxDecoration(
        color: profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Čistý zisk / strata',
                  style: TextStyle(color: Colors.black54)),
              Text(
                NumberFormat.currency(symbol: '€').format(profit),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          Icon(
            profit >= 0 ? Icons.trending_up : Icons.trending_down,
            size: 48,
            color: profit >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
