import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/memo/domain/memo.dart';

class MemoRepository {
  MemoRepository(this._dio);
  final Dio _dio;

  Future<List<Memo>> list({int? folderId, String? search}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/memos',
        queryParameters: {
          'folderId': ?folderId,
          'search': ?search,
        },
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
    int? folderId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/memo',
        data: {
          'folderId': ?folderId,
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

  Future<Memo> update({
    required int id,
    String? title,
    String? content,
    String? tag,
    String? color,
    int? folderId,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/memo/$id',
        data: {
          'folderId': ?folderId,
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
