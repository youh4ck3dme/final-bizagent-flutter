import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../shared/widgets/biz_empty_state.dart';
import '../../../shared/widgets/biz_shimmer.dart';
import '../providers/invoices_provider.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(AppStr.invoiceTitle)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Upomienky',
            onPressed: () => context.push('/invoices/reminders'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-invoice'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(invoicesProvider);
          await ref.read(invoicesProvider.future);
        },
        child: invoicesAsync.when(
          data: (invoices) {
            if (invoices.isEmpty) {
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
                            title: context.t(AppStr.invoiceEmptyTitle),
                            body: context.t(AppStr.invoiceEmptyMsg),
                            ctaLabel: context.t(AppStr.invoiceEmptyCta),
                            onCta: () => context.push('/create-invoice'),
                            icon: Icons.receipt_long,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: invoices.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return Card(
                  child: ListTile(
                    onTap: () =>
                        context.push('/invoices/detail', extra: invoice),
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt_long),
                    ),
                    title: Text(invoice.clientName),
                    subtitle: Text(invoice.number),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(symbol: '€')
                              .format(invoice.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('dd.MM.yyyy').format(invoice.dateIssued),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
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
}
