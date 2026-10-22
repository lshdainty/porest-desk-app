import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/app/theme/chart_palette.dart';
import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/core/format/chart_axis.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart' as cp;
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/closed_cycle_notice.dart'
    show hostContextOf;
import 'package:groo_damda_app/features/expense/domain/fixed_groups.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/fixed_split.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_card.dart';
import 'package:groo_damda_app/shared/widgets/p_chart_tooltip.dart';
import 'package:groo_damda_app/shared/widgets/p_checkbox.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';

/// 통계 · 고정/변동 탭 — 한 기간의 수입·지출을 **고정**과 **변동(고정 제외)** 으로 나눠 보여 준다.
/// 웹 `FixedVariableTab.tsx` 미러.
///
/// 서버가 내리는 건 전체와 그 가운데 고정인 몫뿐이다. 변동은 `전체 − 고정` 으로 이 화면이 구한다
/// ([splitFixed]). 세 숫자가 늘 맞아떨어지고, 환불·미래분 규칙이 서버 한 곳에만 있게 하려는 것이다.
///
/// 색만으로 가르지 않는다 — 고정은 **꽉 찬 색**, 변동은 **옅은 바탕 + 같은 색 1px 테두리**이고,
/// 막대 옆에는 늘 이름과 숫자가 붙는다. 색을 못 보는 사용자도 둘을 구별해야 한다.
enum _Kind { expense, income }

Color _kindColor(GrooTokens t, _Kind k) =>
    k == _Kind.expense ? t.fgExpense : t.statusInfoFg;

/// 변동 칸의 옅은 바탕 — 같은 색을 표면 위에 22% 얹는다.
Color _variableFill(GrooTokens t, _Kind k) =>
    Color.alphaBlend(_kindColor(t, k).withValues(alpha: 0.22), t.bgSurface);

String _money(int v, bool masked) => krwSigned(v, masked, unit: true);

class FixedVariableTab extends ConsumerWidget {
  const FixedVariableTab({
    super.key,
    required this.range,
    required this.periodTrigger,
  });

  final DateRange range;

  /// 기간 고르기 버튼 — 다른 탭과 같은 자리(첫 섹션 오른쪽)에 둔다.
  final Widget periodTrigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rangeAsync = ref.watch(rangeSummaryProvider(range));
    final categoriesAsync = ref.watch(categoriesProvider);
    final masked = ref.watch(hideCardProvider('stats.fixed'));

    void manage() => showFixedBulkSheet(context, ref, range);

    return PPullToRefresh(
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(range));
        ref.invalidate(monthlyTrendProvider(6));
        await Future.wait([
          ref.read(rangeSummaryProvider(range).future),
          ref.read(monthlyTrendProvider(6).future),
        ]);
      },
      child: ListView(
        key: const PageStorageKey('stats-fixed'),
        // 폰 구역 화면 — 구역마다 화면 폭 흰 띠, 맨 위 · 사이 8 은 회색 바닥(I-01 결정 3).
        padding: EdgeInsets.only(
          top: kScreenBandGap,
          // 떠 있는 하단 바 보상
          bottom: bottomNavigationInset(context),
        ),
        children: [
          if (rangeAsync.isLoading && !rangeAsync.hasValue) ...[
            const PScreenSection(child: PSkeleton(height: 200)),
            const SizedBox(height: PSpacing.x2),
            const PScreenSection(child: PSkeleton(height: 240)),
          ] else if (rangeAsync.hasValue) ...[
            PScreenSection(
              child: _Overview(
                kind: _Kind.expense,
                split: splitFixed(
                  rangeAsync.value!.totalExpense,
                  rangeAsync.value!.fixedExpense,
                ),
                masked: masked,
                trailing: periodTrigger,
                onManage: manage,
              ),
            ),
            const SizedBox(height: PSpacing.x2),
            PScreenSection(
              child: _Overview(
                kind: _Kind.income,
                split: splitFixed(
                  rangeAsync.value!.totalIncome,
                  rangeAsync.value!.fixedIncome,
                ),
                masked: masked,
                onManage: manage,
              ),
            ),
            const SizedBox(height: PSpacing.x2),
            PScreenSection(
              child: _MonthlyStackCard(
                summary: rangeAsync.value!,
                masked: masked,
              ),
            ),
            ..._categorySection(
              context,
              rangeAsync.value!,
              categoriesAsync.value ?? const <ExpenseCategory>[],
              masked,
              manage,
            ),
          ] else
            // 오류 — 다른 탭과 같이 빈 상자로 둔다(전역 오류 토스트가 사유를 말한다).
            const SizedBox(height: 120),
        ],
      ),
    );
  }

  List<Widget> _categorySection(
    BuildContext context,
    RangeSummary summary,
    List<ExpenseCategory> categories,
    bool masked,
    VoidCallback manage,
  ) {
    final l = AppLocalizations.of(context);
    final t = context.tokens;
    final rows = _categoryRows(summary.categoryBreakdown, {
      for (final c in categories) c.rowId: c,
    }, l.statsUnassigned);
    if (rows.isEmpty) return const [];
    return [
      const SizedBox(height: PSpacing.x2),
      PScreenSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(title: l.statsFixedCategoryTitle),
            _CategoryBars(rows: rows, masked: masked),
            const SizedBox(height: PSpace.x16),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.borderSubtle)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.pin, size: 12, color: t.fgTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l.statsFixedManageHint,
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PSpace.x12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PButton(
                      label: l.statsFixedManage,
                      variant: PButtonVariant.outline,
                      size: PButtonSize.sm,
                      onPressed: manage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

/// 카드 머리 — 제목 하나 + 오른쪽 자리.
class _Header extends StatelessWidget {
  const _Header({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: PCardTitle(title)),
          ?trailing,
        ],
      ),
    );
  }
}

/// 고정(꽉 찬 색) / 변동(옅은 바탕 + 테두리) 견본 — 범례와 숫자 줄이 같은 모양을 쓴다.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.kind, required this.fixed});
  final _Kind kind;
  final bool fixed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: fixed ? _kindColor(t, kind) : _variableFill(t, kind),
        border: Border.all(color: _kindColor(t, kind)),
        borderRadius: PRadius.brXs,
      ),
    );
  }
}

/// 지출 또는 수입 한 종류의 개요 — 비율 막대 + 전체·고정·고정 제외 숫자 + 한 줄 해설.
class _Overview extends StatelessWidget {
  const _Overview({
    required this.kind,
    required this.split,
    required this.masked,
    required this.onManage,
    this.trailing,
  });

  final _Kind kind;
  final FixedSplit split;
  final bool masked;
  final VoidCallback onManage;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final isExpense = kind == _Kind.expense;
    final noFixed = split.total > 0 && split.fixed == 0;
    final totalLabel = isExpense
        ? l.statsFixedTotalExpense
        : l.statsFixedTotalIncome;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: isExpense ? l.statsFixedExpenseTitle : l.statsFixedIncomeTitle,
          trailing: trailing,
        ),
        if (split.total == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                isExpense ? l.statsFixedExpenseNone : l.statsFixedIncomeNone,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
            ),
          )
        else ...[
          _RatioBar(
            kind: kind,
            split: split,
            semanticLabel: l.statsFixedBarSemantics(
              totalLabel,
              split.fixedPercent,
              split.variablePercent,
            ),
          ),
          const SizedBox(height: PSpace.x16),
          _Figure(label: totalLabel, value: split.total, masked: masked),
          const SizedBox(height: PSpace.x12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Figure(
                  label: isExpense
                      ? l.statsFixedFixedExpense
                      : l.statsFixedFixedIncome,
                  value: split.fixed,
                  masked: masked,
                  swatch: _Swatch(kind: kind, fixed: true),
                  sub: '${split.fixedPercent}%',
                ),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: _Figure(
                  label: isExpense
                      ? l.statsFixedVariableExpense
                      : l.statsFixedVariableIncome,
                  value: split.variable,
                  masked: masked,
                  swatch: _Swatch(kind: kind, fixed: false),
                  sub: '${split.variablePercent}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x16),
          if (noFixed)
            Container(
              padding: const EdgeInsets.all(PSpace.x12),
              decoration: BoxDecoration(
                color: t.bgSunken,
                borderRadius: PRadius.brLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.statsFixedEmptyDesc,
                    style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                  ),
                  const SizedBox(height: PSpace.x8),
                  PButton(
                    label: l.statsFixedManage,
                    variant: PButtonVariant.outline,
                    size: PButtonSize.sm,
                    onPressed: onManage,
                  ),
                ],
              ),
            )
          else
            Text.rich(
              TextSpan(
                style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                children: [
                  TextSpan(
                    text:
                        '${isExpense ? l.statsFixedInsightExpense(split.fixedPercent) : l.statsFixedInsightIncome(split.fixedPercent)} ',
                  ),
                  TextSpan(
                    text: _money(split.variable, masked),
                    style: TextStyle(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                  TextSpan(text: l.statsFixedInsightTail),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// 숫자 한 칸 — 이름 위, 금액 아래. 견본이 있으면 이름 앞에 붙는다.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.masked,
    this.swatch,
    this.sub,
  });

  final String label;
  final int value;
  final bool masked;
  final Widget? swatch;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (swatch != null) ...[swatch!, const SizedBox(width: 6)],
            Flexible(
              child: Text(
                label,
                style: PTypo.caption.copyWith(color: t.fgSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _money(value, masked),
          style: PTypo.bodyLg.copyWith(
            color: t.fgPrimary,
            fontWeight: PFontWeight.bold,
          ),
        ),
        if (sub != null)
          Text(sub!, style: PTypo.caption.copyWith(color: t.fgTertiary)),
      ],
    );
  }
}

/// 한 줄 비율 막대 — 왼쪽이 고정, 오른쪽이 변동. 폭은 전체에 대한 비율이다.
class _RatioBar extends StatelessWidget {
  const _RatioBar({
    required this.kind,
    required this.split,
    required this.semanticLabel,
  });

  final _Kind kind;
  final FixedSplit split;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = _kindColor(t, kind);
    final fixedFrac = split.total == 0 ? 0.0 : split.fixed / split.total;
    Widget cell(String text, Color fg) => Center(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: PTypo.caption.copyWith(color: fg, fontWeight: PFontWeight.bold),
      ),
    );
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: PRadius.brMd,
          child: Container(
            height: 28,
            color: t.bgSunken,
            child: LayoutBuilder(
              builder: (context, c) {
                final fixedW = c.maxWidth * fixedFrac;
                return Row(
                  children: [
                    if (split.fixed > 0)
                      Container(
                        width: fixedW,
                        height: 28,
                        color: color,
                        child: fixedFrac >= 0.14
                            ? cell('${split.fixedPercent}%', t.bgSurface)
                            : null,
                      ),
                    if (split.variable > 0)
                      Expanded(
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: _variableFill(t, kind),
                            border: Border.all(color: color),
                          ),
                          child: 1 - fixedFrac >= 0.14
                              ? cell('${split.variablePercent}%', color)
                              : null,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 월별 누적 막대 ──────────────────────────────────────────

class _MonthRow {
  const _MonthRow(this.label, this.fixed, this.variable);
  final String label;
  final int fixed;
  final int variable;
  int get total => fixed + variable;
}

/// 월 라벨 — 한 해 안이면 'MM', 해가 섞이면 'YYYY.MM'. 추이 탭과 같은 규칙.
List<_MonthRow> _toRows(
  List<({int year, int month, int total, int fixed})> src,
) {
  if (src.isEmpty) return const [];
  final sameYear = src.every((r) => r.year == src.first.year);
  return [
    for (final r in src)
      () {
        final s = splitFixed(r.total, r.fixed);
        final mm = r.month.toString().padLeft(2, '0');
        return _MonthRow(sameYear ? mm : '${r.year}.$mm', s.fixed, s.variable);
      }(),
  ];
}

class _MonthlyStackCard extends ConsumerStatefulWidget {
  const _MonthlyStackCard({required this.summary, required this.masked});
  final RangeSummary summary;
  final bool masked;

  @override
  ConsumerState<_MonthlyStackCard> createState() => _MonthlyStackCardState();
}

class _MonthlyStackCardState extends ConsumerState<_MonthlyStackCard> {
  _Kind _kind = _Kind.expense;
  int? _touchedIdx;
  Offset? _touchPos;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final s = widget.summary;
    // 한 달만 고른 기간이면 막대가 하나뿐이라 의미가 없다 — 그때는 최근 6개월을 보여 준다.
    final useRange = s.monthlyBuckets.length >= 2;
    final trendAsync = useRange
        ? const AsyncData<List<MonthlyTrend>>(<MonthlyTrend>[])
        : ref.watch(monthlyTrendProvider(6));
    final isExpense = _kind == _Kind.expense;
    final rows = useRange
        ? _toRows([
            for (final b in s.monthlyBuckets)
              (
                year: b.year,
                month: b.month,
                total: isExpense ? b.totalExpense : b.totalIncome,
                fixed: isExpense ? b.fixedExpense : b.fixedIncome,
              ),
          ])
        : _toRows([
            for (final m in trendAsync.value ?? const <MonthlyTrend>[])
              (
                year: m.year,
                month: m.month,
                total: isExpense ? m.totalExpense : m.totalIncome,
                fixed: isExpense ? m.fixedExpense : m.fixedIncome,
              ),
          ]);
    final loading = !useRange && trendAsync.isLoading && !trendAsync.hasValue;
    final hasData = rows.any((r) => r.total > 0);
    final axis = niceAxis(
      0,
      rows.isEmpty ? 1 : rows.map((r) => r.total.toDouble()).reduce(math.max),
    );
    final color = _kindColor(t, _kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(title: l.statsFixedTrendTitle),
        PSegmentedControl<_Kind>(
          value: _kind,
          semanticLabel: l.statsFixedTrendKindAria,
          onChanged: (v) => setState(() {
            _kind = v;
            _touchedIdx = null;
          }),
          items: [
            PSegmentedItem(
              value: _Kind.expense,
              label: l.statsFixedKindExpense,
            ),
            PSegmentedItem(value: _Kind.income, label: l.statsFixedKindIncome),
          ],
        ),
        const SizedBox(height: PSpace.x16),
        if (loading)
          const PSkeleton(height: 200)
        else if (!hasData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                l.statsNoData,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
            ),
          )
        else ...[
          if (!useRange)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l.statsFixedTrendRecent,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ),
          SizedBox(
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    minY: 0,
                    maxY: axis.max,
                    barTouchData: BarTouchData(
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
                        final spot = response?.spot;
                        if (spot == null) {
                          if (_touchedIdx != null) {
                            setState(() => _touchedIdx = null);
                          }
                          return;
                        }
                        final i = spot.touchedBarGroup.x;
                        final pos = event.localPosition;
                        if (i >= 0 &&
                            i < rows.length &&
                            (i != _touchedIdx || pos != _touchPos)) {
                          setState(() {
                            _touchedIdx = i;
                            if (pos != null) _touchPos = pos;
                          });
                        }
                      },
                      touchTooltipData: BarTouchTooltipData(
                        // 기본 툴팁 OFF — Stack 위에 직접 그린다(아래 Positioned)
                        getTooltipColor: (_) => Colors.transparent,
                        tooltipBorder: BorderSide.none,
                        tooltipPadding: EdgeInsets.zero,
                        tooltipMargin: 0,
                        getTooltipItem: (_, _, _, _) => null,
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: axis.interval,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: t.borderSubtle,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          interval: axis.interval,
                          getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              formatChartAxis(v),
                              style: PTypo.micro.copyWith(
                                color: t.fgTertiary,
                                fontSize: PFontSize.micro,
                              ),
                            ),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (v, _) {
                            final i = v.round();
                            if (i < 0 || i >= rows.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                rows[i].label,
                                style: PTypo.micro.copyWith(
                                  color: t.fgTertiary,
                                  fontSize: PFontSize.micro,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < rows.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: rows[i].total.toDouble(),
                              width: rows.length > 8 ? 14 : 22,
                              color: color,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              // 아래가 고정(꽉 찬 색), 위가 변동(옅은 색 + 테두리) —
                              // 달마다 고정이 얼마나 일정한지 한눈에 보인다.
                              rodStackItems: [
                                BarChartRodStackItem(
                                  0,
                                  rows[i].fixed.toDouble(),
                                  color,
                                ),
                                BarChartRodStackItem(
                                  rows[i].fixed.toDouble(),
                                  rows[i].total.toDouble(),
                                  _variableFill(t, _kind),
                                  borderSide: BorderSide(color: color),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (_touchedIdx != null &&
                    _touchedIdx! < rows.length &&
                    _touchPos != null)
                  PChartTooltipLayer(
                    anchor: _touchPos!,
                    child: Builder(
                      builder: (_) {
                        final r = rows[_touchedIdx!];
                        return PChartTooltipBox(
                          title: r.label,
                          labelWidth: 40,
                          rows: [
                            PChartTooltipRowData(
                              color: color,
                              label: l.statsFixedLegendFixed,
                              amount: _money(r.fixed, widget.masked),
                            ),
                            PChartTooltipRowData(
                              color: _variableFill(t, _kind),
                              borderColor: color,
                              label: l.statsFixedLegendVariable,
                              amount: _money(r.variable, widget.masked),
                            ),
                          ],
                          footer: [
                            PChartTooltipFooterRowData(
                              label: isExpense
                                  ? l.statsFixedTotalExpense
                                  : l.statsFixedTotalIncome,
                              value: _money(r.total, widget.masked),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Swatch(kind: _kind, fixed: true),
              const SizedBox(width: 6),
              Text(
                l.statsFixedLegendFixed,
                style: PTypo.caption.copyWith(color: t.fgSecondary),
              ),
              const SizedBox(width: 16),
              _Swatch(kind: _kind, fixed: false),
              const SizedBox(width: 6),
              Text(
                l.statsFixedLegendVariable,
                style: PTypo.caption.copyWith(color: t.fgSecondary),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── 카테고리별 고정/변동 ─────────────────────────────────────

class _CategoryRow {
  _CategoryRow({required this.key, required this.name, this.color});
  final String key;
  final String name;
  final String? color;
  int total = 0;
  int fixed = 0;
}

/// 지출 카테고리를 부모 단위로 묶어 고정·변동 몫을 합친다 — 도넛과 같은 묶음 규칙.
List<_CategoryRow> _categoryRows(
  List<CategoryBreakdown> breakdown,
  Map<int, ExpenseCategory> byId,
  String uncategorized,
) {
  final map = <String, _CategoryRow>{};
  for (final c in breakdown) {
    if (c.expenseType != 'EXPENSE') continue;
    final groupId = c.parentCategoryRowId ?? c.categoryRowId;
    final key = groupId == null ? 'none' : '$groupId';
    final row = map.putIfAbsent(
      key,
      () => _CategoryRow(
        key: key,
        name: c.parentCategoryName ?? c.categoryName ?? uncategorized,
        color: groupId == null ? null : byId[groupId]?.color,
      ),
    );
    final s = splitFixed(c.totalAmount, c.fixedAmount);
    row.total += s.total;
    row.fixed += s.fixed;
  }
  return map.values.where((r) => r.total > 0).toList()
    ..sort((a, b) => b.total.compareTo(a.total));
}

const _kCategoryLimit = 8;

class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.rows, required this.masked});
  final List<_CategoryRow> rows;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final shown = rows.take(_kCategoryLimit).toList();
    final max = shown.map((r) => r.total).fold<int>(1, math.max);
    return Column(
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Builder(
            builder: (context) {
              final r = shown[i];
              final s = splitFixed(r.total, r.fixed);
              final dot = cp.resolveChartColor(
                context,
                r.color,
                fallback: GrooChartPalette.category(context, i),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dot,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.semi,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _money(s.total, masked),
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: PRadius.brXs,
                    child: Container(
                      height: 10,
                      color: t.bgSunken,
                      alignment: Alignment.centerLeft,
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth * (s.total / max);
                          final fixedW = s.total == 0
                              ? 0.0
                              : w * (s.fixed / s.total);
                          return Row(
                            children: [
                              if (s.fixed > 0)
                                Container(
                                  width: fixedW,
                                  height: 10,
                                  color: _kindColor(t, _Kind.expense),
                                ),
                              if (s.variable > 0)
                                Container(
                                  width: w - fixedW,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _variableFill(t, _Kind.expense),
                                    border: Border.all(
                                      color: _kindColor(t, _Kind.expense),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  if (s.fixed > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l.statsFixedCategoryFixedPart(s.fixedPercent)} · ${_money(s.fixed, masked)}',
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

// ─── 고정 정리 시트 ──────────────────────────────────────────

/// 거래를 고정으로 정리하는 시트 — 같은 이름으로 나가는 거래를 묶어(월세 열두 달치가 한 줄)
/// 한 번에 고르게 한다. 돈·잔액은 안 움직이고 통계의 분류만 바뀌므로, 되돌리기는 같은 시트에서
/// "변동으로" 를 고르면 된다.
Future<void> showFixedBulkSheet(
  BuildContext context,
  WidgetRef ref,
  DateRange range,
) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  return showPSheet<void>(
    context,
    title: l.statsFixedBulkTitle,
    initialChildSize: 0.85,
    contentBuilder: (ctx, scroll) =>
        _FixedBulkBody(controller: controller, range: range, scroll: scroll),
    footerBuilder: (_) => PSheetFooter(
      controller: controller,
      submitLabel: l.statsFixedBulkApply(0),
    ),
  ).whenComplete(controller.dispose);
}

class _FixedBulkBody extends ConsumerStatefulWidget {
  const _FixedBulkBody({
    required this.controller,
    required this.range,
    required this.scroll,
  });
  final PSheetController controller;
  final DateRange range;
  final ScrollController scroll;

  @override
  ConsumerState<_FixedBulkBody> createState() => _FixedBulkBodyState();
}

class _FixedBulkBodyState extends ConsumerState<_FixedBulkBody> {
  String _type = 'EXPENSE';
  bool _toFixed = true;
  Set<int> _picked = {};

  @override
  void initState() {
    super.initState();
    widget.controller.onSubmit = _apply;
  }

  Future<void> _apply() async {
    if (_picked.isEmpty) return;
    // 시트가 닫힌 뒤에도 토스트를 띄워야 하므로 await 전에 오래 사는 것을 쥔다.
    final l = AppLocalizations.of(context);
    final host = hostContextOf(context);
    final nav = Navigator.of(context);
    widget.controller.setSubmitting(true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      final updated = await repo.bulkMarkFixed(
        _picked.toList(),
        isFixed: _toFixed,
      );
      // 합계가 아니라 분류가 바뀌지만 통계(고정/변동)·목록이 모두 달라진다.
      invalidateAfterExpenseChange(ref);
      ref.invalidate(rangeSummaryProvider(widget.range));
      ref.invalidate(monthlyTrendProvider(6));
      if (!mounted) return;
      nav.pop();
      if (!host.mounted) return;
      showPSnackBar(
        host,
        _toFixed
            ? l.statsFixedBulkDoneFixed(updated)
            : l.statsFixedBulkDoneVariable(updated),
        severity: PSnackSeverity.success,
      );
    } on ApiException {
      // 전역 오류 토스트가 사유를 말한다 — 시트는 그대로 둔다.
    } finally {
      widget.controller.setSubmitting(false);
    }
  }

  void _sync(int count) {
    // 빌드 중에 notify 하면 안 된다 — 프레임 뒤에 푸터에 알린다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.setCanSubmit(count > 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final expensesAsync = ref.watch(rangeExpensesProvider(widget.range));
    final masked = ref.watch(hideCardProvider('stats.fixed'));
    final groups = groupForFixed(
      expensesAsync.value ?? const [],
      _type,
      l.statsFixedBulkUntitled,
    );
    _sync(_picked.length);

    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        Text(
          l.statsFixedBulkDesc(widget.range.startDate, widget.range.endDate),
          style: PTypo.bodySm.copyWith(color: t.fgSecondary),
        ),
        const SizedBox(height: PSpace.x12),
        PSegmentedControl<String>(
          value: _type,
          semanticLabel: l.statsFixedTrendKindAria,
          onChanged: (v) => setState(() {
            _type = v;
            _picked = {};
          }),
          items: [
            PSegmentedItem(value: 'EXPENSE', label: l.statsFixedKindExpense),
            PSegmentedItem(value: 'INCOME', label: l.statsFixedKindIncome),
          ],
        ),
        const SizedBox(height: PSpace.x8),
        PSegmentedControl<bool>(
          value: _toFixed,
          semanticLabel: l.statsFixedBulkTargetAria,
          onChanged: (v) => setState(() => _toFixed = v),
          items: [
            PSegmentedItem(value: true, label: l.statsFixedBulkToFixed),
            PSegmentedItem(value: false, label: l.statsFixedBulkToVariable),
          ],
        ),
        const SizedBox(height: PSpace.x12),
        if (expensesAsync.isLoading && !expensesAsync.hasValue)
          for (var i = 0; i < 4; i++) ...[
            const PSkeleton(height: 52),
            const SizedBox(height: 10),
          ]
        else if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                l.statsFixedBulkEmpty,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
            ),
          )
        else
          for (final g in groups)
            _GroupRow(
              group: g,
              state: groupCheck(g, _picked),
              masked: masked,
              onChanged: (on) =>
                  setState(() => _picked = toggleGroup(g, _picked, on)),
            ),
      ],
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.state,
    required this.masked,
    required this.onChanged,
  });
  final TxGroup group;
  final bool? state;
  final bool masked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final allFixed = group.fixedCount == group.count;
    final someFixed = group.fixedCount > 0 && !allFixed;
    return InkWell(
      onTap: () => onChanged(state != true),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              PCheckbox(
                value: state,
                tristate: true,
                dense: true,
                semanticLabel: group.name,
                onChanged: (v) => onChanged(v == true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l.statsFixedBulkGroupSub(group.count)} · ${_money(group.total, masked)}',
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ),
              ),
              if (allFixed || someFixed)
                Text(
                  allFixed
                      ? l.statsFixedBulkBadgeAll
                      : l.statsFixedBulkBadgeSome(
                          group.fixedCount,
                          group.count,
                        ),
                  style: PTypo.caption.copyWith(
                    color: t.fgBrand,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
