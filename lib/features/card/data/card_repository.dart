import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/card_catalog.dart';

class CardRepository {
  CardRepository(this._dio);
  final Dio _dio;

  /// 카드 카탈로그 검색 (페이지네이션 — `content`로 첫 페이지만 반환).
  Future<List<CardCatalogSummary>> search({
    String? keyword,
    String? cardType, // CREDIT/CHECK
    String? benefitType,
    bool? includeDiscontinued,
    int page = 0,
    int size = 30,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/card-catalogs',
        queryParameters: {
          'keyword': ?keyword,
          'cardType': ?cardType,
          'benefitType': ?benefitType,
          'includeDiscontinued': ?includeDiscontinued,
          'page': page,
          'size': size,
        },
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      // PageResponse 구조: { content: [...], totalPages, totalElements, ... }
      final content =
          (body.data!['content'] as List<dynamic>?) ?? const [];
      return content
          .map((e) =>
              CardCatalogSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CardCatalogDetail> detail(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/card-catalogs/$id');
      final body = ApiResponse<CardCatalogDetail>.fromJson(
        res.data ?? const {},
        (raw) => CardCatalogDetail.fromJson(raw! as Map<String, dynamic>),
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return body.data!;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
