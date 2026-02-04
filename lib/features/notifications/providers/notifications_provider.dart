import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_repository.dart';
import '../data/notifications_repository.dart';
import '../models/notification_model.dart';

// Repository Provider
final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(FirebaseFirestore.instance);
});

// Stream notifikácií
final notificationsStreamProvider = StreamProvider<List<BizNotification>>((
  ref,
) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return Stream.value([]);

  return ref.watch(notificationsRepositoryProvider).watchNotifications(user.id);
});

// Počet neprečítaných
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications =
      ref.watch(notificationsStreamProvider).asData?.value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

// Controller pre akcie
final notificationsControllerProvider =
    NotifierProvider<NotificationsController, AsyncValue<void>>(() {
  return NotificationsController();
});

class NotificationsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> markAsRead(String notificationId) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(notificationsRepositoryProvider)
          .markAsRead(user.id, notificationId),
    );
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).markAllAsRead(user.id),
    );
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(notificationsRepositoryProvider)
          .deleteNotification(user.id, notificationId),
    );
  }
}
