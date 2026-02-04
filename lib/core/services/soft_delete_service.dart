import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for managing soft delete operations following Google/Firebase data retention policies
class SoftDeleteService {
  final FirebaseFirestore _firestore;

  SoftDeleteService(this._firestore);

  /// Move an item to the trash collection (Soft Delete)
  Future<void> moveToTrash(
    String trashCollection,
    String userId,
    String itemId,
    Map<String, dynamic> data, {
    String? reason,
    required String originalCollectionPath,
  }) async {
    final trashRef = _firestore
        .collection(trashCollection)
        .doc(userId)
        .collection('items')
        .doc(itemId);

    // Add metadata for restoration
    final trashData = {
      ...data,
      'deletedAt': FieldValue.serverTimestamp(),
      'deleteReason': reason,
      'originalCollectionPath':
          originalCollectionPath, // Save where it came from
      'originalId': itemId,
    };

    await trashRef.set(trashData);
  }

  /// Restore an item from trash back to its original location
  Future<void> restoreItem(
    String trashCollection,
    String userId,
    String itemId,
  ) async {
    final trashRef = _firestore
        .collection(trashCollection)
        .doc(userId)
        .collection('items')
        .doc(itemId);
    final trashDoc = await trashRef.get();

    if (!trashDoc.exists) {
      throw Exception('Item not found in trash');
    }

    final data = trashDoc.data()!;
    final originalPath = data['originalCollectionPath'] as String?;

    if (originalPath == null) {
      throw Exception('Cannot restore: Original path missing');
    }

    // Clean up trash metadata before restoring
    final restoreData = Map<String, dynamic>.from(data);
    restoreData.remove('deletedAt');
    restoreData.remove('deleteReason');
    restoreData.remove('originalCollectionPath');
    restoreData.remove('originalId');

    // Write back to original location
    // Note: originalPath should be full collection path e.g. "users/123/invoices"
    // We assume the ID is consistent
    await _firestore.collection(originalPath).doc(itemId).set(restoreData);

    // Remove from trash
    await trashRef.delete();
  }

  /// Permanently delete items that are older than 7 days
  Future<void> cleanupExpiredItems(String collection, String userId) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final query = _firestore
        .collection(collection)
        .doc(userId)
        .collection('items')
        .where('deletedAt', isLessThan: sevenDaysAgo);

    final snapshot = await query.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  /// Get all soft deleted items that can still be restored
  Stream<List<Map<String, dynamic>>> getTrashItems(
    String collection,
    String userId,
  ) {
    // We list EVERYTHING in the trash, regardless of age (cleanup job handles expiration)
    // But we can filter by deletedAt if needed.
    return _firestore
        .collection(collection)
        .doc(userId)
        .collection('items')
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  'data': doc.data(),
                  'collection': collection,
                },
              )
              .toList(),
        );
  }

  /// Get count of items in trash
  Stream<int> getTrashCount(String collection, String userId) {
    return _firestore
        .collection(collection)
        .doc(userId)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Permanently delete a specific item (admin function)
  Future<void> permanentDeleteItem(
    String collection,
    String userId,
    String itemId,
  ) async {
    await _firestore
        .collection(collection)
        .doc(userId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  /// Empty trash - permanently delete all soft deleted items
  Future<void> emptyTrash(String collection, String userId) async {
    final query =
        _firestore.collection(collection).doc(userId).collection('items');

    final snapshot = await query.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}

// Collection names for different item types
class SoftDeleteCollections {
  static const String invoices = 'soft_deleted_invoices';
  static const String bizBotConversations = 'soft_deleted_bizbot_conversations';
  static const String notepadItems = 'soft_deleted_notepad_items';
}

// Provider for the soft delete service
final softDeleteServiceProvider = Provider<SoftDeleteService>((ref) {
  return SoftDeleteService(FirebaseFirestore.instance);
});
