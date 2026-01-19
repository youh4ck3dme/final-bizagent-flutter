import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../shared/widgets/biz_empty_state.dart';
import '../../../shared/widgets/biz_shimmer.dart';
import '../providers/expenses_provider.dart';
import '../models/expense_model.dart';
import '../models/expense_category.dart';
import '../widgets/expense_filter_sheet.dart';

// Provider pre filtre
final expenseFilterProvider = StateProvider<ExpenseFilterCriteria>((ref) {
  return const ExpenseFilterCriteria();
});

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final filterCriteria = ref.watch(expenseFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(AppStr.expensesTitle)),
        actions: [
          // Analytics Button
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: 'Analytika',
            onPressed: () => context.push('/expenses/analytics'),
          ),
          // Filter Button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters(filterCriteria))
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filtrovať',
            onPressed: () => _showFilterSheet(context, ref, filterCriteria),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-expense'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expensesProvider);
          await ref.read(expensesProvider.future);
        },
        child: expensesAsync.when(
          data: (expenses) {
            final filteredExpenses = _applyFilters(expenses, filterCriteria);

            if (expenses.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 24),
                          child: BizEmptyState(
                            title: context.t(AppStr.expensesEmptyTitle),
                            body: context.t(AppStr.expensesEmptyMsg),
                            ctaLabel: context.t(AppStr.expensesEmptyCta),
                            onCta: () => context.push('/create-expense'),
                            icon: Icons.shopping_bag_outlined,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            if (filteredExpenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.filter_alt_off,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Žiadne výdavky vyhovujúce filtrom'),
                    TextButton(
                      onPressed: () {
                        ref.read(expenseFilterProvider.notifier).state =
                            const ExpenseFilterCriteria();
                      },
                      child: const Text('Zrušiť filtre'),
                    ),
                  ],
                ),
              );
            }

            // Group by month
            final grouped = <String, List<ExpenseModel>>{};
            for (var e in filteredExpenses) {
              final month =
                  DateFormat('MMMM yyyy', 'sk').format(e.date); // Slovak locale
              grouped.putIfAbsent(month, () => []).add(e);
            }

            final months = grouped.keys.toList();

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: months.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final month = months[index];
                final monthExpenses = grouped[month]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            month.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                          ),
                          Text(
                            // Calculate total for month
                            NumberFormat.currency(symbol: '€').format(
                                monthExpenses.fold(
                                    0.0, (sum, e) => sum + e.amount)),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.blueGrey,
                                ),
                          ),
                        ],
                      ),
                    ),
                    ...monthExpenses.map(
                        (expense) => _buildExpenseItem(context, ref, expense)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
          error: (err, stack) => Center(child: Text('Chyba: $err')),
          loading: () => const BizListShimmer(),
        ),
      ),
    );
  }

  bool _hasActiveFilters(ExpenseFilterCriteria criteria) {
    return criteria.selectedCategories.isNotEmpty ||
        criteria.dateRange != null ||
        criteria.sortOption != ExpenseSortOption.dateDesc || // Default sort
        criteria.amountRange?.start != 0 || // If modified
        (criteria.amountRange?.end ?? 1000) != 1000;
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref,
      ExpenseFilterCriteria currentCriteria) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ExpenseFilterSheet(
          initialCriteria: currentCriteria,
          onApply: (newCriteria) {
            ref.read(expenseFilterProvider.notifier).state = newCriteria;
          },
        ),
      ),
    );
  }

  List<ExpenseModel> _applyFilters(
      List<ExpenseModel> expenses, ExpenseFilterCriteria criteria) {
    var result = List<ExpenseModel>.from(expenses);

    // 1. Categories
    if (criteria.selectedCategories.isNotEmpty) {
      result = result
          .where((e) => criteria.selectedCategories.contains(e.category))
          .toList();
    }

    // 2. Date Range
    if (criteria.dateRange != null) {
      result = result
          .where((e) =>
              e.date.isAfter(criteria.dateRange!.start
                  .subtract(const Duration(days: 1))) &&
              e.date.isBefore(
                  criteria.dateRange!.end.add(const Duration(days: 1))))
          .toList();
    }

    // 3. Amount Range
    if (criteria.amountRange != null) {
      result = result
          .where((e) =>
              e.amount >= criteria.amountRange!.start &&
              e.amount <= criteria.amountRange!.end)
          .toList();
    }

    // 4. Sorting
    switch (criteria.sortOption) {
      case ExpenseSortOption.dateDesc:
        result.sort((a, b) => b.date.compareTo(a.date));
        break;
      case ExpenseSortOption.dateAsc:
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
      case ExpenseSortOption.amountDesc:
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case ExpenseSortOption.amountAsc:
        result.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return result;
  }

  Widget _buildExpenseItem(
      BuildContext context, WidgetRef ref, ExpenseModel expense) {
    final category = expense.category ?? ExpenseCategory.other;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Zmazať výdavok?'),
            content:
                Text('Naozaj chcete zmazať výdavok "${expense.vendorName}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Zrušiť')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Zmazať')),
            ],
          ),
        );

        if (shouldDelete == true) {
          ref
              .read(expensesControllerProvider.notifier)
              .deleteExpense(expense.id);
          return true;
        }
        return false;
      },
      background: Container(
        color: Colors.red.shade100,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Colors.red.shade700),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            context.push('/expenses/detail', extra: expense);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, color: category.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.vendorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (expense.description.isNotEmpty)
                        Text(
                          expense.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      if (expense.receiptUrls.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: InkWell(
                            onTap: () {
                              context.push('/expenses/receipt-viewer', extra: {
                                'url': expense.receiptUrls.first,
                                'isLocal': false,
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.attach_file,
                                    size: 14,
                                    color: Theme.of(context).primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Účtenka',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(symbol: '€').format(expense.amount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        if (expense.categorizationConfidence != null &&
                            expense.categorizationConfidence! < 100)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.auto_awesome,
                                size: 12, color: Colors.amber),
                          ),
                        Text(
                          DateFormat('d.M.').format(expense.date),
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
