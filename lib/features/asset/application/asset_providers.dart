import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/asset_repository.dart';
import '../domain/asset.dart';
import '../domain/asset_summary.dart';
import '../domain/net_worth_point.dart';

final assetRepositoryProvider = FutureProvider<AssetRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return AssetRepository(dio);
});

final assetsProvider = FutureProvider<List<Asset>>((ref) async {
  ref.keepAlive();
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.list();
});

typedef AssetSummaryKey = ({int? year, int? month});

final assetSummaryProvider =
    FutureProvider.family<AssetSummary, AssetSummaryKey>((ref, key) async {
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.summary(year: key.year, month: key.month);
});

/// 최근 N개월 순자산 추이 (기본 12개월).
final netWorthTrendProvider =
    FutureProvider.family<List<NetWorthPoint>, int>((ref, months) async {
  ref.keepAlive();
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.netWorthTrend(months: months);
});

extension AssetListX on List<Asset> {
  Asset? byRowId(int rowId) {
    for (final a in this) {
      if (a.rowId == rowId) return a;
    }
    return null;
  }
}
