import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/stats/data/stats_repository.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';
import 'package:porest_desk_app/features/stats/domain/stats_summaries.dart';

final statsRepositoryProvider = FutureProvider<StatsRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return StatsRepository(dio);
});

typedef DateRange = ({String startDate, String endDate});

/// 임의 기간 요약 — 도넛/하이라이트/추이.
final rangeSummaryProvider = FutureProvider.family<RangeSummary, DateRange>((
  ref,
  range,
) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.range(startDate: range.startDate, endDate: range.endDate);
});

final monthlyTrendProvider = FutureProvider.family<List<MonthlyTrend>, int>((
  ref,
  months,
) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.trend(months: months);
});

typedef OptionalDateRange = ({String? startDate, String? endDate});

final merchantSummaryProvider =
    FutureProvider.family<List<MerchantSummary>, OptionalDateRange>((
      ref,
      range,
    ) async {
      final repo = await ref.watch(statsRepositoryProvider.future);
      return repo.byMerchant(
        startDate: range.startDate,
        endDate: range.endDate,
      );
    });

final assetExpenseSummaryProvider =
    FutureProvider.family<List<AssetExpenseSummary>, OptionalDateRange>((
      ref,
      range,
    ) async {
      final repo = await ref.watch(statsRepositoryProvider.future);
      return repo.byAsset(startDate: range.startDate, endDate: range.endDate);
    });

final heatmapProvider = FutureProvider.family<List<HeatmapCell>, DateRange>((
  ref,
  range,
) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.heatmap(startDate: range.startDate, endDate: range.endDate);
});

/// 일별 요약.
final dailySummaryProvider = FutureProvider.family<DailySummary, String>((
  ref,
  date,
) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.daily(date);
});
