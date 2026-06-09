// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => _Expense(
  rowId: (json['rowId'] as num).toInt(),
  userRowId: (json['userRowId'] as num?)?.toInt(),
  categoryRowId: (json['categoryRowId'] as num?)?.toInt(),
  categoryName: json['categoryName'] as String?,
  categoryIcon: json['categoryIcon'] as String?,
  categoryColor: json['categoryColor'] as String?,
  assetRowId: (json['assetRowId'] as num?)?.toInt(),
  assetName: json['assetName'] as String?,
  expenseType: json['expenseType'] as String,
  amount: (json['amount'] as num).toInt(),
  description: json['description'] as String?,
  expenseDate: json['expenseDate'] as String?,
  merchant: json['merchant'] as String?,
  paymentMethod: json['paymentMethod'] as String?,
  calendarEventRowId: (json['calendarEventRowId'] as num?)?.toInt(),
  todoRowId: (json['todoRowId'] as num?)?.toInt(),
  createAt: json['createAt'] as String?,
  modifyAt: json['modifyAt'] as String?,
);

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
  'rowId': instance.rowId,
  'userRowId': instance.userRowId,
  'categoryRowId': instance.categoryRowId,
  'categoryName': instance.categoryName,
  'categoryIcon': instance.categoryIcon,
  'categoryColor': instance.categoryColor,
  'assetRowId': instance.assetRowId,
  'assetName': instance.assetName,
  'expenseType': instance.expenseType,
  'amount': instance.amount,
  'description': instance.description,
  'expenseDate': instance.expenseDate,
  'merchant': instance.merchant,
  'paymentMethod': instance.paymentMethod,
  'calendarEventRowId': instance.calendarEventRowId,
  'todoRowId': instance.todoRowId,
  'createAt': instance.createAt,
  'modifyAt': instance.modifyAt,
};
