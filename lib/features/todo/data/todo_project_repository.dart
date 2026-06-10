import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/todo/domain/todo_project.dart';

class TodoProjectRepository {
  TodoProjectRepository(this._dio);
  final Dio _dio;

  Future<List<TodoProject>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/todo-projects');
      return _unwrapList(res, 'projects', TodoProject.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TodoProject> create({
    required String projectName,
    String? description,
    String? color,
    String? icon,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/todo-project',
        data: {
          'projectName': projectName,
          'description': ?description,
          'color': ?color,
          'icon': ?icon,
        },
      );
      return _unwrap(res, TodoProject.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TodoProject> update({
    required int id,
    required String projectName,
    String? description,
    String? color,
    String? icon,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/todo-project/$id',
        data: {
          'projectName': projectName,
          'description': ?description,
          'color': ?color,
          'icon': ?icon,
        },
      );
      return _unwrap(res, TodoProject.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/todo-project/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 정렬 순서 변경. PATCH /todo-projects/reorder.
  Future<void> reorder(List<({int projectId, int sortOrder})> items) async {
    try {
      await _dio.patch<dynamic>(
        '/todo-projects/reorder',
        data: {
          'items': [
            for (final i in items)
              {'projectId': i.projectId, 'sortOrder': i.sortOrder},
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
