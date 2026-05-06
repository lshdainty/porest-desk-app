import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/memo_folder_repository.dart';
import '../data/memo_repository.dart';
import '../domain/memo.dart';
import '../domain/memo_folder.dart';

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

// ─── MemoFolder (#340) ──────────────────────────────────────

final memoFolderRepositoryProvider =
    FutureProvider<MemoFolderRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return MemoFolderRepository(dio);
});

final memoFolderListProvider = FutureProvider<List<MemoFolder>>((ref) async {
  ref.keepAlive();
  final repo = await ref.watch(memoFolderRepositoryProvider.future);
  return repo.list();
});

/// 폴더 트리 (root 노드들).
final memoFolderTreeProvider =
    FutureProvider<List<MemoFolderNode>>((ref) async {
  final list = await ref.watch(memoFolderListProvider.future);
  return MemoFolderNode.buildTree(list);
});
