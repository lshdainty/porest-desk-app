// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExpenseTemplate _$ExpenseTemplateFromJson(Map<String, dynamic> json) =>
    _ExpenseTemplate(
      rowId: (json['rowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      templateName: json['templateName'] as String,
      categoryRowId: (json['categoryRowId'] as num).toInt(),
      categoryName: json['categoryName'] as String?,
      assetRowId: (json['assetRowId'] as num).toInt(),
      assetName: json['assetName'] as String?,
      expenseType: json['expenseType'] as String,
      amount: (json['amount'] as num).toInt(),
      description: json['description'] as String?,
      merchant: json['merchant'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      useCount: (json['useCount'] as num?)?.toInt(),
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      lockAmount: json['lockAmount'] as String?,
      lastUsedAt: json['lastUsedAt'] as String?,
      createAt: json['createAt'] as String?,
      modifyAt: json['modifyAt'] as String?,
    );

Map<String, dynamic> _$ExpenseTemplateToJson(_ExpenseTemplate instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'userRowId': instance.userRowId,
      'templateName': instance.templateName,
      'categoryRowId': instance.categoryRowId,
      'categoryName': instance.categoryName,
      'assetRowId': instance.assetRowId,
      'assetName': instance.assetName,
      'expenseType': instance.expenseType,
      'amount': instance.amount,
      'description': instance.description,
      'merchant': instance.merchant,
      'paymentMethod': instance.paymentMethod,
      'useCount': instance.useCount,
      'sortOrder': instance.sortOrder,
      'lockAmount': instance.lockAmount,
      'lastUsedAt': instance.lastUsedAt,
      'createAt': instance.createAt,
      'modifyAt': instance.modifyAt,
    };
