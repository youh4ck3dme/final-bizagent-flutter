import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../models/company_info.dart';
import '../models/ico_lookup_result.dart';

/// Company data source of truth: https://icoatlas.sk/api/company/{ico}
/// See docs/ARCHITECTURE_FINAL.md.
const _icoatlasBaseUrl = 'https://icoatlas.sk';

final icoAtlasServiceProvider = Provider<IcoAtlasService>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _icoatlasBaseUrl,
      connectTimeout: null,
      receiveTimeout: null,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  // Security Interceptor for App Check (optional; icoatlas.sk may require API key via header)
  dio.interceptors.add(
    InterceptorsWrapper(
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
    ),
  );

  const gatewayBaseUrl = String.fromEnvironment(
    'GATEWAY_BASE_URL',
    defaultValue: '',
  );
  return IcoAtlasService(
    dio,
    gatewayBaseUrl: gatewayBaseUrl.isEmpty ? null : gatewayBaseUrl,
  );
});

class IcoAtlasService {
  final Dio _dio;
  final String? _gatewayBaseUrl;
  Dio? _gatewayDio;

  IcoAtlasService(this._dio, {String? gatewayBaseUrl})
      : _gatewayBaseUrl = gatewayBaseUrl;

  Dio? get _gateway {
    if (_gatewayBaseUrl == null) return null;
    _gatewayDio ??= Dio(
      BaseOptions(
        baseUrl: _gatewayBaseUrl,
        connectTimeout: null,
        receiveTimeout: null,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    return _gatewayDio;
  }

  /// Company lookup: single source of truth is icoatlas.sk.
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

  Future<IcoLookupResult?> secureLookup(String ico, String? token) =>
      publicLookup(ico);

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

  /// Autocomplete: via gateway when GATEWAY_BASE_URL is set; otherwise empty.
  Future<List<Map<String, dynamic>>> autocomplete(String query) async {
    if (query.length < 2) return [];
    final gateway = _gateway;
    if (gateway == null) return [];
    try {
      final response = await gateway.get(
        '/api/public/ico/autocomplete',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// VIES validation: via gateway when GATEWAY_BASE_URL is set; otherwise null.
  Future<IcoLookupResult?> viesLookup(
    String countryCode,
    String vatNumber,
  ) async {
    final gateway = _gateway;
    if (gateway == null) return null;
    try {
      final response = await gateway.get(
        '/api/vies/validate',
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
