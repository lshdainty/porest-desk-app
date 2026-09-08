import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/core/network/patch.dart';
import 'package:porest_desk_app/features/memo/domain/memo.dart';

class MemoRepository {
  MemoRepository(this._dio);
  final Dio _dio;

  Future<List<Memo>> list({String? search}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/memos',
        queryParameters: {'search': ?search},
      );
      return _unwrapList(res, 'memos', Memo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Memo> create({
    String? title,
    String? content,
    String? tag,
    String? color,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/memo',
        data: {
          'title': ?title,
          'content': ?content,
          'tag': ?tag,
          'color': ?color,
        },
      );
      return _unwrap(res, Memo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 수정 — 편집 화면이 소유한 칸만 키를 싣는다(QA #99).
  ///
  /// [content] 만 [Patch] 다. 본문은 화면에서 지울 수 있는 유일한 칸이라
  /// "비웠다" 를 명시적 null 로 실어야 서버가 지운다. 제목·태그·색은 화면이 늘
  /// 값을 들고 있어(태그·색은 기본값이 있고 제목은 빈 값을 막는다) 비워질 일이 없다.
  Future<Memo> update({
    required int id,
    String? title,
    Patch<String> content = const Patch.keep(),
    String? tag,
    String? color,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/memo/$id',
        data: {
          'title': ?title,
          if (content.present) 'content': content.value,
          'tag': ?tag,
          'color': ?color,
        },
      );
      return _unwrap(res, Memo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/memo/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> pin(int id) async {
    try {
      await _dio.patch<dynamic>('/memo/$id/pin');
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
