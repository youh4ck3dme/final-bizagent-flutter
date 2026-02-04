import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../tax/providers/tax_thermometer_service.dart';
import '../models/proactive_alert_model.dart';
import '../services/proactive_alerts_service.dart';

final proactiveAlertsServiceProvider = Provider<ProactiveAlertsService>((ref) {
  return ProactiveAlertsService();
});

/// Proaktívne alerty z AI účtovníka (prediktívne, daňový stratég, anomálie).
final proactiveAlertsProvider = Provider<AsyncValue<List<ProactiveAlert>>>((
  ref,
) {
  final invoicesAsync = ref.watch(invoicesProvider);
  final expensesAsync = ref.watch(expensesProvider);
  final taxAsync = ref.watch(taxThermometerProvider);
  final service = ref.watch(proactiveAlertsServiceProvider);

  return invoicesAsync.when(
    data: (invoices) {
      return expensesAsync.when(
        data: (expenses) {
          final taxData = taxAsync.asData?.value;
          if (taxData == null) return const AsyncValue.data([]);
          final alerts = service.generateAlerts(
            invoices: invoices,
            expenses: expenses,
            taxResult: taxData,
            currentBalance: null,
            reserveBalance: null,
          );
          return AsyncValue.data(alerts);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
