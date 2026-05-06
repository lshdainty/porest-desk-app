import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_split.freezed.dart';
part 'expense_split.g.dart';

/// 백엔드 `ExpenseSplitApiDto.Response` 매핑.
@freezed
abstract class ExpenseSplit with _$ExpenseSplit {
  const factory ExpenseSplit({
    required int rowId,
    required int expenseRowId,
    required int categoryRowId,
    String? categoryName,
    required int amount,
    String? label,
    int? sortOrder,
    String? createAt,
    String? modifyAt,
  }) = _ExpenseSplit;

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) =>
      _$ExpenseSplitFromJson(json);
}
