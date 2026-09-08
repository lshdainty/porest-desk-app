import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/memo/data/memo_repository.dart';
import 'package:porest_desk_app/features/memo/data/memo_tag_repository.dart';
import 'package:porest_desk_app/features/memo/domain/memo.dart';
import 'package:porest_desk_app/features/memo/domain/memo_tag.dart';

final memoRepositoryProvider = FutureProvider<MemoRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return MemoRepository(dio);
});

final memoListProvider = FutureProvider<List<Memo>>((ref) async {
  final repo = await ref.watch(memoRepositoryProvider.future);
  return repo.list();
});

/// 검색 필터 적용된 메모 목록.
typedef MemoQuery = ({String? search});

final memoSearchProvider = FutureProvider.family<List<Memo>, MemoQuery>((
  ref,
  q,
) async {
  final repo = await ref.watch(memoRepositoryProvider.future);
  return repo.list(search: q.search);
});

// ─── MemoTag ────────────────────────────────────────────────

final memoTagRepositoryProvider = FutureProvider<MemoTagRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return MemoTagRepository(dio);
});

/// 메모 태그 마스터 — 편집 시트의 태그 선택지 원본(todoTagListProvider 미러).
///
/// `keepAlive` 라 앱 세션 내내 굳는다. 다른 기기(웹 설정 화면)에서 태그를 늘리거나
/// 지운 것은 포그라운드 복귀 때 `invalidateKeepAliveProviders` 가 걷어 낸다 —
/// 거기에 안 걸면 앱을 껐다 켜기 전까지 옛 목록을 계속 보여 준다.
final memoTagListProvider = FutureProvider<List<MemoTag>>((ref) async {
  ref.keepAlive();
  final repo = await ref.watch(memoTagRepositoryProvider.future);
  return repo.list();
});
