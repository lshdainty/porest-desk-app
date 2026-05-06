// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_split.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExpenseSplit _$ExpenseSplitFromJson(Map<String, dynamic> json) =>
    _ExpenseSplit(
      rowId: (json['rowId'] as num).toInt(),
      expenseRowId: (json['expenseRowId'] as num).toInt(),
      categoryRowId: (json['categoryRowId'] as num).toInt(),
      categoryName: json['categoryName'] as String?,
      amount: (json['amount'] as num).toInt(),
      label: json['label'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      createAt: json['createAt'] as String?,
      modifyAt: json['modifyAt'] as String?,
    );

Map<String, dynamic> _$ExpenseSplitToJson(_ExpenseSplit instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'expenseRowId': instance.expenseRowId,
      'categoryRowId': instance.categoryRowId,
      'categoryName': instance.categoryName,
      'amount': instance.amount,
      'label': instance.label,
      'sortOrder': instance.sortOrder,
      'createAt': instance.createAt,
      'modifyAt': instance.modifyAt,
    };
