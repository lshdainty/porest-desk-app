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
