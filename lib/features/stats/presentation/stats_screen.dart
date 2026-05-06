import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../expense/application/expense_providers.dart';
import '../application/stats_providers.dart';
import '../domain/stats_models.dart';

/// 통계 탭. 월 선택 + 5종 차트.
///
/// 1. 월간 수입/지출 + 잔액 카드
/// 2. 6개월 추이 (BarChart 수입/지출)
/// 3. 카테고리 분포 (PieChart, EXPENSE 만)
/// 4. 가맹점 Top 5 (가로 막대 리스트)
/// 5. 시간대 히트맵 (요일 x 시간)
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});
  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  late DateTime _month = monthStart(DateTime.now());

  YM get _ym => (year: _month.year, month: _month.month);
  DateRange get _range => (
        startDate: _fmtDate(_month),
        endDate: _fmtDate(DateTime(_month.year, _month.month + 1, 0)),
      );

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;

    final monthlyAsync = ref.watch(monthlySummaryProvider(_ym));
    final trendAsync = ref.watch(monthlyTrendProvider(6));
    final merchantAsync = ref.watch(merchantSummaryProvider(_range));
    final heatmapAsync = ref.watch(heatmapProvider(_ym));
    final byAssetAsync = ref.watch(assetExpenseSummaryProvider(_range));

    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(monthlySummaryProvider(_ym));
        ref.invalidate(monthlyTrendProvider(6));
        ref.invalidate(merchantSummaryProvider(_range));
        ref.invalidate(heatmapProvider(_ym));
        ref.invalidate(assetExpenseSummaryProvider(_range));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x40),
        children: [
          _MonthHeader(
            month: _month,
            onPrev: () => setState(() => _month =
                DateTime(_month.year, _month.month - 1, 1)),
            onNext: () => setState(() => _month =
                DateTime(_month.year, _month.month + 1, 1)),
            tokens: t,
          ),
          const SizedBox(height: PSpace.x12),

          // 1. 월간 요약
          _MonthSummaryCard(
              async: monthlyAsync, masked: settings.hideAmounts, tokens: t),
          const SizedBox(height: PSpace.x12),

          // 2. 6개월 추이 (BarChart)
          _SectionCard(
            title: '최근 6개월 수입/지출',
            tokens: t,
            child: _TrendChart(async: trendAsync, tokens: t),
          ),
          const SizedBox(height: PSpace.x12),

          // 3. 카테고리 분포
          _SectionCard(
            title: '${_month.month}월 카테고리 분포',
            tokens: t,
            child: _CategoryDonut(
                async: monthlyAsync, masked: settings.hideAmounts, tokens: t),
          ),
          const SizedBox(height: PSpace.x12),

          // 4. 가맹점 Top
          _SectionCard(
            title: '${_month.month}월 가맹점 Top 5',
            tokens: t,
            child: _MerchantTop(
                async: merchantAsync, masked: settings.hideAmounts, tokens: t),
          ),
          const SizedBox(height: PSpace.x12),

          // 5. 자산별 지출 분포
          _SectionCard(
            title: '${_month.month}월 자산별 지출',
            tokens: t,
            child: _AssetUsageList(
                async: byAssetAsync, masked: settings.hideAmounts, tokens: t),
          ),
          const SizedBox(height: PSpace.x12),

          // 5. 시간대 히트맵
          _SectionCard(
            title: '${_month.month}월 시간대 히트맵',
            tokens: t,
            child: _Heatmap(async: heatmapAsync, tokens: t),
          ),
        ],
      ),
    );
  }
}

// ─── Month picker header ───────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.tokens,
  });
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: onPrev,
            icon: Icon(LucideIcons.chevronLeft, color: tokens.fgSecondary)),
        Text(yearMonth(month),
            style: PTypo.h4.copyWith(color: tokens.fgPrimary)),
        IconButton(
            onPressed: onNext,
            icon: Icon(LucideIcons.chevronRight, color: tokens.fgSecondary)),
      ],
    );
  }
}

// ─── Month summary card ────────────────────────────────────

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard(
      {required this.async, required this.masked, required this.tokens});
  final AsyncValue<MonthlySummary> async;
  final bool masked;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final s = async.value;
    final loading = async.isLoading && !async.hasValue;
    final income = s?.totalIncome ?? 0;
    final expense = s?.totalExpense ?? 0;
    final balance = income - expense;

    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCol(
                  label: '수입',
                  value: loading ? '—' : '+${krwMasked(income, masked)}',
                  color: tokens.statusSuccess,
                  tokens: tokens,
                ),
              ),
              Expanded(
                child: _SummaryCol(
                  label: '지출',
                  value: loading ? '—' : '-${krwMasked(expense, masked)}',
                  color: tokens.statusDanger,
                  tokens: tokens,
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          Divider(height: 1, color: tokens.borderSubtle),
          const SizedBox(height: PSpace.x12),
          Row(
            children: [
              Text('잔액',
                  style: PTypo.bodySm.copyWith(
                      color: tokens.fgSecondary,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                  loading
                      ? '—'
                      : krwMasked(balance, masked, sign: true),
                  style: PTypo.body.copyWith(
                      color: balance >= 0
                          ? tokens.statusSuccess
                          : tokens.statusDanger,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCol extends StatelessWidget {
  const _SummaryCol(
      {required this.label,
      required this.value,
      required this.color,
      required this.tokens});
  final String label;
  final String value;
  final Color color;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
        const SizedBox(height: 2),
        Text(value,
            style: PTypo.body.copyWith(
                color: color, fontWeight: FontWeight.w700, fontSize: 17)),
      ],
    );
  }
}

// ─── Section card wrapper ─────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.child, required this.tokens});
  final String title;
  final Widget child;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: PTypo.body.copyWith(
                  color: tokens.fgPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: PSpace.x12),
          child,
        ],
      ),
    );
  }
}

// ─── 6개월 추이 BarChart ──────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.async, required this.tokens});
  final AsyncValue<List<MonthlyTrend>> async;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <MonthlyTrend>[];
    if (async.isLoading && list.isEmpty) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (async.hasError && list.isEmpty) {
      return _ErrorMini(text: '추이 로드 실패', tokens: tokens);
    }
    if (list.isEmpty) {
      return _EmptyMini(text: '데이터 없음', tokens: tokens);
    }

    final maxY = list
        .fold<int>(0,
            (m, t) => [m, t.totalIncome, t.totalExpense].reduce((a, b) => a > b ? a : b))
        .toDouble();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY > 0 ? maxY * 1.15 : 100,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: true),
          gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 25,
              getDrawingHorizontalLine: (_) => FlLine(
                  color: tokens.borderSubtle, strokeWidth: 1, dashArray: [3, 3])),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(_axisFmt(v.toInt()),
                    style: PTypo.caption
                        .copyWith(color: tokens.fgTertiary, fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= list.length) return const SizedBox();
                  return Text('${list[i].month}월',
                      style: PTypo.caption.copyWith(
                          color: tokens.fgSecondary, fontSize: 10));
                },
              ),
            ),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (int i = 0; i < list.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: [
                  BarChartRodData(
                      toY: list[i].totalIncome.toDouble(),
                      color: tokens.statusSuccess,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2))),
                  BarChartRodData(
                      toY: list[i].totalExpense.toDouble(),
                      color: tokens.statusDanger,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _axisFmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return '$v';
  }
}

// ─── 카테고리 분포 도넛 ─────────────────────────────────

class _CategoryDonut extends ConsumerWidget {
  const _CategoryDonut(
      {required this.async, required this.masked, required this.tokens});
  final AsyncValue<MonthlySummary> async;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = async.value;
    if (async.isLoading && s == null) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (async.hasError && s == null) {
      return _ErrorMini(text: '카테고리 로드 실패', tokens: tokens);
    }
    final all = s?.categoryBreakdown ?? const <CategoryBreakdown>[];
    final exp = all.where((c) => c.expenseType == 'EXPENSE').toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    if (exp.isEmpty) return _EmptyMini(text: '데이터 없음', tokens: tokens);

    final categories = ref.watch(categoriesProvider).value ?? const [];
    final total = exp.fold<int>(0, (s, c) => s + c.totalAmount);

    Color colorFor(CategoryBreakdown c) {
      for (final cat in categories) {
        try {
          if (cat.rowId == c.categoryRowId) {
            return parseColor(cat.color, fallback: tokens.fgBrand);
          }
        } catch (_) {}
      }
      return tokens.fgBrand;
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                for (final c in exp.take(8))
                  PieChartSectionData(
                    value: c.totalAmount.toDouble(),
                    color: colorFor(c),
                    radius: 32,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: PSpace.x8),
        for (final c in exp.take(5))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: colorFor(c), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.categoryName ?? '미지정',
                      style: PTypo.bodySm
                          .copyWith(color: tokens.fgPrimary)),
                ),
                Text(
                  '${total > 0 ? ((c.totalAmount / total) * 100).round() : 0}%',
                  style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                ),
                const SizedBox(width: 8),
                Text(krwMasked(c.totalAmount, masked),
                    style: PTypo.bodySm.copyWith(
                        color: tokens.fgPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── 가맹점 Top ──────────────────────────────────────────

class _MerchantTop extends StatelessWidget {
  const _MerchantTop(
      {required this.async, required this.masked, required this.tokens});
  final AsyncValue<List<MerchantSummary>> async;
  final bool masked;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <MerchantSummary>[];
    if (async.isLoading && list.isEmpty) {
      return const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator()));
    }
    if (async.hasError && list.isEmpty) {
      return _ErrorMini(text: '가맹점 로드 실패', tokens: tokens);
    }
    if (list.isEmpty) return _EmptyMini(text: '데이터 없음', tokens: tokens);

    final top5 = (List.of(list)..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)))
        .take(5)
        .toList();
    final maxAmt = top5.first.totalAmount;

    return Column(
      children: [
        for (int i = 0; i < top5.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                          color: tokens.bgMuted,
                          borderRadius: PRadius.brXs),
                      alignment: Alignment.center,
                      child: Text('${i + 1}',
                          style: PTypo.caption.copyWith(
                              color: tokens.fgSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(top5[i].merchant ?? '(이름 없음)',
                            style: PTypo.bodySm
                                .copyWith(color: tokens.fgPrimary))),
                    Text('${top5[i].count}건',
                        style: PTypo.caption
                            .copyWith(color: tokens.fgTertiary)),
                    const SizedBox(width: 8),
                    Text(krwMasked(top5[i].totalAmount, masked),
                        style: PTypo.bodySm.copyWith(
                            color: tokens.fgPrimary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: PRadius.brXs,
                  child: LinearProgressIndicator(
                    value: maxAmt > 0 ? top5[i].totalAmount / maxAmt : 0,
                    minHeight: 6,
                    backgroundColor: tokens.bgTrack,
                    color: tokens.fgBrand,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── 자산별 지출 ───────────────────────────────────────────

class _AssetUsageList extends StatelessWidget {
  const _AssetUsageList(
      {required this.async, required this.masked, required this.tokens});
  final AsyncValue<List<AssetExpenseSummary>> async;
  final bool masked;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <AssetExpenseSummary>[];
    if (async.isLoading && list.isEmpty) {
      return const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator()));
    }
    if (async.hasError && list.isEmpty) {
      return _ErrorMini(text: '자산 로드 실패', tokens: tokens);
    }
    if (list.isEmpty) return _EmptyMini(text: '데이터 없음', tokens: tokens);

    final sorted = (List.of(list)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)));
    final maxAmt = sorted.first.totalAmount;
    final total = sorted.fold<int>(0, (s, a) => s + a.totalAmount);

    return Column(
      children: [
        for (final a in sorted)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(a.assetName ?? '(이름 없음)',
                          style: PTypo.bodySm
                              .copyWith(color: tokens.fgPrimary)),
                    ),
                    Text(
                        total > 0
                            ? '${(a.totalAmount * 100 / total).toStringAsFixed(1)}%'
                            : '-',
                        style:
                            PTypo.caption.copyWith(color: tokens.fgTertiary)),
                    const SizedBox(width: 8),
                    Text(krwMasked(a.totalAmount, masked),
                        style: PTypo.bodySm.copyWith(
                            color: tokens.fgPrimary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: PRadius.brXs,
                  child: LinearProgressIndicator(
                    value: maxAmt > 0 ? a.totalAmount / maxAmt : 0,
                    minHeight: 6,
                    backgroundColor: tokens.bgTrack,
                    color: tokens.fgBrand,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── 히트맵 ───────────────────────────────────────────────

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.async, required this.tokens});
  final AsyncValue<List<HeatmapCell>> async;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <HeatmapCell>[];
    if (async.isLoading && list.isEmpty) {
      return const SizedBox(
          height: 120, child: Center(child: CircularProgressIndicator()));
    }
    if (async.hasError && list.isEmpty) {
      return _ErrorMini(text: '히트맵 로드 실패', tokens: tokens);
    }
    if (list.isEmpty) return _EmptyMini(text: '데이터 없음', tokens: tokens);

    final cellMap = <String, int>{};
    int maxAmt = 0;
    for (final c in list) {
      final key = '${c.dayOfWeek}-${c.hour}';
      cellMap[key] = (cellMap[key] ?? 0) + c.totalAmount;
      if (cellMap[key]! > maxAmt) maxAmt = cellMap[key]!;
    }

    const dows = ['월', '화', '수', '목', '금', '토', '일'];
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 18),
            // 시간 라벨 (0,6,12,18 만)
            for (int h = 0; h < 24; h++)
              Expanded(
                child: Text(
                  h % 6 == 0 ? '$h' : '',
                  textAlign: TextAlign.center,
                  style: PTypo.caption.copyWith(
                      color: tokens.fgTertiary, fontSize: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (int d = 1; d <= 7; d++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text(dows[d - 1],
                      style: PTypo.caption.copyWith(
                          color: tokens.fgSecondary, fontSize: 10)),
                ),
                for (int h = 0; h < 24; h++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(0.5),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _heatColor(
                                cellMap['$d-$h'] ?? 0, maxAmt, tokens),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Color _heatColor(int v, int max, PorestTokens t) {
    if (max == 0 || v == 0) return t.bgMuted;
    final ratio = (v / max).clamp(0.05, 1.0);
    return t.fgBrand.withValues(alpha: ratio);
  }
}

// ─── small helpers ────────────────────────────────────────

class _ErrorMini extends StatelessWidget {
  const _ErrorMini({required this.text, required this.tokens});
  final String text;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
      child: Center(
        child: Text(text,
            style: PTypo.bodySm.copyWith(color: tokens.statusDanger)),
      ),
    );
  }
}

class _EmptyMini extends StatelessWidget {
  const _EmptyMini({required this.text, required this.tokens});
  final String text;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
      child: Center(
        child: Text(text,
            style: PTypo.bodySm.copyWith(color: tokens.fgTertiary)),
      ),
    );
  }
}
