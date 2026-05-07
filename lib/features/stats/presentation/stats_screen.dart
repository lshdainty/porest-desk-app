import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../application/stats_providers.dart';
import '../domain/stats_models.dart';
import '../domain/stats_summaries.dart';

/// 통계·분석 화면 (front `StatsPage` 미러).
///
/// 3 탭: 카테고리 / 추이 / 비교 — 페이지 상단 underline TabBar 로 전환.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});
  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

enum _PeriodKey { m1, m3, y1 }

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late DateTime _month = monthStart(DateTime.now());
  _PeriodKey _period = _PeriodKey.m1;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  YM get _ym => (year: _month.year, month: _month.month);
  YM get _prevYm {
    if (_month.month == 1) return (year: _month.year - 1, month: 12);
    return (year: _month.year, month: _month.month - 1);
  }

  /// 기간 모드에 해당하는 month 번호 list.
  List<int> get _periodMonths {
    if (_period == _PeriodKey.m1) return [_month.month];
    if (_period == _PeriodKey.m3) {
      final q = ((_month.month - 1) ~/ 3) + 1;
      return [q * 3 - 2, q * 3 - 1, q * 3];
    }
    return List.generate(12, (i) => i + 1);
  }

  /// 이전 기간 (year, months).
  ({int year, List<int> months}) get _prevPeriod {
    if (_period == _PeriodKey.m1) {
      return (year: _prevYm.year, months: [_prevYm.month]);
    }
    if (_period == _PeriodKey.m3) {
      final q = ((_month.month - 1) ~/ 3) + 1;
      if (q == 1) return (year: _month.year - 1, months: [10, 11, 12]);
      final pq = q - 1;
      return (year: _month.year, months: [pq * 3 - 2, pq * 3 - 1, pq * 3]);
    }
    return (year: _month.year - 1, months: List.generate(12, (i) => i + 1));
  }

  String get _periodLabel {
    if (_period == _PeriodKey.m1) return '${_month.month}월';
    if (_period == _PeriodKey.m3) {
      final q = ((_month.month - 1) ~/ 3) + 1;
      return '${_month.year}년 $q분기';
    }
    return '${_month.year}년';
  }

  String get _periodNow => switch (_period) {
        _PeriodKey.m1 => '이번 달',
        _PeriodKey.m3 => '이번 분기',
        _PeriodKey.y1 => '이번 해',
      };
  String get _periodPrev => switch (_period) {
        _PeriodKey.m1 => '지난 달',
        _PeriodKey.m3 => '지난 분기',
        _PeriodKey.y1 => '지난 해',
      };
  String get _momLabel => switch (_period) {
        _PeriodKey.m1 => '전월 대비',
        _PeriodKey.m3 => '전분기 대비',
        _PeriodKey.y1 => '전년 대비',
      };

  void setPeriod(_PeriodKey p) {
    setState(() => _period = p);
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime(_month.year + 5, 12, 31),
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        Container(
          color: t.bgSurface,
          child: TabBar(
            controller: _tab,
            isScrollable: false,
            indicatorColor: t.bgBrand,
            indicatorWeight: 2.4,
            labelColor: t.fgPrimary,
            unselectedLabelColor: t.fgTertiary,
            labelStyle: PTypo.bodySm
                .copyWith(fontWeight: FontWeight.w700, color: t.fgPrimary),
            unselectedLabelStyle: PTypo.bodySm
                .copyWith(fontWeight: FontWeight.w500, color: t.fgTertiary),
            dividerColor: t.borderSubtle,
            tabs: const [
              Tab(text: '카테고리'),
              Tab(text: '추이'),
              Tab(text: '비교'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _CategoryTab(state: this),
              _TrendTab(state: this),
              _CompareTab(state: this),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 카테고리 탭 ────────────────────────────────────────────

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab({required this.state});
  final _StatsScreenState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings =
        ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final monthlyAsync = ref.watch(monthlySummaryProvider(state._ym));
    final prevMonthlyAsync =
        ref.watch(monthlySummaryProvider(state._prevYm));
    final yearlyAsync = ref.watch(yearlySummaryProvider(state._month.year));
    final categoriesAsync = ref.watch(categoriesProvider);
    final start = _fmt(state._month);
    final end =
        _fmt(DateTime(state._month.year, state._month.month + 1, 0));
    final merchantAsync =
        ref.watch(merchantSummaryProvider((startDate: start, endDate: end)));
    final heatmapAsync = ref.watch(heatmapProvider(state._ym));

    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(monthlySummaryProvider(state._ym));
        ref.invalidate(merchantSummaryProvider(
            (startDate: start, endDate: end)));
        ref.invalidate(heatmapProvider(state._ym));
        ref.invalidate(yearlySummaryProvider(state._month.year));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x32),
        children: [
          _DonutCard(
            state: state,
            monthlyAsync: monthlyAsync,
            yearlyAsync: yearlyAsync,
            categoriesAsync: categoriesAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: PSpace.x12),
          _TopMerchantsCard(
            async: merchantAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: PSpace.x12),
          _HeatmapCard(async: heatmapAsync),
          const SizedBox(height: PSpace.x12),
          _HighlightsGrid(
            state: state,
            monthlyAsync: monthlyAsync,
            prevMonthlyAsync: prevMonthlyAsync,
            yearlyAsync: yearlyAsync,
            categoriesAsync: categoriesAsync,
            merchantAsync: merchantAsync,
            masked: settings.hideAmounts,
          ),
        ],
      ),
    );
  }
}

// ─── 추이 탭 ────────────────────────────────────────────────

class _TrendTab extends ConsumerWidget {
  const _TrendTab({required this.state});
  final _StatsScreenState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings =
        ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final yearlyAsync = ref.watch(yearlySummaryProvider(state._month.year));
    final monthExpAsync = ref.watch(monthExpensesProvider(state._ym));
    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(yearlySummaryProvider(state._month.year));
        ref.invalidate(monthExpensesProvider(state._ym));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x32),
        children: [
          _TrendBigCard(
            state: state,
            yearlyAsync: yearlyAsync,
            monthExpAsync: monthExpAsync,
          ),
          const SizedBox(height: PSpace.x12),
          _TrendStatsGrid(
            state: state,
            yearlyAsync: yearlyAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: PSpace.x12),
          _SavingsBarsCard(
            state: state,
            yearlyAsync: yearlyAsync,
            monthExpAsync: monthExpAsync,
          ),
        ],
      ),
    );
  }
}

// ─── 비교 탭 ────────────────────────────────────────────────

class _CompareTab extends ConsumerWidget {
  const _CompareTab({required this.state});
  final _StatsScreenState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings =
        ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final monthlyAsync = ref.watch(monthlySummaryProvider(state._ym));
    final prevMonthlyAsync =
        ref.watch(monthlySummaryProvider(state._prevYm));
    final yearlyAsync = ref.watch(yearlySummaryProvider(state._month.year));
    final prevYearlyAsync =
        ref.watch(yearlySummaryProvider(state._month.year - 1));
    final categoriesAsync = ref.watch(categoriesProvider);
    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(monthlySummaryProvider(state._ym));
        ref.invalidate(monthlySummaryProvider(state._prevYm));
        ref.invalidate(yearlySummaryProvider(state._month.year));
        ref.invalidate(yearlySummaryProvider(state._month.year - 1));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x32),
        children: [
          _CompareSummaryGrid(
            state: state,
            monthlyAsync: monthlyAsync,
            prevMonthlyAsync: prevMonthlyAsync,
            yearlyAsync: yearlyAsync,
            prevYearlyAsync: prevYearlyAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: PSpace.x12),
          _CompareCategoryCard(
            state: state,
            monthlyAsync: monthlyAsync,
            prevMonthlyAsync: prevMonthlyAsync,
            yearlyAsync: yearlyAsync,
            prevYearlyAsync: prevYearlyAsync,
            categoriesAsync: categoriesAsync,
            masked: settings.hideAmounts,
          ),
        ],
      ),
    );
  }
}

// ─── 공용 위젯 ─────────────────────────────────────────────

/// 카드 컨테이너.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.bgSurface,
        border: Border.all(color: t.borderSubtle),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _PeriodSeg extends StatelessWidget {
  const _PeriodSeg({required this.value, required this.onChanged});
  final _PeriodKey value;
  final ValueChanged<_PeriodKey> onChanged;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget pill(_PeriodKey v, String label) {
      final active = v == value;
      return GestureDetector(
        onTap: () => onChanged(v),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? t.bgSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1)),
                  ]
                : null,
          ),
          child: Text(label,
              style: PTypo.caption.copyWith(
                  color: active ? t.fgPrimary : t.fgTertiary,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.bgMuted,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill(_PeriodKey.m1, '월'),
          pill(_PeriodKey.m3, '분기'),
          pill(_PeriodKey.y1, '년'),
        ],
      ),
    );
  }
}

class _MonthPickerButton extends StatelessWidget {
  const _MonthPickerButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: t.borderSubtle),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendar, size: 13, color: t.fgSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: PTypo.caption.copyWith(
                    color: t.fgPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 12, color: t.fgTertiary),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelectorRow extends StatelessWidget {
  const _PeriodSelectorRow({required this.state});
  final _StatsScreenState state;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: _MonthPickerButton(
            label: '${state._month.year}년 ${state._month.month}월',
            onTap: state._pickMonth,
          ),
        ),
        const SizedBox(width: 8),
        _PeriodSeg(
          value: state._period,
          onChanged: state.setPeriod,
        ),
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, this.trailing});
  final Widget title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: title),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(text,
        style: PTypo.body.copyWith(
            color: t.fgPrimary, fontWeight: FontWeight.w700));
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({this.text = '데이터가 없습니다'});
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(text,
            style: PTypo.caption.copyWith(color: t.fgTertiary)),
      ),
    );
  }
}

// ─── DONUT CARD ────────────────────────────────────────────

const _donutColorStrings = [
  'oklch(0.55 0.12 55)',
  'oklch(0.50 0.12 340)',
  'oklch(0.50 0.1 140)',
  'oklch(0.50 0.12 290)',
  'oklch(0.48 0.012 195)',
  'oklch(0.50 0.08 50)',
  'oklch(0.52 0.1 215)',
  'oklch(0.50 0.1 230)',
  'oklch(0.55 0.13 25)',
];

Color _donutColor(BuildContext context, int idx) {
  final t = context.tokens;
  if (idx < _donutColorStrings.length) {
    return parseColor(_donutColorStrings[idx], fallback: t.fgBrand);
  }
  return t.fgBrand;
}

class _DonutRow {
  _DonutRow({
    required this.rowId,
    required this.name,
    required this.amount,
    this.icon,
    this.color,
  });
  final int rowId;
  final String name;
  int amount;
  final String? icon;
  final String? color;
  bool hasChildren = false;
}

class _DonutCard extends ConsumerStatefulWidget {
  const _DonutCard({
    required this.state,
    required this.monthlyAsync,
    required this.yearlyAsync,
    required this.categoriesAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<MonthlySummary> monthlyAsync;
  final AsyncValue<YearlySummary> yearlyAsync;
  final AsyncValue<List<dynamic>> categoriesAsync;
  final bool masked;

  @override
  ConsumerState<_DonutCard> createState() => _DonutCardState();
}

class _DonutCardState extends ConsumerState<_DonutCard> {
  int? _activeParentId;

  @override
  void didUpdateWidget(covariant _DonutCard old) {
    super.didUpdateWidget(old);
    // 기간/월 변경 시 드릴다운 해제.
    if (old.state._period != widget.state._period ||
        old.state._month != widget.state._month) {
      _activeParentId = null;
    }
  }

  List<CategoryBreakdown> get _periodBreakdown {
    final s = widget.state;
    final out = <CategoryBreakdown>[];
    void push(List<CategoryBreakdown> list) {
      for (final c in list) {
        if (c.expenseType == 'EXPENSE') out.add(c);
      }
    }

    if (s._period == _PeriodKey.m1) {
      push(widget.monthlyAsync.value?.categoryBreakdown ?? const <CategoryBreakdown>[]);
    } else {
      for (final m
          in widget.yearlyAsync.value?.monthlyAmounts ?? const <MonthlyAmount>[]) {
        if (s._periodMonths.contains(m.month)) push(m.categoryBreakdown);
      }
    }
    return out;
  }

  List<_DonutRow> _aggregateParent(List<CategoryBreakdown> bd) {
    final map = <int, _DonutRow>{};
    final cats = (widget.categoriesAsync.value ?? const []).cast<dynamic>();
    for (final c in bd) {
      final groupId = c.parentCategoryRowId ?? c.categoryRowId;
      if (groupId == null) continue;
      final groupName = c.parentCategoryName ?? c.categoryName ?? '미지정';
      var row = map[groupId];
      if (row == null) {
        final cat = cats
            .cast<dynamic>()
            .where((x) => x.rowId == groupId)
            .cast<dynamic>()
            .firstOrNull;
        row = _DonutRow(
          rowId: groupId,
          name: groupName,
          amount: 0,
          icon: cat?.icon as String?,
          color: cat?.color as String?,
        );
        map[groupId] = row;
      }
      row.amount += c.totalAmount;
      if (c.parentCategoryRowId != null) row.hasChildren = true;
    }
    final list = map.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  List<_DonutRow> _aggregateChildren(
      List<CategoryBreakdown> bd, int parentId) {
    final map = <int, _DonutRow>{};
    final cats = (widget.categoriesAsync.value ?? const []).cast<dynamic>();
    for (final c in bd) {
      if (c.parentCategoryRowId != parentId) continue;
      final id = c.categoryRowId;
      if (id == null) continue;
      var row = map[id];
      if (row == null) {
        final cat = cats
            .cast<dynamic>()
            .where((x) => x.rowId == id)
            .cast<dynamic>()
            .firstOrNull;
        row = _DonutRow(
          rowId: id,
          name: c.categoryName ?? '미지정',
          amount: 0,
          icon: cat?.icon as String?,
          color: cat?.color as String?,
        );
        map[id] = row;
      }
      row.amount += c.totalAmount;
    }
    return map.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final t = context.tokens;
    final loading = s._period == _PeriodKey.m1
        ? widget.monthlyAsync.isLoading
        : widget.yearlyAsync.isLoading;
    final bd = _periodBreakdown;
    final parents = _aggregateParent(bd);
    final isDrilled = _activeParentId != null;
    final children = isDrilled
        ? _aggregateChildren(bd, _activeParentId!)
        : const <_DonutRow>[];
    final view = isDrilled && children.isNotEmpty ? children : parents;
    final total = view.fold<int>(0, (sum, r) => sum + r.amount);
    final activeParent = isDrilled
        ? parents.where((r) => r.rowId == _activeParentId).firstOrNull
        : null;

    final centerLbl = isDrilled && activeParent != null
        ? '${activeParent.name} 세부'
        : '${s._periodLabel} 지출';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: isDrilled
                ? Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _activeParentId = null),
                        child: Text('카테고리별 지출',
                            style: PTypo.body.copyWith(
                                color: t.fgSecondary,
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 4),
                      Text('›',
                          style: PTypo.body.copyWith(color: t.fgTertiary)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: _CardTitle(activeParent?.name ?? ''),
                      ),
                    ],
                  )
                : const _CardTitle('카테고리별 지출'),
          ),
          _PeriodSelectorRow(state: s),
          const SizedBox(height: 14),
          if (loading)
            const _EmptyBox(text: '불러오는 중…')
          else if (view.isEmpty)
            const _EmptyBox(text: '카테고리 데이터가 없습니다')
          else ...[
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      startDegreeOffset: -90,
                      sections: [
                        for (var i = 0; i < view.length; i++)
                          PieChartSectionData(
                            value: view[i].amount.toDouble(),
                            color: _donutColor(context, i),
                            radius: 28,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(centerLbl,
                          style: PTypo.caption
                              .copyWith(color: t.fgSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        '${krwMasked(total, widget.masked)}원',
                        style: PTypo.h4.copyWith(
                            color: t.fgPrimary,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < view.length; i++)
              _DonutLegendRow(
                row: view[i],
                index: i,
                total: total,
                masked: widget.masked,
                clickable: !isDrilled && view[i].hasChildren,
                onTap: !isDrilled && view[i].hasChildren
                    ? () => setState(
                        () => _activeParentId = view[i].rowId)
                    : null,
              ),
          ],
        ],
      ),
    );
  }
}

class _DonutLegendRow extends StatelessWidget {
  const _DonutLegendRow({
    required this.row,
    required this.index,
    required this.total,
    required this.masked,
    required this.clickable,
    required this.onTap,
  });
  final _DonutRow row;
  final int index;
  final int total;
  final bool masked;
  final bool clickable;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final pct = total > 0 ? (row.amount * 100 / total) : 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _donutColor(context, index),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary, fontWeight: FontWeight.w500)),
            ),
            Text('${pct.toStringAsFixed(1)}%',
                style: PTypo.caption.copyWith(color: t.fgTertiary)),
            const SizedBox(width: 12),
            Text(krwMasked(row.amount, masked),
                style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace')),
            if (clickable) ...[
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight,
                  size: 13, color: t.fgTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── TOP MERCHANTS ─────────────────────────────────────────

class _TopMerchantsCard extends StatelessWidget {
  const _TopMerchantsCard({required this.async, required this.masked});
  final AsyncValue<List<MerchantSummary>> async;
  final bool masked;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final list = async.value ?? const <MerchantSummary>[];
    final sorted = (List.of(list)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)));
    final top = sorted.take(5).toList();
    final maxAmt = top.isEmpty ? 1 : top.first.totalAmount;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(title: _CardTitle('많이 쓴 가맹점 TOP 5')),
          if (async.isLoading && top.isEmpty)
            const _EmptyBox(text: '불러오는 중…')
          else if (top.isEmpty)
            const _EmptyBox(text: '가맹점 데이터가 없습니다')
          else
            for (var i = 0; i < top.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${i + 1}',
                        textAlign: TextAlign.center,
                        style: PTypo.caption.copyWith(
                            color:
                                i < 3 ? t.fgBrand : t.fgTertiary,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(top[i].merchant ?? '(이름 없음)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PTypo.bodySm.copyWith(
                                      color: t.fgPrimary,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 6),
                            Text('${top[i].count}회',
                                style: PTypo.caption
                                    .copyWith(color: t.fgTertiary)),
                            const Spacer(),
                            Text(
                              krwMasked(top[i].totalAmount, masked),
                              style: PTypo.bodySm.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: top[i].totalAmount / maxAmt,
                            minHeight: 4,
                            backgroundColor: t.bgMuted,
                            color: _donutColor(context, i),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}

// ─── HEATMAP ───────────────────────────────────────────────

class _HeatmapRow {
  const _HeatmapRow(this.label, this.sub, this.hours);
  final String label;
  final String sub;
  final List<int> hours;
}

const _heatRows = [
  _HeatmapRow('아침', '06–10시', [6, 7, 8, 9]),
  _HeatmapRow('점심', '10–14시', [10, 11, 12, 13]),
  _HeatmapRow('오후', '14–18시', [14, 15, 16, 17]),
  _HeatmapRow('저녁', '18–22시', [18, 19, 20, 21]),
  _HeatmapRow('심야', '22–02시', [22, 23, 0, 1]),
  _HeatmapRow('새벽', '02–06시', [2, 3, 4, 5]),
];

const _heatCols = [
  ('월', 1),
  ('화', 2),
  ('수', 3),
  ('목', 4),
  ('금', 5),
  ('토', 6),
  ('일', 7),
];

int _heatBucket(int v, int max) {
  if (max <= 0 || v <= 0) return 0;
  final r = v / max;
  if (r < 0.08) return 1;
  if (r < 0.22) return 2;
  if (r < 0.45) return 3;
  if (r < 0.75) return 4;
  return 5;
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.async});
  final AsyncValue<List<HeatmapCell>> async;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cells = async.value ?? const <HeatmapCell>[];
    // matrix [row][col]
    final matrix =
        List.generate(_heatRows.length, (_) => List.filled(_heatCols.length, 0));
    for (final c in cells) {
      final colIdx =
          _heatCols.indexWhere((col) => col.$2 == c.dayOfWeek);
      final rowIdx =
          _heatRows.indexWhere((row) => row.hours.contains(c.hour));
      if (colIdx < 0 || rowIdx < 0) continue;
      matrix[rowIdx][colIdx] += c.totalAmount;
    }
    int maxV = 0;
    int total = 0;
    for (final row in matrix) {
      for (final v in row) {
        if (v > maxV) maxV = v;
        total += v;
      }
    }

    Color bgFor(int bucket) {
      if (bucket == 0) return t.bgMuted;
      final alpha = [0.0, 0.18, 0.35, 0.55, 0.75, 1.0][bucket];
      return t.fgBrand.withValues(alpha: alpha);
    }

    Color fgFor(int bucket) {
      if (bucket >= 3) return t.fgOnBrand;
      if (bucket == 0) return t.fgTertiary;
      return t.fgPrimary;
    }

    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(title: _CardTitle('요일·시간대 지출 패턴')),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              '색이 진할수록 지출이 많은 시간대예요 (단위: 원)',
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
          ),
          if (async.isLoading && cells.isEmpty)
            const _EmptyBox(text: '불러오는 중…')
          else if (total == 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('이번 달 거래가 아직 적어요',
                  style: PTypo.caption.copyWith(color: t.fgTertiary)),
            )
          else ...[
            // Header row: 빈 코너 + 요일
            Row(
              children: [
                const SizedBox(width: 56),
                for (final col in _heatCols)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(col.$1,
                          textAlign: TextAlign.center,
                          style: PTypo.caption.copyWith(
                              color: t.fgTertiary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var r = 0; r < _heatRows.length; r++) ...[
              Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_heatRows[r].label,
                            style: PTypo.caption.copyWith(
                                color: t.fgPrimary,
                                fontWeight: FontWeight.w700)),
                        Text(_heatRows[r].sub,
                            style: PTypo.micro.copyWith(
                                color: t.fgTertiary, fontSize: 9)),
                      ],
                    ),
                  ),
                  for (var c = 0; c < _heatCols.length; c++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgFor(_heatBucket(matrix[r][c], maxV)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _shortAmount(matrix[r][c]),
                              style: PTypo.micro.copyWith(
                                  color: fgFor(
                                      _heatBucket(matrix[r][c], maxV)),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (r < _heatRows.length - 1) const SizedBox(height: 4),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text('적음',
                    style:
                        PTypo.caption.copyWith(color: t.fgTertiary)),
                const SizedBox(width: 8),
                for (var i = 1; i <= 5; i++) ...[
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: bgFor(i),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                const SizedBox(width: 4),
                Text('많음',
                    style:
                        PTypo.caption.copyWith(color: t.fgTertiary)),
                const Spacer(),
                Text('총 ${krw(total)}원',
                    style: PTypo.caption.copyWith(
                        color: t.fgSecondary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _shortAmount(int v) {
  if (v <= 0) return '—';
  if (v < 10000) return '${(v / 1000).round()}천';
  return '${(v / 10000).toStringAsFixed(1)}만';
}

// ─── HIGHLIGHTS GRID ───────────────────────────────────────

class _HighlightsGrid extends StatelessWidget {
  const _HighlightsGrid({
    required this.state,
    required this.monthlyAsync,
    required this.prevMonthlyAsync,
    required this.yearlyAsync,
    required this.categoriesAsync,
    required this.merchantAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<MonthlySummary> monthlyAsync;
  final AsyncValue<MonthlySummary> prevMonthlyAsync;
  final AsyncValue<YearlySummary> yearlyAsync;
  final AsyncValue<List<dynamic>> categoriesAsync;
  final AsyncValue<List<MerchantSummary>> merchantAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final s = state;

    // 카테고리 Top
    final bd = monthlyAsync.value?.categoryBreakdown ?? const <CategoryBreakdown>[];
    final groupTotals = <int, ({String name, int amount})>{};
    for (final c in bd) {
      if (c.expenseType != 'EXPENSE') continue;
      final id = c.parentCategoryRowId ?? c.categoryRowId;
      if (id == null) continue;
      final name =
          c.parentCategoryName ?? c.categoryName ?? '미지정';
      final cur = groupTotals[id];
      groupTotals[id] = cur == null
          ? (name: name, amount: c.totalAmount)
          : (name: cur.name, amount: cur.amount + c.totalAmount);
    }
    final topCat = groupTotals.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final topCategory = topCat.firstOrNull;

    // 가맹점 Top
    final merchants = (merchantAsync.value ?? const <MerchantSummary>[]).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final topMerchant = merchants.firstOrNull;

    final totalExpense = monthlyAsync.value?.totalExpense ?? 0;
    final prevExpense = prevMonthlyAsync.value?.totalExpense ?? 0;
    final daysInMonth =
        DateTime(s._month.year, s._month.month + 1, 0).day;

    int periodTotal;
    int divisor;
    if (s._period == _PeriodKey.m1) {
      periodTotal = totalExpense;
      divisor = daysInMonth;
    } else {
      var sum = 0;
      for (final m in yearlyAsync.value?.monthlyAmounts ?? const <MonthlyAmount>[]) {
        if (s._periodMonths.contains(m.month)) sum += m.totalExpense;
      }
      periodTotal = sum;
      divisor = s._periodMonths.length;
    }
    final avgValue = divisor > 0 ? periodTotal ~/ divisor : 0;
    final avgLabel = s._period == _PeriodKey.m1 ? '하루 평균' : '월 평균';
    final dayPct = prevExpense > 0
        ? (((totalExpense - prevExpense) / prevExpense) * 100).round()
        : 0;

    String avgSub;
    if (s._period != _PeriodKey.m1) {
      avgSub = '${s._periodMonths.length}개월 합계 ${krwMasked(periodTotal, masked)}원';
    } else if (prevExpense > 0) {
      avgSub = '전월 대비 ${dayPct >= 0 ? '↑' : '↓'}${dayPct.abs()}%';
    } else {
      avgSub = '전월 비교 불가';
    }

    return Column(
      children: [
        _HighlightCard(
          label: '가장 많이 쓴 카테고리',
          value: topCategory?.name ?? '—',
          sub: topCategory != null
              ? '${krwMasked(topCategory.amount, masked)}원'
              : '데이터 없음',
        ),
        const SizedBox(height: 10),
        _HighlightCard(
          label: '가장 많이 쓴 가맹점',
          value: topMerchant?.merchant ?? '—',
          sub: topMerchant != null
              ? '${topMerchant.count}회 · ${krwMasked(topMerchant.totalAmount, masked)}원'
              : '데이터 없음',
        ),
        const SizedBox(height: 10),
        _HighlightCard(
          label: avgLabel,
          value: '${krwMasked(avgValue, masked)}원',
          sub: avgSub,
          valueIsAmount: true,
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.label,
    required this.value,
    required this.sub,
    this.valueIsAmount = false,
  });
  final String label;
  final String value;
  final String sub;
  final bool valueIsAmount;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: PTypo.caption.copyWith(
                  color: t.fgTertiary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PTypo.h4.copyWith(
                  color: t.fgPrimary,
                  fontWeight: FontWeight.w700,
                  fontFamily: valueIsAmount ? 'monospace' : null)),
          const SizedBox(height: 4),
          Text(sub,
              style: PTypo.caption.copyWith(color: t.fgTertiary)),
        ],
      ),
    );
  }
}

// ─── TREND TAB CARDS ───────────────────────────────────────

class _TrendPoint {
  const _TrendPoint({required this.label, required this.income, required this.expense});
  final String label;
  final int income;
  final int expense;
  int get savings => income - expense;
}

List<_TrendPoint> _computeTrendData(
  _StatsScreenState s,
  AsyncValue<YearlySummary> yearlyAsync,
  AsyncValue<List<Expense>> monthExpAsync,
) {
  if (s._period == _PeriodKey.m1) {
    final exps = monthExpAsync.value ?? const <Expense>[];
    final days = DateTime(s._month.year, s._month.month + 1, 0).day;
    final byDay = <int, ({int income, int expense})>{
      for (var d = 1; d <= days; d++) d: (income: 0, expense: 0),
    };
    for (final e in exps) {
      final raw = e.expenseDate ?? '';
      if (raw.length < 10) continue;
      final day = int.tryParse(raw.substring(8, 10));
      if (day == null) continue;
      final cur = byDay[day];
      if (cur == null) continue;
      if (e.expenseType == 'INCOME') {
        byDay[day] = (income: cur.income + e.amount, expense: cur.expense);
      } else {
        byDay[day] = (income: cur.income, expense: cur.expense + e.amount);
      }
    }
    return [
      for (var d = 1; d <= days; d++)
        _TrendPoint(
          label: '${d.toString().padLeft(2, '0')}일',
          income: byDay[d]!.income,
          expense: byDay[d]!.expense,
        ),
    ];
  }
  final months = (yearlyAsync.value?.monthlyAmounts ?? const <MonthlyAmount>[])
      .where((m) => s._periodMonths.contains(m.month))
      .toList()
    ..sort((a, b) => a.month.compareTo(b.month));
  return [
    for (final m in months)
      _TrendPoint(
        label: '${m.month.toString().padLeft(2, '0')}월',
        income: m.totalIncome,
        expense: m.totalExpense,
      ),
  ];
}

String _fmtTick(double v) {
  if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
  if (v >= 10000) return '${(v / 10000).round()}만';
  return v.toStringAsFixed(0);
}

class _TrendBigCard extends StatelessWidget {
  const _TrendBigCard({
    required this.state,
    required this.yearlyAsync,
    required this.monthExpAsync,
  });
  final _StatsScreenState state;
  final AsyncValue<YearlySummary> yearlyAsync;
  final AsyncValue<List<Expense>> monthExpAsync;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final data = _computeTrendData(state, yearlyAsync, monthExpAsync);
    final loading = state._period == _PeriodKey.m1
        ? monthExpAsync.isLoading
        : yearlyAsync.isLoading;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
              title: _CardTitle('${state._periodLabel} 수입·지출 추이')),
          _PeriodSelectorRow(state: state),
          const SizedBox(height: 16),
          if (loading && data.isEmpty)
            const _EmptyBox(text: '불러오는 중…')
          else if (data.isEmpty || data.every((p) => p.income == 0 && p.expense == 0))
            const _EmptyBox(text: '추이 데이터가 없습니다')
          else ...[
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  lineTouchData: const LineTouchData(enabled: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
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
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(_fmtTick(v),
                              style: PTypo.micro.copyWith(
                                  color: t.fgTertiary, fontSize: 9)),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval:
                            ((data.length - 1) / 5).clamp(1, 1000).toDouble(),
                        getTitlesWidget: (v, _) {
                          final i = v.round();
                          if (i < 0 || i >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(data[i].label,
                                style: PTypo.micro.copyWith(
                                    color: t.fgTertiary, fontSize: 9)),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    // 수입
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < data.length; i++)
                          FlSpot(i.toDouble(), data[i].income.toDouble()),
                      ],
                      isCurved: true,
                      color: t.fgBrand,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                            radius: 2.5,
                            color: t.fgBrand,
                            strokeWidth: 2,
                            strokeColor: t.bgSurface),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: t.fgBrand.withValues(alpha: 0.18),
                      ),
                    ),
                    // 지출
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < data.length; i++)
                          FlSpot(i.toDouble(), data[i].expense.toDouble()),
                      ],
                      isCurved: true,
                      color: t.statusDangerFg,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                            radius: 2.5,
                            color: t.statusDangerFg,
                            strokeWidth: 2,
                            strokeColor: t.bgSurface),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: t.statusDangerFg.withValues(alpha: 0.16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendChip(color: t.fgBrand, label: '수입'),
                const SizedBox(width: 16),
                _LegendChip(color: t.statusDangerFg, label: '지출'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: PTypo.caption.copyWith(color: t.fgSecondary)),
      ],
    );
  }
}

class _TrendStatsGrid extends StatelessWidget {
  const _TrendStatsGrid({
    required this.state,
    required this.yearlyAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<YearlySummary> yearlyAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final months = (yearlyAsync.value?.monthlyAmounts ?? const <MonthlyAmount>[])
        .where((m) => s._periodMonths.contains(m.month))
        .toList();
    final sumIn = months.fold<int>(0, (sum, m) => sum + m.totalIncome);
    final sumOut = months.fold<int>(0, (sum, m) => sum + m.totalExpense);
    final n = months.isEmpty ? 1 : months.length;
    final avgIn = sumIn ~/ n;
    final avgOut = sumOut ~/ n;
    final avgSave = avgIn - avgOut;
    final isSingle = s._period == _PeriodKey.m1;

    final saveRate = avgIn > 0
        ? ((avgSave / avgIn) * 100).toStringAsFixed(1) + '%'
        : '—';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _StatCard(
            label: isSingle ? '수입' : '평균 수입',
            value: '${krwMasked(avgIn, masked)}원'),
        _StatCard(
            label: isSingle ? '지출' : '평균 지출',
            value: '${krwMasked(avgOut, masked)}원'),
        _StatCard(
            label: isSingle ? '순저축' : '평균 저축',
            value: '${krwMasked(avgSave, masked)}원'),
        _StatCard(label: '저축률', value: saveRate),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return _Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: PTypo.caption.copyWith(
                  color: t.fgTertiary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PTypo.h4.copyWith(
                  color: t.fgPrimary,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _SavingsBarsCard extends StatelessWidget {
  const _SavingsBarsCard({
    required this.state,
    required this.yearlyAsync,
    required this.monthExpAsync,
  });
  final _StatsScreenState state;
  final AsyncValue<YearlySummary> yearlyAsync;
  final AsyncValue<List<Expense>> monthExpAsync;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final data = _computeTrendData(state, yearlyAsync, monthExpAsync);
    final isMonth = state._period == _PeriodKey.m1;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: _CardTitle(isMonth ? '일별 순저축' : '월별 순저축'),
            trailing: Text('수입 − 지출',
                style: PTypo.caption.copyWith(color: t.fgTertiary)),
          ),
          if (data.isEmpty)
            const _EmptyBox(text: '데이터가 없습니다')
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
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
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(_fmtTick(v),
                              style: PTypo.micro.copyWith(
                                  color: t.fgTertiary, fontSize: 9)),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval:
                            ((data.length - 1) / 5).clamp(1, 1000).toDouble(),
                        getTitlesWidget: (v, _) {
                          final i = v.round();
                          if (i < 0 || i >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(data[i].label,
                                style: PTypo.micro.copyWith(
                                    color: t.fgTertiary, fontSize: 9)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < data.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i].savings.toDouble(),
                            color: data[i].savings >= 0
                                ? t.fgBrand
                                : t.statusDangerFg,
                            width: data.length > 20 ? 4 : 12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── COMPARE TAB CARDS ─────────────────────────────────────

class _CompareSummaryGrid extends StatelessWidget {
  const _CompareSummaryGrid({
    required this.state,
    required this.monthlyAsync,
    required this.prevMonthlyAsync,
    required this.yearlyAsync,
    required this.prevYearlyAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<MonthlySummary> monthlyAsync;
  final AsyncValue<MonthlySummary> prevMonthlyAsync;
  final AsyncValue<YearlySummary> yearlyAsync;
  final AsyncValue<YearlySummary> prevYearlyAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = state;

    int periodTotal() {
      if (s._period == _PeriodKey.m1) {
        return monthlyAsync.value?.totalExpense ?? 0;
      }
      var sum = 0;
      for (final m in yearlyAsync.value?.monthlyAmounts ?? const <MonthlyAmount>[]) {
        if (s._periodMonths.contains(m.month)) sum += m.totalExpense;
      }
      return sum;
    }

    int prevTotal() {
      final p = s._prevPeriod;
      if (s._period == _PeriodKey.m1) {
        return prevMonthlyAsync.value?.totalExpense ?? 0;
      }
      final pSrc = p.year == s._month.year
          ? yearlyAsync.value
          : prevYearlyAsync.value;
      var sum = 0;
      for (final m in pSrc?.monthlyAmounts ?? const <MonthlyAmount>[]) {
        if (p.months.contains(m.month)) sum += m.totalExpense;
      }
      return sum;
    }

    final now = periodTotal();
    final prev = prevTotal();
    final diff = now - prev;
    final up = diff >= 0;
    final pct = prev > 0
        ? ((diff.abs() / prev) * 100).toStringAsFixed(1) + '%'
        : '—';

    return Column(
      children: [
        _CompareCard(
          label: '${s._periodNow} 지출',
          amount: '${krwMasked(now, masked)}원',
        ),
        const SizedBox(height: 10),
        _CompareCard(
          label: '${s._periodPrev} 지출',
          amount: '${krwMasked(prev, masked)}원',
          muted: true,
        ),
        const SizedBox(height: 10),
        _Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s._momLabel,
                  style: PTypo.caption.copyWith(
                      color: t.fgTertiary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(
                prev > 0 ? '${up ? '+' : '−'}$pct' : '—',
                style: PTypo.h3.copyWith(
                    color: prev <= 0
                        ? t.fgPrimary
                        : (up ? t.statusDangerFg : t.fgBrand),
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace'),
              ),
              const SizedBox(height: 4),
              Text(
                prev > 0
                    ? '${up ? '+' : '−'}${krwMasked(diff.abs(), masked)}원'
                    : '${s._momLabel.replaceFirst(' 대비', '')} 데이터 없음',
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.label,
    required this.amount,
    this.muted = false,
  });
  final String label;
  final String amount;
  final bool muted;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: PTypo.caption.copyWith(
                  color: t.fgTertiary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(amount,
              style: PTypo.h3.copyWith(
                  color: muted ? t.fgSecondary : t.fgPrimary,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _CompareCategoryCard extends StatelessWidget {
  const _CompareCategoryCard({
    required this.state,
    required this.monthlyAsync,
    required this.prevMonthlyAsync,
    required this.yearlyAsync,
    required this.prevYearlyAsync,
    required this.categoriesAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<MonthlySummary> monthlyAsync;
  final AsyncValue<MonthlySummary> prevMonthlyAsync;
  final AsyncValue<YearlySummary> yearlyAsync;
  final AsyncValue<YearlySummary> prevYearlyAsync;
  final AsyncValue<List<dynamic>> categoriesAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = state;

    final cats = categoriesAsync.value ?? const <dynamic>[];
    dynamic catBy(int id) => cats
        .cast<dynamic>()
        .where((c) => c.rowId == id)
        .cast<dynamic>()
        .firstOrNull;

    final byId = <int, ({String name, String? icon, String? color, int now, int prev})>{};
    void addBd(String which, List<CategoryBreakdown> list) {
      for (final c in list) {
        if (c.expenseType != 'EXPENSE') continue;
        final id = c.parentCategoryRowId ?? c.categoryRowId;
        if (id == null) continue;
        final cur = byId[id];
        final name = c.parentCategoryName ?? c.categoryName ?? '미지정';
        final cat = catBy(id);
        var rec = cur ??
            (
              name: name,
              icon: cat?.icon as String?,
              color: cat?.color as String?,
              now: 0,
              prev: 0,
            );
        if (which == 'now') {
          rec = (
            name: rec.name,
            icon: rec.icon,
            color: rec.color,
            now: rec.now + c.totalAmount,
            prev: rec.prev,
          );
        } else {
          rec = (
            name: rec.name,
            icon: rec.icon,
            color: rec.color,
            now: rec.now,
            prev: rec.prev + c.totalAmount,
          );
        }
        byId[id] = rec;
      }
    }

    if (s._period == _PeriodKey.m1) {
      addBd('now', monthlyAsync.value?.categoryBreakdown ?? const <CategoryBreakdown>[]);
      addBd('prev', prevMonthlyAsync.value?.categoryBreakdown ?? const <CategoryBreakdown>[]);
    } else {
      for (final m in yearlyAsync.value?.monthlyAmounts ?? const <MonthlyAmount>[]) {
        if (s._periodMonths.contains(m.month)) {
          addBd('now', m.categoryBreakdown);
        }
      }
      final p = s._prevPeriod;
      final src = p.year == s._month.year
          ? yearlyAsync.value
          : prevYearlyAsync.value;
      for (final m in src?.monthlyAmounts ?? const <MonthlyAmount>[]) {
        if (p.months.contains(m.month)) addBd('prev', m.categoryBreakdown);
      }
    }

    final rows = byId.entries.toList()
      ..sort((a, b) {
        final c = b.value.now.compareTo(a.value.now);
        return c != 0 ? c : b.value.prev.compareTo(a.value.prev);
      });
    final top = rows.take(10).toList();
    final maxAmt = top.isEmpty
        ? 1
        : top
            .map((e) => e.value.now > e.value.prev ? e.value.now : e.value.prev)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 1 << 62);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: _CardTitle('카테고리별 ${s._momLabel}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendChip(color: t.fgBrand, label: s._periodNow),
                const SizedBox(width: 10),
                _LegendChip(
                    color: t.bgBrandMuted, label: s._periodPrev),
              ],
            ),
          ),
          if (top.isEmpty)
            const _EmptyBox(text: '비교할 데이터가 없습니다')
          else
            for (var i = 0; i < top.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _CompareRow(
                row: top[i].value,
                maxAmt: maxAmt,
                masked: masked,
              ),
            ],
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow(
      {required this.row, required this.maxAmt, required this.masked});
  final ({String name, String? icon, String? color, int now, int prev}) row;
  final int maxAmt;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg =
        parseColor(row.color, fallback: t.fgBrand);
    final iconData = lucideByName(row.icon ?? 'tag');
    final diff = row.now - row.prev;
    final up = diff > 0;
    final pct = row.prev > 0 ? ((diff / row.prev) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(iconData, size: 16, color: fg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary, fontWeight: FontWeight.w600)),
            ),
            Text('${krwMasked(row.now, masked)}원',
                style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace')),
            const SizedBox(width: 10),
            SizedBox(
              width: 56,
              child: Text(
                row.prev > 0 ? '${up ? '▲' : '▼'} ${pct.abs()}%' : '—',
                textAlign: TextAlign.right,
                style: PTypo.caption.copyWith(
                    color: row.prev == 0
                        ? t.fgTertiary
                        : (up ? t.statusDangerFg : t.fgBrand),
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 42),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: row.now / maxAmt,
                  minHeight: 10,
                  backgroundColor: t.bgMuted,
                  color: t.fgBrand,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: row.prev / maxAmt,
                  minHeight: 6,
                  backgroundColor: t.bgMuted,
                  color: t.bgBrandMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── helpers ────────────────────────────────────────────────

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
