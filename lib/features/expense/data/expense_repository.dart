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

  /// 캘린더 이벤트에 연결된 거래 목록. GET /calendar/event/{id}/expenses.
  Future<List<Expense>> listByCalendarEvent(int eventId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/calendar/event/$eventId/expenses',
      );
      return _unwrapList(res, 'expenses', Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 할 일에 연결된 거래 목록. GET /todo/{id}/expenses.
  Future<List<Expense>> listByTodo(int todoId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/todo/$todoId/expenses',
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

  Future<Expense> update({
    required int id,
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
      final res = await _dio.put<Map<String, dynamic>>(
        '/expense/$id',
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

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/expense/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// /expenses/search — 키워드/카테고리/자산/기간/금액 범위 등 멀티 조건 검색.
  Future<List<Expense>> search({
    int? categoryId,
    int? assetId,
    String? expenseType,
    String? keyword,
    String? merchant,
    int? minAmount,
    int? maxAmount,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/search',
        queryParameters: {
          'categoryId': ?categoryId,
          'assetId': ?assetId,
          'expenseType': ?expenseType,
          'keyword': ?keyword,
          'merchant': ?merchant,
          'minAmount': ?minAmount,
          'maxAmount': ?maxAmount,
          'startDate': ?startDate,
          'endDate': ?endDate,
        },
      );
      return _unwrapList(res, 'expenses', Expense.fromJson);
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

  Future<ExpenseCategory> createCategory({
    required String categoryName,
    String? icon,
    String? color,
    required String expenseType, // 'EXPENSE' | 'INCOME' | 'TRANSFER'
    int? parentRowId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense/category',
        data: {
          'categoryName': categoryName,
          'icon': ?icon,
          'color': ?color,
          'expenseType': expenseType,
          'parentRowId': ?parentRowId,
        },
      );
      return _unwrap(res, ExpenseCategory.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ExpenseCategory> updateCategory({
    required int id,
    required String categoryName,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/expense/category/$id',
        data: {
          'categoryName': categoryName,
          'icon': ?icon,
          'color': ?color,
          'sortOrder': ?sortOrder,
        },
      );
      return _unwrap(res, ExpenseCategory.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete<void>('/expense/category/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 카테고리 정렬 순서 + 부모 변경. PATCH /expense/categories/reorder.
  /// [items] = (categoryRowId, sortOrder, parentRowId?) tuple 목록.
  Future<void> reorderCategories(
    List<({int categoryRowId, int sortOrder, int? parentRowId})> items,
  ) async {
    try {
      await _dio.patch<dynamic>(
        '/expense/categories/reorder',
        data: {
          'items': [
            for (final i in items)
              {
                'categoryRowId': i.categoryRowId,
                'sortOrder': i.sortOrder,
                'parentRowId': ?i.parentRowId,
              },
          ],
        },
      );
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
