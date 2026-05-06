import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/stats_repository.dart';
import '../domain/stats_models.dart';

final statsRepositoryProvider = FutureProvider<StatsRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return StatsRepository(dio);
});

typedef YM = ({int year, int month});

final monthlySummaryProvider =
    FutureProvider.family<MonthlySummary, YM>((ref, key) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.monthly(year: key.year, month: key.month);
});

final monthlyTrendProvider =
    FutureProvider.family<List<MonthlyTrend>, int>((ref, months) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.trend(months: months);
});

typedef DateRange = ({String? startDate, String? endDate});

final merchantSummaryProvider =
    FutureProvider.family<List<MerchantSummary>, DateRange>((ref, range) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.byMerchant(
      startDate: range.startDate, endDate: range.endDate);
});

final assetExpenseSummaryProvider =
    FutureProvider.family<List<AssetExpenseSummary>, DateRange>(
        (ref, range) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.byAsset(startDate: range.startDate, endDate: range.endDate);
});

final heatmapProvider =
    FutureProvider.family<List<HeatmapCell>, YM>((ref, key) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.heatmap(year: key.year, month: key.month);
});
