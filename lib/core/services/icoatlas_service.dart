import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_info.dart';
import '../models/ico_lookup_result.dart';

final icoAtlasServiceProvider = Provider<IcoAtlasService>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://bizagent-cc.vercel.app/api',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  const isDemo = String.fromEnvironment('ICO_MODE') != 'REAL';
  return IcoAtlasService(dio, isDemoMode: isDemo);
});

class IcoAtlasService {
  final Dio _dio;
  final bool isDemoMode;

  IcoAtlasService(this._dio, {this.isDemoMode = true});

  /// Performs a public IČO lookup via the secure gateway.
  /// Handles 200 (Success) and 429 (Rate Limited).
  Future<IcoLookupResult?> publicLookup(String ico) async {
    try {
      final endpoint = isDemoMode ? '/public/ico/lookup' : '/icoatlas/lookup';
      final response = await _dio.get(endpoint, queryParameters: {'ico': ico});

      if (response.statusCode == 200 && response.data != null && response.data['ok'] == true) {
        return IcoLookupResult.fromMap(response.data['summary'] ?? {});
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final resetIn = e.response?.data?['resetIn'];
        return IcoLookupResult.rateLimited(
          resetIn: resetIn != null ? int.tryParse(resetIn.toString()) : null,
        );
      }
      debugPrint('Public IČO lookup failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Public IČO lookup error: $e');
      return null;
    }
  }

  /// Looks up a company by its IČO (Legacy/Proxy method).
  Future<CompanyInfo?> lookupCompany(String ico) async {
    try {
      // Proxying through the public lookup for now as per architecture rules
      final result = await publicLookup(ico);
      
      if (result != null && !result.isRateLimited && result.name.isNotEmpty) {
        return CompanyInfo(
          name: result.name,
          ico: ico,
          address: result.city, // City as a fallback for address in this simplified view
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Provides company suggestions based on a search query.
  /// Note: This should also be gated or proxied if needed.
  Future<List<Map<String, dynamic>>> autocomplete(String query) async {
    if (query.length < 2) return [];
    
    try {
      // Assuming gateway might have an autocomplete proxy later
      final response = await _dio.get('/public/ico/autocomplete', queryParameters: {'q': query});
      
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
