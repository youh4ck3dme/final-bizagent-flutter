import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../invoices/models/invoice_model.dart';
import '../widgets/upcoming_tax_widget.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../shared/widgets/biz_card.dart';
import '../../../shared/widgets/biz_section_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final invoicesAsync = ref.watch(invoicesProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(context.t(AppStr.spdTitle),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(invoicesProvider);
          ref.invalidate(expensesProvider);
          await Future.wait([
            ref.read(invoicesProvider.future),
            ref.read(expensesProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ahoj, ${user?.displayName ?? 'Používateľ'}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(context.t(AppStr.spdDisclaimer),
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(height: 24),

              // First-run banner (when user has no data yet)
              if (!(invoicesAsync.isLoading || expensesAsync.isLoading) &&
                  !(invoicesAsync.hasError || expensesAsync.hasError))
                _buildFirstRunBanner(
                  context,
                  invoices: invoicesAsync.value ?? const [],
                  expenses: expensesAsync.value ?? const [],
                ),

              // Overdue Alerts
              if (invoicesAsync.value != null)
                _buildOverdueAlert(context, invoicesAsync.value!),

              // Financial Summary
              if (invoicesAsync.isLoading || expensesAsync.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (invoicesAsync.hasError || expensesAsync.hasError)
                Text(context.t(AppStr.errorGeneric))
              else
                _buildFinancials(context, invoicesAsync.value ?? [],
                    expensesAsync.value ?? []),

              const SizedBox(height: 24),
              // Tax Widget
              const UpcomingTaxWidget(),

              const SizedBox(height: 32),

              // Quick Actions
              const BizSectionHeader(title: 'Rýchle akcie'),
              const SizedBox(height: 16),
              _buildActionTile(
                context,
                title: context.t(AppStr.invoiceTitle),
                subtitle: 'Nová faktúra pre klienta',
                icon: Icons.add_circle_outline,
                color: Colors.blue,
                onTap: () => context.push('/create-invoice'),
              ),
              _buildActionTile(
                context,
                title: 'Skenovať bloček',
                subtitle: 'AI vyčítanie údajov',
                icon: Icons.document_scanner_outlined,
                color: Colors.purple,
                onTap: () => context.push('/ai-tools'),
              ),
              _buildActionTile(
                context,
                title: 'Pridať výdavok',
                subtitle: 'Evidencia nákladov',
                icon: Icons.shopping_bag_outlined,
                color: Colors.orange,
                onTap: () => context.push('/create-expense'),
              ),
              _buildActionTile(
                context,
                title: 'Import bank CSV',
                subtitle: 'Automatické párovanie faktúr',
                icon: Icons.upload_file,
                color: Colors.teal,
                onTap: () => context.push('/bank-import'),
              ),
              _buildActionTile(
                context,
                title: 'Export pre účtovníka',
                subtitle: 'Zostava faktúr a výdavkov',
                icon: Icons.download,
                color: Colors.indigo,
                onTap: () => context.push('/export'),
              ),

              const SizedBox(height: 32),
              // Recent Invoices
              const BizSectionHeader(title: 'Posledné faktúry'),
              const SizedBox(height: 16),
              if (invoicesAsync.value != null)
                ...invoicesAsync.value!
                    .take(5)
                    .map((invoice) => _buildRecentInvoiceTile(context, invoice)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverdueAlert(BuildContext context, List<InvoiceModel> invoices) {
    final overdueCount = invoices
        .where((i) =>
            i.status == InvoiceStatus.overdue ||
            (i.status == InvoiceStatus.sent && i.dateDue.isBefore(DateTime.now())))
        .length;

    if (overdueCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/payment-reminders'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Máte $overdueCount faktúr po lehote splatnosti!',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentInvoiceTile(BuildContext context, InvoiceModel invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(invoice.clientName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(invoice.number),
        trailing: Text(
          NumberFormat.currency(symbol: '€').format(invoice.totalAmount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () => context.push('/invoices/${invoice.id}'),
      ),
    );
  }

  Widget _buildFinancials(
      BuildContext context, List<InvoiceModel> invoices, List<dynamic> expenses) {
    double totalIncome = 0;
    for (var i in invoices) {
      totalIncome += i.totalAmount;
    }

    double totalExpenses = 0;
    for (var e in expenses) {
      totalExpenses += e.amount;
    }

    return Column(
      children: [
        Row(
          children: [
            _buildSummaryCard(
              context,
              title: context.t(AppStr.incomeTotal),
              amount: NumberFormat.currency(symbol: '€').format(totalIncome),
              color: Colors.green,
              icon: Icons.trending_up,
            ),
            const SizedBox(width: 16),
            _buildSummaryCard(
              context,
              title: context.t(AppStr.expensesTotal),
              amount: NumberFormat.currency(symbol: '€').format(totalExpenses),
              color: Colors.red,
              icon: Icons.trending_down,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Pie Chart
        if (totalIncome > 0 || totalExpenses > 0)
          GestureDetector(
            onTap: () => context.push('/analytics'),
            child: BizCard(
              child: Column(children: [
              Text(context.t(AppStr.periodLabel),
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: Colors.green,
                        value: totalIncome,
                        title: '', // Too small
                        radius: 50,
                      ),
                      PieChartSectionData(
                        color: Colors.red,
                        value: totalExpenses,
                        title: '',
                        radius: 50,
                      ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem(
                      context, context.t(AppStr.incomeTotal), Colors.green),
                  const SizedBox(width: 16),
                  _legendItem(
                      context, context.t(AppStr.expensesTotal), Colors.red),
                ],
              )
            ]),
          ),),
      ],
    );
  }

  Widget _legendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: BizCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 13)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                amount,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(25),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFirstRunBanner(
    BuildContext context, {
    required List<dynamic> invoices,
    required List<dynamic> expenses,
  }) {
    final isEmpty = invoices.isEmpty && expenses.isEmpty;
    if (!isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BizCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Začni za 30 sekúnd',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vytvor prvú faktúru alebo pridaj výdavok. BizAgent ti začne počítať prehľad hneď.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/create-invoice'),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Vytvoriť faktúru'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/create-expense'),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Pridať výdavok'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
