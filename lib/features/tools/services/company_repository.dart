import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ico_lookup_result.dart';
import '../../auth/providers/auth_repository.dart';
import 'package:dio/dio.dart';


final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(
    db: FirebaseFirestore.instance,
    ref: ref,
  );
});

class CompanyRepository {
  final FirebaseFirestore _db;
  final Ref _ref;

  CompanyRepository({
    required FirebaseFirestore db,
    required Ref ref,
  }) : _db = db, _ref = ref;

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

  Future<void> _refreshFromBackend(String ico) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) throw Exception('Auth required');

    final token = await _ref.read(authRepositoryProvider).currentUserToken;
    if (token == null) throw Exception('Could not get auth token');

// 3) Flutter “Fixer”: vždy posiela contract header
    const icoContractVersion = "1.0.0";

    // Use Dio to call our Unified Gateway (Vercel / Cloud Run proxy)
    final dio = Dio(BaseOptions(
      baseUrl: 'https://bizagent.sk', // Production Gateway
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'X-ICO-LOOKUP-CONTRACT': icoContractVersion,
      },
    ));

    try {
      final response = await dio.get('/api/company/$ico');
      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) throw Exception('Rate limit');
      rethrow;
    }
  }

  /// Mark a lead as opened
  Future<void> markAsOpened(String uid, String ico) async {
    await _db.collection('users').doc(uid).collection('webLeads').doc(ico).update({
      'status': 'opened',
      'openedAt': FieldValue.serverTimestamp(),
    });
  }
}
