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
    required int categoryRowId,
    String? categoryName,
    required int assetRowId,
    String? assetName,
    int? sourceExpenseRowId,
    required String expenseType,
    required int amount,
    String? description,
    String? merchant,
    String? paymentMethod,
    required String frequency,
    int? intervalValue,
    int? dayOfWeek,
    int? dayOfMonth,
    String? startDate, // 'YYYY-MM-DD'
    String? endDate,
    String? nextExecutionDate,
    String? lastExecutedAt,
    String? isActive, // 'Y' | 'N'
    @Default(false) bool autoLog,
    @Default(false) bool notifyDayBefore,
  }) = _RecurringTransaction;

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionFromJson(json);
}
