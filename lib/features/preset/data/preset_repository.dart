import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/expense_template.dart';

class PresetRepository {
  PresetRepository(this._dio);
  final Dio _dio;

  Future<List<ExpenseTemplate>> list() async {
    try {
      final res =
          await _dio.get<Map<String, dynamic>>('/expense-templates');
      return _unwrapList(res, 'templates', ExpenseTemplate.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ExpenseTemplate> create({
    required String templateName,
    required int categoryRowId,
    required int assetRowId,
    required String expenseType,
    required int amount,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? sortOrder,
    bool lockAmount = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/expense-template',
        data: {
          'templateName': templateName,
          'categoryRowId': categoryRowId,
          'assetRowId': assetRowId,
          'expenseType': expenseType,
          'amount': amount,
          'description': ?description,
          'merchant': ?merchant,
          'paymentMethod': ?paymentMethod,
          'sortOrder': ?sortOrder,
          'lockAmount': lockAmount ? 'Y' : 'N',
        },
      );
      return _unwrap(res, ExpenseTemplate.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ExpenseTemplate> update({
    required int id,
    required String templateName,
    required int categoryRowId,
    required int assetRowId,
    required String expenseType,
    required int amount,
    String? description,
    String? merchant,
    String? paymentMethod,
    bool lockAmount = false,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/expense-template/$id',
        data: {
          'templateName': templateName,
          'categoryRowId': categoryRowId,
          'assetRowId': assetRowId,
          'expenseType': expenseType,
          'amount': amount,
          'description': ?description,
          'merchant': ?merchant,
          'paymentMethod': ?paymentMethod,
          'lockAmount': lockAmount ? 'Y' : 'N',
        },
      );
      return _unwrap(res, ExpenseTemplate.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/expense-template/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 템플릿으로 거래 1건 즉시 생성.
  Future<void> use(int id, {required String expenseDate}) async {
    try {
      await _dio.post<dynamic>(
        '/expense-template/$id/use',
        data: {'expenseDate': expenseDate},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

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
