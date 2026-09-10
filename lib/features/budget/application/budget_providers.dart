import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/core/sync/query_freshness.dart';
import 'package:porest_desk_app/features/budget/data/budget_repository.dart';
import 'package:porest_desk_app/features/budget/domain/budget.dart';
import 'package:porest_desk_app/features/budget/domain/budget_compliance.dart';

final budgetRepositoryProvider = FutureProvider<BudgetRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return BudgetRepository(dio);
});

/// 예산 경고 임계값(%) — 사용자 설정값. 게이지 경고색 시작점.
/// 웹 BudgetPage `budgetAlertThreshold ?? 85` 정합. 미설정/실패 시 85 기본.
final budgetAlertThresholdProvider = FutureProvider<int>((ref) async {
  final repo = await ref.watch(authRepositoryProvider.future);
  final threshold = (await repo.getBudgetAlertThreshold()) ?? 85;
  ref.markQueryFetched(ServerQuery.budgetAlertThreshold);
  return threshold;
});

typedef BudgetMonthKey = ({int year, int month});

final monthBudgetsProvider =
    FutureProvider.family<List<Budget>, BudgetMonthKey>((ref, key) async {
      final repo = await ref.watch(budgetRepositoryProvider.future);
      final budgets = await repo.list(year: key.year, month: key.month);
      ref.markQueryFetched(ServerQuery.monthBudgets);
      return budgets;
    });

/// 최근 N개월 예산 준수율 (기본 6).
final budgetComplianceProvider =
    FutureProvider.family<List<BudgetComplianceMonth>, int>((
      ref,
      months,
    ) async {
      ref.keepAlive();
      final repo = await ref.watch(budgetRepositoryProvider.future);
      final compliance = await repo.compliance(months: months);
      ref.markQueryFetched(ServerQuery.budgetCompliance);
      return compliance;
    });
