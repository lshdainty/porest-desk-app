import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/budget_repository.dart';
import '../domain/budget.dart';

final budgetRepositoryProvider = FutureProvider<BudgetRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return BudgetRepository(dio);
});

typedef BudgetMonthKey = ({int year, int month});

final monthBudgetsProvider =
    FutureProvider.family<List<Budget>, BudgetMonthKey>((ref, key) async {
  final repo = await ref.watch(budgetRepositoryProvider.future);
  return repo.list(year: key.year, month: key.month);
});
