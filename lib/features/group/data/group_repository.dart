import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/group.dart';
import '../domain/group_member.dart';

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
    String? color,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/group',
        data: {
          'groupName': groupName,
          'description': ?description,
          'groupTypeId': ?groupTypeId,
          'color': ?color,
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
    String? color,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/group/$id',
        data: {
          'groupName': groupName,
          'description': ?description,
          'groupTypeId': ?groupTypeId,
          'color': ?color,
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

  /// 그룹 상세 (멤버 포함). GET /group/{id}.
  Future<GroupDetail> getDetail(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/group/$id');
      return _unwrap(res, GroupDetail.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 같은 그룹 다른 멤버 목록 — 더치페이/지출분할 멤버 후보용.
  /// GET /groups/members.
  Future<List<SiblingMember>> getSiblingMembers() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/groups/members');
      return _unwrapList(res, 'members', SiblingMember.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 그룹 멤버 제거. DELETE /group/{groupId}/member/{memberId}.
  Future<void> removeMember(int groupId, int memberId) async {
    try {
      await _dio.delete<void>('/group/$groupId/member/$memberId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 멤버 권한 변경 (OWNER/EDIT/READ).
  Future<void> changeMemberRole(int groupId, int memberId, String role) async {
    try {
      await _dio.patch<dynamic>(
        '/group/$groupId/member/$memberId/role',
        data: {'role': role},
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
