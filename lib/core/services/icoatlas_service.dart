import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../models/company_info.dart';
import '../models/ico_lookup_result.dart';

final icoAtlasServiceProvider = Provider<IcoAtlasService>((ref) {
  const baseUrl = 'https://bizagent.sk';

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: null,
    receiveTimeout: null,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  // Security Interceptor for App Check
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      try {
        final token = await FirebaseAppCheck.instance.getToken();
        if (token != null) {
          options.headers['X-Firebase-AppCheck'] = token;
        }
      } catch (e) {
        debugPrint('App Check Token Error: $e');
      }
      return handler.next(options);
    },
  ));

  const isDemo = String.fromEnvironment('ICO_MODE') != 'REAL';
  return IcoAtlasService(dio, isDemoMode: isDemo);
});

class IcoAtlasService {
  final Dio _dio;
  final bool isDemoMode;

  IcoAtlasService(this._dio, {this.isDemoMode = true});

  Future<IcoLookupResult?> publicLookup(String ico) async {
    try {
      final endpoint = '/api/company/${ico.trim()}';
      final response = await _dio.get(
        endpoint,
        options: Options(headers: {'X-ICO-LOOKUP-CONTRACT': '1.0.0'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return IcoLookupResult.fromMap(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      if (e.response?.statusCode == 429) {
        final resetIn = e.response?.data?['resetIn'];
        return IcoLookupResult.rateLimited(
          resetIn: resetIn != null ? int.tryParse(resetIn.toString()) : null,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<IcoLookupResult> fetchByIco(String icoNorm) async {
    final result = await publicLookup(icoNorm);
    if (result == null || result.isRateLimited) throw Exception('Fetch failed');
    return result;
  }

  Future<IcoLookupResult?> secureLookup(String ico, String? token) => publicLookup(ico);

  Future<CompanyInfo?> lookupCompany(String ico) async {
    try {
      final result = await publicLookup(ico);
      if (result != null && !result.isRateLimited && result.name.isNotEmpty) {
        return CompanyInfo(
          name: result.name,
          ico: ico,
          address: result.fullAddress,
          dic: result.dic,
          icDph: result.icDph,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> autocomplete(String query) async {
    if (query.length < 2) return [];
    try {
      final response = await _dio.get('/api/public/ico/autocomplete', queryParameters: {'q': query});
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<IcoLookupResult?> viesLookup(String countryCode, String vatNumber) async {
    try {
      final endpoint = '/api/vies/validate';
      final response = await _dio.get(
        endpoint,
        queryParameters: {'country': countryCode, 'vat': vatNumber},
      );
      if (response.statusCode == 200 && response.data != null) {
        return IcoLookupResult.fromMap(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
