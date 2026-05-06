// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExpenseCategory _$ExpenseCategoryFromJson(Map<String, dynamic> json) =>
    _ExpenseCategory(
      rowId: (json['rowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      expenseType: json['expenseType'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      parentRowId: (json['parentRowId'] as num?)?.toInt(),
      hasChildren: json['hasChildren'] as bool? ?? false,
    );

Map<String, dynamic> _$ExpenseCategoryToJson(_ExpenseCategory instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'userRowId': instance.userRowId,
      'categoryName': instance.categoryName,
      'icon': instance.icon,
      'color': instance.color,
      'expenseType': instance.expenseType,
      'sortOrder': instance.sortOrder,
      'parentRowId': instance.parentRowId,
      'hasChildren': instance.hasChildren,
    };
