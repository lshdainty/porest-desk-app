import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/expense_split/data/expense_split_repository.dart';
import 'package:porest_desk_app/features/expense_split/domain/expense_split.dart';

final expenseSplitRepositoryProvider =
    FutureProvider<ExpenseSplitRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return ExpenseSplitRepository(dio);
});

final expenseSplitsProvider =
    FutureProvider.family<List<ExpenseSplit>, int>((ref, expenseId) async {
  final repo = await ref.watch(expenseSplitRepositoryProvider.future);
  return repo.list(expenseId);
});
