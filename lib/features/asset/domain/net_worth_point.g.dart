// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'net_worth_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetWorthPoint _$NetWorthPointFromJson(Map<String, dynamic> json) =>
    _NetWorthPoint(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      netWorth: (json['netWorth'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NetWorthPointToJson(_NetWorthPoint instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'netWorth': instance.netWorth,
    };
