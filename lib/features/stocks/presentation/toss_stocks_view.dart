import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/core/format/change_rate.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/chart_web_view.dart';
import 'package:groo_damda_app/features/stocks/presentation/stock_market_label.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_donut.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/searchable_list/p_searchable_list.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';

/// 증권 — 시세 · 보유 · 관심 · 호가 (토스증권 Open API 실연동).
///
/// 폰 목록은 띠 셋이다 — 내 투자 → 시장 → 종목(I-13 B). 종목 상세와 포트폴리오 구성은 화면(주소)이다
/// (`/stocks/toss/:symbol` · `/stocks/toss/portfolio` — 3-B).
/// 상승 = 빨강(`fg-critical`) / 하락 = 파랑(`fg-informative`) — 국내 증권 통념, Delta 가 그대로 쓴다.
class TossStocksView extends ConsumerStatefulWidget {
  const TossStocksView({super.key});

  @override
  ConsumerState<TossStocksView> createState() => _TossStocksViewState();
}

enum _Seg { holdings, watch, discover }

/// 숫자 정렬용 tabular figures.
const List<FontFeature> _tnum = [FontFeature.tabularFigures()];

String _detailPath(String symbol) =>
    '/stocks/toss/${Uri.encodeComponent(symbol)}';

class _TossStocksViewState extends ConsumerState<TossStocksView> {
  _Seg _seg = _Seg.holdings;
  Timer? _priceTimer;

  /// 화면에 들어와 300ms 머문 관심 그룹 — 이 그룹들의 심볼만 합쳐 시세를 부른다(I-13 22).
  final Set<int> _visible = {};
  final Map<int, Timer> _lingering = {};

  /// 받은 시세 — 그룹이 화면 밖으로 나가 부르기를 멈춰도 받은 값은 남긴다.
  final Map<String, double> _lastPrices = {};

  @override
  void initState() {
    super.initState();
    // 라이브 갱신 — 10초마다 지켜보는 키만 다시 부른다(family invalidate). prevClose 는 하루 단위라 제외.
    _priceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      ref.invalidate(tossPricesProvider);
      ref.invalidate(tossOrderbookProvider);
      ref.invalidate(tossTradesProvider);
      ref.invalidate(tossCandlesProvider);
      ref.invalidate(tossHoldingsProvider);
    });
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    for (final t in _lingering.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _blockShown(int id) {
    if (_visible.contains(id) || _lingering.containsKey(id)) return;
    _lingering[id] = Timer(const Duration(milliseconds: 300), () {
      _lingering.remove(id);
      if (mounted) setState(() => _visible.add(id));
    });
  }

  void _blockHidden(int id) {
    _lingering.remove(id)?.cancel();
    if (_visible.contains(id) && mounted) {
      setState(() => _visible.remove(id));
    }
  }

  void _openSearch() => showStockSearchSheet(
    context,
    onPick: (symbol) => context.push(_detailPath(symbol)),
  );

  void _openDetail(String symbol) => context.push(_detailPath(symbol));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final masked = ref.watch(hideCardProvider('stocks.summary'));
    final holdingsAsync = ref.watch(tossHoldingsProvider);
    final fxRaw = ref.watch(tossExchangeRateProvider).asData?.value?.rateValue;
    final fx = (fxRaw != null && fxRaw > 0) ? fxRaw : null;
    final holdings = holdingsAsync.asData?.value;
    final holdingItems = sortHoldings(holdings?.items ?? const [], fx);
    final watchAsync = ref.watch(watchGroupsProvider);
    final groups = watchAsync.asData?.value ?? const <StockWatchGroup>[];

    // 보이는 그룹의 심볼을 합쳐 50 씩 한 번에 — 그룹마다 따로 부르지 않는다.
    final symbols = visibleSymbols(groups, _visible);
    for (final chunk in chunkSymbols(symbols)) {
      final prices =
          ref.watch(tossPricesProvider(chunk.join(','))).asData?.value ??
          const <TossPrice>[];
      for (final p in prices) {
        final v = double.tryParse(p.lastPrice);
        if (v != null && v > 0) _lastPrices[p.symbol] = v;
      }
    }

    final head = <Widget>[
      _InvestBand(
        holdingsAsync: holdingsAsync,
        masked: masked,
        onRetry: () {
          ref.invalidate(tossAccountsProvider);
          ref.invalidate(tossHoldingsProvider);
        },
      ),
      const SizedBox(height: kScreenBandGap),
      const _MarketBand(),
      const SizedBox(height: kScreenBandGap),
    ];

    final tabs = ColoredBox(
      color: c.bgLayerDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BandTitle(l.stocksSectionStocks),
          _SearchEntry(onTap: _openSearch),
          Padding(
            padding: const EdgeInsets.only(top: PSpacing.x2),
            child: PChipTabs<_Seg>(
              value: _seg,
              onChanged: (v) => setState(() => _seg = v),
              semanticLabel: l.stocksSectionStocks,
              items: [
                PTab(value: _Seg.holdings, label: l.stocksTabHoldings),
                PTab(value: _Seg.watch, label: l.stocksTabWatch),
                PTab(value: _Seg.discover, label: l.stocksTabDiscover),
              ],
            ),
          ),
        ],
      ),
    );

    final tail = ColoredBox(
      color: c.bgLayerDefault,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.x6,
          PSpacing.x2,
          PSpacing.x6,
          PSpacing.x6,
        ),
        child: Text(
          l.stocksSourceNotice,
          style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
        ),
      ),
    );

    // 관심 갈래는 게으른 sliver — 지어진 묶음만 시세를 지켜본다. 나머지는 한 덩어리.
    final slivers = <Widget>[
      SliverList(delegate: SliverChildListDelegate(head)),
      SliverToBoxAdapter(child: tabs),
    ];
    if (_seg == _Seg.watch) {
      if (watchAsync.hasError && !watchAsync.hasValue) {
        slivers.add(
          SliverToBoxAdapter(
            child: _Failure(
              title: l.stocksFailWatch,
              onRetry: () => ref.invalidate(watchGroupsProvider),
            ),
          ),
        );
      } else if (watchAsync.isLoading && !watchAsync.hasValue) {
        slivers.add(const SliverToBoxAdapter(child: _GroupSkeleton()));
      } else if (groups.isEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: ColoredBox(
              color: c.bgLayerDefault,
              child: PResultSection(
                kind: PResultKind.empty,
                size: PResultSize.medium,
                icon: LucideIcons.star,
                title: l.stocksNoWatchlist,
                description: l.stocksNoWatchlistDesc,
                headingLevel: 3,
              ),
            ),
          ),
        );
      } else {
        slivers.add(
          SliverList.builder(
            itemCount: groups.length + 1,
            itemBuilder: (context, i) {
              if (i == groups.length) {
                return ColoredBox(
                  color: c.bgLayerDefault,
                  child: PList(
                    children: [
                      PListButtonItem(
                        title: l.stocksWatchGroupAdd,
                        titleColor: c.fgBrand,
                        prefix: Icon(
                          LucideIcons.plus,
                          size: 20,
                          color: c.fgBrand,
                        ),
                        onTap: () => showWatchGroupForm(context, ref),
                      ),
                    ],
                  ),
                );
              }
              final g = groups[i];
              return _WatchGroupBlock(
                key: ValueKey('watch-group-${g.rowId}'),
                group: g,
                first: i == 0,
                prices: _lastPrices,
                onShown: () => _blockShown(g.rowId),
                onHidden: () => _blockHidden(g.rowId),
                onTap: _openDetail,
              );
            },
          ),
        );
      }
    } else {
      slivers.add(
        SliverToBoxAdapter(
          child: ColoredBox(
            color: c.bgLayerDefault,
            child: _seg == _Seg.discover
                ? _DiscoverPanel(onPick: _openDetail)
                : _HoldingsList(
                    async: holdingsAsync,
                    items: holdingItems,
                    masked: masked,
                    onTap: _openDetail,
                    onRetry: () {
                      ref.invalidate(tossAccountsProvider);
                      ref.invalidate(tossHoldingsProvider);
                    },
                  ),
          ),
        ),
      );
    }
    slivers.add(SliverToBoxAdapter(child: tail));
    return CustomScrollView(slivers: slivers);
  }
}

// ---- 공용 조각 --------------------------------------------------------------

/// 띠 구역 제목 — 위 24 · 좌우 24 · 아래 4 (R4 t5 · 700).
class _BandTitle extends StatelessWidget {
  const _BandTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.x6,
        PSpacing.x6,
        PSpacing.x6,
        PSpacing.x1,
      ),
      child: Semantics(
        header: true,
        headingLevel: 2,
        child: Text(
          text,
          style: PTypography.t5.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.fgNeutral,
          ),
        ),
      ),
    );
  }
}

PDeltaDirection _dir(StockDirection d) => switch (d) {
  StockDirection.up => PDeltaDirection.up,
  StockDirection.down => PDeltaDirection.down,
  StockDirection.flat => PDeltaDirection.flat,
};

/// 등락률 Delta — ▲/▼ + "12.23%". 0 이면 "0.00%" 화살표 없이 옅은 색.
class _PctDelta extends StatelessWidget {
  const _PctDelta(this.pct);
  final double pct;

  @override
  Widget build(BuildContext context) {
    final d = directionOfPct(pct);
    if (d == StockDirection.flat) {
      return Text(
        '0.00%',
        style: PTypography.t3.copyWith(
          color: context.colors.fgNeutralSubtle,
          fontWeight: FontWeight.w500,
          fontFeatures: _tnum,
        ),
      );
    }
    return PDelta(direction: _dir(d), value: formatChangeRateAbs(pct));
  }
}

/// 손익 금액 + 수익률 Delta ("▲ 338,749,027원 · 10.26%") — 가리면 금액 대신 점.
PDelta _pnlDelta(int pnl, double pct, bool masked, {String? text}) {
  final d = directionOf(pnl.toDouble());
  final amount = masked ? '••••' : krwSigned(pnl.abs(), false, unit: true);
  return PDelta(
    direction: _dir(d),
    value: d == StockDirection.flat
        ? null
        : '$amount · ${formatChangeRateAbs(pct)}',
    text: text,
  );
}

TextStyle _moneyStyle(BuildContext context) => PTypography.t5.copyWith(
  fontWeight: FontWeight.w700,
  color: context.colors.fgNeutral,
  fontFeatures: _tnum,
);

/// 종목 줄 — ds List 누르는 줄. 앞 타일 없음(1T-다), 뒤 = 금액 + Delta.
class _StockLine extends StatelessWidget {
  const _StockLine({
    required this.name,
    required this.detail,
    required this.onTap,
    this.amount,
    this.pct,
    this.rank,
    this.topRank = false,
  });

  final String name;
  final String detail;
  final VoidCallback onTap;
  final String? amount;
  final double? pct;
  final int? rank;
  final bool topRank;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = MediaQuery.sizeOf(context).width;
    return PListButtonItem(
      title: name,
      detail: detail,
      onTap: onTap,
      prefix: rank == null
          ? null
          : SizedBox(
              width: 20,
              child: Text(
                '$rank',
                style: PTypography.t4.copyWith(
                  fontWeight: FontWeight.w700,
                  color: topRank ? c.fgBrand : c.fgNeutralSubtle,
                  fontFeatures: _tnum,
                ),
              ),
            ),
      suffix: PListValue(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: w * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                keepAllAmount(amount ?? '—'),
                textAlign: TextAlign.right,
                style: _moneyStyle(context),
              ),
              if (pct != null) ...[const SizedBox(height: 2), _PctDelta(pct!)],
            ],
          ),
        ),
      ),
    );
  }
}

/// 구역 실패 한 벌 — 제목 + "잠시 뒤 다시 시도해주세요." + [다시 시도]. 오류 원문은 그리지 않는다.
class _Failure extends StatelessWidget {
  const _Failure({required this.title, required this.onRetry});
  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ColoredBox(
      color: context.colors.bgLayerDefault,
      child: PResultSection(
        kind: PResultKind.failure,
        size: PResultSize.medium,
        title: title,
        description: l.stocksFailDesc,
        primaryAction: PResultAction(label: l.actionRetry, onPressed: onRetry),
        headingLevel: 3,
      ),
    );
  }
}

/// 목록 줄 Skeleton — 제목 · 설명 · 오른쪽 두 줄.
class _LineSkeleton extends StatelessWidget {
  const _LineSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.x6,
        vertical: PSpacing.x3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PSkeleton(width: 120, height: 16),
                const SizedBox(height: 4),
                PSkeleton(width: 80, height: 13),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PSkeleton(width: 84, height: 16),
              const SizedBox(height: 4),
              PSkeleton(width: 52, height: 13),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupSkeleton extends StatelessWidget {
  const _GroupSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).stocksRankingLoading,
      child: ColoredBox(
        color: context.colors.bgLayerDefault,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.x6,
                PSpacing.x2,
                PSpacing.x6,
                PSpacing.x2,
              ),
              child: PSkeleton(width: 96, height: 19),
            ),
            for (var i = 0; i < 3; i++) const _LineSkeleton(),
          ],
        ),
      ),
    );
  }
}

/// 찾는 칸(입구) — Searchable List 칸 모양의 단추. 누르면 찾기 시트(밑줄형 large 40 · 돋보기 24 · 글 t6).
class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.x6,
        PSpacing.x2,
        PSpacing.x6,
        0,
      ),
      child: Semantics(
        button: true,
        label: l.stocksSearch,
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.strokeNeutralWeak)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 24, color: c.fgNeutralSubtle),
                const SizedBox(width: PSpacing.x2),
                Expanded(
                  child: Text(
                    l.stocksSearchPlaceholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypography.t6.copyWith(color: c.fgPlaceholder),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- 띠 ① 내 투자 -------------------------------------------------------------

class _InvestBand extends ConsumerWidget {
  const _InvestBand({
    required this.holdingsAsync,
    required this.masked,
    required this.onRetry,
  });

  final AsyncValue<TossHoldings?> holdingsAsync;
  final bool masked;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (holdingsAsync.hasError && !holdingsAsync.hasValue) {
      return PScreenSection(
        padding: EdgeInsets.zero,
        child: _Failure(title: l.stocksFailInvest, onRetry: onRetry),
      );
    }
    if (holdingsAsync.isLoading && !holdingsAsync.hasValue) {
      return PScreenSection(
        padding: const EdgeInsets.symmetric(vertical: PSpacing.x6),
        child: Semantics(
          label: l.stocksMyEval,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.stocksMyEval,
                  style: PTypography.t3.copyWith(
                    color: c.fgNeutralSubtle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: PSpacing.x1),
                PSkeleton(width: 200, height: 32),
                const SizedBox(height: PSpacing.x1),
                PSkeleton(width: 160, height: 18),
              ],
            ),
          ),
        ),
      );
    }
    final h = holdingsAsync.asData?.value;
    final s = h == null
        ? const InvestSummary(
            evalAmount: 0,
            purchaseAmount: 0,
            pnl: 0,
            pnlPct: 0,
            dailyPnl: 0,
            dailyPnlPct: 0,
            count: 0,
          )
        : investSummaryOf(h);
    String money(int v) => masked ? '••••' : krwSigned(v, false, unit: true);
    return PScreenSection(
      padding: const EdgeInsets.only(top: PSpacing.x6, bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: PCardStat(
              label: l.stocksMyEval,
              value: money(s.evalAmount),
              delta: _pnlDelta(
                s.pnl,
                s.pnlPct,
                masked,
                text: l.stocksVsPurchase,
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x3),
          PList(
            children: [
              PListItem(
                title: l.stocksPurchaseAmount,
                titleColor: c.fgNeutralSubtle,
                suffix: PListValue.amount(
                  money(s.purchaseAmount),
                  style: _moneyStyle(context),
                ),
              ),
              PListItem(
                title: l.stocksDayPnl,
                titleColor: c.fgNeutralSubtle,
                suffix: PListValue(
                  child: _pnlDelta(s.dailyPnl, s.dailyPnlPct, masked),
                ),
              ),
              PListItem(
                title: l.stocksHoldingsLabel,
                titleColor: c.fgNeutralSubtle,
                suffix: PListValue(
                  child: Text(
                    l.stocksUnitCount(s.count),
                    style: _moneyStyle(context),
                  ),
                ),
              ),
              PListButtonItem(
                title: l.stocksPortfolioTitle,
                detail: l.stocksPortfolioSub,
                prefix: PListTile(
                  background: c.bgNeutralWeak,
                  color: c.fgNeutral,
                  child: const Icon(LucideIcons.chartPie),
                ),
                suffix: Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: c.fgNeutralSubtle,
                ),
                onTap: () => context.push('/stocks/toss/portfolio'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- 띠 ② 시장 ---------------------------------------------------------------

class _MarketBand extends ConsumerWidget {
  const _MarketBand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final indices = (ref.watch(tossIndicatorPricesProvider).asData?.value ?? [])
        .where((i) => i.priceValue > 0 && indexNameOf(l, i.symbol) != null)
        .toList();
    final fxRaw = ref.watch(tossExchangeRateProvider).asData?.value?.rateValue;
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BandTitle(l.stocksSectionMarket),
          const _MarketStatusLine(),
          const SizedBox(height: PSpacing.x1),
          PList(
            children: [
              for (final i in indices) _IndexLine(index: i),
              if (fxRaw != null && fxRaw > 0)
                PListItem(
                  title: l.stocksExchangeRate,
                  detail: l.stocksFxBasis,
                  suffix: PListValue.amount(
                    fmtFxRate(fxRaw),
                    style: _moneyStyle(context),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 장 상태 줄 — "● 국내 장마감   ● 미국 개장 22:30". 줄바꿈 허용(항목 사이 16 · 줄 사이 4).
class _MarketStatusLine extends ConsumerWidget {
  const _MarketStatusLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final krCal = ref.watch(tossMarketCalendarKrProvider).asData?.value;
    final usCal = ref.watch(tossMarketCalendarUsProvider).asData?.value;
    final kr = _marketState(krCal?.today.regularMarket, _Tz.kr, l);
    final us = _marketState(usCal?.today.regularMarket, _Tz.us, l);
    final markets = [
      (name: l.stocksMarketKr, open: kr.open, detail: kr.detail),
      (name: l.stocksMarketUs, open: us.open, detail: us.detail),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
      child: Wrap(
        spacing: PSpacing.x4,
        runSpacing: 4,
        children: [
          for (final m in markets)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: m.open ? c.fgPositive : c.strokeNeutralSolid,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: m.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: c.fgNeutral,
                          ),
                        ),
                        TextSpan(text: ' ${m.detail}'),
                      ],
                    ),
                    style: PTypography.t4.copyWith(
                      color: c.fgNeutralSubtle,
                      fontFeatures: _tnum,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 지수 줄 — 이름 + 추이선 56×20 + 포인트 / Delta(그 구간 시작 대비 %).
class _IndexLine extends ConsumerWidget {
  const _IndexLine({required this.index});
  final TossIndicatorPrice index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final closes =
        ref.watch(tossIndicatorClosesProvider(index.symbol)).asData?.value ??
        const <double>[];
    double? pct;
    if (closes.length >= 2 && closes.first > 0) {
      pct = (closes.last - closes.first) / closes.first * 100;
    }
    final up = (pct ?? 0) >= 0;
    return PListItem(
      title: indexNameOf(l, index.symbol)!,
      verticalPadding: 10,
      suffix: PListValue(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (closes.length >= 2)
              ExcludeSemantics(
                child: SizedBox(
                  width: 56,
                  height: 20,
                  child: CustomPaint(
                    painter: _SparkPainter(
                      closes,
                      up ? c.fgCritical : c.fgInformative,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: PSpacing.x2),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmtIndexPoint(index.priceValue),
                  style: _moneyStyle(context),
                ),
                if (pct != null) ...[const SizedBox(height: 2), _PctDelta(pct)],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = values.first, hi = values.first;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - lo) / span * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.color != color || old.values != values;
}

// ---- 띠 ③ 종목 · 보유 ---------------------------------------------------------

class _HoldingsList extends StatelessWidget {
  const _HoldingsList({
    required this.async,
    required this.items,
    required this.masked,
    required this.onTap,
    required this.onRetry,
  });

  final AsyncValue<TossHoldings?> async;
  final List<TossHoldingsItem> items;
  final bool masked;
  final void Function(String symbol) onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (async.hasError && !async.hasValue) {
      return _Failure(title: l.stocksFailHoldings, onRetry: onRetry);
    }
    if (async.isLoading && !async.hasValue) {
      return Semantics(
        label: l.stocksRankingLoading,
        child: Column(
          children: [for (var i = 0; i < 5; i++) const _LineSkeleton()],
        ),
      );
    }
    if (items.isEmpty) {
      return PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.medium,
        icon: LucideIcons.wallet,
        title: l.stocksNoHoldings,
        headingLevel: 3,
      );
    }
    return PList(
      semanticLabel: l.stocksTabHoldings,
      children: [
        for (final h in items)
          _StockLine(
            name: h.name.isNotEmpty ? h.name : h.symbol,
            detail:
                '${h.symbol} · ${l.stocksSharesUnit(_qty(h.quantityValue))}',
            amount: masked
                ? '••••'
                : fmtByCurrency(h.marketValueAmountValue, h.currency),
            pct: h.profitLossRateValue,
            onTap: () => onTap(h.symbol),
          ),
      ],
    );
  }
}

String _qty(double q) =>
    q == q.roundToDouble() ? '${q.round()}' : q.toStringAsFixed(4);

// ---- 관심 그룹 -----------------------------------------------------------------

/// 그룹 하나 — 목록 제목("{이름} · {n}" + ⋮) + 줄. 지어지면 보인다고 알리고(시세 부르기) 사라지면 알린다.
class _WatchGroupBlock extends ConsumerStatefulWidget {
  const _WatchGroupBlock({
    super.key,
    required this.group,
    required this.first,
    required this.prices,
    required this.onShown,
    required this.onHidden,
    required this.onTap,
  });

  final StockWatchGroup group;
  final bool first;
  final Map<String, double> prices;
  final VoidCallback onShown;
  final VoidCallback onHidden;
  final void Function(String symbol) onTap;

  @override
  ConsumerState<_WatchGroupBlock> createState() => _WatchGroupBlockState();
}

class _WatchGroupBlockState extends ConsumerState<_WatchGroupBlock> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onShown();
    });
  }

  @override
  void dispose() {
    widget.onHidden();
    super.dispose();
  }

  Future<void> _more() async {
    final l = AppLocalizations.of(context);
    final g = widget.group;
    final rename = PMenuSheetItem(
      label: l.stocksWatchGroupRenameItem,
      icon: LucideIcons.pencil,
    );
    final del = PMenuSheetItem(
      label: l.stocksWatchGroupDelete,
      icon: LucideIcons.trash2,
      tone: PMenuSheetTone.critical,
    );
    final picked = await PMenuSheet.show(
      context,
      semanticLabel: l.stocksWatchGroupMore(g.groupName),
      groups: [
        PMenuSheetGroup([rename, del]),
      ],
    );
    if (!mounted || picked == null) return;
    if (identical(picked, rename)) {
      await showWatchGroupForm(context, ref, group: g);
    } else if (identical(picked, del)) {
      await confirmDeleteWatchGroup(context, ref, g);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final g = widget.group;
    return ColoredBox(
      color: c.bgLayerDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PListHeader(
            title: l.stocksWatchGroupTitle(g.groupName, g.items.length),
            variant: PListHeaderVariant.boldSolid,
            headingLevel: 3,
            topInset: widget.first ? PSpacing.x2 : PSpacing.x4,
            action: PButton.icon(
              icon: LucideIcons.ellipsisVertical,
              semanticLabel: l.stocksWatchGroupMore(g.groupName),
              variant: PButtonVariant.ghost,
              size: PButtonSize.medium,
              onPressed: _more,
            ),
          ),
          if (g.items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.x6,
                PSpacing.x1,
                PSpacing.x6,
                PSpacing.x3,
              ),
              child: Text(
                l.stocksWatchGroupEmpty,
                style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
              ),
            )
          else
            PList(
              semanticLabel: g.groupName,
              children: [
                for (final item in g.items)
                  _WatchLine(
                    item: item,
                    last: widget.prices[item.symbol],
                    onTap: () => widget.onTap(item.symbol),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 관심 줄 — 전일 종가는 이 줄이 지어졌을 때(= 보이는 묶음)만 부른다.
class _WatchLine extends ConsumerWidget {
  const _WatchLine({
    required this.item,
    required this.last,
    required this.onTap,
  });

  final WatchItem item;
  final double? last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final prevClose = last == null
        ? null
        : ref.watch(prevCloseProvider(item.symbol)).asData?.value;
    return _StockLine(
      name: item.nameKr.isNotEmpty ? item.nameKr : item.symbol,
      detail: '${item.symbol} · ${stockMarketLabel(l, item.marketCode)}',
      amount: last == null ? null : fmtByCurrency(last!, item.currency),
      pct: changePctOf(last, prevClose),
      onTap: onTap,
    );
  }
}

/// 그룹 추가 · 이름 바꾸기 폼 — Bottom Sheet. 바깥 누름 · 끌기로 닫히지 않고, 바뀐 값이 있으면 닫기 전에 묻는다.
Future<void> showWatchGroupForm(
  BuildContext context,
  WidgetRef ref, {
  StockWatchGroup? group,
}) {
  final l = AppLocalizations.of(context);
  final probe = _FormProbe();
  return PBottomSheet.show<void>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => _GroupForm(group: group, probe: probe),
  );
}

class _FormProbe {
  bool Function() dirty = () => false;
}

class _GroupForm extends ConsumerStatefulWidget {
  const _GroupForm({required this.group, required this.probe});
  final StockWatchGroup? group;
  final _FormProbe probe;

  @override
  ConsumerState<_GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends ConsumerState<_GroupForm> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.group?.groupName ?? '',
  );
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.probe.dirty = () =>
        _ctrl.text.trim() != (widget.group?.groupName ?? '').trim();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(stocksRepositoryProvider.future);
      final g = widget.group;
      if (g == null) {
        await repo.createWatchGroup(name);
      } else {
        await repo.renameWatchGroup(g.rowId, name);
      }
      ref.invalidate(watchGroupsProvider);
      if (mounted) {
        widget.probe.dirty = () => false;
        PBottomSheet.of(context).close();
      }
    } on ApiException {
      // 서버 에러는 ErrorToastInterceptor 가 띄운다.
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showPSnackBar(
          context,
          AppLocalizations.of(context).stocksWatchGroupSaveFail,
          severity: PSnackSeverity.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canSave = _ctrl.text.trim().isNotEmpty && !_busy;
    return PBottomSheetContent(
      title: widget.group == null
          ? l.stocksWatchGroupAdd
          : l.stocksWatchGroupRename,
      closeLabel: l.actionClose,
      flushBody: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
        child: PField(
          label: l.stocksWatchGroupNamePlaceholder,
          child: PInput(
            controller: _ctrl,
            autofocus: true,
            semanticLabel: l.stocksWatchGroupNamePlaceholder,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
        ),
      ),
      footer: [
        PButton(
          label: l.actionSave,
          size: PButtonSize.large,
          loading: _busy,
          onPressed: canSave ? _save : null,
        ),
      ],
    );
  }
}

/// 그룹 삭제 확인 — Alert Dialog. 삭제 요청 · 실패 길은 지금 그대로.
Future<void> confirmDeleteWatchGroup(
  BuildContext context,
  WidgetRef ref,
  StockWatchGroup g,
) async {
  final l = AppLocalizations.of(context);
  await PAlertDialog.show(
    context,
    title: l.stocksWatchGroupDelete,
    description: g.items.isEmpty
        ? l.stocksWatchGroupDeleteConfirmEmpty(g.groupName)
        : l.stocksWatchGroupDeleteConfirmCount(g.groupName, g.items.length),
    cancelLabel: l.actionCancel,
    actionLabel: l.stocksWatchGroupDelete,
    destructive: true,
    onAction: () async {
      final repo = await ref.read(stocksRepositoryProvider.future);
      await repo.deleteWatchGroup(g.rowId);
      ref.invalidate(watchGroupsProvider);
    },
    onActionError: (e) {
      if (e is ApiException || !context.mounted) return;
      showPSnackBar(
        context,
        l.stocksWatchGroupSaveFail,
        severity: PSnackSeverity.error,
      );
    },
  );
}

/// 관심 별 토글(Q3-B) — 어느 그룹에든 있으면 전부 해제, 없으면 그룹이 하나면 바로 · 둘 이상이면 시트로 고른 그룹에
/// 담는다(그룹이 없으면 기본 그룹부터 만든다).
Future<void> toggleWatch(
  BuildContext context,
  WidgetRef ref,
  String symbol, {
  String? marketCode,
}) async {
  final l = AppLocalizations.of(context);
  final groups =
      ref.read(watchGroupsProvider).asData?.value ?? const <StockWatchGroup>[];
  try {
    final repo = await ref.read(stocksRepositoryProvider.future);
    final entries = [
      for (final g in groups) ...g.items.where((i) => i.symbol == symbol),
    ];
    if (entries.isNotEmpty) {
      for (final e in entries) {
        await repo.removeWatchItem(e.rowId);
      }
    } else if (groups.isEmpty) {
      final g = await repo.createWatchGroup(l.stocksWatchDefaultGroupName);
      await repo.addWatchItem(g.rowId, symbol, marketCode: marketCode);
    } else if (groups.length == 1) {
      await repo.addWatchItem(
        groups.first.rowId,
        symbol,
        marketCode: marketCode,
      );
    } else {
      final byItem = <PMenuSheetItem, StockWatchGroup>{
        for (final g in groups)
          PMenuSheetItem(
            label: l.stocksWatchGroupTitle(g.groupName, g.items.length),
          ): g,
      };
      if (!context.mounted) return;
      final picked = await PMenuSheet.show(
        context,
        title: l.stocksWatchPickGroup,
        layout: PMenuSheetLayout.textOnly,
        groups: [PMenuSheetGroup(byItem.keys.toList())],
      );
      final target = picked == null ? null : byItem[picked];
      if (target == null) return;
      await repo.addWatchItem(target.rowId, symbol, marketCode: marketCode);
    }
    ref.invalidate(watchGroupsProvider);
  } on ApiException {
    // 서버 에러는 ErrorToastInterceptor 가 띄운다.
  } catch (_) {
    if (context.mounted) {
      showPSnackBar(
        context,
        l.stocksWatchAddFail,
        severity: PSnackSeverity.error,
      );
    }
  }
}

// ---- 종목 찾기 (Searchable List · Bottom Sheet) --------------------------------

/// 종목 찾기 시트 — 서버 검색은 마지막 입력 뒤 300ms 에 한 번. 줄은 상세로 가는 줄(라디오 없음).
Future<void> showStockSearchSheet(
  BuildContext context, {
  required void Function(String symbol) onPick,
}) {
  final focus = FocusNode(debugLabel: 'stock search');
  return PBottomSheet.show<String>(
    context,
    initialFocus: focus,
    builder: (_) => _StockSearchSheet(searchFocus: focus),
  ).then((symbol) {
    focus.dispose();
    if (symbol != null) onPick(symbol);
  });
}

class _StockSearchSheet extends ConsumerStatefulWidget {
  const _StockSearchSheet({required this.searchFocus});
  final FocusNode searchFocus;

  @override
  ConsumerState<_StockSearchSheet> createState() => _StockSearchSheetState();
}

class _StockSearchSheetState extends ConsumerState<_StockSearchSheet> {
  String _typed = '';
  String _sent = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final query = _typed.trim();
    final async = ref.watch(stockSearchResultProvider(_sent));
    final results = async.value ?? const <StockMasterItem>[];
    final failed = async.hasError && results.isEmpty;
    final fetching = async.isLoading && !async.hasError && results.isEmpty;
    Widget? body;
    if (query.isNotEmpty && !failed) {
      body = fetching
          ? const PSearchableListSkeleton()
          : PSearchableListResults(
              scrollFog: true,
              semanticLabel: l.stocksSearch,
              children: [
                for (final s in results)
                  PSearchableListItem(
                    value: s.symbol,
                    title: s.nameKr.isNotEmpty ? s.nameKr : s.symbol,
                    detail:
                        '${s.symbol} · ${stockMarketLabel(l, s.marketCode)}'
                        ' · ${stockSecurityTypeLabel(l, s.securityType)}',
                  ),
              ],
            );
    }
    return PBottomSheetContent(
      title: l.stocksSearch,
      closeLabel: l.actionClose,
      flushBody: true,
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: PSearchableList(
          selectionMark: PSearchableListSelectionMark.off,
          focusNode: widget.searchFocus,
          query: _typed,
          onQueryChanged: (q) => setState(() => _typed = q),
          onSearch: (q) => setState(() => _sent = q),
          onValueChanged: (v) => PBottomSheet.of(context).close(v),
          children: [
            PSearchableListInput(
              placeholder: l.stocksSearchPlaceholder,
              semanticLabel: l.actionSearch,
            ),
            if (query.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PSpacing.x6,
                  PSpacing.x4,
                  PSpacing.x6,
                  PSpacing.x6,
                ),
                child: Text(
                  l.stocksSearchHint,
                  style: PTypography.t4.copyWith(
                    color: context.colors.fgNeutralSubtle,
                  ),
                ),
              )
            else if (failed)
              PSearchableListError(
                title: l.stocksFailSearch,
                retryLabel: l.actionRetry,
                retrying: async.isLoading,
                onRetry: () => ref.invalidate(stockSearchResultProvider(_sent)),
              )
            else if (results.isEmpty && !fetching)
              PSearchableListEmpty(
                titleBuilder: (q) => l.stocksSearchNoResults(q),
              ),
            ?body,
          ],
        ),
      ),
    );
  }
}

// ---- 색 헬퍼 ---------------------------------------------------------------

/// 상승/하락 색 — 국내 증권 통념: 상승=빨강, 하락=파랑. (호가 · 체결 표가 쓴다)
Color _trendColor(GrooTokens t, double pct) =>
    pct >= 0 ? t.statusDangerFg : t.fgBrand;

// ---- 매수 유의사항 라벨 (토스 warningType → 한글) ----------------------------

/// 토스 warningType → 로케일 라벨 (웹 `warning.*` 키 미러). 모르는 타입은 원문 노출.
String _warningLabel(AppLocalizations l, String type) => switch (type) {
  'LIQUIDATION_TRADING' => l.stocksWarningLiquidationTrading,
  'OVERHEATED' => l.stocksWarningOverheated,
  'SHORT_TERM_OVERHEAT' => l.stocksWarningShortTermOverheat,
  'EXCESSIVE_RISE' => l.stocksWarningExcessiveRise,
  'INVESTMENT_WARNING' => l.stocksWarningInvestmentWarning,
  'INVESTMENT_RISK' => l.stocksWarningInvestmentRisk,
  'INVESTMENT_CAUTION' => l.stocksWarningInvestmentCaution,
  'VI' || 'VI_STATIC_AND_DYNAMIC' => l.stocksWarningVi,
  'VI_STATIC' => l.stocksWarningViStatic,
  'VI_DYNAMIC' => l.stocksWarningViDynamic,
  'STOCK_WARRANTS' => l.stocksWarningStockWarrants,
  'ADMINISTRATIVE' => l.stocksWarningAdministrative,
  'ADJUSTMENT_OF_SHARES' => l.stocksWarningAdjustmentOfShares,
  _ => type,
};

// ---- 장 상태 계산 (시장 현지 시각 vs 정규장 운영시간) -------------------------

enum _Tz { kr, us }

/// 'HH:MM:SS' → 'HH:MM'
String? _hhmm(String? s) =>
    (s != null && s.length >= 5) ? s.substring(0, 5) : null;

DateTime _nthSundayUtc(int year, int month, int n) {
  var d = DateTime.utc(year, month, 1);
  var count = 0;
  while (true) {
    if (d.weekday == DateTime.sunday) {
      count++;
      if (count == n) return d;
    }
    d = d.add(const Duration(days: 1));
  }
}

/// 미국 동부 서머타임 여부 (3월 둘째 일요일 02:00 ~ 11월 첫째 일요일 02:00).
bool _isUsEasternDst(DateTime utc) {
  final start = _nthSundayUtc(utc.year, 3, 2).add(const Duration(hours: 7));
  final end = _nthSundayUtc(utc.year, 11, 1).add(const Duration(hours: 6));
  return utc.isAfter(start) && utc.isBefore(end);
}

/// 시장 현지 시각(오전/오후 12시간) (KR=UTC+9, US 동부=DST 반영). 웹 `nowInTz` 미러.
String _nowInTz(_Tz tz) {
  final utc = DateTime.now().toUtc();
  final local = tz == _Tz.kr
      ? utc.add(const Duration(hours: 9))
      : utc.subtract(Duration(hours: _isUsEasternDst(utc) ? 4 : 5));
  return timeOfDay12(local);
}

({bool open, String detail}) _marketState(
  TossMarketSession? session,
  _Tz tz,
  AppLocalizations l,
) {
  final start = _hhmm(session?.startTime);
  final end = _hhmm(session?.endTime);
  if (start == null || end == null) {
    return (open: false, detail: l.stocksMarketHoliday);
  }
  final now = _nowInTz(tz);
  if (now.compareTo(start) >= 0 && now.compareTo(end) <= 0) {
    return (open: true, detail: l.stocksMarketTrading(now));
  }
  if (now.compareTo(start) < 0) {
    return (open: false, detail: l.stocksMarketOpensAt(start));
  }
  return (open: false, detail: l.stocksMarketClosed);
}

// ---- 발견(디스커버리) 랭킹 — 토스 rankings 실데이터 -----------------------------

class _RankLine extends ConsumerWidget {
  const _RankLine({
    required this.item,
    required this.index,
    required this.onPick,
  });
  final TossRankingItem item;
  final int index;
  final void Function(String symbol) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref
        .watch(tossStockInfoProvider(item.symbol))
        .asData
        ?.value
        ?.name;
    final last = item.price.lastPriceValue;
    return _StockLine(
      name: (name != null && name.isNotEmpty) ? name : item.symbol,
      detail: item.symbol,
      amount: last > 0 ? fmtByCurrency(last, item.currency) : null,
      pct: item.price.changePct,
      rank: item.rank,
      topRank: index < 3,
      onTap: () => onPick(item.symbol),
    );
  }
}

class _DiscoverPanel extends ConsumerStatefulWidget {
  const _DiscoverPanel({required this.onPick});
  final void Function(String ticker) onPick;

  @override
  ConsumerState<_DiscoverPanel> createState() => _DiscoverPanelState();
}

class _DiscoverPanelState extends ConsumerState<_DiscoverPanel> {
  String _tab = 'gainers';
  String _market = 'KR';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // TOP_GAINERS/LOSERS 는 realtime 미지원 → 1d, 거래량은 실시간.
    final type = _tab == 'gainers'
        ? 'TOP_GAINERS'
        : (_tab == 'losers' ? 'TOP_LOSERS' : 'MARKET_TRADING_VOLUME');
    final duration = _tab == 'volume' ? 'realtime' : '1d';
    final key = '$type|$_market|$duration';
    final rankingsAsync = ref.watch(tossRankingsProvider(key));
    final rankings = rankingsAsync.value?.rankings ?? const <TossRankingItem>[];
    final Widget body;
    if (rankingsAsync.hasError && !rankingsAsync.hasValue) {
      body = _Failure(
        title: l.stocksFailRanking,
        onRetry: () => ref.invalidate(tossRankingsProvider(key)),
      );
    } else if (rankingsAsync.isLoading && !rankingsAsync.hasValue) {
      body = Semantics(
        label: l.stocksRankingLoading,
        child: Column(
          children: [for (var i = 0; i < 10; i++) const _LineSkeleton()],
        ),
      );
    } else if (rankings.isEmpty) {
      body = PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.medium,
        icon: LucideIcons.chartNoAxesColumn,
        title: l.stocksRankingEmpty,
        headingLevel: 3,
      );
    } else {
      body = PList(
        children: [
          for (var i = 0; i < rankings.length; i++)
            _RankLine(item: rankings[i], index: i, onPick: widget.onPick),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            PSpacing.x2,
            PSpacing.x6,
            0,
          ),
          child: PSegmentedControl<String>(
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
            semanticLabel: l.stocksTabDiscover,
            items: [
              PSegmentedItem(value: 'gainers', label: l.stocksGainers),
              PSegmentedItem(value: 'losers', label: l.stocksLosers),
              PSegmentedItem(value: 'volume', label: l.stocksVolume),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            PSpacing.x2,
            PSpacing.x6,
            PSpacing.x2,
          ),
          child: PSegmentedControl<String>(
            value: _market,
            onChanged: (v) => setState(() => _market = v),
            semanticLabel: l.stocksSectionMarket,
            items: [
              PSegmentedItem(value: 'KR', label: l.stocksMarketToggleKr),
              PSegmentedItem(value: 'US', label: l.stocksMarketToggleUs),
            ],
          ),
        ),
        body,
      ],
    );
  }
}

// ---- 차트 기간 (식별자는 임베드 주소 값이라 그대로, 표시 글만 바꾼다) -------------

const _kRanges = ['1D', '1주', '1개월', '3개월', '1년'];

String _rangeLabel(AppLocalizations l, String range) => switch (range) {
  '1주' => l.stocksRange1w,
  '1개월' => l.stocksRange1m,
  '3개월' => l.stocksRange3m,
  '1년' => l.stocksRange1y,
  _ => l.stocksRange1d,
};

/// 심볼 정확 일치 마스터 항목 (KR/US 우선 — 시장 간 심볼 중복 대비).
StockMasterItem? _findMaster(List<StockMasterItem> items, String symbol) {
  final up = symbol.toUpperCase();
  final exact = [
    for (final s in items)
      if (s.symbol.toUpperCase() == up) s,
  ];
  if (exact.isEmpty) return null;
  for (final s in exact) {
    if (s.countryCode == 'KR' || s.countryCode == 'US') return s;
  }
  return exact.first;
}

// ---- 종목 상세 = 화면(3-B) -------------------------------------------------------

/// 종목 상세 화면 — 폰은 띠 다섯(머리 · 차트 / 내 보유 / 호가 · 체결 / 기본 정보 / 일별 시세 + 매매).
/// 주소 `/stocks/toss/:symbol` 만으로 열린다(목록 상태를 넘겨받지 않는다).
class TossStockDetailPage extends ConsumerStatefulWidget {
  const TossStockDetailPage({super.key, required this.symbol});
  final String symbol;

  @override
  ConsumerState<TossStockDetailPage> createState() =>
      _TossStockDetailPageState();
}

class _TossStockDetailPageState extends ConsumerState<TossStockDetailPage> {
  String _range = '1D';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 목록 화면이 위에 살아 있어도 이 화면이 보이는 동안의 호가 · 체결 · 캔들 · 시세를 10초마다 다시 부른다.
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      ref.invalidate(tossPricesProvider);
      ref.invalidate(tossOrderbookProvider);
      ref.invalidate(tossTradesProvider);
      ref.invalidate(tossCandlesProvider);
      ref.invalidate(tossHoldingsProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final masked = ref.watch(hideCardProvider('stocks.summary'));
    final symbol = widget.symbol;

    final master = _findMaster(
      ref.watch(stockSearchProvider(symbol)).asData?.value ??
          const <StockMasterItem>[],
      symbol,
    );
    final info = ref.watch(tossStockInfoProvider(symbol)).asData?.value;
    final holding = ref
        .watch(tossHoldingsProvider)
        .asData
        ?.value
        ?.items
        .where((h) => h.symbol == symbol)
        .firstOrNull;
    final groups =
        ref.watch(watchGroupsProvider).asData?.value ??
        const <StockWatchGroup>[];
    final watched = groups.any((g) => g.items.any((i) => i.symbol == symbol));
    final warnings =
        ref.watch(tossWarningsProvider(symbol)).asData?.value ??
        const <TossStockWarning>[];

    final name = master?.nameKr.isNotEmpty == true
        ? master!.nameKr
        : (info?.name.isNotEmpty == true
              ? info!.name
              : (holding?.name.isNotEmpty == true ? holding!.name : symbol));
    final currency = info?.currency.isNotEmpty == true
        ? info!.currency
        : (master?.currency.isNotEmpty == true
              ? master!.currency
              : (holding?.currency.isNotEmpty == true
                    ? holding!.currency
                    : 'KRW'));
    final isUs = currency == 'USD';

    final pricesAsync = ref.watch(tossPricesProvider(symbol));
    final lastRaw = pricesAsync.asData?.value.firstOrNull?.lastPrice;
    final lastParsed = lastRaw == null ? null : double.tryParse(lastRaw);
    final last = (lastParsed != null && lastParsed > 0) ? lastParsed : null;
    final prevClose = ref.watch(prevCloseProvider(symbol)).asData?.value;
    final changePct = changePctOf(last, prevClose);
    final fxRaw = ref.watch(tossExchangeRateProvider).asData?.value?.rateValue;
    final fxRate = (fxRaw != null && fxRaw > 0) ? fxRaw : null;

    final marketText = master != null
        ? stockMarketLabel(l, master.marketCode)
        : (info?.market ?? '');
    final typeText = info?.isEtf == true
        ? 'ETF'
        : stockSecurityTypeLabel(l, master?.securityType ?? 'STOCK');
    final sub = [
      symbol,
      if (marketText.isNotEmpty) marketText,
      typeText,
    ].join(' · ');

    final head = PScreenSection(
      padding: const EdgeInsets.all(PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name,
            style: PTypography.t7.copyWith(
              fontWeight: FontWeight.w700,
              color: c.fgNeutral,
            ),
          ),
          const SizedBox(height: 2),
          Text(sub, style: PTypography.t3.copyWith(color: c.fgNeutralSubtle)),
          const SizedBox(height: PSpacing.x4),
          Text(
            keepAllAmount(last != null ? fmtByCurrency(last, currency) : '—'),
            style: PTypography.t12.copyWith(
              fontWeight: FontWeight.w700,
              color: c.fgNeutral,
              fontFeatures: _tnum,
            ),
          ),
          if (changePct != null) ...[
            const SizedBox(height: PSpacing.x1),
            Align(alignment: Alignment.centerLeft, child: _PctDelta(changePct)),
          ],
          if (isUs && last != null && fxRate != null) ...[
            const SizedBox(height: 2),
            Text(
              '≈ ${krwSigned((last * fxRate).round(), false, unit: true)}',
              style: PTypography.t3.copyWith(
                color: c.fgNeutralSubtle,
                fontFeatures: _tnum,
              ),
            ),
          ],
          if (last == null && !pricesAsync.isLoading) ...[
            const SizedBox(height: 2),
            Text(
              l.stocksPriceUnavailable,
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: PSpacing.x2),
            Wrap(
              spacing: PSpacing.x1,
              runSpacing: PSpacing.x1,
              children: [
                for (final w in warnings)
                  PBadge(
                    label: _warningLabel(l, w.warningType),
                    tone: PBadgeTone.warning,
                  ),
              ],
            ),
          ],
          const SizedBox(height: PSpacing.x4),
          ChartWebView(symbol: symbol, isUs: isUs, range: _range, height: 168),
          const SizedBox(height: PSpacing.x3),
          // 기간 5칸 — Segmented 는 2 ~ 4칸이라 질문(I-13-1-app-result Q1) 전에는 Chip Tabs 로 둔다.
          PChipTabs<String>(
            value: _range,
            onChanged: (v) => setState(() => _range = v),
            semanticLabel: l.stocksDetailTitle,
            items: [
              for (final r in _kRanges)
                PTab(value: r, label: _rangeLabel(l, r)),
            ],
          ),
        ],
      ),
    );

    final bands = <Widget>[
      head,
      if (holding != null) _HoldingBand(holding: holding, masked: masked),
      _QuotesBand(
        symbol: symbol,
        currency: currency,
        lastPrice: last,
        changePct: changePct ?? 0,
      ),
      _InfoBand(
        symbol: symbol,
        currency: currency,
        info: info,
        lastPrice: last,
        fxRate: fxRate,
      ),
      _DailyBand(symbol: symbol, isUs: isUs, name: name),
    ];

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.stocksDetailTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/stocks'),
          ),
          actions: [
            PTopNavigationIconButton(
              icon: LucideIcons.star,
              label: l.stocksWatchToggleLabel,
              selected: watched,
              onPressed: () => toggleWatch(
                context,
                ref,
                symbol,
                marketCode: master?.marketCode,
              ),
            ),
          ],
        ),
      ),
      body: ListView(children: PScreenBands.children(bands)),
    );
  }
}

/// 키-값 줄 — 키는 옅게, 값은 오른쪽 굵게. 보기만 하는 줄.
Widget _kvLine(
  BuildContext context,
  String key,
  String value, {
  Color? valueColor,
  Widget? valueWidget,
}) {
  final c = context.colors;
  return PListItem(
    title: key,
    titleColor: c.fgNeutralSubtle,
    suffix: PListValue(
      child:
          valueWidget ??
          Text(
            keepAllAmount(value),
            textAlign: TextAlign.right,
            style: _moneyStyle(context).copyWith(color: valueColor),
          ),
    ),
  );
}

/// 띠 ② 내 보유 — 한 줄에 하나. 손익 · 수익률 · 일간 손익은 Delta, 금액은 굵은 고정폭.
class _HoldingBand extends StatelessWidget {
  const _HoldingBand({required this.holding, required this.masked});
  final TossHoldingsItem holding;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final h = holding;
    final cur = h.currency.isEmpty ? 'KRW' : h.currency;
    final pnl = h.profitLossAmountValue.round();
    final day = h.dailyProfitLossAmountValue.round();
    final avg = h.averagePurchasePriceValue;
    final qtyLabel = l.stocksSharesUnit(_qty(h.quantityValue));
    String money(num v) => masked ? '••••' : fmtByCurrency(v.toDouble(), cur);
    PDelta delta(int v, double pct) => _pnlDelta(v, pct, masked);
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BandTitle(l.stocksMyHoldings),
          PList(
            children: [
              _kvLine(
                context,
                l.stocksEvalAmount,
                money(h.marketValueAmountValue),
              ),
              _kvLine(
                context,
                l.stocksEvalPnl,
                '',
                valueWidget: delta(pnl, h.profitLossRateValue),
              ),
              _kvLine(
                context,
                l.stocksReturnRate,
                '',
                valueWidget: _PctDelta(h.profitLossRateValue),
              ),
              _kvLine(context, l.stocksQuantityHeld, qtyLabel),
              _kvLine(
                context,
                l.stocksAvgPrice,
                masked ? '••••' : fmtByCurrency(avg, cur),
              ),
              _kvLine(
                context,
                l.stocksPurchaseAmount,
                money(h.purchaseAmountValue),
              ),
              _kvLine(
                context,
                l.stocksDayPnl,
                '',
                valueWidget: delta(
                  day,
                  (double.tryParse(h.dailyProfitLossRate) ?? 0),
                ),
              ),
              _kvLine(
                context,
                l.stocksFeesTax,
                fmtByCurrency(h.feesValue, cur),
              ),
              _kvLine(context, l.stocksSellable, qtyLabel),
            ],
          ),
        ],
      ),
    );
  }
}

/// 띠 ③ 호가 · 체결.
class _QuotesBand extends StatelessWidget {
  const _QuotesBand({
    required this.symbol,
    required this.currency,
    required this.lastPrice,
    required this.changePct,
  });
  final String symbol;
  final String currency;
  final double? lastPrice;
  final double changePct;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BandTitle(l.stocksOrderbookTrades),
          _QuotesCard(
            symbol: symbol,
            currency: currency,
            lastPrice: lastPrice,
            changePct: changePct,
          ),
        ],
      ),
    );
  }
}

/// 띠 ⑤ 일별 시세 + 끝의 매매(토스만 — 이 화면이 토스 상세다).
class _DailyBand extends ConsumerWidget {
  const _DailyBand({
    required this.symbol,
    required this.isUs,
    required this.name,
  });
  final String symbol;
  final bool isUs;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final candlesAsync = ref.watch(
      tossCandlesProvider((symbol: symbol, interval: '1d')),
    );
    final page = candlesAsync.value;
    final asc = page == null
        ? const <TossCandle>[]
        : ([...page.candles]
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
    final recent = asc.length > 9 ? asc.sublist(asc.length - 9) : asc;
    final rows = <({String date, double close, double chg, int vol})>[];
    for (var i = recent.length - 1; i >= 1; i--) {
      final cd = recent[i];
      final prev = recent[i - 1].closeValue;
      final close = cd.closeValue;
      final chg = prev > 0 ? (close - prev) / prev * 100 : 0.0;
      final ts = cd.timestamp;
      final d = ts.length >= 10 ? DateTime.tryParse(ts.substring(0, 10)) : null;
      rows.add((
        date: d == null ? ts : l.stocksDailyDate(d.month, d.day),
        close: close,
        chg: chg,
        vol: cd.volumeValue.round(),
      ));
      if (rows.length >= 8) break;
    }
    String fmt(double v) => fmtByCurrency(v, isUs ? 'USD' : 'KRW');
    final Widget list;
    if (candlesAsync.hasError && !candlesAsync.hasValue) {
      list = _Failure(
        title: l.stocksFailDaily,
        onRetry: () => ref.invalidate(
          tossCandlesProvider((symbol: symbol, interval: '1d')),
        ),
      );
    } else if (candlesAsync.isLoading && !candlesAsync.hasValue) {
      list = Semantics(
        label: l.stocksDailyPricesLoading,
        child: Column(
          children: [for (var i = 0; i < 5; i++) const _LineSkeleton()],
        ),
      );
    } else if (rows.isEmpty) {
      list = PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.medium,
        icon: LucideIcons.chartCandlestick,
        title: l.stocksDailyPricesEmpty,
        headingLevel: 3,
      );
    } else {
      list = PList(
        children: [
          for (final r in rows)
            PListItem(
              title: r.date,
              detail: l.stocksDailyVolume(krw(r.vol)),
              suffix: PListValue(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      keepAllAmount(fmt(r.close)),
                      style: _moneyStyle(context),
                    ),
                    const SizedBox(height: 2),
                    _PctDelta(r.chg),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BandTitle(l.stocksDailyPrices),
          list,
          // 매매 — 지금처럼 누르면 알림만 뜬다(문구만 ~어요). 매도 = brandSolid · 매수 = criticalSolid, 사이 8.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x5,
              PSpacing.x6,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: PButton(
                    label: l.stocksSell,
                    size: PButtonSize.large,
                    variant: PButtonVariant.brandSolid,
                    onPressed: () => showPSnackBar(
                      context,
                      l.stocksSellOrderStub(name),
                      severity: PSnackSeverity.info,
                    ),
                  ),
                ),
                const SizedBox(width: PSpacing.x2),
                Expanded(
                  child: PButton(
                    label: l.stocksBuy,
                    size: PButtonSize.large,
                    variant: PButtonVariant.criticalSolid,
                    onPressed: () => showPSnackBar(
                      context,
                      l.stocksBuyOrderStub(name),
                      severity: PSnackSeverity.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x3,
              PSpacing.x6,
              0,
            ),
            child: PCallout(
              tone: PCalloutTone.informative,
              icon: LucideIcons.info,
              description: isUs ? l.stocksFeeUs : l.stocksFeeKr,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x3,
              PSpacing.x6,
              0,
            ),
            child: Text(
              '${l.stocksDisclaimerLine1}\n${l.stocksDisclaimerLine2}',
              textAlign: TextAlign.center,
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- 포트폴리오 구성 = 화면 --------------------------------------------------------

/// 포트폴리오 구성 화면 — 도넛 112 + 범례(종목 이름 · 비중). 비중은 원화로 환산해 센다(Q5-A).
class TossPortfolioPage extends ConsumerWidget {
  const TossPortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final holdingsAsync = ref.watch(tossHoldingsProvider);
    final fxRaw = ref.watch(tossExchangeRateProvider).asData?.value?.rateValue;
    final fx = (fxRaw != null && fxRaw > 0) ? fxRaw : null;
    final items = holdingsAsync.asData?.value?.items ?? const [];
    final comp = compositionOf(items, fx);

    Widget content;
    if (holdingsAsync.hasError && !holdingsAsync.hasValue) {
      content = _Failure(
        title: l.stocksFailInvest,
        onRetry: () {
          ref.invalidate(tossAccountsProvider);
          ref.invalidate(tossHoldingsProvider);
        },
      );
    } else if (holdingsAsync.isLoading && !holdingsAsync.hasValue) {
      content = Padding(
        padding: const EdgeInsets.all(PSpacing.x6),
        child: Center(
          child: PSkeleton(
            width: 112,
            height: 112,
            radius: PSkeletonRadius.full,
          ),
        ),
      );
    } else if (items.isEmpty) {
      content = PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.medium,
        icon: LucideIcons.wallet,
        title: l.stocksNoHoldings,
        headingLevel: 2,
      );
    } else if (comp == null) {
      content = PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.medium,
        icon: LucideIcons.chartPie,
        title: l.stocksPortfolioNeedsFx,
        headingLevel: 2,
      );
    } else {
      const palette = PChartColor.values;
      final colors = [
        for (var i = 0; i < comp.length; i++) palette[i % palette.length],
      ];
      content = Padding(
        padding: const EdgeInsets.all(PSpacing.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: PDonutChart(
                label: l.stocksPortfolioTitle,
                diameter: 112,
                centerLabel: l.stocksPortfolioCount(comp.length),
                slices: [
                  for (var i = 0; i < comp.length; i++)
                    PDonutSlice(
                      key: comp[i].symbol,
                      label: comp[i].name,
                      amount: comp[i].krwValue,
                      color: colors[i],
                    ),
                ],
              ),
            ),
            const SizedBox(height: PSpacing.x3),
            PList(
              semanticLabel: l.stocksPortfolioTitle,
              children: [
                for (var i = 0; i < comp.length; i++)
                  PListItem(
                    title: comp[i].name,
                    gutter: 0,
                    prefix: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[i].of(c),
                        borderRadius: BorderRadius.circular(PRounded.r0_5),
                      ),
                    ),
                    suffix: PListValue(
                      child: Text(
                        '${comp[i].weightPct.toStringAsFixed(2)}%',
                        style: _moneyStyle(context),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.stocksPortfolioTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/stocks'),
          ),
        ),
      ),
      body: ListView(
        children: [PScreenSection(padding: EdgeInsets.zero, child: content)],
      ),
    );
  }
}

// ---- 종목 기본정보 (토스 stocks + price-limits) ------------------------------

/// 시가총액 — en 은 ₩ + 로케일 compact(₩1.2T), ko 는 조/억/만 + 원.
///
/// 축약은 차트 축과 같은 함수 하나다. 손으로 짠 예전 코드는 구간마다 정밀도가
/// 달라(조는 `.0` 을 남겨 `5.0조원`, 억은 정수) 같은 규칙이 아니었고, 1억 밑을
/// 반올림해 5,000만원짜리를 `1억원` 이라고 했다.
String _fmtCapKrw(double v) {
  if (localeIsEn()) return '₩${formatChartAxis(v)}';
  return '${formatChartAxis(v)}원';
}

/// 상장주식수 — 금액은 아니지만 같은 한국어 단위 사다리(만·억)를 쓴다.
///
/// 예전엔 10억 주를 넘으면 소수를 떼고(`60억 주`) 그 밑은 한 자리를 남겨
/// (`5.9억 주`) 같은 칸에서 규칙이 바뀌었다 — 축약 규칙은 하나다(QA #73).
/// 단위(주)는 ko 만 붙인다. en 은 행 라벨이 이미 들고 있다.
String _fmtShares(double n) {
  if (localeIsEn()) return formatChartAxis(n);
  return '${formatChartAxis(n)} 주';
}

class _StockInfoCard extends ConsumerWidget {
  const _StockInfoCard({
    required this.symbol,
    required this.currency,
    required this.info,
    required this.lastPrice,
    required this.fxRate,
  });
  final String symbol;
  final String currency;
  final TossStockInfo? info;
  final double? lastPrice;
  final double? fxRate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final info = this.info; // 로컬 바인딩 → 널 승격(field promotion 불가) 위함.
    final isUs = currency == 'USD';
    final isKr = currency == 'KRW';
    final limits = ref.watch(tossPriceLimitsProvider(symbol)).asData?.value;
    final shares = info?.sharesValue ?? 0;
    // 시가총액 = 현재가 × 발행주식수 (USD 는 환율 환산). 시세 없으면 미표시. 웹 미러.
    final last = lastPrice;
    final fx = fxRate;
    final priceInKrw = last == null
        ? null
        : isUs
        ? (fx == null ? null : last * fx)
        : (isKr ? last : null);
    final mcKrw = (priceInKrw != null && shares > 0)
        ? priceInKrw * shares
        : null;
    final upper = limits?.upperValue;
    final lower = limits?.lowerValue;
    final listDate = info?.listDate;

    final rows = <(String, String, Color?)>[
      (
        l.stocksMarket,
        info?.market.isNotEmpty == true
            ? info!.market
            : (isUs ? l.stocksMarketUs : l.stocksMarketKr),
        null,
      ),
      (
        l.stocksInstrumentType,
        info?.isEtf == true ? 'ETF' : l.stocksInstrumentStock,
        null,
      ),
      (
        l.stocksCurrency,
        info?.currency.isNotEmpty == true ? info!.currency : currency,
        null,
      ),
      if (mcKrw != null) (l.stocksMarketCap, _fmtCapKrw(mcKrw), null),
      if (isKr && upper != null)
        (
          l.stocksUpperLimit,
          krwSigned(upper.round(), false, unit: true),
          context.colors.fgCritical,
        ),
      if (isKr && lower != null)
        (
          l.stocksLowerLimit,
          krwSigned(lower.round(), false, unit: true),
          context.colors.fgInformative,
        ),
      if (listDate != null && listDate.isNotEmpty)
        (l.stocksListingDate, listDate, null),
      if (shares > 0) (l.stocksSharesOutstanding, _fmtShares(shares), null),
      (
        // 거래정지는 토스 status(분류성 값)가 아니라 KRX 거래정지 플래그로 판정.
        l.stocksTradingStatus,
        info?.koreanMarketDetail?.krxTradingSuspended == true
            ? l.stocksTradingSuspended
            : l.stocksTradingNormal,
        info?.koreanMarketDetail?.krxTradingSuspended == true
            ? context.colors.fgCritical
            : context.colors.fgPositive,
      ),
    ];

    return PList(
      semanticLabel: l.stocksBasicInfo,
      children: [
        for (final r in rows) _kvLine(context, r.$1, r.$2, valueColor: r.$3),
      ],
    );
  }
}

/// 띠 ④ 기본 정보.
class _InfoBand extends StatelessWidget {
  const _InfoBand({
    required this.symbol,
    required this.currency,
    required this.info,
    required this.lastPrice,
    required this.fxRate,
  });
  final String symbol;
  final String currency;
  final TossStockInfo? info;
  final double? lastPrice;
  final double? fxRate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BandTitle(l.stocksBasicInfo),
          _StockInfoCard(
            symbol: symbol,
            currency: currency,
            info: info,
            lastPrice: lastPrice,
            fxRate: fxRate,
          ),
        ],
      ),
    );
  }
}

// ---- 호가창 (토스 orderbook · 실데이터 전용) ----------------------------------

class _OrderBook extends StatelessWidget {
  const _OrderBook({
    required this.currency,
    required this.lastPrice,
    required this.book,
    required this.changePct,
  });
  final String currency;
  final double? lastPrice;
  final TossOrderbook book;
  final double changePct;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // asks=낮은가격순 → 상단 표시(높은가격 위) 위해 5개 잘라 역순, bids=높은가격순 그대로.
    final asks = [
      for (final e in book.asks.take(5))
        (p: e.priceValue, q: e.volumeValue.round()),
    ].reversed.toList();
    final bids = [
      for (final e in book.bids.take(5))
        (p: e.priceValue, q: e.volumeValue.round()),
    ];
    var maxQ = 1;
    for (final a in asks) {
      if (a.q > maxQ) maxQ = a.q;
    }
    for (final b in bids) {
      if (b.q > maxQ) maxQ = b.q;
    }
    String fmt(double p) =>
        currency == 'USD' ? '\$${p.toStringAsFixed(2)}' : krw(p.round());

    Widget qtyBar({
      required int q,
      required Color tone,
      required bool alignRight,
    }) {
      final f = (maxQ <= 0 ? 0.0 : q / maxQ).clamp(0.0, 1.0);
      // 바는 항상 중심축(가격) 쪽에 붙어 바깥으로 자란다 — 매수=중심(오른쪽)에서 왼쪽으로,
      // 매도=중심(왼쪽)에서 오른쪽으로. FractionallySizedBox+Stack 은 좌측 고정 버그가 있어 Positioned 로 명시.
      return SizedBox(
        height: 22,
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: alignRight ? null : 0,
                right: alignRight ? 0 : null,
                width: c.maxWidth * f,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: chipFill(context, tone, t: 0.13),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Align(
                alignment: alignRight
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: alignRight ? 6 : 0,
                    left: alignRight ? 0 : 6,
                  ),
                  child: Text(
                    krw(q),
                    style: PTypo.micro.copyWith(
                      color: t.fgTertiary,
                      fontFeatures: _tnum,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget row({required double p, required int q, required bool isAsk}) {
      final priceColor = isAsk
          ? context.colors.fgInformative
          : context.colors.fgCritical;
      return SizedBox(
        height: 26,
        child: Row(
          children: [
            Expanded(
              child: isAsk
                  ? const SizedBox.shrink()
                  : qtyBar(
                      q: q,
                      tone: context.colors.fgCritical,
                      alignRight: true,
                    ),
            ),
            SizedBox(
              width: 92,
              child: Center(
                child: Text(
                  fmt(p),
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontFeatures: _tnum,
                    fontSize: 12.5,
                    fontWeight: PFontWeight.bold,
                    color: priceColor,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isAsk
                  ? qtyBar(
                      q: q,
                      tone: context.colors.fgInformative,
                      alignRight: false,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const _OrderBookHead(),
        const SizedBox(height: PSpacing.x1),
        for (final a in asks) row(p: a.p, q: a.q, isAsk: true),
        _OrderBookLast(
          currency: currency,
          lastPrice: lastPrice,
          changePct: changePct,
        ),
        for (final b in bids) row(p: b.p, q: b.q, isAsk: false),
      ],
    );
  }
}

/// 호가 테이블 헤더 — 정적 틀이라 로딩 중에도 실제로 그린다. 실렌더/스켈레톤 공유.
class _OrderBookHead extends StatelessWidget {
  const _OrderBookHead();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final style = TextStyle(
      fontFamily: PTypo.sans,
      fontSize: 10.5,
      fontWeight: PFontWeight.semi,
      color: t.fgTertiary,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            l.stocksBidVolume,
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        const SizedBox(width: 92),
        Expanded(child: Text(l.stocksAskVolume, style: style)),
      ],
    );
  }
}

/// 현재가 스트립 — 값이 호가 응답이 아니라 상위에서 이미 받아둔 시세라
/// 호가 로딩 중에도 실제로 그린다. 실렌더/스켈레톤 공유.
class _OrderBookLast extends StatelessWidget {
  const _OrderBookLast({
    required this.currency,
    required this.lastPrice,
    required this.changePct,
  });
  final String currency;
  final double? lastPrice;
  final double changePct;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            lastPrice != null ? fmtByCurrency(lastPrice!, currency) : '—',
            style: PTypo.bodySm.copyWith(
              color: _trendColor(t, changePct),
              fontWeight: PFontWeight.bold,
              fontFeatures: _tnum,
            ),
          ),
          const SizedBox(width: 6),
          _PctDelta(changePct),
        ],
      ),
    );
  }
}

/// 호가 로딩 스켈레톤 — [_OrderBook] 실렌더 구조를 그대로 따른다.
/// 헤더 행과 현재가 스트립은 실 위젯을 그대로 쓰고, 서버에서 오는 매도/매수
/// 5호가 자리만 placeholder — 행 26 / 잔량 바 22 / 가격 컬럼 92 고정.
class _OrderBookSkeleton extends StatelessWidget {
  const _OrderBookSkeleton({
    required this.currency,
    required this.lastPrice,
    required this.changePct,
  });
  final String currency;
  final double? lastPrice;
  final double changePct;

  /// 잔량 바 길이는 실렌더에서 maxQ 대비 비율이라 값을 알 수 없다 — 프레임마다
  /// 흔들리지 않도록 고정 시퀀스로 대체(랜덤 금지). asks 는 위가 고가라 역순 모양.
  static const _askBars = [0.34, 0.52, 0.41, 0.66, 0.47];
  static const _bidBars = [0.58, 0.44, 0.70, 0.38, 0.50];

  @override
  Widget build(BuildContext context) {
    // 실렌더 row(): SizedBox(height: 26) + 가운데 가격 컬럼 92 고정.
    // 잔량 바는 중심축(가격)에 붙어 바깥으로 자라므로 정렬도 매도=왼쪽/매수=오른쪽.
    Widget row(double factor, {required bool isAsk}) {
      // 실렌더 qtyBar 의 높이 22 · radius 4(=PRadius.brSm, PSkeleton 기본값).
      final bar = FractionallySizedBox(
        alignment: isAsk ? Alignment.centerLeft : Alignment.centerRight,
        widthFactor: factor,
        child: const PSkeleton(height: 22),
      );
      return SizedBox(
        height: 26,
        child: Row(
          children: [
            Expanded(child: isAsk ? const SizedBox.shrink() : bar),
            const SizedBox(
              width: 92,
              child: Center(child: PSkeleton(width: 56, height: 12)),
            ),
            Expanded(child: isAsk ? bar : const SizedBox.shrink()),
          ],
        ),
      );
    }

    return Column(
      children: [
        const _OrderBookHead(),
        const SizedBox(height: PSpacing.x1),
        for (final f in _askBars) row(f, isAsk: true),
        _OrderBookLast(
          currency: currency,
          lastPrice: lastPrice,
          changePct: changePct,
        ),
        for (final f in _bidBars) row(f, isAsk: false),
      ],
    );
  }
}

// ---- 호가 / 체결 탭 카드 (실데이터 전용 · 로딩/빈 상태) -----------------------

typedef _Fill = ({String time, double p, int q, int dir});

/// 라이브 체결 테이프 변환 (토스 trades). dir=직전 체결가 대비 방향. 웹 `liveTradeFills` 미러.
List<_Fill> _liveTradeFills(List<TossTrade>? trades) {
  if (trades == null || trades.isEmpty) return const [];
  final out = <_Fill>[];
  final n = trades.length < 12 ? trades.length : 12;
  for (var i = 0; i < n; i++) {
    final tr = trades[i];
    final p = tr.priceValue;
    final prev = i + 1 < trades.length ? trades[i + 1].priceValue : p;
    final time =
        RegExp(r'(\d{2}:\d{2}:\d{2})').firstMatch(tr.timestamp)?.group(1) ??
        tr.timestamp;
    out.add((
      time: time,
      p: p,
      q: tr.volumeValue.round(),
      dir: p >= prev ? 1 : -1,
    ));
  }
  return out;
}

class _QuotesEmpty extends StatelessWidget {
  const _QuotesEmpty(this.msg);
  final String msg;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: PSpacing.x8,
        horizontal: 12,
      ),
      child: Center(
        child: Text(msg, style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
      ),
    );
  }
}

class _QuotesCard extends ConsumerStatefulWidget {
  const _QuotesCard({
    required this.symbol,
    required this.currency,
    required this.lastPrice,
    required this.changePct,
  });
  final String symbol;
  final String currency;
  final double? lastPrice;
  final double changePct;

  @override
  ConsumerState<_QuotesCard> createState() => _QuotesCardState();
}

class _QuotesCardState extends ConsumerState<_QuotesCard> {
  String _tab = 'book';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final orderbookAsync = ref.watch(tossOrderbookProvider(widget.symbol));
    final tradesAsync = ref.watch(tossTradesProvider(widget.symbol));
    // `asData` 는 AsyncData 일 때만 값을 준다 — 10초 폴링이 만드는 재조회
    // 상태에서 들고 있던 호가·체결을 버리므로 `value` 로 읽는다.
    final book = orderbookAsync.value;
    final hasBook =
        book != null && book.asks.isNotEmpty && book.bids.isNotEmpty;
    final fills = _liveTradeFills(tradesAsync.value);

    Widget content;
    if (_tab == 'book') {
      // 호가는 10초마다 다시 받는다(`_priceTimer`). 그때마다 스켈레톤을 깔면
      // 들고 있던 호가창이 10초마다 사라진다 — 새 호가가 닿을 때까지 직전
      // 호가를 그대로 둔다. 스켈레톤은 아직 아무것도 못 받았을 때만.
      if (orderbookAsync.isLoading && !orderbookAsync.hasValue) {
        content = Semantics(
          label: l.stocksOrderbookLoading,
          child: _OrderBookSkeleton(
            currency: widget.currency,
            lastPrice: widget.lastPrice,
            changePct: widget.changePct,
          ),
        );
      } else if (hasBook) {
        content = _OrderBook(
          currency: widget.currency,
          lastPrice: widget.lastPrice,
          book: book,
          changePct: widget.changePct,
        );
      } else {
        content = _QuotesEmpty(l.stocksOrderbookEmpty);
      }
    } else {
      // 체결도 10초 폴링이다 — 직전 체결 테이프를 새 체결이 닿을 때까지 둔다.
      if (tradesAsync.isLoading && !tradesAsync.hasValue) {
        content = Semantics(
          label: l.stocksTradesLoading,
          child: const _TradeTapeSkeleton(),
        );
      } else if (fills.isEmpty) {
        content = _QuotesEmpty(l.stocksTradesEmpty);
      } else {
        content = _TradeTape(currency: widget.currency, fills: fills);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
          child: PSegmentedControl<String>(
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
            semanticLabel: l.stocksOrderbookTrades,
            items: [
              PSegmentedItem(value: 'book', label: l.stocksOrderbook),
              PSegmentedItem(value: 'tape', label: l.stocksTrades),
            ],
          ),
        ),
        const SizedBox(height: PSpacing.x3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
          child: content,
        ),
      ],
    );
  }
}

// ---- 체결 테이프 (토스 trades · 실데이터 전용) --------------------------------

class _TradeTape extends StatelessWidget {
  const _TradeTape({required this.currency, required this.fills});
  final String currency;
  final List<_Fill> fills;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    String fmt(double p) =>
        currency == 'USD' ? '\$${p.toStringAsFixed(2)}' : krw(p.round());

    return Column(
      children: [
        const _TradeTapeHead(),
        const SizedBox(height: PSpacing.x1),
        for (final f in fills)
          SizedBox(
            height: 25,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    f.time,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontFeatures: _tnum,
                      fontSize: 12,
                      color: t.fgTertiary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    fmt(f.p),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontFeatures: _tnum,
                      fontSize: 12,
                      fontWeight: PFontWeight.bold,
                      color: _trendColor(t, f.dir.toDouble()),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    krw(f.q),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontFeatures: _tnum,
                      fontSize: 12,
                      color: t.fgSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 체결 테이블 헤더 — 정적 틀이라 로딩 중에도 실제로 그린다. 실렌더/스켈레톤 공유.
class _TradeTapeHead extends StatelessWidget {
  const _TradeTapeHead();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final head = TextStyle(
      fontFamily: PTypo.sans,
      fontSize: 10.5,
      fontWeight: PFontWeight.semi,
      color: t.fgTertiary,
    );
    return Row(
      children: [
        Expanded(child: Text(l.stocksTradeTime, style: head)),
        Expanded(
          child: Text(
            l.stocksTradePrice,
            textAlign: TextAlign.right,
            style: head,
          ),
        ),
        Expanded(
          child: Text(
            l.stocksTradeVolume,
            textAlign: TextAlign.right,
            style: head,
          ),
        ),
      ],
    );
  }
}

/// 체결 로딩 스켈레톤 — [_TradeTape] 실렌더 구조를 그대로 따른다.
/// 헤더는 실 위젯을 그대로 쓰고 체결 행만 placeholder — `_liveTradeFills` 상한인
/// 12행 · 행 높이 25 · 3등분 컬럼(시간 좌 / 가격 우 / 수량 우) 그대로.
class _TradeTapeSkeleton extends StatelessWidget {
  const _TradeTapeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TradeTapeHead(),
        const SizedBox(height: PSpacing.x1),
        for (var i = 0; i < 12; i++)
          const SizedBox(
            height: 25,
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PSkeleton(width: 52, height: 12),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PSkeleton(width: 48, height: 12),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PSkeleton(width: 36, height: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
