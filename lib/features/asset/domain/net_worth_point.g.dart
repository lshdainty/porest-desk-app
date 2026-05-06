// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'net_worth_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetWorthPoint _$NetWorthPointFromJson(Map<String, dynamic> json) =>
    _NetWorthPoint(
      month: json['month'] as String,
      totalAssets: (json['totalAssets'] as num?)?.toInt() ?? 0,
      totalDebt: (json['totalDebt'] as num?)?.toInt() ?? 0,
      netWorth: (json['netWorth'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NetWorthPointToJson(_NetWorthPoint instance) =>
    <String, dynamic>{
      'month': instance.month,
      'totalAssets': instance.totalAssets,
      'totalDebt': instance.totalDebt,
      'netWorth': instance.netWorth,
    };
