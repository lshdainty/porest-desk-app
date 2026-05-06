// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssetSummary _$AssetSummaryFromJson(Map<String, dynamic> json) =>
    _AssetSummary(
      totalBalance: (json['totalBalance'] as num?)?.toInt() ?? 0,
      totalAssets: (json['totalAssets'] as num?)?.toInt() ?? 0,
      totalDebt: (json['totalDebt'] as num?)?.toInt() ?? 0,
      netWorth: (json['netWorth'] as num?)?.toInt() ?? 0,
      lastMonthNetWorth: (json['lastMonthNetWorth'] as num?)?.toInt() ?? 0,
      changeAmount: (json['changeAmount'] as num?)?.toInt() ?? 0,
      changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$AssetSummaryToJson(_AssetSummary instance) =>
    <String, dynamic>{
      'totalBalance': instance.totalBalance,
      'totalAssets': instance.totalAssets,
      'totalDebt': instance.totalDebt,
      'netWorth': instance.netWorth,
      'lastMonthNetWorth': instance.lastMonthNetWorth,
      'changeAmount': instance.changeAmount,
      'changePercent': instance.changePercent,
    };
