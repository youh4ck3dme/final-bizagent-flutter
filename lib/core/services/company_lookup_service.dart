import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_info.dart';

final companyLookupServiceProvider = Provider<CompanyLookupService>((ref) {
  return CompanyLookupService(FirebaseFunctions.instance);
});

class CompanyLookupService {
  final FirebaseFunctions _functions;

  CompanyLookupService(this._functions);

  Future<CompanyInfo?> lookup(String ico) async {
    try {
      final result = await _functions.httpsCallable('lookupCompany').call(
        {'ico': ico},
      );

      final data = result.data;
      if (data == null) return null;

      // Handle Map<Object?, Object?> conversion issues
      final map = Map<String, dynamic>.from(data as Map);
      return CompanyInfo.fromMap(map);
    } catch (e) {
      // In production, log to Crashlytics
      debugPrint('Error looking up company: $e');
      return null;
    }
  }
}
