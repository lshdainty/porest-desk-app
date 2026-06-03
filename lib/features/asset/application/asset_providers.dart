import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/asset_repository.dart';
import '../domain/asset.dart';
import '../domain/asset_summary.dart';
import '../domain/asset_transfer.dart';
import '../domain/card_billing.dart';
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

/// 단건 자산 (상세 화면 진입용).
final assetByIdProvider =
    FutureProvider.family<Asset, int>((ref, id) async {
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.getById(id);
});

/// 자산 잔액 추이 (주별, 기본 12주).
typedef AssetBalanceTrendKey = ({int assetId, int weeks});

final assetBalanceTrendProvider = FutureProvider.family<
    List<AssetBalancePoint>, AssetBalanceTrendKey>((ref, key) async {
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.balanceTrend(key.assetId, weeks: key.weeks);
});

/// 자산 이체 내역 (옵션 startDate/endDate).
typedef AssetTransfersKey = ({String? startDate, String? endDate});

final assetTransfersProvider = FutureProvider.family<List<AssetTransfer>,
    AssetTransfersKey>((ref, key) async {
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.listTransfers(startDate: key.startDate, endDate: key.endDate);
});

/// 신용카드 청구 사이클 (결제예정액·예정일·청구이력).
/// 카드 상세 진입 시 조회. `payCard` 후 invalidate.
final cardBillingProvider =
    FutureProvider.family<CardBilling, int>((ref, assetId) async {
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.getCardBilling(assetId);
});

extension AssetListX on List<Asset> {
  Asset? byRowId(int rowId) {
    for (final a in this) {
      if (a.rowId == rowId) return a;
    }
    return null;
  }
}
