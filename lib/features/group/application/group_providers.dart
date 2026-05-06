import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/group_repository.dart';
import '../domain/group.dart';
import '../domain/group_member.dart';

final groupRepositoryProvider = FutureProvider<GroupRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return GroupRepository(dio);
});

final groupListProvider = FutureProvider<List<Group>>((ref) async {
  final repo = await ref.watch(groupRepositoryProvider.future);
  return repo.list();
});

final groupDetailProvider =
    FutureProvider.family<GroupDetail, int>((ref, id) async {
  final repo = await ref.watch(groupRepositoryProvider.future);
  return repo.getDetail(id);
});
