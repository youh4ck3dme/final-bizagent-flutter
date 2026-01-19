import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../tax/providers/tax_provider.dart';
import '../../tax/providers/tax_thermometer_service.dart';

class DashboardTaxWidget extends ConsumerWidget {
  const DashboardTaxWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlines = ref.watch(upcomingTaxDeadlinesProvider);
    final thermometerAsync = ref.watch(taxThermometerProvider);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tax Thermometer Section
            _buildThermometer(context, thermometerAsync),
            
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 2. Deadlines Section
            const Row(
              children: [
                 Icon(Icons.calendar_month_outlined, color: Colors.indigo, size: 20),
                 SizedBox(width: 8),
                 Text('Daňový kalendár',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            
            if (deadlines.isEmpty)
              const Text("Žiadne nadchádzajúce termíny.", style: TextStyle(color: Colors.grey))
            else
              ...deadlines.take(2).map((deadline) => _buildDeadlineItem(deadline)),
              
             if (deadlines.length > 2)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('+ ${deadlines.length - 2} ďalšie',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThermometer(BuildContext context, AsyncValue<TaxThermometerResult> asyncValue) {
    return asyncValue.when(
      loading: () => const LinearProgressIndicator(),
      error: (err, stack) => const Text('Chyba výpočtu obratu'),
      data: (result) {
        final currency = NumberFormat.currency(locale: 'sk_SK', symbol: '€');
        Color color = Colors.green;
        String statusText = "Všetko v poriadku";
        
        if (result.isCritical) {
          color = Colors.red;
          statusText = "Povinná registrácia DPH!";
        } else if (result.isWarning) {
          color = Colors.orange;
          statusText = "Blížite sa k limitu";
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.thermostat, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Obrat (Ost. 12 mesiacov)',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: color, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 10
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: result.percentage.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade100,
                color: color,
                minHeight: 12,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currency.format(result.currentTurnover),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  '/ ${currency.format(result.threshold)}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeadlineItem(dynamic deadline) {
      final isToday = deadline.date.year == DateTime.now().year &&
                  deadline.date.month == DateTime.now().month &&
                  deadline.date.day == DateTime.now().day;
                  
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isToday
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.indigo.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd').format(deadline.date),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isToday ? Colors.red : Colors.indigo,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(deadline.date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.red : Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    deadline.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    deadline.description,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}
