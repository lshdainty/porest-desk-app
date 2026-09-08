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

  /// 생성 — [parentRowId] 를 주면 그 할 일의 **하위 할 일**로 만들어진다.
  ///
  /// 키를 빼면 서버가 최상위로 만든다(`TodoServiceImpl.createTodo` 의 `parent`
  /// 는 안 오면 null 이다). 그래서 편집 시트의 하위 빠른 추가는 **반드시** 부모
  /// 아이디를 실어야 한다 — 안 실으면 목록에는 안 보이고 상위 목록에만 쌓인다.
  Future<Todo> create({
    required String title,
    String? content,
    String? priority,
    String? category,
    String? dueDate,
    String? type,
    int? parentRowId,
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
          'parentRowId': ?parentRowId,
        },
      );
      return _unwrap(res, Todo.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 수정 — 편집 화면이 소유한 칸만 키를 싣는다(QA #99).
  ///
  /// [content] · [dueDate] · [category] 가 [Patch] 다. 메모는 지울 수 있고,
  /// 기한은 안 정한 상태로 되돌릴 수 있고, **태그는 뗄 수 있다** — 셋 다 명시적
  /// null 을 실어야 서버가 지운다. 종전엔 `category` 가 `String?` 이라 "태그 없음"
  /// 을 보낼 방법이 없었고(널이면 키째 빠져 서버가 옛 태그를 지켰다), 그래서 앱에서
  /// 한 번 붙은 태그를 뗄 수 없었다.
  /// 우선순위는 화면이 늘 값을 들고 있다(기본값이 있다).
  /// 태그 마스터 연결(`tagIds`)은 [updateTags] 가 따로 다룬다 —
  /// "null=미변경 · 빈 배열=전부 해제" 라는 뜻이 이미 확정돼 있어(QA #87) 섞지 않는다.
  Future<Todo> update({
    required int id,
    required String title,
    Patch<String> content = const Patch.keep(),
    String? priority,
    Patch<String> category = const Patch.keep(),
    Patch<String> dueDate = const Patch.keep(),
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/todo/$id',
        data: {
          'title': title,
          if (content.present) 'content': content.value,
          'priority': ?priority,
          if (category.present) 'category': category.value,
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
