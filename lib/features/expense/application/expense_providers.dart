import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/expense_repository.dart';
import '../domain/expense.dart';
import '../domain/expense_category.dart';

/// Repository provider — Dio 가 준비되면 ExpenseRepository 반환.
final expenseRepositoryProvider = FutureProvider<ExpenseRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return ExpenseRepository(dio);
});

/// 카테고리 전체 목록 — 거의 변하지 않으므로 keepAlive.
final categoriesProvider = FutureProvider<List<ExpenseCategory>>((ref) async {
  ref.keepAlive();
  final repo = await ref.watch(expenseRepositoryProvider.future);
  return repo.categories();
});

/// 월간 거래 목록 — `(year, month)` 키로 family.
typedef MonthKey = ({int year, int month});

final monthExpensesProvider =
    FutureProvider.family<List<Expense>, MonthKey>((ref, key) async {
  final repo = await ref.watch(expenseRepositoryProvider.future);
  final start = _firstDay(key.year, key.month);
  final end = _lastDay(key.year, key.month);
  return repo.list(startDate: start, endDate: end);
});

/// 자산 별 최근 거래 N건 — front `useSearchExpenses({assetId})` 미러.
/// AssetDetailDialog 등에서 활용.
typedef AssetExpensesKey = ({int assetId, int limit});

final expensesByAssetProvider =
    FutureProvider.family<List<Expense>, AssetExpensesKey>((ref, key) async {
  final repo = await ref.watch(expenseRepositoryProvider.future);
  final all = await repo.search(assetId: key.assetId);
  all.sort((a, b) =>
      (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''));
  return all.take(key.limit).toList();
});

/// 캘린더 이벤트별 연결 거래 (#252).
final expensesByCalendarEventProvider =
    FutureProvider.family<List<Expense>, int>((ref, eventId) async {
  final repo = await ref.watch(expenseRepositoryProvider.future);
  return repo.listByCalendarEvent(eventId);
});

/// 할 일별 연결 거래 (#252).
final expensesByTodoProvider =
    FutureProvider.family<List<Expense>, int>((ref, todoId) async {
  final repo = await ref.watch(expenseRepositoryProvider.future);
  return repo.listByTodo(todoId);
});

/// 자산 ID 로만 필터링한 거래 목록 (#254 — ExpenseScreen 자산 필터 배지용).
/// front `?assetId=N` 쿼리 미러: 빈 list 일 수 있음.
final expensesByAssetIdProvider =
    FutureProvider.family<List<Expense>, int>((ref, assetId) async {
  final repo = await ref.watch(expenseRepositoryProvider.future);
  final all = await repo.search(assetId: assetId);
  all.sort((a, b) =>
      (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''));
  return all;
});

String _firstDay(int y, int m) =>
    '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-01';
String _lastDay(int y, int m) {
  final last = DateTime(y, m + 1, 0).day;
  return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-'
      '${last.toString().padLeft(2, '0')}';
}

/// 카테고리 lookup by rowId.
extension CategoryListX on List<ExpenseCategory> {
  ExpenseCategory? byRowId(int rowId) {
    for (final c in this) {
      if (c.rowId == rowId) return c;
    }
    return null;
  }
}
