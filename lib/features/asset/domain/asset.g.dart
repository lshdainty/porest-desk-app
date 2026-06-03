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
};
