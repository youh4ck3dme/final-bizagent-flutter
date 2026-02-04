import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/invoice_model.dart';
import 'invoices_repository.dart';
import '../../../core/services/soft_delete_service.dart';

final invoicesProvider = StreamProvider<List<InvoiceModel>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return Stream.value([]);
  return ref.watch(invoicesRepositoryProvider).watchInvoices(user.id);
});

final invoicesControllerProvider =
    NotifierProvider<InvoicesController, AsyncValue<void>>(() {
  return InvoicesController();
});

class InvoicesController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> addInvoice(InvoiceModel invoice) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(invoicesRepositoryProvider).addInvoice(user.id, invoice),
    );
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(invoicesRepositoryProvider).updateInvoice(user.id, invoice),
    );
  }

  Future<void> updateStatus(String invoiceId, InvoiceStatus status) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(invoicesRepositoryProvider)
          .updateInvoiceStatus(user.id, invoiceId, status),
    );
  }

  Future<void> softDeleteInvoice(String invoiceId, {String? reason}) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(invoicesRepositoryProvider);
      final invoice = await repo.getInvoice(user.id, invoiceId);

      if (invoice != null) {
        await ref.read(softDeleteServiceProvider).moveToTrash(
              SoftDeleteCollections.invoices,
              user.id,
              invoiceId,
              invoice.toMap(),
              reason: reason,
              originalCollectionPath: 'users/${user.id}/invoices',
            );
        await repo.deleteInvoice(user.id, invoiceId);
      }
    });
  }

  Future<void> deleteInvoices(List<String> invoiceIds, {String? reason}) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(invoicesRepositoryProvider);
      final service = ref.read(softDeleteServiceProvider);

      for (final id in invoiceIds) {
        final invoice = await repo.getInvoice(user.id, id);
        if (invoice != null) {
          await service.moveToTrash(
            SoftDeleteCollections.invoices,
            user.id,
            id,
            invoice.toMap(),
            reason: reason,
            originalCollectionPath: 'users/${user.id}/invoices',
          );
          await repo.deleteInvoice(user.id, id);
        }
      }
    });
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await softDeleteInvoice(invoiceId);
  }
}
