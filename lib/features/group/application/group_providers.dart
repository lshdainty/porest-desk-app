import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/group_repository.dart';
import '../domain/group_member.dart';

// group UI 폐지(캘린더 공유 → user_calendar). 더치페이 형제 멤버만 유지.
final groupRepositoryProvider = FutureProvider<GroupRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return GroupRepository(dio);
});

/// 같은 그룹 다른 멤버 (더치페이 멤버 picker / 멘션 후보).
final siblingMembersProvider =
    FutureProvider<List<SiblingMember>>((ref) async {
  final repo = await ref.watch(groupRepositoryProvider.future);
  return repo.getSiblingMembers();
});
