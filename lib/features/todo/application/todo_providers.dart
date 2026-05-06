import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';
import '../domain/todo_stats.dart';

final todoRepositoryProvider = FutureProvider<TodoRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return TodoRepository(dio);
});

typedef TodoFilter = ({String? status, String? priority});

final todoListProvider =
    FutureProvider.family<List<Todo>, TodoFilter>((ref, filter) async {
  final repo = await ref.watch(todoRepositoryProvider.future);
  return repo.list(status: filter.status, priority: filter.priority);
});

/// 단건 todo (서브태스크/딥링크 진입용).
final todoByIdProvider =
    FutureProvider.family<Todo, int>((ref, id) async {
  final repo = await ref.watch(todoRepositoryProvider.future);
  return repo.getById(id);
});

/// 부모 todo 의 서브태스크 목록.
final todoSubtasksProvider =
    FutureProvider.family<List<Todo>, int>((ref, parentId) async {
  final repo = await ref.watch(todoRepositoryProvider.future);
  return repo.getSubtasks(parentId);
});

/// 전체 todo 통계 (대시보드/요약 위젯용).
final todoStatsProvider = FutureProvider<TodoStats>((ref) async {
  final repo = await ref.watch(todoRepositoryProvider.future);
  return repo.stats();
});
