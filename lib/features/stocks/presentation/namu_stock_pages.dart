/// 나무 종목 상세 · 포트폴리오 구성 — 화면(주소)이다(I-13 13-3 · 3-B).
/// `/stocks/namu/:symbol` · `/stocks/namu/portfolio` 만으로 열린다(목록 상태를 넘겨받지 않는다).
///
/// 호가 · 체결 · 오늘 시세 · 투자자별 · 투자 지표 · ETF · 시간외 · 매도가능 줄은 I-13b 13b-1 · 13b-3 몫이라
/// 이 화면에 비워 둔 띠가 없다 — 그 구역이 생길 때 띠가 더해진다. 나무 상세에는 매도 · 매수가 없다(읽기 전용).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/lifecycle/screen_visibility.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/stocks/application/namu_model.dart';
import 'package:groo_damda_app/features/stocks/application/namu_providers.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/chart_web_view.dart';
import 'package:groo_damda_app/features/stocks/presentation/namu_stocks_view.dart';
import 'package:groo_damda_app/features/stocks/presentation/stock_market_label.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/features/stocks/presentation/watch_actions.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 종목 상세 화면 — 폰은 띠 넷(머리 · 차트 / 내 보유 / 기본 정보 / 일별 시세), 보유 종목이 아니면 내 보유 띠가 없다.
class NamuStockDetailPage extends ConsumerStatefulWidget {
  const NamuStockDetailPage({super.key, required this.symbol});
  final String symbol;

  @override
  ConsumerState<NamuStockDetailPage> createState() =>
      _NamuStockDetailPageState();
}

class _NamuStockDetailPageState extends ConsumerState<NamuStockDetailPage> {
  String _range = '1D';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 보유 종목은 잔고 응답이 현재가를 준다(추가 호출 없음). 관심 종목만 시세 1콜 — 박자는 웹과 같은 30초,
    // 앱이 가려진 동안은 멈춘다.
    _timer = Timer.periodic(namuPricePollInterval, (_) {
      if (!mounted || !ref.read(appForegroundProvider)) return;
      ref.invalidate(namuQuotesProvider(widget.symbol));
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

    final master = findMasterBySymbol(
      ref.watch(stockSearchProvider(symbol)).asData?.value ??
          const <StockMasterItem>[],
      symbol,
    );
    final krwAsync = ref.watch(namuHoldingsProvider('KRW'));
    final usdAsync = ref.watch(namuHoldingsProvider('USD'));
    final fx = ref.watch(securitiesExchangeRateProvider).asData?.value;
    final view = mergeNamuHoldings(
      krwAsync.asData?.value,
      usdAsync.asData?.value,
      fx,
    );
    final holding = view.rows.where((r) => r.symbol == symbol).firstOrNull;
    final groups =
        ref.watch(watchGroupsProvider).asData?.value ??
        const <StockWatchGroup>[];
    final watched = groups.any((g) => g.items.any((i) => i.symbol == symbol));

    final name = master?.nameKr.isNotEmpty == true
        ? master!.nameKr
        : (holding?.name ?? symbol);
    // 보유 종목이면 행이 자기 통화를 안다. 아니면 마스터가 안다.
    final currency =
        holding?.currency ??
        (master?.currency.isNotEmpty == true ? master!.currency : 'KRW');
    final isUs = currency == 'USD';

    // 현재가 — 보유 종목이면 잔고 응답에 이미 있다. 관심 종목만 서버 대리 조회로 1콜.
    final quoteAsync = holding == null
        ? ref.watch(namuQuotesProvider(symbol))
        : null;
    final quote = quoteAsync?.asData?.value.firstOrNull;
    final lastRaw = holding != null ? holding.currentPrice : quote?.price;
    final last = (lastRaw != null && lastRaw > 0) ? lastRaw : null;
    final prevClose = holding != null ? null : quote?.previousClose;
    final changePct = holding != null
        ? null
        : changePctOf(last, quote?.previousClose);

    final sub = master != null
        ? '$symbol · ${stockMarketLabel(l, master.marketCode)}'
        : symbol;

    final head = PScreenSection(
      padding: const EdgeInsets.symmetric(vertical: PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  keepAll(name),
                  style: PTypography.t7.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.fgNeutral,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                ),
                const SizedBox(height: PSpacing.x4),
                Text(
                  keepAllAmount(
                    last != null ? fmtByCurrency(last, currency) : '—',
                  ),
                  style: PTypography.t12.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.fgNeutral,
                    fontFeatures: kStocksTnum,
                  ),
                ),
                if (changePct != null && last != null && prevClose != null) ...[
                  const SizedBox(height: PSpacing.x1),
                  // "▲ 45,200원 · 0.30%" — 금액(전일 종가 대비)과 등락률(13-1 M5 와 같게)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: namuPnlDelta(
                      last - prevClose,
                      changePct,
                      currency,
                      false,
                    ),
                  ),
                ],
                if (last == null && !(quoteAsync?.isLoading ?? false)) ...[
                  const SizedBox(height: 2),
                  Text(
                    l.namuPriceEmpty,
                    style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                  ),
                ],
                const SizedBox(height: PSpacing.x4),
                ChartWebView(
                  symbol: symbol,
                  isUs: isUs,
                  range: _range,
                  height: 168,
                ),
                const SizedBox(height: PSpacing.x3),
              ],
            ),
          ),
          // 차트 기간 5칸 — 전용 Segmented(칸 좌우 4). 글은 static 16 이라 글자 200% 에서도 안 꺾인다.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: PSegmentedControl<String>.chartPeriod(
              value: _range,
              onChanged: (v) => setState(() => _range = v),
              semanticLabel: l.stocksDetailTitle,
              items: [
                for (final r in kStockRanges)
                  PSegmentedItem(value: r, label: stockRangeLabel(l, r)),
              ],
            ),
          ),
        ],
      ),
    );

    final bands = <Widget>[
      head,
      if (holding != null) _NamuHoldingBand(holding: holding, masked: masked),
      _NamuInfoBand(master: master, currency: currency),
      _NamuDailyBand(symbol: symbol, currency: currency),
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
              // 켬은 선 2.5(toggle.md:31) — 끔은 선 2. 색은 상단 바 안이라 둘 다 fg-neutral
              selectedIcon: LucideIcons.star500,
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

/// 띠 ② 내 보유 — 잔고 응답이 주는 여섯 줄(수수료 · 세금 · 매도가능은 나무가 안 준다). 한 줄에 하나.
class _NamuHoldingBand extends StatelessWidget {
  const _NamuHoldingBand({required this.holding, required this.masked});
  final NamuMergedHolding holding;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final h = holding;
    final cur = h.currency;
    String money(double v) => masked ? '••••' : fmtByCurrency(v, cur);
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksMyHoldings),
          PList(
            children: [
              stocksKvLine(context, l.stocksEvalAmount, money(h.evalAmount)),
              stocksKvLine(
                context,
                l.stocksEvalPnl,
                '',
                valueWidget: namuPnlDelta(
                  h.profitLoss,
                  h.returnPct,
                  cur,
                  masked,
                ),
              ),
              stocksKvLine(
                context,
                l.stocksQuantityHeld,
                l.stocksSharesUnit(stocksQty(h.quantity)),
              ),
              stocksKvLine(
                context,
                l.stocksReturnRate,
                '',
                valueWidget: StocksPctDelta(h.returnPct),
              ),
              stocksKvLine(context, l.stocksAvgPrice, money(h.avgPrice)),
              stocksKvLine(
                context,
                l.stocksPurchaseAmount,
                money(h.costAmount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 띠 ③ 기본 정보 — 나무는 마스터가 아는 것까지다(시총 · 상장주식수 · 상하한가는 I-13b 가 더한다).
class _NamuInfoBand extends StatelessWidget {
  const _NamuInfoBand({required this.master, required this.currency});
  final StockMasterItem? master;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = master;
    return PScreenSection(
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StocksBandTitle(l.stocksBasicInfo),
          PList(
            children: [
              stocksKvLine(
                context,
                l.stocksMarket,
                m != null
                    ? stockMarketLabel(l, m.marketCode)
                    : (currency == 'USD' ? l.stocksMarketUs : l.stocksMarketKr),
              ),
              stocksKvLine(context, l.stocksCurrency, currency),
              stocksKvLine(
                context,
                l.stocksInstrumentType,
                m?.securityType == 'ETF' ? 'ETF' : l.stocksInstrumentStock,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 띠 ④ 일별 시세 — 일봉에서 파생한다(증권사는 서버가 고른다). 끝에 시세는 참고용 안내 한 줄(첫 증권사 안내는 없다).
class _NamuDailyBand extends ConsumerWidget {
  const _NamuDailyBand({required this.symbol, required this.currency});
  final String symbol;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final async = ref.watch(securitiesDailyCandlesProvider(symbol));
    final page = async.value;
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
    final Widget list;
    if (async.hasError && !async.hasValue) {
      list = StocksFailure(
        title: l.stocksFailDaily,
        onRetry: () => ref.invalidate(securitiesDailyCandlesProvider(symbol)),
      );
    } else if (async.isLoading && !async.hasValue) {
      list = Semantics(
        label: l.stocksDailyPricesLoading,
        child: Column(
          children: [for (var i = 0; i < 5; i++) const StocksLineSkeleton()],
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
                      keepAllAmount(fmtByCurrency(r.close, currency)),
                      style: stocksMoneyStyle(context),
                    ),
                    const SizedBox(height: 2),
                    StocksPctDelta(r.chg),
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
          StocksBandTitle(l.stocksDailyPrices),
          list,
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x3,
              PSpacing.x6,
              0,
            ),
            child: Text(
              l.stocksDisclaimerLine2,
              textAlign: TextAlign.center,
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
          ),
        ],
      ),
    );
  }
}

/// 포트폴리오 구성 화면 — 도넛 112 + 범례. 비중은 원화로 환산해 센다. 환율이 없으면 도넛 대신 안내.
class NamuPortfolioPage extends ConsumerWidget {
  const NamuPortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final krwAsync = ref.watch(namuHoldingsProvider('KRW'));
    final usdAsync = ref.watch(namuHoldingsProvider('USD'));
    final fxAsync = ref.watch(securitiesExchangeRateProvider);
    final view = mergeNamuHoldings(
      krwAsync.asData?.value,
      usdAsync.asData?.value,
      fxAsync.asData?.value,
    );
    final loading =
        (krwAsync.isLoading && !krwAsync.hasValue) ||
        (usdAsync.isLoading && !usdAsync.hasValue);
    final failed =
        krwAsync.hasError &&
        !krwAsync.hasValue &&
        usdAsync.hasError &&
        !usdAsync.hasValue;
    final comp = namuCompositionOf(view);
    // 금액 가리기 — 도넛 조각 금액도, 범례 비중도 가린다(13-1 H5 와 같게)
    final masked = ref.watch(hideCardProvider('stocks.summary'));

    Widget content;
    if (failed) {
      content = StocksFailure(
        title: l.stocksFailInvest,
        description: l.namuFailDesc,
        onRetry: () {
          ref.invalidate(namuHoldingsProvider('KRW'));
          ref.invalidate(namuHoldingsProvider('USD'));
        },
      );
    } else if (loading) {
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
    } else if (view.count == 0) {
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
        title: l.namuDonutNeedsFx,
        headingLevel: 2,
      );
    } else {
      content = StocksCompositionBody(comp: comp, masked: masked);
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
