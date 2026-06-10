import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/widgets/p_back_button.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_chip.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_search_field.dart';
import '../../../shared/widgets/p_segmented.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../data/stocks_mock.dart';
import '../domain/stock.dart';

/// 증권 — 시세 · 보유 · 관심 · 호가 (토스증권 Open API 연동 가정, mock 시세).
/// 웹 `pages/stocks/ui/StocksPage.tsx` 미러.
/// 상승=statusDangerFg / 하락=fgBrand (국내 증권 통념, 기존 시맨틱 토큰 재활용).
class StocksScreen extends ConsumerStatefulWidget {
  const StocksScreen({super.key});

  @override
  ConsumerState<StocksScreen> createState() => _StocksScreenState();
}

enum _Seg { holdings, watch }

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

    final holdingsSorted = [...kStockHoldings]
      ..sort((a, b) => holdingEval(b).compareTo(holdingEval(a)));
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
          _SummaryCard(masked: masked),
          const SizedBox(height: PSpace.x16),
          // 종목 검색 트리거 — 공통 PSearchField 시각(36px) 그대로, 탭 시 검색 시트
          GestureDetector(
            onTap: _openSearch,
            child: const AbsorbPointer(
              child: PSearchField(hint: '종목 검색'),
            ),
          ),
          const SizedBox(height: 14),
          PSegmented<_Seg>(
            value: _seg,
            onChanged: (v) => setState(() => _seg = v),
            options: [
              PSegmentOption(
                  value: _Seg.holdings,
                  label: '보유 ${kStockHoldings.length}'),
              PSegmentOption(
                  value: _Seg.watch, label: '관심 ${_watchedTickers.length}'),
            ],
          ),
          const SizedBox(height: 14),
          if (_seg == _Seg.holdings)
            PCard(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  for (final h in holdingsSorted)
                    Builder(builder: (context) {
                      final ev = holdingEval(h);
                      final pnl = ev - holdingCost(h);
                      final pct = pnl / holdingCost(h) * 100;
                      return _StockRow(
                        ticker: h.ticker,
                        sub: '${h.qty}주 보유',
                        onTap: () => _openDetail(h.ticker),
                        right: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              krwMasked(ev, masked, mask: '••••'),
                              style: TextStyle(
                                fontFamily: PTypo.sans,
                                fontSize: 13.5,
                                fontWeight: PFontWeight.bold,
                                color: t.fgPrimary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${pnl >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontFamily: PTypo.sans,
                                fontSize: PFontSize.micro,
                                fontWeight: PFontWeight.bold,
                                color: _trendColor(t, pnl.toDouble()),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            )
          else ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in _watchGroups)
                  PChip(
                    label: '${g.name} ${g.tickers.length}',
                    selected: g.id == _activeGroup,
                    onTap: () => setState(() => _activeGroup = g.id),
                  ),
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
    final holding =
        kStockHoldings.where((h) => h.ticker == ticker).firstOrNull;
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
        borderRadius: BorderRadius.circular(11),
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

// ---- 요약 카드 ---------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.masked});
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final totalEval =
        kStockHoldings.fold<int>(0, (sum, h) => sum + holdingEval(h));
    final totalCost =
        kStockHoldings.fold<int>(0, (sum, h) => sum + holdingCost(h));
    final totalPnl = totalEval - totalCost;
    final totalPnlPct = totalPnl / totalCost * 100;
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
                ('보유 종목', '${kStockHoldings.length}개'),
                ('환율(USD)', '₩${krw(kFxUsdKrw.round())}.5'),
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
  final StockHolding? holding;
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

    final info = <(String, String)>[
      ('시가총액', s.marketCap),
      ('PER', s.per != null ? s.per!.toStringAsFixed(1) : '—'),
      (
        'EPS',
        s.eps != null
            ? (s.isUs
                ? '\$${s.eps!.toStringAsFixed(2)}'
                : krw(s.eps!.round()))
            : '—'
      ),
      ('52주 최고',
          s.isUs ? '\$${s.high52.toStringAsFixed(2)}' : krw(s.high52.round())),
      ('52주 최저',
          s.isUs ? '\$${s.low52.toStringAsFixed(2)}' : krw(s.low52.round())),
      ('거래량', s.vol),
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
                  const SizedBox(height: 1),
                  Text(
                    '${s.ticker} · ${s.isUs ? '미국' : 'KRX'} · ${s.sector}',
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
                ],
              ),
            ),
            // 관심 토글 — active=chart-yellow blend (spec)
            InkWell(
              onTap: widget.onToggleWatch,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.watched
                      ? chipFill(context, starTone, t: 0.18)
                      : t.bgSunken,
                  borderRadius: BorderRadius.circular(10),
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
                style: PTypo.caption.copyWith(color: t.fgTertiary),
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
              PSegmented<String>(
                value: _range,
                onChanged: (v) => setState(() => _range = v),
                options: [
                  for (final r in _kRanges)
                    PSegmentOption(value: r, label: r),
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
            final ev = holdingEval(h);
            final cost = holdingCost(h);
            final pnl = ev - cost;
            final pnlPct = pnl / cost * 100;
            final rows = <(String, String, Color)>[
              ('평가금액', widget.masked ? '••••' : '${krw(ev)}원', t.fgPrimary),
              (
                '평가손익',
                widget.masked
                    ? '••••'
                    : '${pnl >= 0 ? '+' : '−'}${krw(pnl, abs: true)}원',
                _trendColor(t, pnl.toDouble())
              ),
              ('보유수량', '${h.qty}주', t.fgPrimary),
              (
                '수익률',
                '${pnlPct >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(2)}%',
                _trendColor(t, pnl.toDouble())
              ),
              (
                '평균단가',
                s.isUs ? '\$${h.avg.toStringAsFixed(2)}' : '${krw(h.avg.round())}원',
                t.fgSecondary
              ),
              ('매입금액', widget.masked ? '••••' : '${krw(cost)}원', t.fgSecondary),
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
                        Expanded(child: _KvCell(rows[i + 1], tokens: t)),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: PSpace.x16),
        ],

        // 호가
        PCard(
          padding: const EdgeInsets.all(PSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('호가', tokens: t),
              const SizedBox(height: PSpace.x12),
              _OrderBook(stock: s),
            ],
          ),
        ),
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
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
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
            ),
          ),
        ],
      );
}

// ---- 호가창 (연동 전 시드 고정 의사난수 잔량) ----------------------------------

class _OrderBook extends StatelessWidget {
  const _OrderBook({required this.stock});
  final Stock stock;

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
    final asks = [
      for (final i in [4, 3, 2, 1, 0])
        (p: base + tick * (i + 1), q: (40 + rng(i + 1) * 960).round()),
    ];
    final bids = [
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
                  style: PTypo.micro.copyWith(color: t.fgTertiary),
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
