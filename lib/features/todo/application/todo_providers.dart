import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/todo/data/todo_repository.dart';
import 'package:porest_desk_app/features/todo/data/todo_tag_repository.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/todo/domain/todo_tag.dart';

final todoRepositoryProvider = FutureProvider<TodoRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return TodoRepository(dio);
});

typedef TodoFilter = ({String? status, String? priority});

final todoListProvider = FutureProvider.family<List<Todo>, TodoFilter>((
  ref,
  filter,
) async {
  final repo = await ref.watch(todoRepositoryProvider.future);
  return repo.list(status: filter.status, priority: filter.priority);
});

/// 단건 todo (딥링크 진입용).
final todoByIdProvider = FutureProvider.family<Todo, int>((ref, id) async {
  final repo = await ref.watch(todoRepositoryProvider.future);
  return repo.getById(id);
});

// ─── TodoTag ────────────────────────────────────────────────

final todoTagRepositoryProvider = FutureProvider<TodoTagRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return TodoTagRepository(dio);
});

final todoTagListProvider = FutureProvider<List<TodoTag>>((ref) async {
  ref.keepAlive();
  final repo = await ref.watch(todoTagRepositoryProvider.future);
  return repo.list();
});
