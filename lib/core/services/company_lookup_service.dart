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
    // Use Firebase Functions proxy to IcoAtlas.sk (server-side API key)
    try {
      final result = await _functions.httpsCallable('lookupCompany').call(
        {'ico': ico},
      ).timeout(const Duration(seconds: 10));

      final data = result.data;
      if (data == null) return null;

      final map = Map<String, dynamic>.from(data as Map);
      return CompanyInfo.fromMap(map);
    } catch (e) {
      debugPrint('Company lookup failed: $e');
      return null;
    }
  }
}
