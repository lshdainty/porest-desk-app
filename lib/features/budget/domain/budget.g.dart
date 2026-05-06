// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Budget _$BudgetFromJson(Map<String, dynamic> json) => _Budget(
  rowId: (json['rowId'] as num).toInt(),
  userRowId: (json['userRowId'] as num?)?.toInt(),
  categoryRowId: (json['categoryRowId'] as num).toInt(),
  categoryName: json['categoryName'] as String?,
  budgetAmount: (json['budgetAmount'] as num).toInt(),
  budgetYear: (json['budgetYear'] as num).toInt(),
  budgetMonth: (json['budgetMonth'] as num).toInt(),
);

Map<String, dynamic> _$BudgetToJson(_Budget instance) => <String, dynamic>{
  'rowId': instance.rowId,
  'userRowId': instance.userRowId,
  'categoryRowId': instance.categoryRowId,
  'categoryName': instance.categoryName,
  'budgetAmount': instance.budgetAmount,
  'budgetYear': instance.budgetYear,
  'budgetMonth': instance.budgetMonth,
};
