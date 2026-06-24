import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/asset/data/asset_repository.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';
import 'package:porest_desk_app/features/asset/domain/card_billing.dart';
import 'package:porest_desk_app/features/asset/domain/net_worth_point.dart';
import 'package:porest_desk_app/features/stocks/application/stocks_providers.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';

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

/// 토스에 연결된 투자 자산의 라이브 평가액(KRW) 맵 (assetRowId → 평가액).
///
/// - 평가액 = 토스 현재가(toss_symbol) × 보유수량(toss_quantity). 토스 계좌 보유분과 무관하게
///   시세만 빌려 계산하므로, 타 증권사 보유 주식도 토스 시세로 실시간 평가된다.
/// - 프로(SECURITIES) + 토스 연결 사용자가 아니거나 연결 자산이 없으면 빈 맵 → 오버레이 무효과.
/// - 화면에서 invalidate 하면 시세를 재조회해 실시간 갱신된다.
final tossValuationMapProvider = FutureProvider<Map<int, int>>((ref) async {
  final features = ref.watch(myFeaturesProvider).asData?.value;
  final enabled = (features?.hasSecurities ?? false) && (features?.tossConnected ?? false);
  if (!enabled) return const {};
  final assets = await ref.watch(assetsProvider.future);
  final linked = assets
      .where((a) => (a.tossSymbol?.isNotEmpty ?? false) && a.tossQuantity != null)
      .toList();
  if (linked.isEmpty) return const {};
  final symbols = {for (final a in linked) a.tossSymbol!}.toList();
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    final prices = await repo.getPrices(symbols);
    final priceBySymbol = {for (final p in prices) p.symbol: p.priceValue};
    final map = <int, int>{};
    for (final a in linked) {
      final price = priceBySymbol[a.tossSymbol];
      if (price == null) continue;
      map[a.rowId] = (price * a.tossQuantity!).round();
    }
    return map;
  } catch (_) {
    // 토스 미설정/조회 실패 — 오버레이 없이 기존 잔액 유지.
    return const {};
  }
});

extension AssetListX on List<Asset> {
  Asset? byRowId(int rowId) {
    for (final a in this) {
      if (a.rowId == rowId) return a;
    }
    return null;
  }
}
