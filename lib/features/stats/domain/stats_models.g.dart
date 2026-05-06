// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MonthlyTrend _$MonthlyTrendFromJson(Map<String, dynamic> json) =>
    _MonthlyTrend(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      totalIncome: (json['totalIncome'] as num?)?.toInt() ?? 0,
      totalExpense: (json['totalExpense'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MonthlyTrendToJson(_MonthlyTrend instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'totalIncome': instance.totalIncome,
      'totalExpense': instance.totalExpense,
    };

_CategoryBreakdown _$CategoryBreakdownFromJson(Map<String, dynamic> json) =>
    _CategoryBreakdown(
      categoryRowId: (json['categoryRowId'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String?,
      parentCategoryRowId: (json['parentCategoryRowId'] as num?)?.toInt(),
      parentCategoryName: json['parentCategoryName'] as String?,
      expenseType: json['expenseType'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CategoryBreakdownToJson(_CategoryBreakdown instance) =>
    <String, dynamic>{
      'categoryRowId': instance.categoryRowId,
      'categoryName': instance.categoryName,
      'parentCategoryRowId': instance.parentCategoryRowId,
      'parentCategoryName': instance.parentCategoryName,
      'expenseType': instance.expenseType,
      'totalAmount': instance.totalAmount,
    };

_MonthlySummary _$MonthlySummaryFromJson(Map<String, dynamic> json) =>
    _MonthlySummary(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      totalIncome: (json['totalIncome'] as num?)?.toInt() ?? 0,
      totalExpense: (json['totalExpense'] as num?)?.toInt() ?? 0,
      categoryBreakdown:
          (json['categoryBreakdown'] as List<dynamic>?)
              ?.map(
                (e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <CategoryBreakdown>[],
    );

Map<String, dynamic> _$MonthlySummaryToJson(_MonthlySummary instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'totalIncome': instance.totalIncome,
      'totalExpense': instance.totalExpense,
      'categoryBreakdown': instance.categoryBreakdown,
    };

_MerchantSummary _$MerchantSummaryFromJson(Map<String, dynamic> json) =>
    _MerchantSummary(
      merchant: json['merchant'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MerchantSummaryToJson(_MerchantSummary instance) =>
    <String, dynamic>{
      'merchant': instance.merchant,
      'totalAmount': instance.totalAmount,
      'count': instance.count,
    };

_AssetExpenseSummary _$AssetExpenseSummaryFromJson(Map<String, dynamic> json) =>
    _AssetExpenseSummary(
      assetRowId: (json['assetRowId'] as num?)?.toInt(),
      assetName: json['assetName'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AssetExpenseSummaryToJson(
  _AssetExpenseSummary instance,
) => <String, dynamic>{
  'assetRowId': instance.assetRowId,
  'assetName': instance.assetName,
  'totalAmount': instance.totalAmount,
  'count': instance.count,
};

_HeatmapCell _$HeatmapCellFromJson(Map<String, dynamic> json) => _HeatmapCell(
  dayOfWeek: (json['dayOfWeek'] as num).toInt(),
  hour: (json['hour'] as num).toInt(),
  totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$HeatmapCellToJson(_HeatmapCell instance) =>
    <String, dynamic>{
      'dayOfWeek': instance.dayOfWeek,
      'hour': instance.hour,
      'totalAmount': instance.totalAmount,
    };
