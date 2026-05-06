import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/memo_repository.dart';
import '../domain/memo.dart';

final memoRepositoryProvider = FutureProvider<MemoRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return MemoRepository(dio);
});

final memoListProvider = FutureProvider<List<Memo>>((ref) async {
  final repo = await ref.watch(memoRepositoryProvider.future);
  return repo.list();
});

/// 검색/폴더 필터 적용된 메모 목록.
typedef MemoQuery = ({int? folderId, String? search});

final memoSearchProvider =
    FutureProvider.family<List<Memo>, MemoQuery>((ref, q) async {
  final repo = await ref.watch(memoRepositoryProvider.future);
  return repo.list(folderId: q.folderId, search: q.search);
});
