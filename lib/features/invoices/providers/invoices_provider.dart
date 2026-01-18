import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/invoice_model.dart';
import 'invoices_repository.dart';

final invoicesProvider = StreamProvider<List<InvoiceModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(invoicesRepositoryProvider).watchInvoices(user.id);
});

final invoicesControllerProvider =
    StateNotifierProvider<InvoicesController, AsyncValue<void>>((ref) {
  return InvoicesController(ref);
});

class InvoicesController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  InvoicesController(this._ref) : super(const AsyncValue.data(null));

  Future<void> addInvoice(InvoiceModel invoice) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _ref.read(invoicesRepositoryProvider).addInvoice(user.id, invoice));
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _ref.read(invoicesRepositoryProvider).updateInvoice(user.id, invoice));
  }

  Future<void> updateStatus(String invoiceId, InvoiceStatus status) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref
        .read(invoicesRepositoryProvider)
        .updateInvoiceStatus(user.id, invoiceId, status));
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref
        .read(invoicesRepositoryProvider)
        .deleteInvoice(user.id, invoiceId));
  }
}
