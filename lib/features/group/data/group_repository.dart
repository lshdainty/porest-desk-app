import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/group.dart';

class GroupRepository {
  GroupRepository(this._dio);
  final Dio _dio;

  Future<List<Group>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/groups');
      return _unwrapList(res, 'groups', Group.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Group> create({
    required String groupName,
    String? description,
    int? groupTypeId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/group',
        data: {
          'groupName': groupName,
          'description': ?description,
          'groupTypeId': ?groupTypeId,
        },
      );
      return _unwrap(res, Group.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Group> update({
    required int id,
    required String groupName,
    String? description,
    int? groupTypeId,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/group/$id',
        data: {
          'groupName': groupName,
          'description': ?description,
          'groupTypeId': ?groupTypeId,
        },
      );
      return _unwrap(res, Group.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/group/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Group> joinByCode(String inviteCode) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/group/join',
        data: {'inviteCode': inviteCode},
      );
      return _unwrap(res, Group.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> regenerateInviteCode(int id) async {
    try {
      await _dio.patch<dynamic>('/group/$id/regenerate-invite-code');
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
