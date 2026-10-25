import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';

// 통계 · 비교 탭 구역(I-08 37) — 요약(큰 숫자 + 증감 + 견줌 막대) · 지표 셋 · 카테고리별 증감 · 요일별 지출 비교(ds 막대 두 계열).
// 증감은 ds Delta(▲ fg-critical · ▼ fg-informative), "좋은지 나쁜지" 는 글이 말한다(색 강조를 걷는다).

PDeltaDirection deltaDirection(num d) => d > 0
    ? PDeltaDirection.up
    : d < 0
    ? PDeltaDirection.down
    : PDeltaDirection.flat;

/// 견줌 막대 한 줄 — 기간 이름 44 · 막대 8 · 금액(한 줄 · 고정폭 · 오른쪽 끝). 금액이 길면 막대가 양보하고(최소 64), 그래도
/// 모자라면 금액이 아래 줄로 내려간다 — 숫자 중간에서 꺾지 않는다.
class _CompareBar extends StatelessWidget {
  const _CompareBar({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.current,
  });

  final String label;
  final String amount;
  final double ratio;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scaler = MediaQuery.textScalerOf(context);
    final labelStyle = PTypography.t2.copyWith(
      color: c.fgNeutralSubtle,
      fontWeight: FontWeight.w700,
    );
    final amountStyle = PTypography.t3.copyWith(
      color: current ? c.fgNeutral : c.fgNeutralMuted,
      fontWeight: FontWeight.w700,
      fontFeatures: tabularFigures,
    );
    final labelText = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44),
      child: Text(keepAll(label), style: labelStyle),
    );
    final amountText = Text(
      amount,
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.end,
      style: amountStyle,
    );
    final bar = ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PRounded.full),
        child: SizedBox(
          height: 8,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio.clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: current ? c.fgBrand : c.bgNeutralWeak,
                  // 지난 기간은 1px 테두리를 안쪽에(바탕과 구분)
                  border: current
                      ? null
                      : Border.all(color: c.strokeNeutralWeak),
                  borderRadius: BorderRadius.circular(PRounded.full),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        double w(String t, TextStyle s) => (TextPainter(
          text: TextSpan(text: t, style: s),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout()).width;
        final labelW = math.max(scaler.scale(44), w(label, labelStyle));
        final need =
            labelW +
            PSpacing.x2_5 +
            64 +
            PSpacing.x2_5 +
            w(amount, amountStyle);
        if (need <= constraints.maxWidth + 0.01) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              labelText,
              const SizedBox(width: PSpacing.x2_5),
              Expanded(child: bar),
              const SizedBox(width: PSpacing.x2_5),
              amountText,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PSpacing.x1,
          children: [
            Row(
              children: [
                labelText,
                const Spacer(),
                Flexible(child: amountText),
              ],
            ),
            bar,
          ],
        );
      },
    );
  }
}

/// 요약 — 머리 없는 띠. 큰 숫자 "{기간 지출}" + 증감(Delta) + 문장 + 견줌 막대 둘.
class StatsCompareSummarySection extends StatelessWidget {
  const StatsCompareSummarySection({
    super.key,
    required this.period,
    required this.now,
    required this.prev,
    required this.masked,
  });

  final StatsPeriod period;

  /// 둘 다 값이 있어야 그린다(아니면 첫 불러오기).
  final RangeSummary? now;
  final RangeSummary? prev;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (now == null || prev == null) {
      return statsSection(
        children: [
          PSkeleton.text(PTypography.t3, width: 100),
          const SizedBox(height: PSpacing.x1),
          PSkeleton.text(PTypography.t9, width: 200),
          const SizedBox(height: PSpacing.x3),
          PSkeleton.text(PTypography.t4, width: 240),
          const SizedBox(height: PSpacing.x4),
          const PSkeleton(
            width: double.infinity,
            height: 8,
            radius: PSkeletonRadius.full,
          ),
          const SizedBox(height: PSpacing.x2_5),
          const PSkeleton(
            width: double.infinity,
            height: 8,
            radius: PSkeletonRadius.full,
          ),
        ],
      );
    }
    final totalNow = now!.totalExpense;
    final totalPrev = prev!.totalExpense;
    final diff = totalNow - totalPrev;
    final less = diff <= 0;
    final hasPrev = totalPrev > 0;
    final barMax = math.max(1, math.max(totalNow, totalPrev));
    String money(int v) => statsWon(v, masked);
    final nowName = period.now(l);
    final prevName = period.previous(l);
    final base = PTypography.t4.copyWith(color: c.fgNeutral);
    return statsSection(
      children: [
        PCardStat(
          label: l.statsPeriodSpending(nowName),
          value: money(totalNow),
          delta: hasPrev
              ? PDelta(
                  direction: deltaDirection(diff),
                  value: statsChangeRate(
                    totalNow,
                    totalPrev,
                    fractionDigits: 1,
                  ),
                )
              : null,
        ),
        const SizedBox(height: PSpacing.x3),
        if (hasPrev && diff == 0)
          Text(l.statsCompareSame, style: base)
        else if (hasPrev)
          // 강조는 금액만 700 — 좋은지 나쁜지는 글이 말한다
          Text.rich(
            TextSpan(
              style: base,
              children: [
                TextSpan(text: '${keepAll(l.statsVsLastPrefix(prevName))} '),
                TextSpan(
                  text:
                      '${keepAllAmount(money(diff.abs()))} ${less ? l.statsVsLastDirLess : l.statsVsLastDirMore}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' ${keepAll(l.statsVsLastSuffix(prevName))}'),
              ],
            ),
          )
        else
          Text(
            keepAll(l.statsNoDataFor(prevName)),
            style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
          ),
        const SizedBox(height: PSpacing.x4),
        _CompareBar(
          label: nowName,
          amount: money(totalNow),
          ratio: totalNow / barMax,
          current: true,
        ),
        const SizedBox(height: PSpacing.x2_5),
        _CompareBar(
          label: prevName,
          amount: money(totalPrev),
          ratio: totalPrev / barMax,
          current: false,
        ),
      ],
    );
  }
}

/// 지표 셋(하루 평균 · 거래 건수 · 건당 평균) — 폰은 한 줄에 하나. 머리 없는 띠.
class StatsCompareMetricsSection extends StatelessWidget {
  const StatsCompareMetricsSection({
    super.key,
    required this.period,
    required this.now,
    required this.prev,
    required this.nowExpenses,
    required this.prevExpenses,
    required this.masked,
  });

  final StatsPeriod period;
  final RangeSummary? now;
  final RangeSummary? prev;
  final List<Expense>? nowExpenses;
  final List<Expense>? prevExpenses;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loading =
        now == null ||
        prev == null ||
        nowExpenses == null ||
        prevExpenses == null;
    if (loading) {
      return statsSection(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: PSpacing.x5),
            PSkeleton.text(PTypography.t3, width: 80),
            const SizedBox(height: PSpacing.x1),
            PSkeleton.text(PTypography.t9, width: 160),
            const SizedBox(height: PSpacing.x1),
            PSkeleton.text(PTypography.t3, width: 140),
          ],
        ],
      );
    }
    final totalNow = now!.totalExpense;
    final totalPrev = prev!.totalExpense;
    final txNow = statsExpenseCount(nowExpenses!);
    final txPrev = statsExpenseCount(prevExpenses!);
    final today = DateTime.now();
    DateTime dOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    var nowEnd = period.to;
    if (nowEnd.isAfter(today)) nowEnd = today;
    final nowDays = (dOnly(nowEnd).difference(dOnly(period.from)).inDays + 1)
        .clamp(1, 100000);
    final prevDays =
        (dOnly(period.prev.to).difference(dOnly(period.prev.from)).inDays + 1)
            .clamp(1, 100000);
    final rows = <({String label, int now, int prev, bool count})>[
      (
        label: l.statsCompareDailyAvg,
        now: (totalNow / nowDays).round(),
        prev: (totalPrev / prevDays).round(),
        count: false,
      ),
      (label: l.statsCompareTxCount, now: txNow, prev: txPrev, count: true),
      (
        label: l.statsComparePerTx,
        now: txNow > 0 ? (totalNow / txNow).round() : 0,
        prev: txPrev > 0 ? (totalPrev / txPrev).round() : 0,
        count: false,
      ),
    ];
    String fmt(int v, bool count) =>
        count ? l.statsCountValue(v) : statsWon(v, masked);
    final prevName = period.previous(l);
    return statsSection(
      children: [
        for (final (i, m) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: PSpacing.x5),
          PCardStat(
            label: m.label,
            value: fmt(m.now, m.count),
            delta: PDelta(
              direction: deltaDirection(m.now - m.prev),
              value: fmt((m.now - m.prev).abs(), m.count),
              text: '$prevName ${fmt(m.prev, m.count)}',
            ),
          ),
        ],
      ],
    );
  }
}

/// 카테고리별 증감 — 줄 = List 보기만 하는 줄: 이름 줄바꿈 · 설명 "지난 → 이번" · 뒤 증감 금액(U+2212 · 원까지) + %.
class StatsCompareCategorySection extends StatelessWidget {
  const StatsCompareCategorySection({
    super.key,
    required this.now,
    required this.prev,
    required this.categories,
    required this.masked,
  });

  final RangeSummary? now;
  final RangeSummary? prev;
  final List<ExpenseCategory>? categories;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final head = BudgetHead(
      title: l.statsCategoryDelta,
      note: l.statsSortByChange,
    );
    if (now == null || prev == null) {
      return BudgetListSection(
        header: head,
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpacing.x6,
                vertical: PSpacing.x3,
              ),
              child: Row(
                spacing: PSpacing.x3,
                children: [
                  const PSkeleton(
                    width: 40,
                    height: 40,
                    radius: PSkeletonRadius.r12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: PSpacing.x0_5,
                      children: [
                        PSkeleton.text(PTypography.t5, width: 100),
                        PSkeleton.text(PTypography.t3, width: 140),
                      ],
                    ),
                  ),
                  PSkeleton.text(PTypography.t5, width: 64),
                ],
              ),
            ),
        ],
      );
    }
    final byId = catIndex(categories);
    final byGroup =
        <
          int,
          ({String name, String? icon, String? color, int now, int prev})
        >{};
    void add(bool isNow, List<CategoryBreakdown> list) {
      for (final cb in list) {
        if (cb.expenseType != 'EXPENSE') continue;
        final id = cb.parentCategoryRowId ?? cb.categoryRowId;
        if (id == null) continue;
        final cur =
            byGroup[id] ??
            (
              name:
                  cb.parentCategoryName ?? cb.categoryName ?? l.statsUnassigned,
              icon: byId[id]?.icon,
              color: byId[id]?.color,
              now: 0,
              prev: 0,
            );
        byGroup[id] = (
          name: cur.name,
          icon: cur.icon,
          color: cur.color,
          now: cur.now + (isNow ? cb.totalAmount : 0),
          prev: cur.prev + (isNow ? 0 : cb.totalAmount),
        );
      }
    }

    add(true, now!.categoryBreakdown);
    add(false, prev!.categoryBreakdown);
    // 증감액 절댓값 큰 순
    final rows = byGroup.values.toList()
      ..sort((a, b) {
        final byDelta = (b.now - b.prev).abs().compareTo(
          (a.now - a.prev).abs(),
        );
        return byDelta != 0 ? byDelta : b.now.compareTo(a.now);
      });
    final top = rows.take(10).toList();
    if (top.isEmpty) {
      return BudgetSection(
        header: head,
        children: [BudgetEmptyLine(l.statsNoCompareData)],
      );
    }
    return BudgetListSection(
      header: head,
      children: [
        PList(
          semanticLabel: l.statsCategoryDelta,
          children: [
            for (final r in top)
              () {
                final diff = r.now - r.prev;
                final up = diff > 0;
                final fg = resolveChartColor(
                  context,
                  r.color,
                  fallback: c.fgBrand,
                );
                final tone = diff == 0
                    ? c.fgNeutral
                    : (up ? c.fgCritical : c.fgInformative);
                final sign = diff > 0 ? '+' : (diff < 0 ? kChartMinus : '');
                return PListItem(
                  title: r.name,
                  align: PListAlign.top,
                  detail:
                      '${statsWon(r.prev, masked)} → ${statsWon(r.now, masked)}',
                  prefix: PListTile(
                    background: softBg(context, fg),
                    color: fg,
                    child: Icon(lucideByName(r.icon ?? 'tag')),
                  ),
                  suffix: PListValue(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          keepAllAmount('$sign${statsWon(diff.abs(), masked)}'),
                          semanticsLabel:
                              '$sign${statsWon(diff.abs(), masked)}',
                          textAlign: TextAlign.end,
                          style: PTypography.t5.copyWith(
                            color: tone,
                            fontWeight: FontWeight.w700,
                            fontFeatures: tabularFigures,
                          ),
                        ),
                        Text(
                          r.prev > 0
                              ? '${up ? '▲' : (diff < 0 ? '▼' : '')} ${statsChangeRate(r.now, r.prev)}'
                                    .trim()
                              : '—',
                          style: PTypography.t3.copyWith(
                            color: c.fgNeutralSubtle,
                            fontFeatures: tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }(),
          ],
        ),
      ],
    );
  }
}

/// 요일별 지출 비교 — 지표 타일 둘(이번 · 지난 기간 = 같은 색의 옅은 단계) + ds 막대 두 계열 + 인사이트 한 줄.
class StatsCompareWeekdaySection extends StatefulWidget {
  const StatsCompareWeekdaySection({
    super.key,
    required this.period,
    required this.nowExpenses,
    required this.prevExpenses,
    required this.masked,
  });

  final StatsPeriod period;

  /// 둘 다 값이 있어야 그린다(아니면 첫 불러오기).
  final List<Expense>? nowExpenses;
  final List<Expense>? prevExpenses;
  final bool masked;

  @override
  State<StatsCompareWeekdaySection> createState() =>
      _StatsCompareWeekdaySectionState();
}

class _StatsCompareWeekdaySectionState
    extends State<StatsCompareWeekdaySection> {
  Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final masked = widget.masked;
    final head = BudgetHead(title: l.statsWeekdayTitle);
    if (widget.nowExpenses == null || widget.prevExpenses == null) {
      return statsSection(
        header: head,
        children: const [StatsChartSkeleton(height: 180)],
      );
    }
    final now = statsWeekdaySums(widget.nowExpenses!);
    final prev = statsWeekdaySums(widget.prevExpenses!);
    final days = weekdayLabels(mondayFirst: true);
    final nowName = widget.period.now(l);
    final prevName = widget.period.previous(l);
    String money(int v) => statsWon(v, masked);
    final sumNow = now.fold<int>(0, (a, b) => a + b);
    final sumPrev = prev.fold<int>(0, (a, b) => a + b);
    final name = l.statsChartWeekdayName(nowName);

    // 인사이트 — 감소폭 최대 요일 우선, 없으면 증가폭 최대.
    String insight;
    var bestDrop = 0, dropIdx = -1;
    for (var i = 0; i < 7; i++) {
      final drop = prev[i] - now[i];
      if (drop > bestDrop) {
        bestDrop = drop;
        dropIdx = i;
      }
    }
    if (dropIdx >= 0) {
      insight = l.statsWeekdayInsightDown(days[dropIdx], money(bestDrop));
    } else {
      var bestRise = 0, riseIdx = -1;
      for (var i = 0; i < 7; i++) {
        final rise = now[i] - prev[i];
        if (rise > bestRise) {
          bestRise = rise;
          riseIdx = i;
        }
      }
      insight = riseIdx >= 0
          ? l.statsWeekdayInsightUp(days[riseIdx], money(bestRise))
          : l.statsWeekdayInsightSame;
    }
    return statsSection(
      header: head,
      children: [
        PChartLegendTiles(
          items: [
            PChartLegendItem(
              key: 'now',
              label: nowName,
              color: PChartColor.blue,
              total: money(sumNow),
            ),
            PChartLegendItem(
              key: 'prev',
              label: prevName,
              color: PChartColor.blue,
              weak: true,
              total: money(sumPrev),
            ),
          ],
          hidden: _hidden,
          onHiddenChanged: (h) => setState(() => _hidden = h),
        ),
        const SizedBox(height: PSpacing.x2),
        PBarChart(
          label: name,
          height: 180,
          hidden: _hidden,
          categories: days,
          series: [
            PChartSeries(
              key: 'now',
              label: nowName,
              color: PChartColor.blue,
              values: [for (final v in now) v.toDouble()],
            ),
            PChartSeries(
              key: 'prev',
              label: prevName,
              color: PChartColor.blue,
              weak: true,
              values: [for (final v in prev) v.toDouble()],
            ),
          ],
          axisFormatter: maskFormatter(masked),
          valueFormatter: maskFormatter(masked),
        ),
        PChartDataTable(
          caption: name,
          columns: [
            PChartDataColumn(l.statsTableWeekday),
            PChartDataColumn(nowName),
            PChartDataColumn(prevName),
          ],
          rows: [
            for (var i = 0; i < 7; i++)
              [days[i], money(now[i]), money(prev[i])],
          ],
        ),
        const SizedBox(height: PSpacing.x3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: PSpacing.x1_5,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: PSpacing.x0_5),
              child: Icon(LucideIcons.sparkles, size: 16, color: c.fgBrand),
            ),
            Expanded(
              child: Text(
                keepAll(insight),
                style: PTypography.t3.copyWith(color: c.fgNeutralMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
