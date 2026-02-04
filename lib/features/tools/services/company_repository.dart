import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ico_lookup_result.dart';
import '../../../core/services/icoatlas_service.dart';
import '../../auth/providers/auth_repository.dart';
import 'package:flutter/foundation.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(
    db: FirebaseFirestore.instance,
    ref: ref,
    remote: ref.read(icoAtlasServiceProvider),
  );
});

class CompanyRepository {
  final FirebaseFirestore _db;
  final Ref _ref;
  final IcoAtlasService _remote;

  CompanyRepository({
    required FirebaseFirestore db,
    required Ref ref,
    required IcoAtlasService remote,
  })  : _db = db,
        _ref = ref,
        _remote = remote;

  /// Optimized lookup: Returns local cache immediately if exists.
  /// Result contains indicator if it's stale.
  Future<IcoLookupResult?> getFromCache(String ico) async {
    final docRef = _db.collection('companies').doc(ico);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      return IcoLookupResult.fromFirestore(snapshot.data()!);
    }
    return null;
  }

  /// Atomic refresh from backend with hash comparison to avoid flicker
  Future<IcoLookupResult?> refresh(String ico, {String? existingHash}) async {
    try {
      await _refreshFromBackend(ico);

      final refreshedSnap = await _db.collection('companies').doc(ico).get();
      if (refreshedSnap.exists) {
        final newResult = IcoLookupResult.fromFirestore(refreshedSnap.data()!);

        // If hash hasn't changed, we can signal the UI to not flicker
        // (Though Firestore listeners or NotifyListeners usually handle this,
        // manual control is better for UX)
        if (existingHash != null && newResult.hash == existingHash) {
          return null; // Signals NO CHANGE needed
        }

        return newResult;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Refresh company data from source of truth (icoatlas.sk via IcoAtlasService).
  Future<void> _refreshFromBackend(String ico) async {
    final user = _ref.read(authStateProvider).asData?.value;
    if (!kDebugMode && user == null) {
      throw Exception('Na prístup k týmto dátam sa vyžaduje prihlásenie.');
    }

    final fresh = await _remote.publicLookup(ico);
    if (fresh == null || !fresh.isValid) {
      if (fresh != null && fresh.isRateLimited) throw Exception('Rate limit');
      throw Exception('Údaje sa nepodarilo načítať');
    }

    await _db
        .collection('companies')
        .doc(ico)
        .set(fresh.toFirestore(), SetOptions(merge: true));
  }

  /// Mark a lead as opened
  Future<void> markAsOpened(String uid, String ico) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('webLeads')
        .doc(ico)
        .update({'status': 'opened', 'openedAt': FieldValue.serverTimestamp()});
  }
}
