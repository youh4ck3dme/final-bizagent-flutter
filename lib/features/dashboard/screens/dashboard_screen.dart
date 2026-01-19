import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // For SchedulerBinding
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For tracking tutorial view

import '../../auth/providers/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../invoices/models/invoice_model.dart';
import '../widgets/dashboard_tax_widget.dart';
import '../providers/revenue_provider.dart';
import '../providers/profit_provider.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../shared/widgets/biz_card.dart';
import '../../../shared/widgets/biz_section_header.dart';
import '../widgets/smart_dashboard_empty_state.dart';
import '../widgets/smart_insights_widget.dart';
import '../../../core/services/tutorial_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Global Keys for Tutorial
  final GlobalKey _dashboardKey = GlobalKey();
  final GlobalKey _scanKey = GlobalKey();
  final GlobalKey _invoiceKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Schedule tutorial check after layout
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    // Show tutorial if user is Anonymous (Demo) OR if it's a fresh install check
    // Ideally we use SharedPreferences to check if tutorial was already shown
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial =
        prefs.getBool('hasSeenTutorial_${user.id}') ?? false;

    if (!hasSeenTutorial && (user.isAnonymous)) {
      if (!mounted) return;
      TutorialService.showDashboardTutorial(
        context: context,
        dashboardKey: _dashboardKey,
        scanKey: _scanKey,
        invoiceKey: _invoiceKey,
        onFinish: () {
          prefs.setBool('hasSeenTutorial_${user.id}', true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final invoicesAsync = ref.watch(invoicesProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final revenueAsync = ref.watch(revenueMetricsProvider);
    final profitAsync = ref.watch(profitMetricsProvider);

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
          
          final double padding = isDesktop ? 32.0 : 16.0;
          final int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(invoicesProvider);
              ref.invalidate(expensesProvider);
              await Future.wait([
                ref.read(invoicesProvider.future),
                ref.read(expensesProvider.future),
              ]);
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
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
    
                      // First-run banner
                      if (!(invoicesAsync.isLoading || expensesAsync.isLoading) &&
                          !(invoicesAsync.hasError || expensesAsync.hasError) &&
                          (invoicesAsync.value?.isEmpty ?? true) &&
                          (expensesAsync.value?.isEmpty ?? true))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: SmartDashboardEmptyState(key: _dashboardKey),
                        ),
    
                      // Overdue Alerts
                      if (invoicesAsync.value != null)
                        _buildOverdueAlert(context, invoicesAsync.value!),
    
                      // Financial Summary (Responsive Grid)
                      if (revenueAsync.isLoading || profitAsync.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (revenueAsync.hasError || profitAsync.hasError)
                        Text(context.t(AppStr.errorGeneric))
                      else
                        _buildExecutiveDashboard(
                          context,
                          revenueAsync.value!,
                          profitAsync.value!,
                          expensesAsync.value ?? [],
                          crossAxisCount: crossAxisCount, // Dynamic Column Count
                        ),
    
                      const SizedBox(height: 24),
                      // AI Insights
                      const SmartInsightsWidget(),
    
                      // Tax Widget
                      const DashboardTaxWidget(),
    
                      const SizedBox(height: 32),
    
                      // Quick Actions
                      BizSectionHeader(title: context.t(AppStr.quickActions)),
                      const SizedBox(height: 16),
                      
                      // Using Wrap for responsive Quick Actions on large screens
                      if (isDesktop)
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(width: 300, child: _buildActionTile(context, title: context.t(AppStr.invoiceTitle), subtitle: 'Nová faktúra pre klienta', icon: Icons.add_circle_outline, color: Colors.blue, onTap: () => context.push('/create-invoice'), widgetKey: _invoiceKey)),
                            SizedBox(width: 300, child: _buildActionTile(context, title: context.t(AppStr.magicScan), subtitle: context.t(AppStr.magicScanSubtitle), icon: Icons.auto_awesome, color: Colors.purple, onTap: () => context.push('/ai-tools'), widgetKey: _scanKey)),
                            SizedBox(width: 300, child: _buildActionTile(context, title: 'Pridať výdavok', subtitle: 'Evidencia nákladov', icon: Icons.shopping_bag_outlined, color: Colors.orange, onTap: () => context.push('/create-expense'))),
                            SizedBox(width: 300, child: _buildActionTile(context, title: 'Import bank CSV', subtitle: 'Automatické párovanie faktúr', icon: Icons.upload_file, color: Colors.teal, onTap: () => context.push('/bank-import'))),
                            SizedBox(width: 300, child: _buildActionTile(context, title: 'Export pre účtovníka', subtitle: 'Zostava faktúr a výdavkov', icon: Icons.download, color: Colors.indigo, onTap: () => context.push('/export'))),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildActionTile(
                              context,
                              title: context.t(AppStr.invoiceTitle),
                              subtitle: 'Nová faktúra pre klienta',
                              icon: Icons.add_circle_outline,
                              color: Colors.blue,
                              onTap: () => context.push('/create-invoice'),
                              widgetKey: _invoiceKey,
                            ),
                            _buildActionTile(
                              context,
                              title: context.t(AppStr.magicScan),
                              subtitle: context.t(AppStr.magicScanSubtitle),
                              icon: Icons.auto_awesome,
                              color: Colors.purple,
                              onTap: () => context.push('/ai-tools'),
                              widgetKey: _scanKey,
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
                          ],
                        ),
    
                      const SizedBox(height: 32),
                      // Recent Invoices
                      const BizSectionHeader(title: 'Posledné faktúry'),
                      const SizedBox(height: 16),
                      if (invoicesAsync.value != null)
                        ...invoicesAsync.value!.take(5).map(
                            (invoice) => _buildRecentInvoiceTile(context, invoice)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverdueAlert(BuildContext context, List<InvoiceModel> invoices) {
    final overdueCount = invoices
        .where((i) =>
            i.status == InvoiceStatus.overdue ||
            (i.status == InvoiceStatus.sent &&
                i.dateDue.isBefore(DateTime.now())))
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

  Widget _buildExecutiveDashboard(BuildContext context, RevenueMetrics revenue,
      ProfitMetrics profit, List<dynamic> expenses, {int crossAxisCount = 2}) {
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Column(
      children: [
        GridView.count(
          crossAxisCount: crossAxisCount, // Use dynamic count
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard(
              context,
              title: 'Príjmy (Celkovo)',
              amount: NumberFormat.currency(symbol: '€')
                  .format(revenue.totalRevenue),
              color: Colors.green,
              icon: Icons.account_balance_wallet_outlined,
            ),
            _buildSummaryCard(
              context,
              title: 'Čistý Zisk',
              amount: NumberFormat.currency(symbol: '€').format(profit.profit),
              color: Colors.blue,
              icon: Icons.savings_outlined,
              subtitle:
                  'Marža: ${(profit.profitMargin * 100).toStringAsFixed(1)}%',
            ),
            _buildSummaryCard(
              context,
              title: 'Neuhradené',
              amount: NumberFormat.currency(symbol: '€')
                  .format(revenue.unpaidAmount),
              color: Colors.orange,
              icon: Icons.pending_actions_outlined,
              subtitle: '${revenue.overdueCount} po lehote',
            ),
            _buildSummaryCard(
              context,
              title: 'Výdavky',
              amount: NumberFormat.currency(symbol: '€').format(totalExpenses),
              color: Colors.red,
              icon: Icons.shopping_cart_outlined,
            ),
            _buildSummaryCard(
              context,
              title: 'Tento mesiac',
              amount: NumberFormat.currency(symbol: '€')
                  .format(revenue.thisMonthRevenue),
              color: Colors.teal,
              icon: Icons.calendar_today_outlined,
              subtitle:
                  'Zisk: ${NumberFormat.currency(symbol: '€').format(profit.thisMonthProfit)}',
            ),
            _buildSummaryCard(
              context,
              title: 'Priemerná faktúra',
              amount: NumberFormat.currency(symbol: '€')
                  .format(revenue.averageInvoiceValue),
              color: Colors.indigo,
              icon: Icons.bar_chart_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Pie Chart
        if (revenue.totalRevenue > 0 || totalExpenses > 0)
          GestureDetector(
            onTap: () => context.push('/analytics'),
            child: BizCard(
              child: Column(children: [
                Text('Pomer Príjmy vs Výdavky',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: revenue.totalRevenue,
                          title: '',
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
            ),
          ),
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
    String? subtitle,
  }) {
    return BizCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              amount,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
    Key? widgetKey, // Added Key support
  }) {
    return Card(
      key: widgetKey, // Assign Key here
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
}
