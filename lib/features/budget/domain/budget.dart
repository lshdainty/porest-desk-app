import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

/// 백엔드 `ExpenseBudgetApiDto.Response` 매핑.
@freezed
abstract class Budget with _$Budget {
  const factory Budget({
    required int rowId,
    int? userRowId,
    required int categoryRowId,
    String? categoryName,
    required int budgetAmount,
    required int budgetYear,
    required int budgetMonth,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
}
