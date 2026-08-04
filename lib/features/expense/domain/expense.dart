import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

/// 백엔드 `ExpenseApiDto.Response` 1:1 매핑.
@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required int rowId,
    int? userRowId,
    int? categoryRowId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    int? assetRowId,
    String? assetName,
    required String expenseType, // 'EXPENSE' | 'INCOME'
    required int amount,
    String? description,
    String? expenseDate, // ISO LocalDateTime ('YYYY-MM-DDTHH:mm:ss')
    String? merchant,
    String? paymentMethod,
    /// 할부 개월 (null = 일시불). 신용카드 결제에만 의미.
    int? installmentMonths,
    /// 환불 원거래 행 아이디 (null = 환불 아님). 수입이면서 이 값이 있으면 지출 상계로 집계.
    int? refundOfExpenseRowId,
    int? calendarEventRowId,
    int? todoRowId,
    // 활성 분할 항목들의 카테고리 id (없으면 빈 리스트). 목록 카테고리 필터를 split-aware 하게 매칭.
    @Default(<int>[]) List<int> splitCategoryRowIds,
    String? createAt,
    String? modifyAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
}

extension ExpenseX on Expense {
  /// 표시용 부호 적용 (지출=음수, 수입/이체=양수).
  int get signedAmount => expenseType == 'EXPENSE' ? -amount : amount;

  /// 'YYYY-MM-DD' 부분만 (그룹화·필터용).
  String? get expenseDateOnly => expenseDate?.substring(0, 10);
}
