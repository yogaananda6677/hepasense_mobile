import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/education_content.dart';

class EducationRepository {
  EducationRepository(this._api);
  final ApiClient _api;

  Future<EducationPage> list({
    required EducationType type,
    required int page,
    String? category,
    String search = '',
    bool? featured,
  }) async {
    try {
      final query = <String, dynamic>{'type': type.apiValue, 'page': page};
      if (category != null && category.isNotEmpty) query['category'] = category;
      if (search.trim().isNotEmpty) query['search'] = search.trim();
      if (featured != null) query['featured'] = featured;
      final response = await _api.dio.get(
        '/api/v1/education/articles/',
        queryParameters: query,
      );
      return EducationPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<List<EducationCategory>> categories() async {
    try {
      final response = await _api.dio.get('/api/v1/education/categories/');
      return (response.data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(EducationCategory.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<EducationArticle> detail(String slug) async {
    try {
      final response = await _api.dio.get(
        '/api/v1/education/articles/${Uri.encodeComponent(slug)}/',
      );
      return EducationArticle.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}
