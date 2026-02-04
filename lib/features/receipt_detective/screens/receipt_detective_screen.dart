import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/reconstructed_suggestion_model.dart';
import '../providers/receipt_detective_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../shared/widgets/biz_empty_state.dart';

/// Bloček Detective – rekonštrukcia stratených dokladov z fragmentov.
class ReceiptDetectiveScreen extends ConsumerWidget {
  const ReceiptDetectiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(receiptDetectiveSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.search, color: BizTheme.slovakBlue),
            SizedBox(width: 8),
            Text('Bloček Detective'),
          ],
        ),
      ),
      body: suggestionsAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return BizEmptyState(
              icon: Icons.check_circle_outline,
              title: 'Žiadne návrhy na rekonštrukciu',
              body:
                  'Pridaj výdavky alebo importuj bankový výpis – AI ti navrhne doklady na doplnenie.',
              ctaLabel: 'Pridať výdavok',
              onCta: () => context.push('/create-expense'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              return _SuggestionCard(
                suggestion: s,
                onTap: () {
                  if (s.expenseId != null) {
                    final expenses =
                        ref.read(expensesProvider).asData?.value ?? [];
                    final match =
                        expenses.where((e) => e.id == s.expenseId).toList();
                    final expense = match.isEmpty ? null : match.first;
                    if (expense != null) {
                      context.push('/expenses/detail', extra: expense);
                    } else {
                      context.push(
                        '/create-expense',
                        extra: {'initialText': s.vendorHint},
                      );
                    }
                  } else {
                    context.push(
                      '/create-expense',
                      extra: {'initialText': s.vendorHint},
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Chyba: $e')),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final ReconstructedExpenseSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionCard({required this.suggestion, required this.onTap});

  Color _confidenceColor() {
    if (suggestion.confidence >= 85) return Colors.green;
    if (suggestion.confidence >= 70) return Colors.orange;
    return Colors.red.shade700;
  }

  Widget _confidenceChip(ReconstructedExpenseSuggestion s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _confidenceColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${s.confidenceLabel} (${s.confidence}%)',
        style: TextStyle(
          fontSize: 11,
          color: _confidenceColor(),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BizTheme.slovakBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: BizTheme.slovakBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.vendorHint,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          suggestion.sourceLabel,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '€${suggestion.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BizTheme.slovakBlue,
                        ),
                  ),
                ],
              ),
              if (suggestion.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  suggestion.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    DateFormat('d.M.y').format(suggestion.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  _confidenceChip(suggestion),
                  if (suggestion.isAcceptableForTax) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Vhodné pre DPH',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
