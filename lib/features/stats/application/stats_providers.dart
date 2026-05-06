import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/stats_repository.dart';
import '../domain/stats_models.dart';
import '../domain/stats_summaries.dart';

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

/// 일별 요약 (#251).
final dailySummaryProvider =
    FutureProvider.family<DailySummary, String>((ref, date) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.daily(date);
});

/// 주별 요약 (#251).
typedef WeekRange = ({String weekStart, String weekEnd});
final weeklySummaryProvider =
    FutureProvider.family<WeeklySummary, WeekRange>((ref, key) async {
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.weekly(weekStart: key.weekStart, weekEnd: key.weekEnd);
});

/// 연간 요약 (#251 #284).
final yearlySummaryProvider =
    FutureProvider.family<YearlySummary, int>((ref, year) async {
  ref.keepAlive();
  final repo = await ref.watch(statsRepositoryProvider.future);
  return repo.yearly(year);
});
