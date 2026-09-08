import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/core/network/patch.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/todo/domain/todo_stats.dart';

class TodoRepository {
  TodoRepository(this._dio);
  final Dio _dio;

  Future<List<Todo>> list({
    String? status,
    String? priority,
    String? type,
  }) async {
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

  /// 수정 — 편집 화면이 소유한 칸만 키를 싣는다(QA #99).
  ///
  /// [content] 와 [dueDate] 가 [Patch] 다. 메모는 지울 수 있고 기한은 안 정한
  /// 상태로 되돌릴 수 있어, 둘 다 명시적 null 을 실어야 서버가 지운다.
  /// 우선순위·카테고리는 화면이 늘 값을 들고 있다(둘 다 기본값이 있다).
  /// 태그(`tagIds`)는 [updateTags] 가 따로 다룬다 — "null=미변경 · 빈 배열=전부 해제"
  /// 라는 뜻이 이미 확정돼 있어(QA #87) 여기에 섞지 않는다.
  Future<Todo> update({
    required int id,
    required String title,
    Patch<String> content = const Patch.keep(),
    String? priority,
    String? category,
    Patch<String> dueDate = const Patch.keep(),
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/todo/$id',
        data: {
          'title': title,
          if (content.present) 'content': content.value,
          'priority': ?priority,
          'category': ?category,
          if (dueDate.present) 'dueDate': dueDate.value,
        },
      );
      return _unwrap(res, Todo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 상태 토글 — 이번 토글로 실제 적립된 별빛(earnedStarlight)을 돌려준다.
  /// 회수·평생 1회 차단이면 0. 화면 토스트가 이 값을 그대로 써야 "+N" 이 거짓이 되지 않는다.
  Future<int> setStatus(int id, String status) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/todo/$id/status',
        data: {'status': status},
      );
      final data = res.data?['data'];
      if (data is Map<String, dynamic>) {
        return (data['earnedStarlight'] as num?)?.toInt() ?? 0;
      }
      return 0;
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

  /// 단건 조회. GET /todo/{id}.
  Future<Todo> getById(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/todo/$id');
      return _unwrap(res, Todo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 정렬 순서 변경. PATCH /todos/reorder.
  Future<void> reorder(List<({int todoId, int sortOrder})> items) async {
    try {
      await _dio.patch<dynamic>(
        '/todos/reorder',
        data: {
          'items': [
            for (final i in items)
              {'todoId': i.todoId, 'sortOrder': i.sortOrder},
          ],
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 서브태스크 목록. GET /todo/{id}/subtasks.
  Future<List<Todo>> getSubtasks(int parentId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/todo/$parentId/subtasks',
      );
      return _unwrapList(res, 'todos', Todo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 태그 일괄 변경. PATCH /todo/{id}/tags.
  Future<void> updateTags(int id, List<int> tagIds) async {
    try {
      await _dio.patch<dynamic>('/todo/$id/tags', data: {'tagIds': tagIds});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 통계 (카운트 묶음). GET /todos/stats.
  Future<TodoStats> stats() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/todos/stats');
      return _unwrap(res, TodoStats.fromJson);
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
