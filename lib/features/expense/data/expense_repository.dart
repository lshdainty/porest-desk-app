import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense_split/data/expense_split_repository.dart';

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
    int? assetRowId, // 자산 미연결 거래 허용 — 서버도 nullable
    required String expenseType,
    required int amount,
    required String expenseDate,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? installmentMonths,
    int? refundOfExpenseRowId,
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
          'installmentMonths': ?installmentMonths,
          'refundOfExpenseRowId': ?refundOfExpenseRowId,
        },
      );
      return _unwrap(res, Expense.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// [splits] 가 non-null 이면 금액과 함께 분할을 원자적으로 교체(PUT body 에 splits 포함).
  /// null 이면 분할 미변경(백엔드가 기존 분할 유지). 금액↔분할 합 일치화(reconcile) 저장에 사용.
  Future<Expense> update({
    required int id,
    required int categoryRowId,
    int? assetRowId, // 자산 미연결 거래 허용 — 서버도 nullable
    required String expenseType,
    required int amount,
    required String expenseDate,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? installmentMonths,
    int? refundOfExpenseRowId,
    List<SplitInput>? splits,
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
          'installmentMonths': ?installmentMonths,
          'refundOfExpenseRowId': ?refundOfExpenseRowId,
          if (splits != null)
            'splits': [
              for (final s in splits)
                {
                  'categoryRowId': s.categoryRowId,
                  'amount': s.amount,
                  'label': ?s.label,
                  'sortOrder': ?s.sortOrder,
                },
            ],
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
    String? expenseType,
    int? sortOrder,
    // parentRowId 는 null 자체가 의미("최상위로 이동")라 ?-skip 불가 —
    // [includeParentRowId] 로 명시 전송 여부를 구분 (웹은 항상 포함 전송).
    bool includeParentRowId = false,
    int? parentRowId,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/expense/category/$id',
        data: {
          'categoryName': categoryName,
          'icon': ?icon,
          'color': ?color,
          'expenseType': ?expenseType,
          'sortOrder': ?sortOrder,
          if (includeParentRowId) 'parentRowId': parentRowId,
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

  /// 카테고리에 달린 거래를 다른 카테고리로 일괄 이동.
  /// POST /expense/category/{id}/move-transactions
  ///
  /// 거래가 직접 달린 카테고리는 부모가 될 수 없어 하위를 만들 수 없는데, 그걸 푸는 방법.
  Future<int> moveCategoryTransactions(int id, int targetCategoryRowId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense/category/$id/move-transactions',
        data: {'targetCategoryRowId': targetCategoryRowId},
      );
      return _movedCount(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 하위 카테고리를 만들면서 이 카테고리의 거래를 그리로 옮긴다.
  /// POST /expense/category/{id}/split-into-child
  ///
  /// 거래가 있어 하위를 못 만들고, 옮길 하위가 없어 거래도 못 옮기는 교착을 푼다.
  Future<int> splitCategoryIntoChild(
    int id, {
    required String childName,
    required String icon,
    required String color,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense/category/$id/split-into-child',
        data: {'childName': childName, 'icon': icon, 'color': color},
      );
      return _movedCount(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 이동 응답(거래·반복거래·분할)의 합계 — 사용자에겐 "몇 건 옮겼는지"만 보여준다.
  int _movedCount(Map<String, dynamic>? raw) {
    final body = ApiResponse<Map<String, dynamic>>.fromJson(
      raw ?? const {},
      (d) => (d as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final d = body.data ?? const <String, dynamic>{};
    return ((d['expenses'] as num?)?.toInt() ?? 0) +
        ((d['recurring'] as num?)?.toInt() ?? 0) +
        ((d['splits'] as num?)?.toInt() ?? 0);
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
