import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/ui/biz_theme.dart';

class BizInvoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final String status;
  final Color? statusColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const BizInvoiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.status,
    this.statusColor,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'sk', symbol: '€');
    
    return Card(
      elevation: isSelected ? 0 : BizTheme.elevation,
      color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
        side: isSelected 
            ? BorderSide(color: theme.colorScheme.primary, width: 2) 
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: BizTheme.spacingSm),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
        child: Semantics(
          label: 'Faktúra $subtitle pre $title, suma ${currency.format(amount)}, dátum ${DateFormat('dd.MM.yyyy').format(date)}',
          button: true,
          child: Padding(
            padding: const EdgeInsets.all(BizTheme.spacingMd),
            child: Row(
              children: [
                // Icon Placeholder or Status Indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (statusColor ?? theme.colorScheme.primary).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: statusColor ?? theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: BizTheme.spacingMd),
                
                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                
                // Amount & Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(amount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary, // Or specific logic
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd.MM.yyyy').format(date),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
