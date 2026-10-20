import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/core/sync/query_freshness.dart';
import 'package:groo_damda_app/features/stats/data/stats_repository.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';

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
  final summary = await repo.range(
    startDate: range.startDate,
    endDate: range.endDate,
  );
  ref.markQueryFetched(ServerQuery.rangeSummary);
  return summary;
});

/// 최근 N개월 수입·지출(과 그중 고정 몫) — 고정·변동 탭이 한 달만 고른 기간에 쓴다.
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
      final merchants = await repo.byMerchant(
        startDate: range.startDate,
        endDate: range.endDate,
      );
      ref.markQueryFetched(ServerQuery.merchantSummary);
      return merchants;
    });

final heatmapProvider = FutureProvider.family<List<HeatmapCell>, DateRange>((
  ref,
  range,
) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  final cells = await repo.heatmap(
    startDate: range.startDate,
    endDate: range.endDate,
  );
  ref.markQueryFetched(ServerQuery.heatmap);
  return cells;
});
