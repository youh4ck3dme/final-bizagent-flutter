import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_info.dart';

final icoAtlasServiceProvider = Provider<IcoAtlasService>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://icoatlas.sk/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));
  
  // Note: For production, an API key would be added to headers here
  // headers: {'Authorization': 'Bearer ${const String.fromEnvironment('ICOATLAS_API_KEY')}'}
  
  return IcoAtlasService(dio);
});

class IcoAtlasService {
  final Dio _dio;

  IcoAtlasService(this._dio);

  /// Looks up a company by its IČO.
  Future<CompanyInfo?> lookupCompany(String ico) async {
    try {
      final response = await _dio.get('/company/$ico');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        return CompanyInfo.fromMap(_mapIcoAtlasToCompanyInfo(data));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Provides company suggestions based on a search query.
  Future<List<Map<String, dynamic>>> autocomplete(String query) async {
    if (query.length < 2) return [];
    
    try {
      final response = await _dio.get('/autocomplete', queryParameters: {'q': query});
      
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Maps ICOATLAS specific fields to BizAgent's CompanyInfo format.
  Map<String, dynamic> _mapIcoAtlasToCompanyInfo(dynamic data) {
    // Standardizing the response from Laravel to our local model
    return {
      'name': data['name'] ?? '',
      'ico': data['ico'] ?? data['cin'] ?? '',
      'dic': data['dic'] ?? data['tin'],
      'icDph': data['v_tin'] ?? data['ic_dph'],
      'address': data['formatted_address'] ?? data['address'] ?? '',
    };
  }
}
