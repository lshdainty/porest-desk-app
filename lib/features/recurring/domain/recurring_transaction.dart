import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_transaction.freezed.dart';
part 'recurring_transaction.g.dart';

/// 백엔드 `RecurringTransactionApiDto.Response` 매핑.
///
/// frequency: 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY'
/// expenseType: 'EXPENSE' | 'INCOME' | 'TRANSFER'
/// isActive: 'Y' | 'N' (YNType)
/// dayOfWeek: ISO 1=월 ~ 7=일
/// dayOfMonth: 1~31
@freezed
abstract class RecurringTransaction with _$RecurringTransaction {
  const factory RecurringTransaction({
    required int rowId,
    int? userRowId,
    @Default(0) int categoryRowId,
    String? categoryName,
    @Default(0) int assetRowId,
    String? assetName,

    /// 이체일 때 받는 자산. 지출·수입이면 null.
    int? toAssetRowId,
    String? toAssetName,

    /// 이체 수수료. 지출·수입이면 null.
    int? fee,

    /// 이체 이자 — 받는 자산이 대출일 때만 값이 있다.
    int? interestAmount,
    int? sourceExpenseRowId,
    required String expenseType,
    @Default(0) int amount,
    String? description,
    String? merchant,
    String? paymentMethod,
    required String frequency,
    int? intervalValue,
    int? dayOfWeek,
    int? dayOfMonth,
    String? executionTime, // 'HH:mm:ss' — 실행분을 만들 시각 [userClock]
    String? startDate, // 'YYYY-MM-DD'
    String? endDate,
    int? maxOccurrences,
    @Default(0) int executedCount,
    String? nextExecutionDate,
    String? lastExecutedAt,
    String? isActive, // 'Y' | 'N'
    @Default(false) bool autoLog,
    @Default(false) bool notifyDayBefore,
  }) = _RecurringTransaction;

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionFromJson(json);
}
