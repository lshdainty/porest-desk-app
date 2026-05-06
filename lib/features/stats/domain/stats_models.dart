import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats_models.freezed.dart';
part 'stats_models.g.dart';

/// `/expenses/summary/trend?months=N` 의 한 점.
@freezed
abstract class MonthlyTrend with _$MonthlyTrend {
  const factory MonthlyTrend({
    required int year,
    required int month,
    @Default(0) int totalIncome,
    @Default(0) int totalExpense,
  }) = _MonthlyTrend;

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) =>
      _$MonthlyTrendFromJson(json);
}

/// `/expenses/summary/monthly` 의 카테고리 분포 항목.
@freezed
abstract class CategoryBreakdown with _$CategoryBreakdown {
  const factory CategoryBreakdown({
    int? categoryRowId,
    String? categoryName,
    int? parentCategoryRowId,
    String? parentCategoryName,
    String? expenseType,
    @Default(0) int totalAmount,
  }) = _CategoryBreakdown;

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      _$CategoryBreakdownFromJson(json);
}

@freezed
abstract class MonthlySummary with _$MonthlySummary {
  const factory MonthlySummary({
    required int year,
    required int month,
    @Default(0) int totalIncome,
    @Default(0) int totalExpense,
    @Default(<CategoryBreakdown>[]) List<CategoryBreakdown> categoryBreakdown,
  }) = _MonthlySummary;

  factory MonthlySummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryFromJson(json);
}

@freezed
abstract class MerchantSummary with _$MerchantSummary {
  const factory MerchantSummary({
    String? merchant,
    @Default(0) int totalAmount,
    @Default(0) int count,
  }) = _MerchantSummary;

  factory MerchantSummary.fromJson(Map<String, dynamic> json) =>
      _$MerchantSummaryFromJson(json);
}

@freezed
abstract class AssetExpenseSummary with _$AssetExpenseSummary {
  const factory AssetExpenseSummary({
    int? assetRowId,
    String? assetName,
    @Default(0) int totalAmount,
    @Default(0) int count,
  }) = _AssetExpenseSummary;

  factory AssetExpenseSummary.fromJson(Map<String, dynamic> json) =>
      _$AssetExpenseSummaryFromJson(json);
}

@freezed
abstract class HeatmapCell with _$HeatmapCell {
  const factory HeatmapCell({
    required int dayOfWeek, // 1=월 ~ 7=일 (백엔드 표기 따름)
    required int hour, // 0~23
    @Default(0) int totalAmount,
  }) = _HeatmapCell;

  factory HeatmapCell.fromJson(Map<String, dynamic> json) =>
      _$HeatmapCellFromJson(json);
}
