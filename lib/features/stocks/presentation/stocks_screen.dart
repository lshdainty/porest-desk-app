import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/colors.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/features/stocks/application/stocks_providers.dart';
import 'package:porest_desk_app/features/stocks/data/stocks_mock.dart';
import 'package:porest_desk_app/features/stocks/data/toss_dto.dart';
import 'package:porest_desk_app/features/stocks/domain/stock.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';

/// 증권 — 시세 · 보유 · 관심 · 호가 (토스증권 Open API 연동 가정, mock 시세).
/// 웹 `pages/stocks/ui/StocksPage.tsx` 미러.
/// 상승=statusDangerFg / 하락=fgBrand (국내 증권 통념, 기존 시맨틱 토큰 재활용).
class StocksScreen extends ConsumerStatefulWidget {
  const StocksScreen({super.key});

  @override
  ConsumerState<StocksScreen> createState() => _StocksScreenState();
}

enum _Seg { holdings, watch, discover }

/// 숫자 정렬용 tabular figures — 웹 `.num`(tnum) 미러. 가격·수량·수익률·지수 등에 적용.
const List<FontFeature> _tnum = [FontFeature.tabularFigures()];

class _StocksScreenState extends ConsumerState<StocksScreen> {
  _Seg _seg = _Seg.holdings;
  late List<WatchGroup> _watchGroups =
      kStockWatch.map((g) => g.copyWith(tickers: [...g.tickers])).toList();
  late String _activeGroup = _watchGroups.first.id;

  Set<String> get _watchedTickers =>
      {for (final g in _watchGroups) ...g.tickers};

  bool _isWatched(String ticker) => _watchedTickers.contains(ticker);

  void _toggleWatch(String ticker) {
    setState(() {
      final inSome = _watchGroups.any((g) => g.tickers.contains(ticker));
      _watchGroups = [
        for (final g in _watchGroups)
          if (inSome)
            g.copyWith(tickers: g.tickers.where((x) => x != ticker).toList())
          else if (g.id == _activeGroup)
            g.copyWith(tickers: [...g.tickers, ticker])
          else
            g,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final masked = ref.watch(settingsProvider).value?.hideAmounts ?? false;

    // 개인키 미연결 시 전 화면 연결 유도 (mock 노출 금지). 토스 API는 시세 포함 모든
    // 조회가 개인키 토큰을 요구하므로(공용키 폐기), 키 없으면 조회 불가.
    final credAsync = ref.watch(tossCredentialStatusProvider);
    final connected = credAsync.asData?.value.connected ?? false;
    if (!credAsync.isLoading && !connected) {
      return _ConnectGate();
    }

    // 토스 Open API 라이브 시세·환율 오버레이 (연결 시에만 실데이터 적용).
    ref.watch(stockLiveOverlayProvider);

    // 보유자산 — 키 연결 시 실데이터, 미연결 시 null(연결 유도 빈 상태). mock 미사용.
    final holdings = ref.watch(tossHoldingsProvider).asData?.value;
    final holdingItems = holdings == null
        ? const <TossHoldingsItem>[]
        : ([...holdings.items]
          ..sort((a, b) =>
              b.marketValueAmountValue.compareTo(a.marketValueAmountValue)));
    final curGroup = _watchGroups.firstWhere(
      (g) => g.id == _activeGroup,
      orElse: () => _watchGroups.first,
    );

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: const Text('증권'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x24),
        children: [
          const _IndexStrip(),
          const SizedBox(height: PSpace.x16),
          _SummaryCard(masked: masked, holdings: holdings),
          const SizedBox(height: PSpace.x16),
          // 종목 검색 트리거 — 공통 PSearchField 시각(36px) 그대로, 탭 시 검색 시트
          GestureDetector(
            onTap: _openSearch,
            child: const AbsorbPointer(
              child: PSearchField(hint: '종목 검색'),
            ),
          ),
          const SizedBox(height: 14),
          PTabs<_Seg>(
            value: _seg,
            onChanged: (v) => setState(() => _seg = v),
            variant: PTabsVariant.container,
            size: PTabsSize.sm,
            expand: true,
            items: [
              PTabItem(
                  value: _Seg.holdings,
                  label: '보유 ${holdingItems.length}'),
              PTabItem(
                  value: _Seg.watch, label: '관심 ${_watchedTickers.length}'),
              const PTabItem(value: _Seg.discover, label: '발견'),
            ],
          ),
          const SizedBox(height: 14),
          if (_seg == _Seg.discover)
            _DiscoverPanel(onPick: _openDetail)
          else if (_seg == _Seg.holdings)
            holdings == null
                ? _HoldingsEmpty(onConnect: () => context.push('/account'))
                : holdingItems.isEmpty
                    ? PCard(
                        padding: const EdgeInsets.symmetric(
                            vertical: PSpace.x32, horizontal: PSpace.x20),
                        child: Center(
                          child: Text(
                            '보유 중인 종목이 없어요.',
                            style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                          ),
                        ),
                      )
                    : PCard(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          children: [
                            for (final h in holdingItems)
                              _StockRow(
                                ticker: h.symbol,
                                sub: '${h.quantity}주 보유',
                                onTap: () => _openDetail(h.symbol),
                                right: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      krwMasked(
                                          h.marketValueAmountValue.round(),
                                          masked,
                                          mask: '••••'),
                                      style: TextStyle(
                                        fontFamily: PTypo.sans,
                                        fontFeatures: _tnum,
                                        fontSize: 13.5,
                                        fontWeight: PFontWeight.bold,
                                        color: t.fgPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '${h.profitLossRateValue >= 0 ? '+' : ''}${h.profitLossRateValue.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        fontFamily: PTypo.sans,
                                        fontFeatures: _tnum,
                                        fontSize: PFontSize.micro,
                                        fontWeight: PFontWeight.bold,
                                        color: _trendColor(
                                            t, h.profitLossAmountValue),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )
          else ...[
            PTabs<String>(
              value: _activeGroup,
              onChanged: (v) => setState(() => _activeGroup = v),
              variant: PTabsVariant.container,
              size: PTabsSize.sm,
              items: [
                for (final g in _watchGroups)
                  PTabItem(value: g.id, label: '${g.name} ${g.tickers.length}'),
              ],
            ),
            const SizedBox(height: 14),
            PCard(
              padding: const EdgeInsets.all(6),
              child: curGroup.tickers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: PSpace.x32, horizontal: PSpace.x20),
                      child: Center(
                        child: Text(
                          '관심 종목이 없어요. 검색해서 별표를 눌러보세요.',
                          style:
                              PTypo.bodySm.copyWith(color: t.fgTertiary),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (final ticker in curGroup.tickers)
                          _StockRow(
                            ticker: ticker,
                            onTap: () => _openDetail(ticker),
                          ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  void _openSearch() {
    var query = '';
    showPSheet<void>(
      context,
      title: '종목 검색',
      initialChildSize: 0.9,
      contentBuilder: (sheetCtx, scrollCtrl) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          final ql = query.trim().toLowerCase();
          final results = ql.isEmpty
              ? kStocks
              : kStocks
                  .where((s) =>
                      s.name.toLowerCase().contains(ql) ||
                      s.ticker.toLowerCase().contains(ql) ||
                      s.sector.contains(query.trim()))
                  .toList();
          final t = sheetCtx.tokens;
          return ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(
                PSpace.x20, 0, PSpace.x20, PSpace.x24),
            children: [
              PSearchField(
                hint: '종목명 · 티커로 검색 (예: 삼성전자, NVDA)',
                autofocus: true,
                onChanged: (v) => setSheet(() => query = v),
              ),
              const SizedBox(height: PSpace.x8),
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x40),
                  child: Center(
                    child: Text(
                      "'$query' 검색 결과가 없어요",
                      style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                    ),
                  ),
                )
              else
                for (final s in results)
                  _StockRow(
                    ticker: s.ticker,
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      _openDetail(s.ticker);
                    },
                  ),
            ],
          );
        },
      ),
    );
  }

  void _openDetail(String ticker) {
    final holding = ref
        .read(tossHoldingsProvider)
        .asData
        ?.value
        ?.items
        .where((h) => h.symbol == ticker)
        .firstOrNull;
    showPSheet<void>(
      context,
      title: '종목 상세',
      initialChildSize: 0.9,
      contentBuilder: (sheetCtx, scrollCtrl) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => _StockDetailBody(
          ticker: ticker,
          holding: holding,
          watched: _isWatched(ticker),
          onToggleWatch: () {
            _toggleWatch(ticker);
            setSheet(() {});
          },
          scrollController: scrollCtrl,
          masked: ref.read(settingsProvider).value?.hideAmounts ?? false,
        ),
      ),
    );
  }
}

// ---- 색 헬퍼 ---------------------------------------------------------------

/// 상승/하락 색 — 국내 증권 통념: 상승=빨강(error), 하락=파랑(primary).
Color _trendColor(PorestTokens t, double pct) =>
    pct >= 0 ? t.statusDangerFg : t.fgBrand;

/// 종목 심볼 배지 tone — KR=chart-blue / US=chart-violet (다크 light swap).
Color _marketTone(BuildContext context, Stock s) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (s.isUs) {
    return dark ? PorestPalette.chartVioletLight : PorestPalette.chartViolet;
  }
  return dark ? PorestPalette.chartBlueLight : PorestPalette.chartBlue;
}

String _fmtPrice(Stock s) => s.isUs
    ? '\$${s.price.toStringAsFixed(2)}'
    : '${krw(s.price.round())}원';

// ---- 등락률 배지 (색 + 부호 + 아이콘 3중 병기 — A11y 1.4.1) -------------------

class _PctBadge extends StatelessWidget {
  const _PctBadge({required this.pct, this.size = 13});
  final double pct;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final up = pct >= 0;
    final color = _trendColor(t, pct);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(up ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: size + 2, color: color),
        const SizedBox(width: 2),
        Text(
          '${up ? '+' : ''}${pct.toStringAsFixed(2)}%',
          style: TextStyle(
            fontFamily: PTypo.sans,
            fontFeatures: _tnum,
            fontSize: size,
            fontWeight: PFontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---- 종목 심볼 배지 ----------------------------------------------------------

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock, this.size = 40});
  final Stock stock;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = _marketTone(context, stock);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: chipFill(context, tone, t: 0.16),
        borderRadius: PRadius.tile(size),
      ),
      child: Text(
        stock.isUs ? stock.ticker.substring(0, 2) : stock.name.substring(0, 1),
        style: TextStyle(
          fontFamily: PTypo.sans,
          fontSize: size * 0.34,
          fontWeight: PFontWeight.bold,
          letterSpacing: -0.02 * size * 0.34,
          color: chipText(context, tone, t: 0.72),
        ),
      ),
    );
  }
}

// ---- 미니 스파크라인 ---------------------------------------------------------

class _Sparkline extends StatelessWidget {
  const _Sparkline({
    required this.values,
    required this.color,
    required this.height,
    this.fill = false,
  });
  final List<double> values;
  final Color color;
  final double height;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparkPainter(values: values, color: color, fill: fill),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.values, required this.color, required this.fill});
  final List<double> values;
  final Color color;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var min = values.first;
    var max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final range = (max - min) == 0 ? 1.0 : max - min;
    final step = size.width / (values.length - 1);
    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          i * step,
          size.height - ((values[i] - min) / range) * (size.height - 8) - 4,
        ),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.drawCircle(pts.last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.values != values || old.color != color || old.fill != fill;
}

// ---- 종목 리스트 행 ----------------------------------------------------------

class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.ticker,
    required this.onTap,
    this.sub,
    this.right,
  });
  final String ticker;
  final VoidCallback onTap;
  final String? sub;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = findStock(ticker);
    if (s == null) return const SizedBox.shrink();
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brMd,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: PSpace.x12),
        child: Row(
          children: [
            _StockBadge(stock: s),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${s.ticker} · ${sub ?? s.sector}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PTypo.micro.copyWith(color: t.fgTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            SizedBox(
              width: 56,
              child: Opacity(
                opacity: 0.9,
                child: _Sparkline(
                  values: s.spark,
                  color: _trendColor(t, s.changePct),
                  height: 28,
                ),
              ),
            ),
            const SizedBox(width: PSpace.x12),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 78),
              child: right ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmtPrice(s),
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontFeatures: _tnum,
                          fontSize: 13.5,
                          fontWeight: PFontWeight.bold,
                          color: t.fgPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      _PctBadge(pct: s.changePct, size: 11.5),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- 개인키 미연결: 전 화면 연결 유도 -----------------------------------------

class _ConnectGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: const Text('증권'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(PSpace.x24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.lock, size: 32, color: t.fgTertiary),
              const SizedBox(height: PSpace.x12),
              Text(
                '증권 계정을 연결해 주세요',
                style: PTypo.body.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
              const SizedBox(height: PSpace.x4),
              Text(
                '토스증권 키를 연결하면 시세·보유 종목과\n평가손익을 실시간으로 볼 수 있어요.',
                textAlign: TextAlign.center,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
              const SizedBox(height: PSpace.x16),
              PButton(
                label: '설정에서 연결하기',
                variant: PButtonVariant.outline,
                size: PButtonSize.sm,
                onPressed: () => context.push('/account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- 보유 빈 상태 (증권 계정 미연결) -----------------------------------------

class _HoldingsEmpty extends StatelessWidget {
  const _HoldingsEmpty({required this.onConnect});
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PCard(
      padding: const EdgeInsets.symmetric(
          vertical: PSpace.x32, horizontal: PSpace.x20),
      child: Column(
        children: [
          Icon(LucideIcons.wallet, size: 32, color: t.fgTertiary),
          const SizedBox(height: PSpace.x12),
          Text(
            '증권 계정을 연결해 주세요',
            style: PTypo.body.copyWith(
              color: t.fgPrimary,
              fontWeight: PFontWeight.semi,
            ),
          ),
          const SizedBox(height: PSpace.x4),
          Text(
            '토스증권 키를 연결하면 보유 종목과\n평가손익을 실시간으로 볼 수 있어요.',
            textAlign: TextAlign.center,
            style: PTypo.bodySm.copyWith(color: t.fgTertiary),
          ),
          const SizedBox(height: PSpace.x16),
          PButton(
            label: '계정 연결하기',
            variant: PButtonVariant.outline,
            size: PButtonSize.sm,
            onPressed: onConnect,
          ),
        ],
      ),
    );
  }
}

// ---- 요약 카드 ---------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.masked, required this.holdings});
  final bool masked;

  /// 키 연결 시 보유 요약(서버 계산). null 이면 연결 유도 빈 상태.
  final TossHoldings? holdings;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final h = holdings;
    if (h == null) {
      // 미연결 — 연결 유도 카드 (mock 평가금액 노출 안 함).
      return PCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '내 투자 평가금액',
              style: TextStyle(
                fontFamily: PTypo.sans,
                fontSize: 12.5,
                fontWeight: PFontWeight.semi,
                color: t.fgTertiary,
              ),
            ),
            const SizedBox(height: PSpace.x8),
            Text(
              '증권 계정을 연결하면 보유자산이 보여요',
              style: PTypo.bodySm.copyWith(color: t.fgTertiary),
            ),
          ],
        ),
      );
    }
    final totalEval = h.marketValueAmountValue.round();
    final totalCost = h.totalPurchaseAmountValue.round();
    final totalPnl = h.profitLossAmountValue.round();
    final totalPnlPct = h.profitLossRateValue;
    final pnlColor = _trendColor(t, totalPnl.toDouble());

    return PCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 투자 평가금액',
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: 12.5,
              fontWeight: PFontWeight.semi,
              color: t.fgTertiary,
            ),
          ),
          const SizedBox(height: PSpace.x4),
          Text(
            masked ? kHideMask : '${krw(totalEval)}원',
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontFeatures: _tnum,
              fontSize: 28,
              fontWeight: PFontWeight.bold,
              letterSpacing: -0.56,
              color: t.fgPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                masked
                    ? '••••'
                    : '${totalPnl >= 0 ? '+' : '−'}${krw(totalPnl, abs: true)}원',
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontFeatures: _tnum,
                  fontSize: 13.5,
                  fontWeight: PFontWeight.bold,
                  color: pnlColor,
                ),
              ),
              const SizedBox(width: PSpace.x8),
              _PctBadge(pct: totalPnlPct),
            ],
          ),
          const SizedBox(height: PSpace.x16),
          Container(height: 1, color: t.borderSubtle),
          const SizedBox(height: PSpace.x16),
          Row(
            children: [
              for (final (label, value) in [
                ('매입금액', masked ? '••••' : '${krw(totalCost)}원'),
                ('보유 종목', '${h.items.length}개'),
                (
                  '환율(USD)',
                  '₩${krw(kFxUsdKrw.truncate())}.${((kFxUsdKrw - kFxUsdKrw.truncate()) * 10).round()}'
                ),
              ])
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style:
                              PTypo.micro.copyWith(color: t.fgTertiary)),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontFeatures: _tnum,
                          fontSize: 13.5,
                          fontWeight: PFontWeight.bold,
                          color: t.fgPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- 종목 상세 ---------------------------------------------------------------

const _kRanges = ['1D', '1주', '1개월', '3개월', '1년'];

class _StockDetailBody extends StatefulWidget {
  const _StockDetailBody({
    required this.ticker,
    required this.holding,
    required this.watched,
    required this.onToggleWatch,
    required this.scrollController,
    required this.masked,
  });
  final String ticker;
  final TossHoldingsItem? holding;
  final bool watched;
  final VoidCallback onToggleWatch;
  final ScrollController scrollController;
  final bool masked;

  @override
  State<_StockDetailBody> createState() => _StockDetailBodyState();
}

class _StockDetailBodyState extends State<_StockDetailBody> {
  String _range = '1D';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = findStock(widget.ticker);
    if (s == null) return const SizedBox.shrink();
    final trend = _trendColor(t, s.changePct);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final starTone =
        dark ? PorestPalette.chartYellowLight : PorestPalette.chartYellow;

    // 국내 종목 상/하한가 (±30%, 호가단위 반올림)
    double tickOf(double p) => p >= 100000
        ? 500
        : p >= 10000
            ? 100
            : p >= 1000
                ? 10
                : 1;
    double roundTick(double p) {
      final tk = tickOf(p);
      return (p / tk).round() * tk;
    }

    final info = <(String, String, Color?)>[
      ('시가총액', s.marketCap, null),
      ('PER', s.per != null ? s.per!.toStringAsFixed(1) : '—', null),
      (
        'EPS',
        s.eps != null
            ? (s.isUs
                ? '\$${s.eps!.toStringAsFixed(2)}'
                : krw(s.eps!.round()))
            : '—',
        null
      ),
      if (!s.isUs) ...[
        ('상한가', krw(roundTick(s.price * 1.3).round()), t.statusDangerFg),
        ('하한가', krw(roundTick(s.price * 0.7).round()), t.fgBrand),
      ],
      ('52주 최고',
          s.isUs ? '\$${s.high52.toStringAsFixed(2)}' : krw(s.high52.round()),
          null),
      ('52주 최저',
          s.isUs ? '\$${s.low52.toStringAsFixed(2)}' : krw(s.low52.round()),
          null),
      ('거래량', s.vol, null),
    ];

    return ListView(
      controller: widget.scrollController,
      padding:
          const EdgeInsets.fromLTRB(PSpace.x20, 0, PSpace.x20, PSpace.x24),
      children: [
        // 헤더: 종목명 · 관심 토글
        Row(
          children: [
            _StockBadge(stock: s, size: 46),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: 17,
                      fontWeight: PFontWeight.bold,
                      letterSpacing: -0.17,
                      color: t.fgPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          s.ticker,
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 시장 배지 (NASDAQ / KRX·NXT) — shared PBadge(secondary)
                      PBadge(
                        label: s.isUs ? 'NASDAQ' : 'KRX·NXT',
                        variant: PBadgeVariant.secondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '· ${s.sector}',
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 관심 토글 — active=chart-yellow blend (spec)
            InkWell(
              onTap: widget.onToggleWatch,
              borderRadius: PRadius.tile(38),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.watched
                      ? chipFill(context, starTone, t: 0.18)
                      : t.bgSunken,
                  borderRadius: PRadius.tile(38),
                  border: Border.all(color: t.borderSubtle),
                ),
                child: Icon(
                  LucideIcons.star,
                  size: 18,
                  fill: widget.watched ? 1 : 0,
                  color: widget.watched
                      ? chipText(context, starTone, t: 0.62)
                      : t.fgTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x16),

        // 현재가
        Text(
          _fmtPrice(s),
          style: TextStyle(
            fontFamily: PTypo.sans,
            fontFeatures: _tnum,
            fontSize: PFontSize.h1,
            fontWeight: PFontWeight.bold,
            letterSpacing: -0.6,
            color: t.fgPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            _PctBadge(pct: s.changePct, size: 14),
            if (s.isUs) ...[
              const SizedBox(width: PSpace.x8),
              Text(
                '≈ ${krw(priceKrw(s))}원',
                style: PTypo.caption.copyWith(color: t.fgTertiary, fontFeatures: _tnum),
              ),
            ],
          ],
        ),
        const SizedBox(height: PSpace.x16),

        // 차트 + 기간
        PCard(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: Column(
            children: [
              _Sparkline(values: s.spark, color: trend, height: 150, fill: true),
              const SizedBox(height: PSpace.x8),
              PTabs<String>(
                value: _range,
                onChanged: (v) => setState(() => _range = v),
                variant: PTabsVariant.container,
                size: PTabsSize.sm,
                expand: true,
                items: [
                  for (final r in _kRanges)
                    PTabItem(value: r, label: r),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        // 내 보유
        if (widget.holding != null) ...[
          Builder(builder: (context) {
            final h = widget.holding!;
            final ev = h.marketValueAmountValue.round();
            final pnl = h.profitLossAmountValue.round();
            final pnlPct = h.profitLossRateValue;
            final qty = h.quantityValue;
            final qtyLabel = qty == qty.roundToDouble()
                ? '${qty.round()}주'
                : '${qty.toStringAsFixed(4)}주';
            final avg = h.averagePurchasePriceValue;
            final rows = <(String, String, Color)>[
              ('평가금액', widget.masked ? '••••' : '${krw(ev)}원', t.fgPrimary),
              (
                '평가손익',
                widget.masked
                    ? '••••'
                    : '${pnl >= 0 ? '+' : '−'}${krw(pnl, abs: true)}원',
                _trendColor(t, pnl.toDouble())
              ),
              ('보유수량', qtyLabel, t.fgPrimary),
              (
                '수익률',
                '${pnlPct >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(2)}%',
                _trendColor(t, pnl.toDouble())
              ),
              (
                '평균단가',
                h.isUs ? '\$${avg.toStringAsFixed(2)}' : '${krw(avg.round())}원',
                t.fgSecondary
              ),
              ('매도가능', qtyLabel, t.fgSecondary),
            ];
            return PCard(
              padding: const EdgeInsets.all(PSpace.x16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('내 보유', tokens: t),
                  const SizedBox(height: PSpace.x12),
                  for (var i = 0; i < rows.length; i += 2) ...[
                    if (i > 0) const SizedBox(height: PSpace.x12),
                    Row(
                      children: [
                        Expanded(child: _KvCell(rows[i], tokens: t)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: i + 1 < rows.length
                              ? _KvCell(rows[i + 1], tokens: t)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: PSpace.x16),
        ],

        // 호가 / 체결
        _QuotesCard(stock: s),
        const SizedBox(height: PSpace.x16),

        // 기본 정보
        PCard(
          padding: const EdgeInsets.all(PSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('기본 정보', tokens: t),
              const SizedBox(height: PSpace.x4),
              for (var i = 0; i < info.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(
                            top: BorderSide(color: t.borderSubtle),
                          ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        info[i].$1,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: 12.5,
                          color: t.fgTertiary,
                        ),
                      ),
                      Text(
                        info[i].$2,
                        style: PTypo.bodySm.copyWith(
                          color: info[i].$3 ?? t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                          fontFeatures: _tnum,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        // 일별 시세
        _DailyQuoteTable(stock: s),
        const SizedBox(height: PSpace.x16),

        // 매매 (모의) — 매도=primary(파랑), 매수=danger(빨강) — 국내 통념
        Row(
          children: [
            Expanded(
              child: PButton(
                label: '매도',
                size: PButtonSize.lg,
                fullWidth: true,
                onPressed: () => showPSnackBar(
                    context, '${s.name} 매도 주문 — Open API 연동 시 동작'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PButton(
                label: '매수',
                variant: PButtonVariant.danger,
                size: PButtonSize.lg,
                fullWidth: true,
                onPressed: () => showPSnackBar(
                    context, '${s.name} 매수 주문 — Open API 연동 시 동작'),
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x16),
        // 수수료 안내 — 토스증권 Open API 기준
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: t.bgSunken,
            borderRadius: PRadius.brMd,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, size: 14, color: t.fgTertiary),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: Text(
                  s.isUs
                      ? '미국주식 매매수수료 0.1% · 환전 수수료 별도 적용'
                      : '국내주식 매매수수료 무료 (2026.6까지) · 이후 KRX 0.015% / NXT 0.014%',
                  style: PTypo.micro
                      .copyWith(color: t.fgSecondary, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),
        Text(
          '토스증권 Open API 연동 시 실시간 호가·체결가가 반영됩니다.\n시세는 투자 참고용이며 실제 주문은 약관 동의 후 가능합니다.',
          textAlign: TextAlign.center,
          style: PTypo.micro.copyWith(color: t.fgTertiary, height: 1.5),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.tokens});
  final String label;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontFamily: PTypo.sans,
          fontSize: 12.5,
          fontWeight: PFontWeight.bold,
          color: tokens.fgSecondary,
        ),
      );
}

class _KvCell extends StatelessWidget {
  const _KvCell(this.row, {required this.tokens});
  final (String, String, Color) row;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.$1, style: PTypo.micro.copyWith(color: tokens.fgTertiary)),
          const SizedBox(height: 2),
          Text(
            row.$2,
            style: PTypo.bodySm.copyWith(
              color: row.$3,
              fontWeight: PFontWeight.bold,
              fontFeatures: _tnum,
            ),
          ),
        ],
      );
}

// ---- 호가창 (연동 전 시드 고정 의사난수 잔량) ----------------------------------

class _OrderBook extends StatelessWidget {
  const _OrderBook({required this.stock, this.live});
  final Stock stock;
  final TossOrderbook? live;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = stock;
    final base = s.price;
    final tick = s.isUs
        ? 0.5
        : base >= 100000
            ? 500.0
            : base >= 10000
                ? 100.0
                : 50.0;
    double rng(int i) => ((i * 9301 + 49297) % 233280) / 233280;
    final hasLive =
        live != null && live!.asks.isNotEmpty && live!.bids.isNotEmpty;
    // 라이브: asks=낮은가격순 → 상단 표시 위해 5개 역순(높은가격 위), bids=높은가격순 그대로.
    final asks = hasLive
        ? [
            for (final e in live!.asks.take(5))
              (p: e.priceValue, q: e.volumeValue.round()),
          ].reversed.toList()
        : [
            for (final i in [4, 3, 2, 1, 0])
              (p: base + tick * (i + 1), q: (40 + rng(i + 1) * 960).round()),
          ];
    final bids = hasLive
        ? [
            for (final e in live!.bids.take(5))
              (p: e.priceValue, q: e.volumeValue.round()),
          ]
        : [
            for (final i in [0, 1, 2, 3, 4])
              (p: base - tick * (i + 1), q: (40 + rng(i + 7) * 960).round()),
          ];
    var maxQ = 1;
    for (final a in asks) {
      if (a.q > maxQ) maxQ = a.q;
    }
    for (final b in bids) {
      if (b.q > maxQ) maxQ = b.q;
    }
    String fmt(double p) =>
        s.isUs ? '\$${p.toStringAsFixed(2)}' : krw(p.round());

    Widget qtyBar({
      required int q,
      required Color tone,
      required bool alignRight,
    }) {
      return SizedBox(
        height: 22,
        child: Stack(
          children: [
            FractionallySizedBox(
              alignment:
                  alignRight ? Alignment.centerRight : Alignment.centerLeft,
              widthFactor: q / maxQ,
              child: Container(
                decoration: BoxDecoration(
                  color: chipFill(context, tone, t: 0.13),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Align(
              alignment:
                  alignRight ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                    right: alignRight ? 6 : 0, left: alignRight ? 0 : 6),
                child: Text(
                  krw(q),
                  style:
                      PTypo.micro.copyWith(color: t.fgTertiary, fontFeatures: _tnum),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget row({required double p, required int q, required bool isAsk}) {
      final priceColor = isAsk ? t.fgBrand : t.statusDangerFg;
      return SizedBox(
        height: 26,
        child: Row(
          children: [
            Expanded(
              child: isAsk
                  ? const SizedBox.shrink()
                  : qtyBar(q: q, tone: t.statusDangerFg, alignRight: true),
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
                  ? qtyBar(q: q, tone: t.fgBrand, alignRight: false)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '매수 잔량',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 10.5,
                  fontWeight: PFontWeight.semi,
                  color: t.fgTertiary,
                ),
              ),
            ),
            const SizedBox(width: 92),
            Expanded(
              child: Text(
                '매도 잔량',
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 10.5,
                  fontWeight: PFontWeight.semi,
                  color: t.fgTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x4),
        for (final a in asks) row(p: a.p, q: a.q, isAsk: true),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: t.borderSubtle),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _fmtPrice(s),
                style: PTypo.bodySm.copyWith(
                  color: _trendColor(t, s.changePct),
                  fontWeight: PFontWeight.bold,
                  fontFeatures: _tnum,
                ),
              ),
              const SizedBox(width: 6),
              _PctBadge(pct: s.changePct, size: 11),
            ],
          ),
        ),
        for (final b in bids) row(p: b.p, q: b.q, isAsk: false),
      ],
    );
  }
}

// ---- 시장 지수 값 포맷 (천단위 + 소수 2자리) ----------------------------------

String _fmtIndex(double v) {
  final neg = v < 0;
  final abs = v.abs();
  final intPart = abs.truncate();
  final dec = ((abs - intPart) * 100).round().toString().padLeft(2, '0');
  final intStr = intPart.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );
  return '${neg ? '-' : ''}$intStr.$dec';
}

// ---- 시장 지수 스트립 (가로 스크롤) ------------------------------------------

class _IndexStrip extends StatelessWidget {
  const _IndexStrip();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: kMarketIndices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final ix = kMarketIndices[i];
          return SizedBox(
            width: 128,
            child: PCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ix.name,
                    style: PTypo.caption.copyWith(
                      color: t.fgSecondary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmtIndex(ix.value),
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontFeatures: _tnum,
                      fontSize: 15,
                      fontWeight: PFontWeight.bold,
                      letterSpacing: -0.3,
                      color: t.fgPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _PctBadge(pct: ix.changePct, size: 11),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---- 발견(디스커버리) 랭킹 — 급상승/급하락/거래량 ----------------------------

class _DiscoverPanel extends StatefulWidget {
  const _DiscoverPanel({required this.onPick});
  final void Function(String ticker) onPick;

  @override
  State<_DiscoverPanel> createState() => _DiscoverPanelState();
}

class _DiscoverPanelState extends State<_DiscoverPanel> {
  String _tab = 'gainers';

  double _volNum(String vol) {
    final raw = vol.replaceAll(',', '');
    if (raw.endsWith('M')) {
      return (double.tryParse(raw.substring(0, raw.length - 1)) ?? 0) * 1000000;
    }
    if (raw.endsWith('K')) {
      return (double.tryParse(raw.substring(0, raw.length - 1)) ?? 0) * 1000;
    }
    return double.tryParse(raw) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final list = [...kStocks];
    if (_tab == 'gainers') {
      list.sort((a, b) => b.changePct.compareTo(a.changePct));
    } else if (_tab == 'losers') {
      list.sort((a, b) => a.changePct.compareTo(b.changePct));
    } else {
      list.sort((a, b) => _volNum(b.vol).compareTo(_volNum(a.vol)));
    }
    final top = list.take(6).toList();

    return Column(
      children: [
        PTabs<String>(
          value: _tab,
          onChanged: (v) => setState(() => _tab = v),
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          items: const [
            PTabItem(value: 'gainers', label: '급상승'),
            PTabItem(value: 'losers', label: '급하락'),
            PTabItem(value: 'volume', label: '거래량'),
          ],
        ),
        const SizedBox(height: 10),
        PCard(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              for (var i = 0; i < top.length; i++)
                Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${i + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontFeatures: _tnum,
                          fontSize: 14,
                          fontWeight: PFontWeight.bold,
                          color: i < 3 ? t.fgBrand : t.fgTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _StockRow(
                        ticker: top[i].ticker,
                        onTap: () => widget.onPick(top[i].ticker),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---- 호가 / 체결 탭 카드 -----------------------------------------------------

class _QuotesCard extends ConsumerStatefulWidget {
  const _QuotesCard({required this.stock});
  final Stock stock;

  @override
  ConsumerState<_QuotesCard> createState() => _QuotesCardState();
}

class _QuotesCardState extends ConsumerState<_QuotesCard> {
  String _tab = 'book';

  @override
  Widget build(BuildContext context) {
    final s = widget.stock;
    // 라이브 호가·체결 (토스 Open API). 키/데이터 없으면 의사난수 폴백.
    final liveBook = ref.watch(tossOrderbookProvider(s.ticker)).asData?.value;
    final liveTrades = ref.watch(tossTradesProvider(s.ticker)).asData?.value;
    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PTabs<String>(
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
            variant: PTabsVariant.container,
            size: PTabsSize.sm,
            expand: true,
            items: const [
              PTabItem(value: 'book', label: '호가'),
              PTabItem(value: 'tape', label: '체결'),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          if (_tab == 'book')
            _OrderBook(stock: s, live: liveBook)
          else
            _TradeTape(stock: s, live: liveTrades),
        ],
      ),
    );
  }
}

// ---- 체결 테이프 (연동 전 시드 고정 의사난수) --------------------------------

class _TradeTape extends StatelessWidget {
  const _TradeTape({required this.stock, this.live});
  final Stock stock;
  final List<TossTrade>? live;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = stock;
    final tick = s.isUs
        ? 0.5
        : s.price >= 100000
            ? 500.0
            : s.price >= 10000
                ? 100.0
                : 50.0;
    double rng(int i) => ((i * 2654435761) % 100000) / 100000;
    String fmt(double p) =>
        s.isUs ? '\$${p.toStringAsFixed(2)}' : krw(p.round());

    // 라이브 체결(토스): dir=직전 체결가 대비 방향. 없으면 의사난수 폴백.
    final liveData = live;
    final fills = (liveData != null && liveData.isNotEmpty)
        ? [
            for (var i = 0; i < liveData.length && i < 12; i++)
              (() {
                final tr = liveData[i];
                final p = tr.priceValue;
                final prev =
                    i + 1 < liveData.length ? liveData[i + 1].priceValue : p;
                final time = RegExp(r'(\d{2}:\d{2}:\d{2})')
                        .firstMatch(tr.timestamp)
                        ?.group(1) ??
                    tr.timestamp;
                return (
                  time: time,
                  p: p,
                  q: tr.volumeValue.round(),
                  dir: p >= prev ? 1 : -1,
                );
              })(),
          ]
        : [
            for (var i = 0; i < 12; i++)
              (() {
                final dir = rng(i + 3) > 0.45 ? 1 : -1;
                final p = s.price + dir * tick * (rng(i + 9) * 2).round();
                final q = (1 + rng(i + 5) * 80).round();
                final mm = 42 - i;
                final ss = (rng(i + 7) * 59).round();
                return (
                  time:
                      '15:${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}',
                  p: p,
                  q: q,
                  dir: dir,
                );
              })(),
          ];

    TextStyle head() => TextStyle(
          fontFamily: PTypo.sans,
          fontSize: 10.5,
          fontWeight: PFontWeight.semi,
          color: t.fgTertiary,
        );

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text('체결시각', style: head())),
            Expanded(
                child: Text('체결가', textAlign: TextAlign.right, style: head())),
            Expanded(
                child: Text('체결량', textAlign: TextAlign.right, style: head())),
          ],
        ),
        const SizedBox(height: PSpace.x4),
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

// ---- 일별 시세 표 ------------------------------------------------------------

class _DailyQuoteTable extends StatelessWidget {
  const _DailyQuoteTable({required this.stock});
  final Stock stock;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = stock;
    final rows = dailyQuotes(s);
    String fmt(double v) =>
        s.isUs ? '\$${v.toStringAsFixed(2)}' : krw(v.round());
    String fmtVol(double v) =>
        s.isUs ? '${v.toStringAsFixed(1)}M' : krw(v.round());

    Widget headCell(String label, int flex, TextAlign align) => Expanded(
          flex: flex,
          child: Text(
            label,
            textAlign: align,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.micro,
              fontWeight: PFontWeight.semi,
              color: t.fgTertiary,
            ),
          ),
        );

    Widget cell(String text, int flex, TextAlign align, Color color,
            {FontWeight? weight}) =>
        Expanded(
          flex: flex,
          child: Text(
            text,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontFeatures: _tnum,
              fontSize: 12.5,
              fontWeight: weight ?? PFontWeight.regular,
              color: color,
            ),
          ),
        );

    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('일별 시세', tokens: t),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: PSpace.x8),
            child: Row(
              children: [
                headCell('일자', 10, TextAlign.left),
                headCell('종가', 12, TextAlign.right),
                headCell('등락률', 10, TextAlign.right),
                headCell('거래량', 13, TextAlign.right),
              ],
            ),
          ),
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.borderSubtle)),
              ),
              child: Row(
                children: [
                  cell(r.date, 10, TextAlign.left, t.fgSecondary),
                  cell(fmt(r.close), 12, TextAlign.right, t.fgPrimary,
                      weight: PFontWeight.semi),
                  cell(
                    '${r.chg >= 0 ? '+' : ''}${r.chg.toStringAsFixed(2)}%',
                    10,
                    TextAlign.right,
                    _trendColor(t, r.chg),
                    weight: PFontWeight.bold,
                  ),
                  cell(fmtVol(r.vol), 13, TextAlign.right, t.fgTertiary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
