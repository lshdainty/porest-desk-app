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

    /// 원 통화 금액 (해외 결제). null 이면 원화 결제 — amount 가 곧 결제액이다.
    double? originalAmount,

    /// 원 통화 (ISO 4217, 예: USD).
    String? originalCurrency,

    /// 적용 환율 (원 통화 1단위당 원화). amount ≈ originalAmount × exchangeRate.
    double? exchangeRate,

    /// 이 거래에 달린 환불 건수·합계. 지우면 함께 사라지므로 화면이 미리 알린다.
    @Default(0) int refundCount,
    @Default(0) int refundedAmount,

    /// 시스템이 만든 거래의 출처 — `TRADE_REALIZED`(매도 실현손익) /
    /// `TRANSFER_INTEREST`(이체 이자). null 이면 손으로 쓴 거래다.
    ///
    /// 값이 있으면 금액·날짜·자산은 계산 결과라 고칠 수 없다. 원본 거래를 지우면
    /// 함께 사라진다. 카테고리·메모는 분류라서 그대로 고칠 수 있다.
    String? autoSource,
    int? calendarEventRowId,
    int? todoRowId,
    // 활성 분할 항목들의 카테고리 id (없으면 빈 리스트). 목록 카테고리 필터를 split-aware 하게 매칭.
    @Default(<int>[]) List<int> splitCategoryRowIds,
    String? createAt,
    String? modifyAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);
}

extension ExpenseX on Expense {
  /// 표시용 부호 적용 (지출=음수, 수입/이체=양수).
  int get signedAmount => expenseType == 'EXPENSE' ? -amount : amount;

  /// 이 거래에 아직 환불할 수 있는 금액 — **금액 − 이미 환불된 금액**(QA #152).
  ///
  /// 환불 합계가 원거래를 넘으면 통계 상계가 원거래보다 커져 지출이 수입으로
  /// 뒤집힌다. 그래서 상한은 원거래 금액이 아니라 **남은 금액**이다 —
  /// 12,000원 지출에 5,000원을 환불해 뒀으면 다음 환불은 7,000원까지다.
  ///
  /// 음수로는 안 내려간다. 상한이 없던 시절에 쌓인 초과 환불이 남아 있어,
  /// 그 거래를 열면 뺄셈이 음수로 떨어진다.
  int get refundableAmount {
    final left = amount - refundedAmount;
    return left < 0 ? 0 : left;
  }

  /// 'YYYY-MM-DD' 부분만 (그룹화·필터용).
  String? get expenseDateOnly => expenseDate?.substring(0, 10);
}
