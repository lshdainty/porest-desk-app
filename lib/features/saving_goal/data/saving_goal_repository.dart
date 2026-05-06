import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/saving_goal.dart';

class SavingGoalRepository {
  SavingGoalRepository(this._dio);
  final Dio _dio;

  Future<List<SavingGoal>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/saving-goals');
      return _unwrapList(res, 'goals', SavingGoal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SavingGoal> create({
    required String title,
    String? description,
    required int targetAmount,
    String? deadlineDate,
    String? icon,
    String? color,
    int? linkedAssetRowId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/saving-goal',
        data: {
          'title': title,
          'description': ?description,
          'targetAmount': targetAmount,
          'deadlineDate': ?deadlineDate,
          'icon': ?icon,
          'color': ?color,
          'linkedAssetRowId': ?linkedAssetRowId,
        },
      );
      return _unwrap(res, SavingGoal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SavingGoal> update({
    required int id,
    required String title,
    String? description,
    required int targetAmount,
    String? deadlineDate,
    String? icon,
    String? color,
    int? linkedAssetRowId,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/saving-goal/$id',
        data: {
          'title': title,
          'description': ?description,
          'targetAmount': targetAmount,
          'deadlineDate': ?deadlineDate,
          'icon': ?icon,
          'color': ?color,
          'linkedAssetRowId': ?linkedAssetRowId,
        },
      );
      return _unwrap(res, SavingGoal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SavingGoal> contribute(int id, {required int amount, String? note}) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/saving-goal/$id/contribute',
        data: {
          'amount': amount,
          'note': ?note,
        },
      );
      return _unwrap(res, SavingGoal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/saving-goal/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 단건 조회. GET /saving-goal/{id}.
  Future<SavingGoal> getById(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/saving-goal/$id');
      return _unwrap(res, SavingGoal.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 정렬 순서 변경. PATCH /saving-goals/reorder.
  Future<void> reorder(List<({int id, int sortOrder})> items) async {
    try {
      await _dio.patch<dynamic>(
        '/saving-goals/reorder',
        data: {
          'items': [
            for (final i in items)
              {'id': i.id, 'sortOrder': i.sortOrder},
          ],
        },
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
