import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/memo/domain/memo_tag.dart';

/// 메모 태그 마스터 — `TodoTagRepository` 미러.
///
/// 경로·본문·응답이 `/todo-tag` 와 같은 모양이다(`MemoTagApiController` 가 그렇게
/// 맞춰 뒀다). 설정에서 두 관리 화면이 나란히 놓이므로 두 리포지토리가 갈라질
/// 이유가 없다 — 한쪽만 손보면 같은 자리에서 두 번 고치게 된다.
class MemoTagRepository {
  MemoTagRepository(this._dio);
  final Dio _dio;

  Future<List<MemoTag>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/memo-tags');
      return _unwrapList(res, 'tags', MemoTag.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<MemoTag> create({required String tagName, String? color}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/memo-tag',
        data: {'tagName': tagName, 'color': ?color},
      );
      return _unwrap(res, MemoTag.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<MemoTag> update({
    required int id,
    required String tagName,
    String? color,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/memo-tag/$id',
        data: {'tagName': tagName, 'color': ?color},
      );
      return _unwrap(res, MemoTag.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 태그를 지운다. 서버가 이 태그를 쓰던 메모의 `tag` 와 마스터 연결을 함께
  /// 비운다 — 그 메모들은 '태그 없음' 으로 남는다(삭제 확인창이 약속하는 것).
  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/memo-tag/$id');
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
