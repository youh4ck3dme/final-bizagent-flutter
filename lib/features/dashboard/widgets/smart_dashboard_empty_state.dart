import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../settings/providers/settings_provider.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../expenses/providers/expenses_provider.dart';

class SmartDashboardEmptyState extends ConsumerWidget {
  const SmartDashboardEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final invoices = ref.watch(invoicesProvider).valueOrNull ?? [];
    final expenses = ref.watch(expensesProvider).valueOrNull ?? [];

    final isSettingsCompleted = settings != null &&
        settings.companyName.isNotEmpty &&
        settings.companyIco.isNotEmpty;

    final isInvoiceCompleted = invoices.isNotEmpty;
    final isExpenseCompleted = expenses.isNotEmpty;

    // Premium gradient background for the welcome feeling
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vitajte v BizAgent!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pripravte svoju firmu na úspech',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Smart Checklist
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildChecklistItem(
                    context,
                    title: 'Nastaviť firemné údaje',
                    subtitle: 'IČO, DIČ a adresa pre faktúry',
                    icon: Icons.business,
                    isCompleted: isSettingsCompleted,
                    onTap: () => context.push('/settings'),
                  ),
                  const Divider(height: 1),
                  _buildChecklistItem(
                    context,
                    title: 'Vytvoriť prvú faktúru',
                    subtitle: 'Vystavte doklad pre klienta',
                    icon: Icons.receipt_long,
                    isCompleted: isInvoiceCompleted,
                    onTap: () => context.push('/create-invoice'),
                  ),
                  const Divider(height: 1),
                  _buildChecklistItem(
                    context,
                    title: 'Pridať prvý výdavok',
                    subtitle: 'Nahrajte bloček cez AI',
                    icon: Icons.shopping_bag_outlined,
                    isCompleted: isExpenseCompleted,
                    onTap: () => context.push('/create-expense'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? Colors.green : Colors.grey[300]!,
                    width: 2,
                  ),
                  color: isCompleted ? Colors.green : Colors.transparent,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
