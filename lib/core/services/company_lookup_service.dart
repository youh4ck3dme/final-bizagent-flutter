import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_info.dart';
import 'icoatlas_service.dart';

final companyLookupServiceProvider = Provider<CompanyLookupService>((ref) {
  return CompanyLookupService(
    ref.read(icoAtlasServiceProvider),
    FirebaseFunctions.instance,
  );
});

class CompanyLookupService {
  final IcoAtlasService _icoAtlas;
  final FirebaseFunctions _functions;

  CompanyLookupService(this._icoAtlas, this._functions);

  Future<CompanyInfo?> lookup(String ico) async {
    // 1. Try ICOATLAS first (Direct & Fast)
    final icoAtlasInfo = await _icoAtlas.lookupCompany(ico);
    if (icoAtlasInfo != null) return icoAtlasInfo;

    // 2. Fallback to Firebase Functions (Slovensko.Digital)
    try {
      // Small check to avoid calling if we know it will fail or if no billing
      // For Spark plan, functions might still work if not using Secret Manager, 
      // but if the project is blocked, this will catch it.
      final result = await _functions.httpsCallable('lookupCompany').call(
        {'ico': ico},
      ).timeout(const Duration(seconds: 10));

      final data = result.data;
      if (data == null) return null;

      final map = Map<String, dynamic>.from(data as Map);
      return CompanyInfo.fromMap(map);
    } catch (e) {
      debugPrint('Company lookup fallback failed (likely billing/quota): $e');
      return null;
    }
  }
}
