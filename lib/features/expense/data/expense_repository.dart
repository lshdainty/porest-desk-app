import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/expense.dart';
import '../domain/expense_category.dart';

/// `/expenses`, `/expense/categories`, `/expense` 호출.
class ExpenseRepository {
  ExpenseRepository(this._dio);
  final Dio _dio;

  // ─────────────────────────────────────────────
  // Expense
  // ─────────────────────────────────────────────

  Future<List<Expense>> list({
    String? startDate, // 'YYYY-MM-DD'
    String? endDate,
    int? categoryId,
    int? assetId,
    String? expenseType,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses',
        queryParameters: {
          'startDate': ?startDate,
          'endDate': ?endDate,
          'categoryId': ?categoryId,
          'assetId': ?assetId,
          'expenseType': ?expenseType,
        },
      );
      return _unwrapList(res, 'expenses', Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Expense> create({
    required int categoryRowId,
    required int assetRowId,
    required String expenseType,
    required int amount,
    required String expenseDate,
    String? description,
    String? merchant,
    String? paymentMethod,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense',
        data: {
          'categoryRowId': categoryRowId,
          'assetRowId': assetRowId,
          'expenseType': expenseType,
          'amount': amount,
          'expenseDate': expenseDate,
          'description': ?description,
          'merchant': ?merchant,
          'paymentMethod': ?paymentMethod,
        },
      );
      return _unwrap(res, Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ─────────────────────────────────────────────
  // ExpenseCategory
  // ─────────────────────────────────────────────

  Future<List<ExpenseCategory>> categories() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/expense/categories');
      return _unwrapList(res, 'categories', ExpenseCategory.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  T _unwrap<T>(
    Response<Map<String, dynamic>> res,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<T>.fromJson(
      res.data ?? const {},
      (raw) => fromJson(raw! as Map<String, dynamic>),
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    return body.data!;
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
