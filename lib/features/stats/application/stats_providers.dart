import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/core/sync/stats_freshness.dart';
import 'package:porest_desk_app/features/stats/data/stats_repository.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';

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
  ref.markStatsFetched(StatsQuery.rangeSummary);
  return summary;
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
      ref.markStatsFetched(StatsQuery.merchantSummary);
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
  ref.markStatsFetched(StatsQuery.heatmap);
  return cells;
});
