import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/budget.dart';
import '../domain/budget_compliance.dart';

class BudgetRepository {
  BudgetRepository(this._dio);
  final Dio _dio;

  Future<List<Budget>> list({int? year, int? month}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expense/budgets',
        queryParameters: {
          'year': ?year,
          'month': ?month,
        },
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      final list = (body.data!['budgets'] as List<dynamic>?) ?? const [];
      return list
          .map((e) => Budget.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> create({
    required int categoryRowId,
    required int budgetAmount,
    required int budgetYear,
    required int budgetMonth,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/expense/budget',
        data: {
          'categoryRowId': categoryRowId,
          'budgetAmount': budgetAmount,
          'budgetYear': budgetYear,
          'budgetMonth': budgetMonth,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> update({required int id, required int budgetAmount}) async {
    try {
      await _dio.put<dynamic>(
        '/expense/budget/$id',
        data: {'budgetAmount': budgetAmount},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/expense/budget/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// N개월 예산 준수율. GET /expense/budgets/compliance?months=N (기본 6).
  Future<List<BudgetComplianceMonth>> compliance({int months = 6}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expense/budgets/compliance',
        queryParameters: {'months': months},
      );
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      final list = (body.data!['months'] as List<dynamic>?) ?? const [];
      return list
          .map((e) =>
              BudgetComplianceMonth.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
