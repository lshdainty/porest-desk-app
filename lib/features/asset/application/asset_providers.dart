import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/asset/data/asset_repository.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_trade.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';
import 'package:porest_desk_app/features/asset/domain/card_billing.dart';
import 'package:porest_desk_app/features/asset/domain/net_worth_point.dart';
import 'package:porest_desk_app/features/stocks/application/live_prices.dart';
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
final netWorthTrendProvider = FutureProvider.family<List<NetWorthPoint>, int>((
  ref,
  months,
) async {
  ref.keepAlive();
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.netWorthTrend(months: months);
});

/// 단건 자산 (상세 화면 진입용).
final assetByIdProvider = FutureProvider.family<Asset, int>((ref, id) async {
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.getById(id);
});

/// 자산 잔액 추이 (주별, 기본 12주).
typedef AssetBalanceTrendKey = ({int assetId, int weeks});

final assetBalanceTrendProvider =
    FutureProvider.family<List<AssetBalancePoint>, AssetBalanceTrendKey>((
      ref,
      key,
    ) async {
      final repo = await ref.watch(assetRepositoryProvider.future);
      return repo.balanceTrend(key.assetId, weeks: key.weeks);
    });

/// 자산 이체 내역 (옵션 startDate/endDate).
typedef AssetTransfersKey = ({String? startDate, String? endDate});

final assetTransfersProvider =
    FutureProvider.family<List<AssetTransfer>, AssetTransfersKey>((
      ref,
      key,
    ) async {
      final repo = await ref.watch(assetRepositoryProvider.future);
      return repo.listTransfers(startDate: key.startDate, endDate: key.endDate);
    });

/// 신용카드 청구 사이클 (결제예정액·예정일·청구이력).
/// 카드 상세 진입 시 조회. `payCard` 후 invalidate.
final cardBillingProvider = FutureProvider.family<CardBilling, int>((
  ref,
  assetId,
) async {
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.getCardBilling(assetId);
});

/// 통화가 KRW 가 아니면(해외 종목) 환율 환산 대상.
/// 투자 자산 라이브 평가 1건 — 평가액(KRW) + 전일 대비 등락액(계산 가능할 때만).
typedef InvestmentValuation = ({int value, int? changeAmt});

/// 투자 자산 라이브 평가 맵 (assetRowId → 평가액·등락액).
///
/// - holdings 가 있는 자산(신규 모델): 평가액 = Σ 직접입력(holdingValue)
///   + Σ 연동(현재가 × 수량, 해외 종목은 환율로 KRW 환산).
///   시세·환율은 **증권사 무관 경로**(/securities/**)로 받는다 — 서버가 사용자가 고른 기본
///   소스로 대신 조회하므로 앱이 증권사를 알 필요가 없다. 예전에는 토스 경로를 직접 불러
///   나무만 연결한 사용자의 평가액이 0/누락으로 보였다.
///   연동 보유의 가격을 하나라도 못 구하면 그 자산은 맵에서 제외(서버 스냅샷 잔액 유지).
///   등락액 = Σ 연동 (현재가 − 전일종가) × 수량 — 전일종가가 조회된 종목만 합산,
///   하나도 없으면 null(등락 미표시).
/// - holdings 가 없는 자산: 기존 tossSymbol/tossQuantity 단일 연동 경로(deprecated) 유지.
/// - 직접입력만 있는 자산은 시세가 불필요하므로 게이트(프로+증권사연결)와 무관하게 평가.
/// - 화면에서 invalidate 하면 시세를 재조회해 실시간 갱신된다.
final investmentValuationMapProvider =
    FutureProvider<Map<int, InvestmentValuation>>((ref) async {
      final features = ref.watch(myFeaturesProvider).asData?.value;
      final enabled =
          (features?.hasSecurities ?? false) &&
          (features?.hasBrokerConnection ?? false);
      final assets = await ref.watch(assetsProvider.future);

      final targets = assets.where((a) => a.assetType == 'INVESTMENT').toList();
      if (targets.isEmpty) return const {};

      // 시세가 필요한 심볼 수집 — holdings 의 linked + 레거시 단일 연동.
      final symbols = <String>{};
      for (final a in targets) {
        if (a.holdings.isNotEmpty) {
          for (final h in a.holdings) {
            if (h.linked && (h.tossSymbol?.isNotEmpty ?? false)) {
              symbols.add(h.tossSymbol!);
            }
          }
        } else if ((a.tossSymbol?.isNotEmpty ?? false) &&
            a.tossQuantity != null) {
          symbols.add(a.tossSymbol!);
        }
      }

      // 시세·통화별 환율·전일종가 조달은 livePricesProvider 한 곳에 있다 —
      // 자산 상세·추가/편집도 같은 걸 써야 한 화면에서 금액이 어긋나지 않는다.
      LivePrices live = const LivePrices.empty();
      if (enabled && symbols.isNotEmpty) {
        try {
          live = await ref.watch(
            livePricesProvider(livePricesKey(symbols)).future,
          );
        } catch (_) {
          live = const LivePrices.empty();
        }
      }

      double? unitKrw(String symbol) => live.unitKrw(symbol);
      double? unitPrevKrw(String symbol) => live.prevUnitKrw(symbol);

      final map = <int, InvestmentValuation>{};
      for (final a in targets) {
        if (a.holdings.isNotEmpty) {
          var total = 0.0;
          var change = 0.0;
          var hasChange = false;
          var priceable = true;
          for (final h in a.holdings) {
            if (h.linked) {
              final sym = h.tossSymbol ?? '';
              final unit = sym.isEmpty ? null : unitKrw(sym);
              if (unit == null) {
                priceable = false;
                break; // 연동가 미확보 — 서버 스냅샷 잔액 유지.
              }
              // 라이브 표시용 오버레이 계산 — 저장되는 평가액은 서버가 BigDecimal 로 산정한다.
              final qty = h.quantityValue;
              total += unit * qty;
              final prevUnit = unitPrevKrw(sym);
              if (prevUnit != null) {
                change += (unit - prevUnit) * qty;
                hasChange = true;
              }
            } else {
              total += (h.holdingValue ?? 0).toDouble();
            }
          }
          if (!priceable) continue;
          map[a.rowId] = (
            value: total.round(),
            changeAmt: hasChange ? change.round() : null,
          );
        } else if ((a.tossSymbol?.isNotEmpty ?? false) &&
            a.tossQuantity != null) {
          final unit = unitKrw(a.tossSymbol!);
          if (unit == null) continue;
          final qty = a.tossQuantity!;
          final prevUnit = unitPrevKrw(a.tossSymbol!);
          map[a.rowId] = (
            value: (unit * qty).round(),
            changeAmt: prevUnit != null
                ? ((unit - prevUnit) * qty).round()
                : null,
          );
        }
      }
      return map;
    });

/// (호환) 토스 연동 투자 자산의 라이브 평가액(KRW) 맵 — investmentValuationMapProvider 의 value 투영.
final tossValuationMapProvider = FutureProvider<Map<int, int>>((ref) async {
  final m = await ref.watch(investmentValuationMapProvider.future);
  return {for (final e in m.entries) e.key: e.value.value};
});

extension AssetListX on List<Asset> {
  Asset? byRowId(int rowId) {
    for (final a in this) {
      if (a.rowId == rowId) return a;
    }
    return null;
  }
}

/// 자산의 매수·매도 내역 — 언제 사고 팔았는지, 실현손익이 얼마인지.
final assetTradesProvider = FutureProvider.family<List<AssetTrade>, int>((
  ref,
  assetRowId,
) async {
  final repo = await ref.watch(assetRepositoryProvider.future);
  return repo.getTrades(assetRowId);
});
