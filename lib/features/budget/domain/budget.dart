import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

/// 백엔드 `ExpenseBudgetApiDto.Response` 매핑.
///
/// `categoryRowId` 는 nullable — 카테고리 미지정 예산이 '월 전체 상한' 으로
/// 사용됨 (web `ExpenseBudget.categoryRowId: number | null` 동일).
@freezed
abstract class Budget with _$Budget {
  const factory Budget({
    required int rowId,
    int? userRowId,
    int? categoryRowId,
    String? categoryName,
    required int budgetAmount,
    required int budgetYear,
    required int budgetMonth,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
}
