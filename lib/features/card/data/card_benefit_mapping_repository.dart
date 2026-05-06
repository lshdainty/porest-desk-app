import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/card_benefit_mapping.dart';

/// 카드 혜택 ↔ 가계부 카테고리 매핑 — front `cardBenefitMappingApi` 미러.
class CardBenefitMappingRepository {
  CardBenefitMappingRepository(this._dio);
  final Dio _dio;

  Future<List<CardBenefitMapping>> list() async {
    try {
      final res =
          await _dio.get<Map<String, dynamic>>('/card-benefit-mappings');
      return _unwrapList(res, 'mappings', CardBenefitMapping.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 사용자 정의 매핑 추가.
  /// POST /card-benefit-mappings { benefitCategory, expenseCategoryRowId }
  Future<CardBenefitMapping> create({
    required String benefitCategory,
    required int expenseCategoryRowId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/card-benefit-mappings',
        data: {
          'benefitCategory': benefitCategory,
          'expenseCategoryRowId': expenseCategoryRowId,
        },
      );
      final body = ApiResponse<CardBenefitMapping>.fromJson(
        res.data ?? const {},
        (raw) =>
            CardBenefitMapping.fromJson(raw! as Map<String, dynamic>),
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return body.data!;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 사용자 정의 매핑 제거. DELETE /card-benefit-mappings/{id}.
  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/card-benefit-mappings/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  List<T> _unwrapList<T>(
    Response<Map<String, dynamic>> res,
    String listKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<Map<String, dynamic>>.fromJson(
      res.data ?? const {},
      (raw) => raw! as Map<String, dynamic>,
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    final list = (body.data![listKey] as List<dynamic>?) ?? const [];
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
