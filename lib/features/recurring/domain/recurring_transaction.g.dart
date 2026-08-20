// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurringTransaction _$RecurringTransactionFromJson(
  Map<String, dynamic> json,
) => _RecurringTransaction(
  rowId: (json['rowId'] as num).toInt(),
  userRowId: (json['userRowId'] as num?)?.toInt(),
  categoryRowId: (json['categoryRowId'] as num?)?.toInt() ?? 0,
  categoryName: json['categoryName'] as String?,
  assetRowId: (json['assetRowId'] as num?)?.toInt() ?? 0,
  assetName: json['assetName'] as String?,
  sourceExpenseRowId: (json['sourceExpenseRowId'] as num?)?.toInt(),
  expenseType: json['expenseType'] as String,
  amount: (json['amount'] as num?)?.toInt() ?? 0,
  description: json['description'] as String?,
  merchant: json['merchant'] as String?,
  paymentMethod: json['paymentMethod'] as String?,
  frequency: json['frequency'] as String,
  intervalValue: (json['intervalValue'] as num?)?.toInt(),
  dayOfWeek: (json['dayOfWeek'] as num?)?.toInt(),
  dayOfMonth: (json['dayOfMonth'] as num?)?.toInt(),
  executionTime: json['executionTime'] as String?,
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  maxOccurrences: (json['maxOccurrences'] as num?)?.toInt(),
  executedCount: (json['executedCount'] as num?)?.toInt() ?? 0,
  nextExecutionDate: json['nextExecutionDate'] as String?,
  lastExecutedAt: json['lastExecutedAt'] as String?,
  isActive: json['isActive'] as String?,
  autoLog: json['autoLog'] as bool? ?? false,
  notifyDayBefore: json['notifyDayBefore'] as bool? ?? false,
);

Map<String, dynamic> _$RecurringTransactionToJson(
  _RecurringTransaction instance,
) => <String, dynamic>{
  'rowId': instance.rowId,
  'userRowId': instance.userRowId,
  'categoryRowId': instance.categoryRowId,
  'categoryName': instance.categoryName,
  'assetRowId': instance.assetRowId,
  'assetName': instance.assetName,
  'sourceExpenseRowId': instance.sourceExpenseRowId,
  'expenseType': instance.expenseType,
  'amount': instance.amount,
  'description': instance.description,
  'merchant': instance.merchant,
  'paymentMethod': instance.paymentMethod,
  'frequency': instance.frequency,
  'intervalValue': instance.intervalValue,
  'dayOfWeek': instance.dayOfWeek,
  'dayOfMonth': instance.dayOfMonth,
  'executionTime': instance.executionTime,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'maxOccurrences': instance.maxOccurrences,
  'executedCount': instance.executedCount,
  'nextExecutionDate': instance.nextExecutionDate,
  'lastExecutedAt': instance.lastExecutedAt,
  'isActive': instance.isActive,
  'autoLog': instance.autoLog,
  'notifyDayBefore': instance.notifyDayBefore,
};
