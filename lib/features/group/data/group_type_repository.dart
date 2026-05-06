import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/group_type.dart';

class GroupTypeRepository {
  GroupTypeRepository(this._dio);
  final Dio _dio;

  Future<List<GroupType>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/group-types');
      return _unwrapList(res, 'groupTypes', GroupType.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<GroupType> create({
    required String typeName,
    String? color,
    int? sortOrder,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/group-type',
        data: {
          'typeName': typeName,
          'color': ?color,
          'sortOrder': ?sortOrder,
        },
      );
      return _unwrap(res, GroupType.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<GroupType> update({
    required int id,
    required String typeName,
    String? color,
    int? sortOrder,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/group-type/$id',
        data: {
          'typeName': typeName,
          'color': ?color,
          'sortOrder': ?sortOrder,
        },
      );
      return _unwrap(res, GroupType.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/group-type/$id');
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
