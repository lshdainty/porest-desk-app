import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../domain/expense.dart';

/// v0.1: 메모리 기반 mock. Phase 7+ 에서 백엔드 연결로 교체될 예정.
final categoriesProvider = Provider<List<Category>>((_) => mockCategories);
final assetsProvider = Provider<List<Asset>>((_) => mockAssets);

final expensesProvider =
    NotifierProvider<ExpensesNotifier, List<Expense>>(ExpensesNotifier.new);

class ExpensesNotifier extends Notifier<List<Expense>> {
  @override
  List<Expense> build() => mockExpensesForCurrentMonth();

  void add(Expense e) => state = [...state, e];
  void remove(String id) => state = state.where((x) => x.id != id).toList();
}

/// 카테고리 lookup 헬퍼.
extension CategoryListX on List<Category> {
  Category byId(String id) =>
      firstWhere((c) => c.id == id, orElse: () => first);
}

extension AssetListX on List<Asset> {
  Asset byId(String id) =>
      firstWhere((a) => a.id == id, orElse: () => first);
}
