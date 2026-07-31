// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Asset _$AssetFromJson(Map<String, dynamic> json) => _Asset(
  rowId: (json['rowId'] as num).toInt(),
  userRowId: (json['userRowId'] as num?)?.toInt(),
  assetName: json['assetName'] as String,
  assetType: json['assetType'] as String,
  balance: (json['balance'] as num?)?.toInt(),
  currency: json['currency'] as String?,
  color: json['color'] as String?,
  institution: json['institution'] as String?,
  memo: json['memo'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
  isIncludedInTotal: json['isIncludedInTotal'] as String?,
  creditLimit: (json['creditLimit'] as num?)?.toInt(),
  paymentDay: (json['paymentDay'] as num?)?.toInt(),
  paymentAssetRowId: (json['paymentAssetRowId'] as num?)?.toInt(),
  tossSymbol: json['tossSymbol'] as String?,
  tossQuantity: (json['tossQuantity'] as num?)?.toInt(),
  holdings:
      (json['holdings'] as List<dynamic>?)
          ?.map((e) => AssetHolding.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AssetHolding>[],
);

Map<String, dynamic> _$AssetToJson(_Asset instance) => <String, dynamic>{
  'rowId': instance.rowId,
  'userRowId': instance.userRowId,
  'assetName': instance.assetName,
  'assetType': instance.assetType,
  'balance': instance.balance,
  'currency': instance.currency,
  'color': instance.color,
  'institution': instance.institution,
  'memo': instance.memo,
  'sortOrder': instance.sortOrder,
  'isIncludedInTotal': instance.isIncludedInTotal,
  'creditLimit': instance.creditLimit,
  'paymentDay': instance.paymentDay,
  'paymentAssetRowId': instance.paymentAssetRowId,
  'tossSymbol': instance.tossSymbol,
  'tossQuantity': instance.tossQuantity,
  'holdings': instance.holdings,
};

_AssetHolding _$AssetHoldingFromJson(Map<String, dynamic> json) =>
    _AssetHolding(
      rowId: (json['rowId'] as num?)?.toInt(),
      linked: json['linked'] as bool? ?? false,
      tossSymbol: json['tossSymbol'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      holdingName: json['holdingName'] as String?,
      holdingValue: (json['holdingValue'] as num?)?.toInt(),
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AssetHoldingToJson(_AssetHolding instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'linked': instance.linked,
      'tossSymbol': instance.tossSymbol,
      'quantity': instance.quantity,
      'holdingName': instance.holdingName,
      'holdingValue': instance.holdingValue,
      'sortOrder': instance.sortOrder,
    };
