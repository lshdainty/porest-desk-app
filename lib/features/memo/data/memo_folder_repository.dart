import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/memo/domain/memo_folder.dart';

/// 메모 폴더 — front `memoFolderApi` 미러.
class MemoFolderRepository {
  MemoFolderRepository(this._dio);
  final Dio _dio;

  Future<List<MemoFolder>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/memo/folders');
      return _unwrapList(res, 'folders', MemoFolder.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<MemoFolder> create({required String folderName, int? parentId}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/memo/folder',
        data: {'folderName': folderName, 'parentId': ?parentId},
      );
      return _unwrap(res, MemoFolder.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<MemoFolder> update({
    required int id,
    required String folderName,
    int? parentId,
    int? sortOrder,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/memo/folder/$id',
        data: {
          'folderName': folderName,
          'parentId': ?parentId,
          'sortOrder': ?sortOrder,
        },
      );
      return _unwrap(res, MemoFolder.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/memo/folder/$id');
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
