import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/budget_repository.dart';
import '../domain/budget.dart';
import '../domain/budget_compliance.dart';

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

/// 최근 N개월 예산 준수율 (기본 6).
final budgetComplianceProvider =
    FutureProvider.family<List<BudgetComplianceMonth>, int>((ref, months) async {
  ref.keepAlive();
  final repo = await ref.watch(budgetRepositoryProvider.future);
  return repo.compliance(months: months);
});
