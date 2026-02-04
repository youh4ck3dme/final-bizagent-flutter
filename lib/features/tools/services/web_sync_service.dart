import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_repository.dart';

final webSyncServiceProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final user = ref.read(authStateProvider).asData?.value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.id)
      .collection('webLeads')
      .orderBy('createdAt', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});
