import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_axis.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_aggregates.dart';
import 'package:porest_desk_app/features/expense/presentation/tx_detail_dialog.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/stocks/application/stocks_providers.dart';
import 'package:porest_desk_app/features/stocks/data/toss_dto.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';
import 'package:porest_desk_app/features/asset/domain/card_billing.dart';
import 'package:porest_desk_app/shared/widgets/p_chart_tooltip.dart';
import 'package:porest_desk_app/features/asset/domain/asset_type_meta.dart';
import 'package:porest_desk_app/features/asset/presentation/holding_format.dart';
import 'package:porest_desk_app/features/asset/presentation/widgets/asset_logo.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_trade_sheet.dart';
import 'package:porest_desk_app/features/expense/presentation/transfer_detail_sheet.dart';
import 'package:porest_desk_app/features/expense/presentation/widgets/transfer_row.dart';

/// 자산 상세 — front `AssetDetailDialog` 모바일 미러.
///
/// 공통 `showPSheet` 사용. 구성 (web 동일):
/// - Hero 카드 (브랜드 그라디언트 + 아이콘 + 이름 + 잔액)
/// - 12/24/52주 잔액 추이 + 3개월/6개월/1년 segmented
/// - 최근 거래 12건 + "전체 보기 →"
/// - 푸터: 편집 1개 (본문 끝에 함께 스크롤)
void showAssetDetailRich(
  BuildContext context,
  Asset asset, {
  VoidCallback? onEdit,
}) {
  showPSheet<void>(
    context,
    title: _titleFor(AppLocalizations.of(context), asset),
    contentBuilder: (ctx, scrollCtrl) =>
        _DetailBody(asset: asset, scrollController: scrollCtrl, onEdit: onEdit),
    footerBuilder: (ctx) => _DetailFooter(asset: asset, onEdit: onEdit),
  );
}

/// 상세 footer — [편집] 1개. 금액 가리기는 카드 우상단 눈 버튼과 계정 > 보안에도
/// 있어 여기서 뺐다(spec drawer.md 액션 구성).
class _DetailFooter extends StatelessWidget {
  const _DetailFooter({required this.asset, this.onEdit});
  final Asset asset;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return PViewFooter(
      onEdit: () {
        Navigator.of(context).pop();
        if (onEdit != null) {
          onEdit!();
        } else {
          context.push('/account-card-manage');
        }
      },
    );
  }
}

String _titleFor(AppLocalizations l, Asset a) {
  if (a.assetType == 'CREDIT_CARD' || a.assetType == 'CHECK_CARD') {
    return l.assetCardDetail;
  }
  if (a.assetType == 'INVESTMENT') return l.assetInvestDetail;
  return l.assetAccountDetail;
}

enum _Period { p3m, p6m, p1y }

extension on _Period {
  int get weeks => switch (this) {
    _Period.p3m => 12,
    _Period.p6m => 24,
    _Period.p1y => 52,
  };
  String label(AppLocalizations l) => switch (this) {
    _Period.p3m => l.assetPeriod3m,
    _Period.p6m => l.assetPeriod6m,
    _Period.p1y => l.assetPeriod1y,
  };
  String headerLabel(AppLocalizations l) => l.assetWeeksCount(weeks);
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.asset,
    required this.scrollController,
    this.onEdit,
  });
  final Asset asset;
  final ScrollController scrollController;
  final VoidCallback? onEdit;
  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  _Period _period = _Period.p3m;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 여는 쪽은 탭 시점의 asset 을 넘긴다 — 시트가 열린 채 매수·취소가 일어나면
    // 목록 provider 는 새 값인데 스냅샷은 옛 수량·평가액이 남는다. 산 목록에서
    // 같은 자산을 다시 찾아 쓴다(웹 AssetDetailDialog 와 같은 처리).
    var asset = widget.asset;
    final liveAssets = ref.watch(assetsProvider).value;
    if (liveAssets != null) {
      final i = liveAssets.indexWhere((a) => a.rowId == widget.asset.rowId);
      if (i >= 0) asset = liveAssets[i];
    }
    final masked = ref.watch(hideCardProvider('asset.detail'));
    final meta = AssetTypeMeta.of(asset.assetType);
    final brandFg = resolveChartColor(context, asset.color, fallback: t.fgBrand);

    final isCard =
        asset.assetType == 'CREDIT_CARD' || asset.assetType == 'CHECK_CARD';
    final isInv = asset.assetType == 'INVESTMENT';
    // 연결계좌형 체크카드 — 결제가 계좌에서 즉시 빠져 잔액이 늘 0 이다. 히어로는 잔액
    // 대신 "이번 달 사용액", 내역은 당월 1일~말일 전체(사용자 결정). 미연결 체크카드는
    // 잔액이 실제로 쌓이므로 일반 계좌처럼 그대로다. (web 정합)
    final isCheckLinked =
        asset.assetType == 'CHECK_CARD' && asset.paymentAssetRowId != null;
    final valueLabel = isCheckLinked
        ? l.assetValueLabelCheckCard
        : isCard
        ? l.assetValueLabelCard
        : isInv
        ? l.assetValuationShort
        : l.expSummaryBalance;
    final seriesLabel = isCard
        ? l.assetSeriesUsage
        : isInv
        ? l.assetValuationShort
        : l.expSummaryBalance;
    final trendTitle = l.assetTrendRecent(
      _period.headerLabel(l),
      isCard
          ? l.assetTrendKindUsage
          : isInv
              ? l.assetTrendKindValuation
              : l.assetTrendKindBalance,
    );

    final trendAsync = ref.watch(
      assetBalanceTrendProvider((assetId: asset.rowId, weeks: _period.weeks)),
    );
    // recent tx — web 와 동일 12건. 연결계좌형 체크카드는 "이번 달 뭐 썼나" 가 목적이라
    // 당월(1일~말일) 전체를 다 가져온다 — 12건 컷을 두면 월말엔 월초 내역이 잘린다.
    final now = DateTime.now();
    String ymd(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final recentAsync = isCheckLinked
        ? ref
            .watch(assetPeriodExpensesProvider((
              assetId: asset.rowId,
              startDate: ymd(DateTime(now.year, now.month, 1)),
              endDate: ymd(DateTime(now.year, now.month + 1, 0)),
            )))
            // 기간 provider 는 예정분을 안 거른다 — "이번 달 내역" 규칙(지나간 것만)을 여기서 맞춘다.
            .whenData((list) =>
                list.where((e) => !isScheduledTx(e.expenseDate)).toList())
        : ref.watch(
            expensesByAssetProvider((assetId: asset.rowId, limit: 12)),
          );
    // 이체는 expense 가 아니라 asset_transfer — 따로 받아 이 자산에 걸린 것만 추린다.
    // 한 건이 자산 두 개에 걸치므로 보내는 쪽·받는 쪽 둘 다 확인한다(서버 필터는 기간만 지원).
    final monthPrefix =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final assetTransfers = (ref
                .watch(assetTransfersProvider((startDate: null, endDate: null)))
                .value ??
            const <AssetTransfer>[])
        .where((tr) =>
            (tr.fromAssetRowId == asset.rowId ||
                tr.toAssetRowId == asset.rowId) &&
            // 지출과 같은 규칙 — "최근 거래" 에는 지나간 것만 올린다.
            !isScheduledTx(tr.transferDate) &&
            // 체크카드 "이번 달 내역" 은 이체도 당월만 — 지출과 기간을 맞춘다.
            (!isCheckLinked ||
                (tr.transferDate ?? '').startsWith(monthPrefix)))
        .toList();
    // CREDIT_CARD 는 신판 카드 상세 본문(_CardDetailBody) — 회차 히어로가 금액 담당.
    final isCredit = asset.assetType == 'CREDIT_CARD';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        _HeroCard(
          asset: asset,
          meta: meta,
          valueLabel: valueLabel,
          isCard: isCard,
          masked: masked,
          nameRowOnly: isCredit,
        ),
        if (isCredit) ...[
          _CardDetailBody(
            asset: asset,
            masked: masked,
            onEdit: widget.onEdit,
          ),
        ] else ...[
        const SizedBox(height: PSpace.x16),
        // 체크카드 — 실적 배지만(청구 회차 없음, design 신판)
        if (isCard) ...[
          _CardPerfBadge(assetRowId: asset.rowId, masked: masked),
          const SizedBox(height: PSpace.x16),
        ],
        if (isInv) ...[
          _InvChangeLine(assetRowId: asset.rowId, masked: masked),
          _HoldingsSection(asset: asset, onEdit: widget.onEdit),
          const SizedBox(height: PSpace.x16),
        ],

        // Trend header — 연결계좌형 체크카드는 잔액이 늘 0 이라 평평한 0 선뿐이다.
        // 차트만 빼고 내역은 그대로 둔다. (web 정합)
        if (!isCheckLinked) ...[
        Row(
          children: [
            Expanded(
              child: Text(
                trendTitle,
                style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PTabs<_Period>(
              value: _period,
              size: PTabsSize.sm,
              items: [
                for (final p in _Period.values)
                  PTabItem(value: p, label: p.label(l)),
              ],
              onChanged: (p) => setState(() => _period = p),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x12),
        SizedBox(
          height: 160,
          child: _BalanceTrendChart(
            async: trendAsync,
            tokens: t,
            brandFg: brandFg,
            seriesLabel: seriesLabel,
            masked: masked,
          ),
        ),
        const SizedBox(height: PSpace.x20),
        ],

        // Recent tx
        Row(
          children: [
            Expanded(
              child: Text(
                (recentAsync.value?.isNotEmpty ?? false)
                    ? (isCheckLinked
                        ? l.assetMonthTxCount(recentAsync.value!.length)
                        : l.assetRecentTxCount(recentAsync.value!.length))
                    : l.dashRecent,
                style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
            ),
            InkWell(
              borderRadius: PRadius.brSm,
              onTap: () {
                Navigator.of(context).pop();
                context.go('/expense?assetId=${asset.rowId}');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.assetViewAll,
                      style: PTypo.bodySm.copyWith(
                        color: t.fgSecondary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 12,
                      color: t.fgSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x8),
        _RecentExpenses(
            async: recentAsync,
            transfers: assetTransfers,
            perspectiveAssetRowId: asset.rowId,
            masked: masked,
            tokens: t),
        ],
      ],
    );
  }
}

/// 투자 히어로 아래 등락 라인 — design: "+N% · 오늘 ±M원" (상승=빨강/하락=파랑).
/// 라이브 평가(연동가·전일종가) 가능할 때만 표시.
class _InvChangeLine extends ConsumerWidget {
  const _InvChangeLine({required this.assetRowId, required this.masked});
  final int assetRowId;
  final bool masked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final v = ref
        .watch(investmentValuationMapProvider)
        .asData
        ?.value[assetRowId];
    final chg = v?.changeAmt;
    if (masked || v == null || chg == null) return const SizedBox.shrink();
    final base = v.value - chg;
    final pct = base == 0 ? 0.0 : chg / base * 100;
    final up = chg >= 0;
    final color = up ? t.statusDangerFg : t.fgBrand;
    return Padding(
      padding: const EdgeInsets.only(bottom: PSpace.x16),
      child: Row(
        children: [
          Text(
            '${up ? '+' : ''}${pct.toStringAsFixed(1)}%',
            style: PTypo.bodySm.copyWith(
              color: color,
              fontWeight: PFontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          Text(
            l.assetTodayChange(
              krwSigned(chg.abs(), false, sign: up ? '+' : '−'),
            ),
            style: PTypo.caption.copyWith(
              color: t.fgTertiary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 투자 보유 종목 섹션 — design AssetDetailDialog '보유 종목' 플랫 리스트 미러.
/// linked: "N주 · 현재가 X 연동" + 등락% / manual: "직접 입력". 행 탭 → 편집.
/// 레거시 단일 연동(tossSymbol/tossQuantity) 자산은 가상 1건으로 표시(편집에서 이관).
class _HoldingsSection extends ConsumerWidget {
  const _HoldingsSection({required this.asset, this.onEdit});
  final Asset asset;
  final VoidCallback? onEdit;

  List<AssetHolding> get _holdings {
    if (asset.holdings.isNotEmpty) return asset.holdings;
    if ((asset.tossSymbol?.isNotEmpty ?? false) && asset.tossQuantity != null) {
      return [
        AssetHolding(
          linked: true,
          tossSymbol: asset.tossSymbol,
          quantity: asset.tossQuantity?.toString(),
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final holdings = _holdings;

    // 연동 심볼 시세 — 게이트(프로+토스연결) ON 일 때만 조회.
    final features = ref.watch(myFeaturesProvider).asData?.value;
    final gate =
        (features?.hasSecurities ?? false) && (features?.tossConnected ?? false);
    final symbols = [
      for (final h in holdings)
        if (h.linked && (h.tossSymbol?.isNotEmpty ?? false)) h.tossSymbol!,
    ];
    final prices = gate && symbols.isNotEmpty
        ? (ref
                .watch(tossPricesProvider((symbols.toSet().toList()..sort())
                    .join(',')))
                .asData
                ?.value ??
            const [])
        : const <TossPrice>[];
    final priceBySymbol = {for (final p in prices) p.symbol: p};
    final hasForeign = prices.any((p) {
      final cur = p.currency;
      return cur != null && cur.isNotEmpty && cur.toUpperCase() != 'KRW';
    });
    final fx = hasForeign
        ? ref.watch(tossExchangeRateProvider).asData?.value?.rateValue ?? 0.0
        : 0.0;

    double? unitKrw(String symbol) {
      final p = priceBySymbol[symbol];
      if (p == null) return null;
      final foreign = p.currency != null &&
          p.currency!.isNotEmpty &&
          p.currency!.toUpperCase() != 'KRW';
      if (foreign) return fx > 0 ? p.priceValue * fx : null;
      return p.priceValue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.assetHoldings,
              style: PTypo.bodySm.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${holdings.length}',
              style: PTypo.bodySm.copyWith(
                color: t.fgBrand,
                fontWeight: PFontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        if (holdings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpace.x20),
            child: Center(
              child: Text(
                l.assetHoldingsEmptyDetail,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
            ),
          )
        else
          for (int i = 0; i < holdings.length; i++)
            _HoldingRow(
              holding: holdings[i],
              // 매수·매도는 종목마다 연다 — 어떤 종목인지 정해진 채로 들어가야
              // 다시 고를 일이 없다(종목 추가는 편집에서 토스 검색으로).
              onTrade: (type) => showAssetTradeSheet(context,
                  asset: asset, holding: holdings[i], defaultType: type),
              first: i == 0,
              unitKrw: holdings[i].linked &&
                      (holdings[i].tossSymbol?.isNotEmpty ?? false)
                  ? unitKrw(holdings[i].tossSymbol!)
                  : null,
              rawPrice: holdings[i].linked
                  ? priceBySymbol[holdings[i].tossSymbol]
                  : null,
              onTap: onEdit,
            ),

        // 거래 내역 — 언제 사고 팔았는지, 실현손익이 얼마인지. 취소도 여기서.
        _TradeHistory(assetRowId: asset.rowId),
      ],
    );
  }
}

/// 매수·매도 내역 — 취소하면 예수금·보유 수량·원가가 거래 전으로 돌아간다.
class _TradeHistory extends ConsumerWidget {
  const _TradeHistory({required this.assetRowId});
  final int assetRowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final trades = ref.watch(assetTradesProvider(assetRowId)).value ?? const [];
    if (trades.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: PSpace.x16),
        Text(l.tradeHistory,
            style: PTypo.bodySm
                .copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold)),
        for (final tr in trades)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
            child: Row(
              children: [
                Text(
                  tr.tradeType == 'SELL' ? l.tradeSell : l.tradeBuy,
                  style: PTypo.micro.copyWith(
                    color: tr.tradeType == 'SELL' ? t.fgBrand : t.statusDanger,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: Text(tr.holdingKey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
                ),
                Text(
                  '${tr.quantity ?? ''} · ${(tr.tradeDate ?? '').split('T').first}',
                  style: PTypo.micro.copyWith(color: t.fgTertiary),
                ),
                const SizedBox(width: PSpace.x8),
                Text(krwSigned(tr.amount ?? 0, false, unit: true),
                    style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                if (tr.realizedPl != null && tr.realizedPl != 0) ...[
                  const SizedBox(width: PSpace.x8),
                  Text(
                    krwSigned(tr.realizedPl!.abs(), false,
                        sign: tr.realizedPl! > 0 ? '+' : '-'),
                    style: PTypo.micro.copyWith(
                      color: tr.realizedPl! > 0 ? t.fgIncome : t.fgExpense,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(LucideIcons.trash2, size: 14, color: t.fgTertiary),
                  visualDensity: VisualDensity.compact,
                  tooltip: l.actionDelete,
                  onPressed: () => _confirmDelete(context, ref, tr.rowId),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int rowId) async {
    final l = AppLocalizations.of(context);
    // "삭제" 라벨은 자산 삭제와 헷갈린다 — 웹과 같은 "거래 취소" 로 통일한다.
    final ok = await showPConfirmDialog(
      context,
      title: l.tradeDeleteTitle,
      message: l.tradeDeleteConfirm,
      confirmLabel: l.tradeDeleteTitle,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.deleteTrade(rowId);
      ref.invalidate(assetsProvider);
      ref.invalidate(assetTradesProvider(assetRowId));
      if (!context.mounted) return;
      showPSnackBar(context, l.tradeDeleted, severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      showPSnackBar(context, e.message, severity: PSnackSeverity.error);
    }
  }
}

/// 보유 종목 1행 — design 플랫 행(이름/서브 · 평가액/등락% · chevron).
class _HoldingRow extends ConsumerWidget {
  const _HoldingRow({
    required this.holding,
    required this.first,
    required this.unitKrw,
    required this.rawPrice,
    this.onTap,
    this.onTrade,
  });
  final AssetHolding holding;
  final bool first;
  final double? unitKrw; // 연동 1주 KRW 환산가 (미확보 시 null)
  final TossPrice? rawPrice; // 표시용 원통화 현재가
  final VoidCallback? onTap;
  /// 이 종목에 대한 매수·매도. 종목이 정해진 자리라 시트에서 다시 고를 필요가 없다.
  final ValueChanged<String>? onTrade;

  String _fmtRawPrice(TossPrice p) {
    final foreign = p.currency != null &&
        p.currency!.isNotEmpty &&
        p.currency!.toUpperCase() != 'KRW';
    if (foreign) {
      return '\$${p.priceValue.toStringAsFixed(2)}';
    }
    return '${krw(p.priceValue.round())}원';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final h = holding;
    final name = (h.holdingName?.isNotEmpty ?? false)
        ? h.holdingName!
        : (h.tossSymbol ?? '');

    // 서브 — linked: "{qty}주 · 현재가 {price} 연동"(연동은 주식뿐) /
    // manual: 수량을 적어 뒀으면 "{qty}{단위} · 직접 입력", 없으면 "직접 입력".
    final qty = formatHoldingQty(h.quantity, h.holdingType);
    final String sub;
    if (h.linked) {
      sub = rawPrice != null
          ? l.assetHoldingLinkedDetail(qty, _fmtRawPrice(rawPrice!))
          : '${l.assetSharesCount(qty)} · ${l.assetHoldingLinkedBadge}';
    } else {
      sub = h.quantityValue > 0
          ? '${l.assetHoldingQtyUnit(qty, holdingUnitLabel(l, h.holdingType))} · ${l.assetHoldingManualDetail}'
          : l.assetHoldingManualDetail;
    }

    // 평가액 — linked: 라이브(가격×수량), 폴백 서버 스냅샷(holdingValue) / manual: holdingValue.
    final int? value = h.linked
        ? (unitKrw != null
            ? (unitKrw! * h.quantityValue).round()
            : h.holdingValue)
        : (h.holdingValue ?? 0);

    // 등락% — 연동 + 전일종가 확보 시.
    final prev = h.linked && (h.tossSymbol?.isNotEmpty ?? false)
        ? ref.watch(prevCloseProvider(h.tossSymbol!)).asData?.value
        : null;
    double? pct;
    if (h.linked && rawPrice != null && prev != null && prev > 0) {
      pct = (rawPrice!.priceValue - prev) / prev * 100;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
        decoration: BoxDecoration(
          border: first
              ? null
              : Border(top: BorderSide(color: t.borderSubtle)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.body.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.caption.copyWith(
                      color: t.fgTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value != null ? '${krw(value)}원' : '—',
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (pct != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                    style: PTypo.micro.copyWith(
                      color: pct >= 0 ? t.statusDangerFg : t.fgBrand,
                      fontWeight: PFontWeight.semi,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
            // 매수·매도는 상세를 어디서 열었든 가능해야 한다 — 편집 진입(onTap)
            // 여부에 묶으면 자산 화면에서 연 상세만 매매가 막힌다(웹은 된다).
            if (onTrade != null || onTap != null)
              const SizedBox(width: PSpace.x8),
            if (onTrade != null) ...[
              PButton(
                label: l.tradeBuy,
                variant: PButtonVariant.ghost,
                size: PButtonSize.sm,
                onPressed: () => onTrade!('BUY'),
              ),
              PButton(
                label: l.tradeSell,
                variant: PButtonVariant.ghost,
                size: PButtonSize.sm,
                onPressed: () => onTrade!('SELL'),
              ),
            ],
            if (onTap != null)
              Icon(LucideIcons.chevronRight, size: 15, color: t.fgTertiary),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.asset,
    required this.meta,
    required this.valueLabel,
    required this.isCard,
    required this.masked,
    this.nameRowOnly = false,
  });
  final Asset asset;
  final AssetTypeMeta meta;
  final String valueLabel;
  final bool isCard;
  final bool masked;

  /// 신용카드 — 이름 행만(구분선·잔액 생략, 회차 히어로가 금액 담당).
  final bool nameRowOnly;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final subtitle = [
      asset.institution,
      assetTypeLabel(l, asset.assetType),
      asset.memo,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    // 카드만 절대값이다. 카드 잔액은 "미결제 사용액이 음수" 라는 규약이라 화면에는
    // 얼마 썼나로 뒤집어 보여 준다. 그 밖의 자산은 음수가 정상 상태다 — 마이너스 통장,
    // 잔액을 실제와 맞추지 않은 계좌. abs() 를 씌우면 −5,000 이 "5,000원" 으로 보여
    // 목록·편집 폼과 어긋난다.
    final heroIsCard =
        asset.assetType == 'CREDIT_CARD' || asset.assetType == 'CHECK_CARD';
    final rawBalance = asset.balance ?? 0;
    // 연결계좌형 체크카드는 잔액이 늘 0 — 히어로는 이번 달 사용액(서버 계산)을 보여준다.
    final checkLinked =
        asset.assetType == 'CHECK_CARD' && asset.paymentAssetRowId != null;
    final heroBalance = checkLinked
        ? (asset.monthlyUsedAmount ?? 0)
        : heroIsCard
            ? rawBalance.abs()
            : rawBalance;
    // 플랫 히어로(design 신판) — 그라데이션 카드 제거, 이름 행 아래 구분선만.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 14),
          margin: EdgeInsets.only(bottom: nameRowOnly ? 0 : 14),
          decoration: nameRowOnly
              ? null
              : BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.borderSubtle)),
                ),
          child: Row(
            children: [
              // web hero 정합 — 타입 글리프 대신 AssetLogo 모노그램 (icon 제거 마이그 잔재 정리)
              AssetLogo(asset: asset, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.assetName,
                      style: PTypo.h3.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!nameRowOnly) ...[
        Text(
          valueLabel,
          style: PTypo.micro.copyWith(
            color: t.fgTertiary,
            fontWeight: PFontWeight.semi,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        // 큰 금액 — 숫자/원 분리해서 원 폰트만 작게.
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                // 카드는 부호 없이 중립색 — 결제 예정 금액 표기(사용자 결정).
                // 그 밖은 마이너스면 그대로 보여 준다.
                text: masked
                    ? '••••••'
                    : (heroBalance < 0 ? '−${krw(heroBalance.abs())}' : krw(heroBalance)),
                style: PTypo.h1.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.6,
                ),
              ),
              if (!masked)
                TextSpan(
                  text: wonUnit(),
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        // 예수금·평가금액 — 실제 증권 계좌처럼 나눠 보여 준다(예수금이 있을 때만).
        if (asset.assetType == 'INVESTMENT' && (asset.cashBalance ?? 0) != 0) ...[
          const SizedBox(height: PSpace.x8),
          Text(
            '${l.assetCashBalance} ${masked ? '••••••' : krw(asset.cashBalance!)}'
            ' · ${l.assetHoldingBalance} ${masked ? '••••••' : krw(asset.holdingBalance ?? 0)}',
            style: PTypo.caption.copyWith(color: t.fgTertiary),
          ),
        ],
        ],
      ],
    );
  }
}

class _BalanceTrendChart extends StatefulWidget {
  const _BalanceTrendChart({
    required this.async,
    required this.tokens,
    required this.brandFg,
    required this.seriesLabel,
    required this.masked,
  });
  final AsyncValue<List<AssetBalancePoint>> async;
  final PorestTokens tokens;
  final Color brandFg;
  final String seriesLabel;
  final bool masked;

  @override
  State<_BalanceTrendChart> createState() => _BalanceTrendChartState();
}

class _BalanceTrendChartState extends State<_BalanceTrendChart> {
  int? _touchedIdx;
  Offset? _touchPos;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = widget.tokens;
    final brandFg = widget.brandFg;
    final seriesLabel = widget.seriesLabel;
    final masked = widget.masked;
    final list = widget.async.value ?? const <AssetBalancePoint>[];
    if (widget.async.isLoading && list.isEmpty) {
      // 차트 영역 전체 PSkeleton — 부모 SizedBox(height:160) 의 영역에 fill.
      return SizedBox.expand(child: PSkeleton(borderRadius: PRadius.brLg));
    }
    if (list.isEmpty) {
      return _ChartPlaceholder(
          text: AppLocalizations.of(context).assetChartNoData, tokens: tokens);
    }
    final n = list.length;
    final spots = [
      for (int i = 0; i < n; i++)
        FlSpot(i.toDouble(), list[i].balance.toDouble()),
    ];
    // Y축: 웹 Recharts auto-nice 와 동일한 0기준 nice 눈금 (공유 niceAxis).
    // 대출 등 음수 잔액이면 0 아래로도 nice 확장 → 눈금이 딱 떨어지고 겹치지 않음.
    final values = list.map((p) => p.balance.toDouble()).toList(growable: false);
    final maxRaw = values.reduce((a, b) => a > b ? a : b);
    final minRaw = values.reduce((a, b) => a < b ? a : b);
    final yAxis = niceAxis(minRaw, maxRaw);
    final yMin = yAxis.min;
    final yMax = yAxis.max;
    final yInterval = yAxis.interval;
    final xInterval = (n / 6).clamp(1.0, double.infinity);

    final chart = LineChart(
      LineChartData(
        minX: 0,
        maxX: (n - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: tokens.borderSubtle,
            strokeWidth: 1,
            dashArray: const [3, 3],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: yInterval,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  masked ? '••••' : formatChartAxis(v),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: PTypo.micro.copyWith(
                    color: tokens.fgTertiary,
                    fontSize: PFontSize.micro,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: xInterval,
              getTitlesWidget: (v, _) {
                final i = v.round();
                if (i < 0 || i >= n) return const SizedBox.shrink();
                // 너무 빽빽하면 균등 stride 만 표시.
                final stride = (n / 6).ceil();
                if (n > 12 && stride > 1 && i % stride != 0 && i != n - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l.weekN(i + 1),
                    style: PTypo.micro.copyWith(
                      color: tokens.fgTertiary,
                      fontSize: PFontSize.micro,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent ||
                event is FlPanEndEvent ||
                event is FlPanCancelEvent ||
                event is FlLongPressEnd ||
                event is FlPointerExitEvent) {
              if (_touchedIdx != null) {
                setState(() => _touchedIdx = null);
              }
              return;
            }
            final touched = response?.lineBarSpots;
            if (touched == null || touched.isEmpty) {
              if (_touchedIdx != null) {
                setState(() => _touchedIdx = null);
              }
              return;
            }
            final i = touched.first.x.toInt();
            final pos = event.localPosition;
            if (i >= 0 && i < list.length && (i != _touchedIdx || pos != _touchPos)) {
              setState(() {
                _touchedIdx = i;
                if (pos != null) _touchPos = pos;
              });
            }
          },
          // 기본 RichText 툴팁 OFF — web 라운드 사각 인디케이터 정합을 위해
          // Stack 위 PChartTooltipBox 로 직접 렌더 (아래 Positioned).
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipBorder: BorderSide.none,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 0,
            getTooltipItems: (touched) =>
                List<LineTooltipItem?>.filled(touched.length, null),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: brandFg,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: brandFg,
                strokeColor: tokens.bgSurface,
                strokeWidth: 1.5,
              ),
            ),
            // web recharts 정합 — fill 은 차트 바닥이 아니라 0 기준선을 향해 채움.
            // 양수 구간은 라인 아래(belowBarData), 음수 구간은 라인 위(aboveBarData)로
            // cutOffY=0 에서 잘라 채운다 (카드 사용 추이처럼 전부 음수면 위쪽 fill).
            belowBarData: BarAreaData(
              show: true,
              applyCutOffY: true,
              cutOffY: 0,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  brandFg.withValues(alpha: 0.28),
                  brandFg.withValues(alpha: 0),
                ],
              ),
            ),
            aboveBarData: BarAreaData(
              show: true,
              applyCutOffY: true,
              cutOffY: 0,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  brandFg.withValues(alpha: 0.28),
                  brandFg.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        chart,
        if (_touchedIdx != null && _touchedIdx! < list.length && _touchPos != null)
          PChartTooltipLayer(
            anchor: _touchPos!,
            child: PChartTooltipBox(
              // web BalanceTooltip 정합 — 'N주 · MM-DD'
              title:
                  '${l.weekN(_touchedIdx! + 1)} · ${_fmtWeekStart(list[_touchedIdx!].weekStart)}',
              labelWidth: 40,
              rows: [
                PChartTooltipRowData(
                  color: brandFg,
                  label: seriesLabel,
                  amount: masked
                      ? '••••••'
                      : krwSigned(list[_touchedIdx!].balance, false, unit: true),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 'YYYY-MM-DD' → 'MM-DD' (web weekStart.slice(5) 정합).
String _fmtWeekStart(String iso) => iso.length >= 10 ? iso.substring(5) : iso;

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.text, required this.tokens});
  final String text;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSunken,
        borderRadius: PRadius.brLg,
      ),
      alignment: Alignment.center,
      child: Text(text, style: PTypo.bodySm.copyWith(color: tokens.fgTertiary)),
    );
  }
}

class _RecentExpenses extends StatelessWidget {
  const _RecentExpenses({
    required this.async,
    required this.masked,
    required this.tokens,
    this.transfers = const [],
    this.perspectiveAssetRowId,
  });
  final AsyncValue<List<Expense>> async;
  final bool masked;
  final PorestTokens tokens;
  /// 이 자산에 걸린 이체. 지출/수입 일 합계에는 넣지 않고 그날 행 뒤에만 붙인다.
  final List<AssetTransfer> transfers;
  /// 부호 기준 자산 — 출금이면 -(금액+수수료), 입금이면 +금액.
  final int? perspectiveAssetRowId;
  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <Expense>[];
    if (async.isLoading && list.isEmpty) {
      // 실렌더와 같은 날짜 그룹 구조 — 그룹 사이 16, 헤더(날짜+요일+일 합계) + 행.
      // 평평한 행만 깔면 데이터가 오는 순간 헤더 높이만큼 목록이 밀린다.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int g = 0; g < 2; g++) ...[
            Padding(
              padding: EdgeInsets.only(top: g == 0 ? 0 : PSpace.x16),
              child: const Row(
                children: [
                  PSkeleton.line(width: 56, height: 14),
                  SizedBox(width: PSpace.x8),
                  PSkeleton.line(width: 20, height: 14),
                  Spacer(),
                  PSkeleton.line(width: 72, height: 14),
                ],
              ),
            ),
            for (int i = 0; i < 2; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    PSkeleton(
                        width: 36, height: 36, borderRadius: PRadius.tile(36)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PSkeleton.line(width: 120, height: 14),
                          SizedBox(height: 4),
                          PSkeleton.line(width: 80, height: 11),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const PSkeleton.line(width: 56, height: 14),
                  ],
                ),
              ),
          ],
        ],
      );
    }
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            AppLocalizations.of(context).assetNoLinkedTx,
            style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
          ),
        ),
      );
    }

    // 가계부 메인 리스트 미러 — 카드 제거, 날짜 그룹 헤더(웹 DateGroupHeader
    // 정합: 날짜 primary/bold + 요일 tertiary + 우측 일 지출/수입 합계) + 플랫 행.
    final dayGroups = <String, List<Expense>>{};
    for (final e in list) {
      dayGroups.putIfAbsent(e.expenseDateOnly ?? '', () => <Expense>[]).add(e);
    }
    final entries = dayGroups.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var gi = 0; gi < entries.length; gi++) ...[
          // 헤더-행 간격은 행 자체 pt 12(웹 LedgerRow py-3)가 담당 — bottom 0.
          Padding(
            padding: EdgeInsets.only(top: gi == 0 ? 0 : PSpace.x16),
            child: _DayGroupHeader(
              dayKey: entries[gi].key,
              items: entries[gi].value,
              masked: masked,
              tokens: tokens,
            ),
          ),
          for (final e in entries[gi].value)
            _ExpenseRow(expense: e, masked: masked, tokens: tokens),
          // 이체는 시각이 없어(LocalDate) 그날의 맨 뒤 — web 정렬과 같은 자리.
          for (final tr in transfers.where((x) =>
              (x.transferDate ?? '').length >= 10 &&
              x.transferDate!.substring(0, 10) == entries[gi].key))
            TransferRow(
              key: ValueKey('t${tr.rowId}'),
              transfer: tr,
              masked: masked,
              perspectiveAssetRowId: perspectiveAssetRowId,
              onTap: () => showTransferDetailSheet(context, tr),
            ),
        ],
      ],
    );
  }
}

/// 날짜 그룹 헤더 — 웹 DateGroupHeader 미러 ("7월 8일" + "수" + 일 합계).
class _DayGroupHeader extends StatelessWidget {
  const _DayGroupHeader({
    required this.dayKey,
    required this.items,
    required this.masked,
    required this.tokens,
  });
  final String dayKey;
  final List<Expense> items;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(dayKey);
    final label = d == null ? null : formatDay(d);
    // 서버 집계와 같은 규칙 — 환불 상계 + 예정 제외.
    final dayExpense = expenseSum(items);
    final dayIncome = incomeSum(items);
    return Row(
      children: [
        Text(
          label?.md ?? dayKey,
          style: PTypo.bodySm.copyWith(
            color: tokens.fgPrimary,
            fontWeight: PFontWeight.bold,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: PSpace.x8),
          Text(
            label.dow,
            style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
          ),
        ],
        const Spacer(),
        if (dayExpense > 0)
          Text(
            krwSigned(dayExpense, masked, sign: '−', unit: true),
            style: PTypo.caption.copyWith(
              color: tokens.fgExpense,
              fontWeight: PFontWeight.semi,
            ),
          ),
        if (dayIncome > 0) ...[
          if (dayExpense > 0) const SizedBox(width: PSpace.x8),
          Text(
            krwSigned(dayIncome, masked, sign: '+', unit: true),
            style: PTypo.caption.copyWith(
              color: tokens.fgIncome,
              fontWeight: PFontWeight.semi,
            ),
          ),
        ],
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.masked,
    required this.tokens,
  });
  final Expense expense;
  final bool masked;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = resolveChartColor(context, expense.categoryColor, fallback: tokens.fgBrand);
    final bg = softBg(context, color);
    final title =
        expense.merchant ??
        expense.description ??
        (expense.categoryName ?? l.assetTxFallback);
    final subParts = [
      expense.categoryName ?? l.assetCategoryOther,
      if ((expense.assetName ?? '').isNotEmpty) expense.assetName!,
    ];
    return InkWell(
      onTap: () => showTxDetailDialog(context, expense),
      borderRadius: PRadius.brMd,
      child: Padding(
        // 웹 LedgerRow 정합 — py-3(12), 좌우 0(헤더와 좌측 라인 일치).
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bg, borderRadius: PRadius.tile(36)),
              alignment: Alignment.center,
              child: Icon(
                lucideByName(expense.categoryIcon),
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.bodySm.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              masked
                  ? '••••••'
                  : krwSigned(expense.signedAmount, false,
                      sign: expense.signedAmount > 0 ? '+' : '', unit: true),
              style: PTypo.bodySm.copyWith(
                color: tokens.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 신용카드 청구 사이클 — 결제예정액·예정일 + '지금 결제' + 청구이력.
/// GET /asset/{id}/billing 사용. '지금 결제' 후 billing/assets invalidate.
/// chart green 시멘틱(실적 달성) — 다크 light variant 스왑(웹 --color-cat-green 미러).
Color _chartGreenOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF6BCB86) // chart-green-light
        : const Color(0xFF2D8060); // chart-green

/// 결제 회차(청구월) 항목 — 예정 1건 + 과거 결제 완료(COMPLETED) 이력.
class _CardStatement {
  const _CardStatement({
    required this.label,
    required this.scheduled,
    required this.amount,
    required this.paymentDate,
    this.periodStart,
    this.periodEnd,
  });
  final String label;
  final bool scheduled;
  final int amount;
  final String paymentDate;
  final String? periodStart;
  final String? periodEnd;
}

/// 카드 월 실적 배지 — design 신판(달성/잔여 요약, 웹 CardPerfBadge 미러).
/// 달성: cat-green 10% tint / 미달: sunken. 실적 무관 카드면 숨김.
class _CardPerfBadge extends ConsumerWidget {
  const _CardPerfBadge({required this.assetRowId, required this.masked});
  final int assetRowId;
  final bool masked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final async = ref.watch(cardPerformanceProvider(
        (assetRowId: assetRowId, yearMonth: _currentYearMonth())));
    final p = async.value;
    if (async.isLoading && p == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: t.bgSunken,
          borderRadius: PRadius.brLg,
        ),
        child: const Row(
          children: [
            PSkeleton(width: 30, height: 30, borderRadius: PRadius.brFull),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PSkeleton.line(width: 130, height: 13),
                  SizedBox(height: 4),
                  PSkeleton.line(width: 160, height: 11),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (p == null || !p.isRequired || p.requiredAmount == null) {
      return const SizedBox.shrink();
    }
    final done = p.isAchieved;
    final green = _chartGreenOf(context);
    final pct = (p.achievementRate.clamp(0, 1.5) * 100).truncate();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        // 웹 color-mix(in oklab, cat-green 10%, surface) 결과값 고정
        // (sRGB alphaBlend 10% 는 녹색기가 죽어 웹과 어긋남 — oklab 혼합 미러)
        color: done
            ? (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2B3840)
                : const Color(0xFFEAF2EE))
            : t.bgSunken,
        borderRadius: PRadius.brLg,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: t.bgSurface, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(
              done ? LucideIcons.check : LucideIcons.target,
              size: 15,
              color: done ? green : t.fgSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  done
                      ? l.assetPerfDone
                      : l.assetPerfRemain(
                          krwSigned(p.remainingAmount ?? 0, masked, unit: true)),
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  masked
                      ? '•••••• · $pct%'
                      : '${krw(p.currentAmount)} / ${krw(p.requiredAmount!)}${wonUnit()} · $pct%',
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 카드 상세 본문 — design card-detail.jsx 신판(현대카드 결제정보 패턴, 웹 CardDetailBody
/// 미러). 회차 히어로(기간 선택 시트) / 결제일·이용 기간 행 / 액션 2타일 /
/// 한도 사용 게이지·실적 배지 / 이용 내역(정렬 칩 + 날짜 그룹). CREDIT_CARD 전용.
class _CardDetailBody extends ConsumerStatefulWidget {
  const _CardDetailBody({
    required this.asset,
    required this.masked,
    this.onEdit,
  });
  final Asset asset;
  final bool masked;
  final VoidCallback? onEdit;

  @override
  ConsumerState<_CardDetailBody> createState() => _CardDetailBodyState();
}

enum _UsageSort { recent, amount, category }

class _CardDetailBodyState extends ConsumerState<_CardDetailBody> {
  int _stIdx = 0;
  _UsageSort _sort = _UsageSort.recent;
  bool _paying = false;

  List<_CardStatement> _statements(CardBilling? b) {
    final out = <_CardStatement>[];
    if (b?.nextPaymentDate != null) {
      final d = DateTime.tryParse(b!.nextPaymentDate!);
      out.add(_CardStatement(
        label: d != null ? formatDay(d).md : b.nextPaymentDate!,
        scheduled: true,
        amount: b.upcomingAmount,
        paymentDate: b.nextPaymentDate!,
        periodStart: b.upcomingPeriodStart,
        periodEnd: b.upcomingPeriodEnd,
      ));
    }
    // 과거 회차 — 결제월별 합산: 같은 달에 여러 번(선결제 등) 결제해도 월 1행(사용자 결정).
    // 라벨은 정규 결제일(paymentDay, 말일 보정), 기간은 결제월의 전월 1일~말일(백엔드 회차 규칙 미러).
    String pad2(int n) => n.toString().padLeft(2, '0');
    final byMonth = <String, ({int amount, String latest})>{};
    for (final h in b?.history ?? const <BillingItem>[]) {
      if (h.status != 'COMPLETED') continue;
      final ym = h.paymentDate.substring(0, 7);
      final cur = byMonth[ym];
      byMonth[ym] = cur == null
          ? (amount: h.billingAmount, latest: h.paymentDate)
          : (
              amount: cur.amount + h.billingAmount,
              latest: h.paymentDate.compareTo(cur.latest) > 0
                  ? h.paymentDate
                  : cur.latest,
            );
    }
    for (final entry in byMonth.entries) {
      final parts = entry.key.split('-');
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y == null || m == null) continue;
      final lastDay = DateTime(y, m + 1, 0).day;
      final rawDay =
          b?.paymentDay ?? int.tryParse(entry.value.latest.substring(8, 10)) ?? 1;
      final day = rawDay > lastDay ? lastDay : rawDay;
      final paymentDate = '${entry.key}-${pad2(day)}';
      final py = m == 1 ? y - 1 : y;
      final pm = m == 1 ? 12 : m - 1;
      final pLast = DateTime(py, pm + 1, 0).day;
      out.add(_CardStatement(
        label: formatDay(DateTime(y, m, day)).md,
        scheduled: false,
        amount: entry.value.amount,
        paymentDate: paymentDate,
        periodStart: '$py-${pad2(pm)}-01',
        periodEnd: '$py-${pad2(pm)}-${pad2(pLast)}',
      ));
    }
    return out;
  }

  /// 결제 시트 — 금액을 고칠 수 있다(부분 선결제). 기본값은 남은 청구액.
  /// 일부만 내면 나머지는 결제일에 정상적으로 빠진다(서버가 '사용액 − 이미 결제액'으로 잡는다).
  Future<void> _confirmAndPay(CardBilling b) async {
    final l = AppLocalizations.of(context);
    final upcoming = b.upcomingAmount;
    final ctrl = TextEditingController(text: upcoming.toString());
    final sheet = PSheetController();

    int parsed() => int.tryParse(ctrl.text.replaceAll(',', '')) ?? 0;
    void syncCanSubmit() {
      final v = parsed();
      sheet.setCanSubmit(v > 0 && v <= upcoming);
    }

    ctrl.addListener(syncCanSubmit);
    int? picked;
    sheet.onSubmit = () async {
      picked = parsed();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    };

    await showPSheet<void>(
      context,
      title: l.assetPayNow,
      shrinkWrap: true,
      contentBuilder: (ctx, _) {
        final t = ctx.tokens;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            ctrl.removeListener(syncCanSubmit);
            void onChanged() {
              syncCanSubmit();
              setLocal(() {});
            }

            ctrl.addListener(onChanged);
            final v = parsed();
            final dateSuffix = b.nextPaymentDate != null
                ? l.assetPayConfirmDateSuffix(b.nextPaymentDate!)
                : '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l.assetPayConfirmMessage(krw(upcoming))}$dateSuffix',
                  style: PTypo.body.copyWith(color: t.fgSecondary, height: 1.7),
                ),
                const SizedBox(height: PSpace.x20),
                Text(l.assetPayAmount,
                    style: PTypo.caption.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x8),
                PTextInput(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(),
                  placeholder: '0',
                ),
                if (v > 0 && v < upcoming) ...[
                  const SizedBox(height: PSpace.x8),
                  Text(l.assetPayRemainder(krw(upcoming - v)),
                      style: PTypo.micro.copyWith(color: t.fgTertiary)),
                ],
              ],
            );
          },
        );
      },
      footerBuilder: (ctx) => PSheetFooter(
        controller: sheet,
        submitLabel: l.assetPayAction,
      ),
    );

    ctrl.dispose();
    sheet.dispose();
    if (picked == null || !mounted) return;
    await _pay(picked!);
  }

  Future<void> _pay(int amount) async {
    if (_paying) return;
    final l = AppLocalizations.of(context);
    setState(() => _paying = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.payCard(widget.asset.rowId, amount: amount);
      ref
        ..invalidate(cardBillingProvider(widget.asset.rowId))
        ..invalidate(assetsProvider)
        ..invalidate(assetByIdProvider(widget.asset.rowId));
      if (!mounted) return;
      showPSnackBar(context, l.assetPaymentRecorded,
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.assetPayFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  /// 되돌릴 수 있는 가장 최근 결제.
  ///
  /// 결제는 실행하면 되돌릴 길이 없었다 — 그 이체는 청구와 묶여 있어 잠가 뒀고 취소
  /// 경로도 없었다. 잘못 눌렀을 때 바로 무를 수 있게 마지막 한 건을 짚어 준다.
  BillingItem? _lastPayment(CardBilling? b) {
    final done = (b?.history ?? const <BillingItem>[])
        .where((h) => h.status == 'COMPLETED')
        .toList();
    if (done.isEmpty) return null;
    return done.reduce((a, x) => x.paymentDate.compareTo(a.paymentDate) > 0 ? x : a);
  }

  Future<void> _confirmAndCancelPayment(BillingItem billing) async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.assetCancelPayment,
      message: l.assetCancelPaymentConfirm(
        krw(billing.billingAmount),
        billing.paymentDate,
      ),
      confirmLabel: l.assetCancelPayment,
      destructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _paying = true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.cancelCardPayment(billing.rowId);
      // 이체·잔액·청구가 함께 되돌아간다 — 가계부도 비운다(이자 지출 등).
      ref
        ..invalidate(cardBillingProvider(widget.asset.rowId))
        ..invalidate(assetsProvider)
        ..invalidate(assetByIdProvider(widget.asset.rowId));
      invalidateAfterExpenseChange(ref);
      if (!mounted) return;
      showPSnackBar(context, l.assetPaymentCancelled,
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.expActionFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _goEdit() {
    Navigator.of(context).pop();
    if (widget.onEdit != null) {
      widget.onEdit!();
    } else {
      context.push('/account-card-manage');
    }
  }

  void _openPeriodPicker(List<_CardStatement> stmts) {
    final byYear = <String, List<(int, _CardStatement)>>{};
    for (var i = 0; i < stmts.length; i++) {
      byYear.putIfAbsent(stmts[i].paymentDate.substring(0, 4), () => []).add((i, stmts[i]));
    }
    showPSheet<void>(
      context,
      title: AppLocalizations.of(context).assetPeriodPick,
      shrinkWrap: true,
      contentBuilder: (ctx, _) {
        final t = ctx.tokens;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in byYear.entries)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontFamily: PTypo.sans,
                            fontSize: PFontSize.bodyMd,
                            fontWeight: PFontWeight.bold,
                            color: t.fgPrimary,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var ri = 0; ri < entry.value.length; ri++)
                            InkWell(
                              onTap: () {
                                // showPSheet 는 root navigator — rootNavigator pop 필수.
                                Navigator.of(context, rootNavigator: true).pop();
                                setState(() => _stIdx = entry.value[ri].$1);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 15),
                                decoration: ri == 0
                                    ? null
                                    : BoxDecoration(
                                        border: Border(
                                            top: BorderSide(
                                                color: t.borderSubtle)),
                                      ),
                                child: Row(
                                  children: [
                                    Text(
                                      entry.value[ri].$2.scheduled
                                          ? '${entry.value[ri].$2.label} (${AppLocalizations.of(ctx).assetScheduledTag})'
                                          : entry.value[ri].$2.label,
                                      style: TextStyle(
                                        fontFamily: PTypo.sans,
                                        fontSize: PFontSize.bodyMd,
                                        fontWeight: entry.value[ri].$1 == _stIdx
                                            ? PFontWeight.bold
                                            : PFontWeight.medium,
                                        color: t.fgPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      widget.masked
                                          ? '••••••'
                                          : krwSigned(entry.value[ri].$2.amount,
                                              false, unit: true),
                                      style: PTypo.bodySm
                                          .copyWith(color: t.fgTertiary),
                                    ),
                                    if (entry.value[ri].$1 == _stIdx) ...[
                                      const SizedBox(width: 8),
                                      Icon(LucideIcons.check,
                                          size: 16, color: t.fgBrand),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final masked = widget.masked;
    final asset = widget.asset;
    final billingAsync = ref.watch(cardBillingProvider(asset.rowId));
    final b = billingAsync.value;
    final stmts = _statements(b);
    final st = stmts.isEmpty ? null : stmts[_stIdx.clamp(0, stmts.length - 1)];

    final limit = asset.creditLimit ?? 0;
    final used = (asset.balance ?? 0).abs();
    final limitPct =
        limit > 0 ? ((used / limit) * 100).round().clamp(0, 100) : 0;
    final limitWarn = limitPct >= 80;
    final paymentDay = b?.paymentDay ?? asset.paymentDay;
    final canPay = (b?.upcomingAmount ?? 0) > 0 && !_paying;
    final periodText = st?.periodStart != null && st?.periodEnd != null
        ? '${_fmtDate(st!.periodStart!)} ~ ${_fmtDate(st.periodEnd!)}'
        : null;
    // 이용 내역 — 선택 회차의 청구 기간(전월 1일~말일)만 조회(사용자 결정).
    // 기간 미확정(폴백 회차)이면 카드 전체 최근 12건.
    final usageAsync = st?.periodStart != null && st?.periodEnd != null
        ? ref.watch(assetPeriodExpensesProvider((
            assetId: asset.rowId,
            startDate: st!.periodStart!,
            endDate: st.periodEnd!,
          )))
        : ref.watch(
            expensesByAssetProvider((assetId: asset.rowId, limit: 12)));

    if (billingAsync.isLoading && b == null) {
      // 실렌더(아래 히어로) 미러 — 회차 라벨+chevron / 금액 / 결제일 행 / 액션 타일.
      // 액션 타일까지 자리를 잡아야 데이터가 오는 순간 아래가 통째로 밀리지 않는다.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(2, 2, 2, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PSkeleton.line(width: 130, height: 20),
                    SizedBox(width: 7),
                    PSkeleton(
                        width: 24, height: 24, borderRadius: PRadius.brFull),
                  ],
                ),
                SizedBox(height: 10),
                PSkeleton.line(width: 180, height: 32),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
            child: const Row(
              children: [
                SizedBox(width: 68, child: PSkeleton.line(width: 56, height: 14)),
                PSkeleton.line(width: 110, height: 14),
                Spacer(),
                PSkeleton.line(width: 90, height: 11),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: Row(
              children: [
                for (int i = 0; i < 2; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 14),
                      decoration: BoxDecoration(
                        color: t.bgSunken,
                        borderRadius: PRadius.brLg,
                      ),
                      child: const Column(
                        children: [
                          PSkeleton(
                              width: 30,
                              height: 30,
                              borderRadius: PRadius.brMd),
                          SizedBox(height: 8),
                          PSkeleton.line(width: 48, height: 11),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    final green = _chartGreenOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 결제 예정 히어로 — 회차 선택
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: PRadius.brMd,
                onTap: stmts.isEmpty ? null : () => _openPeriodPicker(stmts),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      st?.label ?? '—',
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.h3,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -0.4,
                        color: t.fgPrimary,
                      ),
                    ),
                    if (st?.scheduled ?? false) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: t.borderDefault),
                          borderRadius: PRadius.brFull,
                        ),
                        child: Text(
                          l.assetScheduledTag,
                          style: PTypo.micro.copyWith(
                            color: t.fgSecondary,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 7),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: t.bgSunken,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(LucideIcons.chevronDown,
                          size: 14, color: t.fgSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: masked ? '••••••' : krw(st?.amount ?? 0),
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.displayMd,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -0.96,
                        color: t.fgPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (!masked)
                      TextSpan(
                        text: wonUnit(),
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.h3,
                          fontWeight: PFontWeight.bold,
                          color: t.fgPrimary,
                        ),
                      ),
                  ],
                ),
              ),
              if (st != null && !st.scheduled) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.check, size: 13, color: green),
                    const SizedBox(width: 4),
                    Text(
                      l.assetPaidDone,
                      style: PTypo.caption.copyWith(
                        color: green,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // 결제일 · 카드 이용 기간
        if (paymentDay != null)
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 68,
                  child: Text(
                    l.assetPaymentDay,
                    style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                  ),
                ),
                Text(
                  l.assetMonthlyPaymentDay(paymentDay),
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
                const Spacer(),
                if (periodText != null)
                  Text(
                    l.assetUsagePeriod(periodText),
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
              ],
            ),
          ),

        // 빠른 액션
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: _CardActionTile(
                  icon: LucideIcons.zap,
                  label: l.assetPayNow,
                  enabled: canPay,
                  onTap: b == null ? null : () => _confirmAndPay(b),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardActionTile(
                  icon: LucideIcons.slidersHorizontal,
                  label: l.assetLimitSettings,
                  onTap: _goEdit,
                ),
              ),
              // 결제 취소 — 실수로 누른 결제를 무른다. 되돌릴 게 있을 때만 보인다.
              if (_lastPayment(b) != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _CardActionTile(
                    icon: LucideIcons.undo2,
                    label: l.assetCancelPayment,
                    enabled: !_paying,
                    onTap: () => _confirmAndCancelPayment(_lastPayment(b)!),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 한도 사용 · 실적
        if (limit > 0)
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.only(top: 18),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l.assetLimitUsage,
                      style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l.assetLimitPctUsed(limitPct),
                      style: PTypo.bodySm.copyWith(
                        color: limitWarn ? chartRedOf(context) : t.fgBrand,
                        fontWeight: PFontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 11, bottom: 7),
                  child: ClipRRect(
                    borderRadius: PRadius.brFull,
                    child: SizedBox(
                      height: 8,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Container(color: t.bgSunken),
                          FractionallySizedBox(
                            widthFactor: limitPct / 100,
                            child: Container(
                              color: limitWarn
                                  ? chartRedOf(context)
                                  : t.bgBrandSolid,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      masked
                          ? '••••••'
                          : l.assetLimitOf(krw(used), '${krw(limit)}${wonUnit()}'),
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                    const Spacer(),
                    Text(
                      masked
                          ? '••••••'
                          : l.assetLimitRemain(krwSigned(
                              (limit - used).clamp(0, limit), false,
                              unit: true)),
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: PRadius.brFull,
                    onTap: _goEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: t.borderDefault),
                        borderRadius: PRadius.brFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.pencil,
                              size: 12, color: t.fgPrimary),
                          const SizedBox(width: 5),
                          Text(
                            l.assetLimitEdit,
                            style: PTypo.caption.copyWith(
                              color: t.fgPrimary,
                              fontWeight: PFontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _CardPerfBadge(assetRowId: asset.rowId, masked: masked),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _CardPerfBadge(assetRowId: asset.rowId, masked: masked),
          ),

        // 이용 내역 — 정렬 칩 + 리스트
        Container(
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.only(top: 18),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.borderSubtle)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    l.assetUsageHistory,
                    style: PTypo.body.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                  if ((usageAsync.value?.length ?? 0) > 0) ...[
                    const SizedBox(width: 5),
                    Text(
                      '${usageAsync.value!.length}',
                      style: PTypo.body.copyWith(
                        color: t.fgBrand,
                        fontWeight: PFontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  const Spacer(),
                  InkWell(
                    borderRadius: PRadius.brSm,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/expense?assetId=${asset.rowId}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.assetViewAll,
                            style: PTypo.bodySm.copyWith(
                              color: t.fgSecondary,
                              fontWeight: PFontWeight.semi,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(LucideIcons.chevronRight,
                              size: 12, color: t.fgSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // 정렬 — 통계 화면과 동일한 pills 탭(공용, 사용자 결정)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PTabs<_UsageSort>(
                    value: _sort,
                    variant: PTabsVariant.pills,
                    size: PTabsSize.sm,
                    items: [
                      PTabItem(
                          value: _UsageSort.recent, label: l.assetSortRecent),
                      PTabItem(
                          value: _UsageSort.amount, label: l.assetSortAmount),
                      PTabItem(
                          value: _UsageSort.category,
                          label: l.assetSortCategory),
                    ],
                    onChanged: (v) => setState(() => _sort = v),
                  ),
                ),
              ),
              if (_sort == _UsageSort.recent)
                // 정렬 탭 ↔ 첫 날짜 그룹 간격 — 웹 paddingTop 16 정합(사용자 결정)
                Padding(
                  padding: const EdgeInsets.only(top: PSpace.x16),
                  child: _RecentExpenses(
                      async: usageAsync, masked: masked, tokens: t),
                )
              else
                Builder(builder: (context) {
                  final list = [...(usageAsync.value ?? const <Expense>[])];
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          l.assetNoUsage,
                          style:
                              PTypo.bodySm.copyWith(color: t.fgTertiary),
                        ),
                      ),
                    );
                  }
                  if (_sort == _UsageSort.amount) {
                    list.sort(
                        (a, b) => b.amount.abs().compareTo(a.amount.abs()));
                  } else {
                    list.sort((a, b) => (a.categoryName ?? '')
                        .compareTo(b.categoryName ?? ''));
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      children: [
                        for (final e in list)
                          _ExpenseRow(
                              expense: e, masked: masked, tokens: t),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

/// 빠른 액션 타일 — sunken 박스 + 아이콘 30 박스(surface) + 라벨(design cdt-action).
class _CardActionTile extends StatelessWidget {
  const _CardActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        borderRadius: PRadius.brLg,
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          decoration: BoxDecoration(
            color: t.bgSunken,
            borderRadius: PRadius.brLg,
          ),
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: t.bgSurface,
                  borderRadius: PRadius.brMd,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 15, color: t.fgSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypo.caption.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 'yyyy-MM-dd' → 'M.d' 표기.
String _fmtDate(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (m == null || d == null) return iso;
  return '$m.$d';
}

/// stats 차트와 동일한 만/억 단위 — 한글 단위가 KRW 와 어울리고
/// '4.3M'/'-40.4M' 보다 짧게 표현돼 reservedSize 안에 안전히 들어간다.

String _currentYearMonth() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}';
}
