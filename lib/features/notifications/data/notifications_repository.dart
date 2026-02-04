import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationsRepository {
  final FirebaseFirestore _firestore;

  NotificationsRepository(this._firestore);

  // Stream notifikácií pre používateľa
  Stream<List<BizNotification>> watchNotifications(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users/$userId/notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BizNotification.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Označiť ako prečítané
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users/$userId/notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Označiť všetky ako prečítané
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users/$userId/notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Zmazať notifikáciu
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore
        .collection('users/$userId/notifications')
        .doc(notificationId)
        .delete();
  }

  // Pridať notifikáciu (pre interné použitie alebo cloud functions)
  Future<void> addNotification(
    String userId,
    BizNotification notification,
  ) async {
    await _firestore
        .collection('users/$userId/notifications')
        .add(notification.toMap());
  }
}
