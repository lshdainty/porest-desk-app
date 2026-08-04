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
  cashBalance: (json['cashBalance'] as num?)?.toInt(),
  holdingBalance: (json['holdingBalance'] as num?)?.toInt(),
  currency: json['currency'] as String?,
  exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
  color: json['color'] as String?,
  institution: json['institution'] as String?,
  memo: json['memo'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
  isIncludedInTotal: json['isIncludedInTotal'] as String?,
  creditLimit: (json['creditLimit'] as num?)?.toInt(),
  paymentDay: (json['paymentDay'] as num?)?.toInt(),
  paymentAssetRowId: (json['paymentAssetRowId'] as num?)?.toInt(),
  cardCatalog: json['cardCatalog'] == null
      ? null
      : AssetCardCatalog.fromJson(json['cardCatalog'] as Map<String, dynamic>),
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
  'cashBalance': instance.cashBalance,
  'holdingBalance': instance.holdingBalance,
  'currency': instance.currency,
  'exchangeRate': instance.exchangeRate,
  'color': instance.color,
  'institution': instance.institution,
  'memo': instance.memo,
  'sortOrder': instance.sortOrder,
  'isIncludedInTotal': instance.isIncludedInTotal,
  'creditLimit': instance.creditLimit,
  'paymentDay': instance.paymentDay,
  'paymentAssetRowId': instance.paymentAssetRowId,
  'cardCatalog': instance.cardCatalog,
  'tossSymbol': instance.tossSymbol,
  'tossQuantity': instance.tossQuantity,
  'holdings': instance.holdings,
};

_AssetCardCatalog _$AssetCardCatalogFromJson(Map<String, dynamic> json) =>
    _AssetCardCatalog(
      rowId: (json['rowId'] as num).toInt(),
      cardName: json['cardName'] as String,
      imgUrl: json['imgUrl'] as String?,
      companyName: json['companyName'] as String?,
      companyLogoUrl: json['companyLogoUrl'] as String?,
    );

Map<String, dynamic> _$AssetCardCatalogToJson(_AssetCardCatalog instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'cardName': instance.cardName,
      'imgUrl': instance.imgUrl,
      'companyName': instance.companyName,
      'companyLogoUrl': instance.companyLogoUrl,
    };

_AssetHolding _$AssetHoldingFromJson(Map<String, dynamic> json) =>
    _AssetHolding(
      rowId: (json['rowId'] as num?)?.toInt(),
      holdingType:
          $enumDecodeNullable(
            _$AssetHoldingTypeEnumMap,
            json['holdingType'],
            unknownValue: AssetHoldingType.stock,
          ) ??
          AssetHoldingType.stock,
      linked: json['linked'] as bool? ?? false,
      tossSymbol: json['tossSymbol'] as String?,
      quantity: holdingQuantityFromJson(json['quantity']),
      holdingName: json['holdingName'] as String?,
      holdingValue: (json['holdingValue'] as num?)?.toInt(),
      totalCost: (json['totalCost'] as num?)?.toInt(),
      avgPrice: json['avgPrice'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AssetHoldingToJson(_AssetHolding instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'holdingType': _$AssetHoldingTypeEnumMap[instance.holdingType]!,
      'linked': instance.linked,
      'tossSymbol': instance.tossSymbol,
      'quantity': instance.quantity,
      'holdingName': instance.holdingName,
      'holdingValue': instance.holdingValue,
      'totalCost': instance.totalCost,
      'avgPrice': instance.avgPrice,
      'sortOrder': instance.sortOrder,
    };

const _$AssetHoldingTypeEnumMap = {
  AssetHoldingType.stock: 'STOCK',
  AssetHoldingType.gold: 'GOLD',
  AssetHoldingType.crypto: 'CRYPTO',
};
