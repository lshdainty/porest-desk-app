import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_summary.freezed.dart';
part 'asset_summary.g.dart';

/// 백엔드 `AssetApiDto.AssetSummaryResponse` 매핑.
@freezed
abstract class AssetSummary with _$AssetSummary {
  const factory AssetSummary({
    @Default(0) int totalBalance,
    @Default(0) int totalAssets,
    @Default(0) int totalDebt,
    @Default(0) int netWorth,
    @Default(0) int lastMonthNetWorth,
    @Default(0) int changeAmount,
    @Default(0.0) double changePercent,
  }) = _AssetSummary;

  factory AssetSummary.fromJson(Map<String, dynamic> json) =>
      _$AssetSummaryFromJson(json);
}
