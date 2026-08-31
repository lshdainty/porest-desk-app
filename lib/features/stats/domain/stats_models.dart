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

/// `/expenses/summary/range?startDate&endDate` 의 응답.
/// 도넛/하이라이트 + 추이 차트용 monthlyBuckets 포함.
@freezed
abstract class RangeSummary with _$RangeSummary {
  const factory RangeSummary({
    required String startDate,
    required String endDate,
    @Default(0) int totalIncome,
    @Default(0) int totalExpense,
    @Default(<CategoryBreakdown>[]) List<CategoryBreakdown> categoryBreakdown,
    @Default(<RangeMonthlyBucket>[]) List<RangeMonthlyBucket> monthlyBuckets,
  }) = _RangeSummary;

  factory RangeSummary.fromJson(Map<String, dynamic> json) =>
      _$RangeSummaryFromJson(json);
}

/// 추이 차트용 월별 버킷 — 0인 달도 포함.
/// 카테고리 단위 금액 — 월별 지출 분해(카테고리 추이 차트)용.
@freezed
abstract class CategoryAmount with _$CategoryAmount {
  const factory CategoryAmount({int? categoryRowId, @Default(0) int amount}) =
      _CategoryAmount;

  factory CategoryAmount.fromJson(Map<String, dynamic> json) =>
      _$CategoryAmountFromJson(json);
}

@freezed
abstract class RangeMonthlyBucket with _$RangeMonthlyBucket {
  const factory RangeMonthlyBucket({
    required int year,
    required int month,
    @Default(0) int totalIncome,
    @Default(0) int totalExpense,
    // 그 달의 카테고리별 지출(EXPENSE만, split-aware) — 카테고리 월별 추이용. 구버전 응답이면 빈 리스트.
    @Default(<CategoryAmount>[]) List<CategoryAmount> categoryExpenses,
  }) = _RangeMonthlyBucket;

  factory RangeMonthlyBucket.fromJson(Map<String, dynamic> json) =>
      _$RangeMonthlyBucketFromJson(json);
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
