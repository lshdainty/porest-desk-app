import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/group_repository.dart';
import '../data/group_type_repository.dart';
import '../domain/group.dart';
import '../domain/group_member.dart';
import '../domain/group_type.dart';

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

/// 같은 그룹 다른 멤버 (더치페이 멤버 picker / 멘션 후보 등에서 활용).
final siblingMembersProvider =
    FutureProvider<List<SiblingMember>>((ref) async {
  final repo = await ref.watch(groupRepositoryProvider.future);
  return repo.getSiblingMembers();
});

// ─── GroupType ────────────────────────────────────────────

final groupTypeRepositoryProvider =
    FutureProvider<GroupTypeRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return GroupTypeRepository(dio);
});

final groupTypeListProvider = FutureProvider<List<GroupType>>((ref) async {
  ref.keepAlive();
  final repo = await ref.watch(groupTypeRepositoryProvider.future);
  return repo.list();
});
