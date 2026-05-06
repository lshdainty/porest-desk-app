import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_category.freezed.dart';
part 'expense_category.g.dart';

/// 백엔드 `ExpenseCategoryApiDto.Response` 1:1 매핑.
@freezed
abstract class ExpenseCategory with _$ExpenseCategory {
  const factory ExpenseCategory({
    required int rowId,
    int? userRowId,
    required String categoryName,
    String? icon,
    String? color,
    String? expenseType, // 'EXPENSE' | 'INCOME' | 'TRANSFER' (없을 수도)
    int? sortOrder,
    int? parentRowId,
    @Default(false) bool hasChildren,
  }) = _ExpenseCategory;

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) =>
      _$ExpenseCategoryFromJson(json);
}
