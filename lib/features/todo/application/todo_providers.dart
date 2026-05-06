import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';

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
