import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/todo.dart';

class TodoRepository {
  TodoRepository(this._dio);
  final Dio _dio;

  Future<List<Todo>> list({String? status, String? priority, String? type}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/todos',
        queryParameters: {
          'status': ?status,
          'priority': ?priority,
          'type': ?type,
        },
      );
      return _unwrapList(res, 'todos', Todo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Todo> create({
    required String title,
    String? content,
    String? priority,
    String? category,
    String? dueDate,
    String? type,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/todo',
        data: {
          'title': title,
          'content': ?content,
          'priority': ?priority,
          'category': ?category,
          'dueDate': ?dueDate,
          'type': type ?? 'TASK',
        },
      );
      return _unwrap(res, Todo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Todo> update({
    required int id,
    required String title,
    String? content,
    String? priority,
    String? category,
    String? dueDate,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/todo/$id',
        data: {
          'title': title,
          'content': ?content,
          'priority': ?priority,
          'category': ?category,
          'dueDate': ?dueDate,
        },
      );
      return _unwrap(res, Todo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> setStatus(int id, String status) async {
    try {
      await _dio.patch<dynamic>(
        '/todo/$id/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> pin(int id) async {
    try {
      await _dio.patch<dynamic>('/todo/$id/pin');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/todo/$id');
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
