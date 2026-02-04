import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/soft_delete_service.dart';
import '../../auth/providers/auth_repository.dart';

/// Monitoring stream for all items in the invoice trash
final invoiceTrashProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return Stream.value([]);

  return ref
      .watch(softDeleteServiceProvider)
      .getTrashItems(SoftDeleteCollections.invoices, user.id);
});

/// Monitoring stream for BizBot conversations in trash
final bizBotTrashProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return Stream.value([]);

  return ref
      .watch(softDeleteServiceProvider)
      .getTrashItems(SoftDeleteCollections.bizBotConversations, user.id);
});

/// Monitoring stream for Notepad items in trash
final notepadTrashProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return Stream.value([]);

  return ref
      .watch(softDeleteServiceProvider)
      .getTrashItems(SoftDeleteCollections.notepadItems, user.id);
});

/// Count of ALL items in the trash for badges
final trashCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return Stream.value(0);

  final invoicesCount = ref
      .watch(softDeleteServiceProvider)
      .getTrashCount(SoftDeleteCollections.invoices, user.id);
  final bizBotCount = ref
      .watch(softDeleteServiceProvider)
      .getTrashCount(SoftDeleteCollections.bizBotConversations, user.id);
  final notepadCount = ref
      .watch(softDeleteServiceProvider)
      .getTrashCount(SoftDeleteCollections.notepadItems, user.id);

  // Combine streams (logic is simpler via StreamGroup or similar, but for 3 we can just map)
  return invoicesCount.asyncMap((c1) async {
    final c2 = await bizBotCount.first;
    final c3 = await notepadCount.first;
    return c1 + c2 + c3;
  });
});

final trashControllerProvider =
    NotifierProvider<TrashController, AsyncValue<void>>(() {
  return TrashController();
});

class TrashController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> restoreItem(String collection, String itemId) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(softDeleteServiceProvider)
          .restoreItem(collection, user.id, itemId),
    );
  }

  Future<void> permanentDeleteItem(String collection, String itemId) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(softDeleteServiceProvider)
          .permanentDeleteItem(collection, user.id, itemId),
    );
  }

  Future<void> emptyAllTrash() async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(softDeleteServiceProvider);
      await service.emptyTrash(SoftDeleteCollections.invoices, user.id);
      await service.emptyTrash(
        SoftDeleteCollections.bizBotConversations,
        user.id,
      );
      await service.emptyTrash(SoftDeleteCollections.notepadItems, user.id);
    });
  }
}
