// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_trade.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssetTrade _$AssetTradeFromJson(Map<String, dynamic> json) => _AssetTrade(
  rowId: (json['rowId'] as num).toInt(),
  assetRowId: (json['assetRowId'] as num).toInt(),
  tradeType: json['tradeType'] as String,
  holdingType: json['holdingType'] as String?,
  holdingKey: json['holdingKey'] as String,
  linked: json['linked'] as bool? ?? false,
  quantity: json['quantity'] as String?,
  amount: (json['amount'] as num?)?.toInt(),
  fee: (json['fee'] as num?)?.toInt(),
  realizedPl: (json['realizedPl'] as num?)?.toInt(),
  tradeDate: json['tradeDate'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$AssetTradeToJson(_AssetTrade instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'assetRowId': instance.assetRowId,
      'tradeType': instance.tradeType,
      'holdingType': instance.holdingType,
      'holdingKey': instance.holdingKey,
      'linked': instance.linked,
      'quantity': instance.quantity,
      'amount': instance.amount,
      'fee': instance.fee,
      'realizedPl': instance.realizedPl,
      'tradeDate': instance.tradeDate,
      'description': instance.description,
    };
