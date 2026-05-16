import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../app/theme/chart_palette.dart';
import '../../../app/theme/shadow.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_segmented_control.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../application/stats_providers.dart';
import '../domain/stats_models.dart';

/// 통계·분석 화면 (front `StatsPage` 미러).
///
/// 3 탭: 카테고리 / 추이 / 비교 — 페이지 상단 underline TabBar 로 전환.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});
  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

enum _SegMode { month, quarter, year, custom }

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

({DateTime from, DateTime to}) _monthRangeOf(DateTime base) {
  final f = DateTime(base.year, base.month, 1);
  final t = DateTime(base.year, base.month + 1, 0);
  return (from: f, to: t);
}

({DateTime from, DateTime to}) _quarterRangeOf(DateTime base) {
  final q = (base.month - 1) ~/ 3;
  final f = DateTime(base.year, q * 3 + 1, 1);
  final t = DateTime(base.year, q * 3 + 4, 0);
  return (from: f, to: t);
}

({DateTime from, DateTime to}) _yearRangeOf(DateTime base) {
  return (from: DateTime(base.year, 1, 1), to: DateTime(base.year, 12, 31));
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late DateTime _from;
  late DateTime _to;
  _SegMode _segMode = _SegMode.month;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    final r = _monthRangeOf(DateTime.now());
    _from = r.from;
    _to = r.to;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  DateRange get _range => (startDate: _ymd(_from), endDate: _ymd(_to));

  /// 이전 동등 기간 (segMode 별).
  ({DateTime from, DateTime to}) get _prevRange {
    switch (_segMode) {
      case _SegMode.month:
        return (
          from: DateTime(_from.year, _from.month - 1, 1),
          to: DateTime(_from.year, _from.month, 0),
        );
      case _SegMode.quarter:
        return (
          from: DateTime(_from.year, _from.month - 3, 1),
          to: DateTime(_from.year, _from.month, 0),
        );
      case _SegMode.year:
        return (
          from: DateTime(_from.year - 1, 1, 1),
          to: DateTime(_from.year - 1, 12, 31),
        );
      case _SegMode.custom:
        final days = _to.difference(_from).inDays + 1;
        final t = _from.subtract(const Duration(days: 1));
        final f = t.subtract(Duration(days: days - 1));
        return (from: f, to: t);
    }
  }

  DateRange get _prevRangeKey =>
      (startDate: _ymd(_prevRange.from), endDate: _ymd(_prevRange.to));

  /// 단일 월 모드면 일평균, 그 외엔 월평균.
  bool get _useDailyAvg =>
      _segMode == _SegMode.month || _segMode == _SegMode.custom;

  /// 단일 월 또는 1개월 이내 사용자 기간이면 trend chart 일별. 그 외 월별.
  bool useDailyTrend(int monthlyBucketCount) =>
      _segMode == _SegMode.month ||
      (_segMode == _SegMode.custom && monthlyBucketCount <= 1);

  String get _periodLabel {
    if (_segMode == _SegMode.month) return '${_from.year}년 ${_from.month}월';
    if (_segMode == _SegMode.quarter) {
      final q = (_from.month - 1) ~/ 3 + 1;
      return '${_from.year}년 $q분기';
    }
    if (_segMode == _SegMode.year) return '${_from.year}년';
    final sameYear = _from.year == _to.year;
    return sameYear
        ? '${_from.month}/${_from.day} ~ ${_to.month}/${_to.day}'
        : '${_ymd(_from)} ~ ${_ymd(_to)}';
  }

  String get _periodNow => switch (_segMode) {
        _SegMode.month => '이번 달',
        _SegMode.quarter => '이번 분기',
        _SegMode.year => '이번 해',
        _SegMode.custom => '선택 기간',
      };
  String get _periodPrev => switch (_segMode) {
        _SegMode.month => '지난 달',
        _SegMode.quarter => '지난 분기',
        _SegMode.year => '지난 해',
        _SegMode.custom => '이전 기간',
      };
  String get _momLabel => switch (_segMode) {
        _SegMode.month => '전월 대비',
        _SegMode.quarter => '전분기 대비',
        _SegMode.year => '전년 대비',
        _SegMode.custom => '이전 기간 대비',
      };
  String get _avgLabel => _useDailyAvg ? '하루 평균' : '월 평균';

  void setSegMode(_SegMode m) {
    setState(() {
      _segMode = m;
      final now = DateTime.now();
      switch (m) {
        case _SegMode.month:
          final r = _monthRangeOf(now);
          _from = r.from; _to = r.to;
        case _SegMode.quarter:
          final r = _quarterRangeOf(now);
          _from = r.from; _to = r.to;
        case _SegMode.year:
          final r = _yearRangeOf(now);
          _from = r.from; _to = r.to;
        case _SegMode.custom:
          // 현재 from/to 유지 — 사용자가 캘린더로 직접 조정
          break;
      }
    });
  }

  void setCustomRange(DateTime f, DateTime t) {
    setState(() {
      _from = f;
      _to = t;
      _segMode = _SegMode.custom;
    });
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _from, end: _to),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
    );
    if (picked != null) {
      setCustomRange(picked.start, picked.end);
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
            // 웹 underline 변형이 var(--bg-brand-hover) 사용 → 매칭.
            indicatorColor: t.bgBrandHover,
            indicatorWeight: 2.4,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: t.fgPrimary,
            unselectedLabelColor: t.fgTertiary,
            labelStyle: PTypo.bodySm
                .copyWith(fontWeight: PFontWeight.bold, color: t.fgPrimary),
            unselectedLabelStyle: PTypo.bodySm
                .copyWith(fontWeight: PFontWeight.medium, color: t.fgTertiary),
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
    final rangeAsync = ref.watch(rangeSummaryProvider(state._range));
    final categoriesAsync = ref.watch(categoriesProvider);
    final merchantAsync = ref.watch(merchantSummaryProvider((
      startDate: state._range.startDate,
      endDate: state._range.endDate,
    )));
    final heatmapAsync = ref.watch(heatmapProvider(state._range));

    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(state._range));
        ref.invalidate(merchantSummaryProvider((
          startDate: state._range.startDate,
          endDate: state._range.endDate,
        )));
        ref.invalidate(heatmapProvider(state._range));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x32),
        children: [
          _DonutCard(
            state: state,
            rangeAsync: rangeAsync,
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
            rangeAsync: rangeAsync,
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
    final rangeAsync = ref.watch(rangeSummaryProvider(state._range));
    final monthExpAsync = ref.watch(rangeExpensesProvider(state._range));
    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(state._range));
        ref.invalidate(rangeExpensesProvider(state._range));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x32),
        children: [
          _TrendBigCard(
            state: state,
            rangeAsync: rangeAsync,
            monthExpAsync: monthExpAsync,
          ),
          const SizedBox(height: PSpace.x12),
          _TrendStatsGrid(
            state: state,
            rangeAsync: rangeAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: PSpace.x12),
          _SavingsBarsCard(
            state: state,
            rangeAsync: rangeAsync,
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
    final rangeAsync = ref.watch(rangeSummaryProvider(state._range));
    final prevRangeAsync = ref.watch(rangeSummaryProvider(state._prevRangeKey));
    final categoriesAsync = ref.watch(categoriesProvider);
    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(state._range));
        ref.invalidate(rangeSummaryProvider(state._prevRangeKey));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x32),
        children: [
          _CompareSummaryGrid(
            state: state,
            rangeAsync: rangeAsync,
            prevRangeAsync: prevRangeAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: PSpace.x12),
          _CompareCategoryCard(
            state: state,
            rangeAsync: rangeAsync,
            prevRangeAsync: prevRangeAsync,
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
        borderRadius: PRadius.brLg,
      ),
      child: child,
    );
  }
}

class _PeriodSelectorRow extends StatelessWidget {
  const _PeriodSelectorRow({required this.state});
  final _StatsScreenState state;
  @override
  Widget build(BuildContext context) {
    final s = state;
    final isCustom = s._segMode == _SegMode.custom;
    final customLabel = isCustom
        ? (s._from.year == s._to.year
            ? '${s._from.month}/${s._from.day} ~ ${s._to.month}/${s._to.day}'
            : '${s._from.year.toString().substring(2)}.${s._from.month.toString().padLeft(2, '0')}.${s._from.day.toString().padLeft(2, '0')} ~ '
                '${s._to.year.toString().substring(2)}.${s._to.month.toString().padLeft(2, '0')}.${s._to.day.toString().padLeft(2, '0')}')
        : '사용자 지정';
    return Align(
      alignment: Alignment.centerRight,
      child: PSegmentedControl<_SegMode>(
        value: s._segMode,
        elevated: true,
        items: [
          const PSegmentItem(_SegMode.month, '월'),
          const PSegmentItem(_SegMode.quarter, '분기'),
          const PSegmentItem(_SegMode.year, '년'),
          PSegmentItem(_SegMode.custom, customLabel, onTap: s._pickRange),
        ],
        onChanged: s.setSegMode,
      ),
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
          ?trailing,
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
    // 웹 `CardTitle style={{ fontSize: 'var(--fs-body-lg)' }}` 매칭.
    return Text(text,
        style: TextStyle(
            color: t.fgPrimary,
            fontSize: PFontSize.bodyLg,
            fontWeight: PFontWeight.bold));
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

/// Donut 차트 카테고리 색 — [PorestChartPalette] 위임.
/// stats inline OKLCH 9색 배열은 통합 차트 팔레트로 흡수 (light/dark 분기).
Color _donutColor(BuildContext context, int idx) =>
    PorestChartPalette.category(context, idx);

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
    required this.rangeAsync,
    required this.categoriesAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<RangeSummary> rangeAsync;
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
    // 기간 변경 시 드릴다운 해제.
    if (old.state._from != widget.state._from ||
        old.state._to != widget.state._to ||
        old.state._segMode != widget.state._segMode) {
      _activeParentId = null;
    }
  }

  List<CategoryBreakdown> get _periodBreakdown {
    final raw = widget.rangeAsync.value?.categoryBreakdown ?? const <CategoryBreakdown>[];
    return [for (final c in raw) if (c.expenseType == 'EXPENSE') c];
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
    final loading = widget.rangeAsync.isLoading;
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

    // 도넛 센터 라벨은 항상 짧게 — custom 모드의 full date range 가 도넛 안으로 침범하지 않도록.
    final centerPeriodLbl =
        s._segMode == _SegMode.custom ? '선택 기간' : s._periodLabel;
    final centerLbl = isDrilled && activeParent != null
        ? '${activeParent.name} 세부'
        : '$centerPeriodLbl 지출';

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
                            style: TextStyle(
                                fontSize: PFontSize.bodyLg,
                                color: t.fgSecondary,
                                fontWeight: PFontWeight.medium)),
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
          const SizedBox(height: PSpace.x12),
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
                            fontWeight: PFontWeight.heavy,
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
      borderRadius: PRadius.brSm,
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
                      color: t.fgPrimary, fontWeight: PFontWeight.medium)),
            ),
            Text('${pct.toStringAsFixed(1)}%',
                style: PTypo.caption.copyWith(color: t.fgTertiary)),
            const SizedBox(width: 12),
            Text(krwMasked(row.amount, masked),
                style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
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
                                i < 3 ? t.fgIncome : t.fgTertiary,
                            fontWeight: PFontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(top[i].merchant ?? '(이름 없음)',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: PTypo.bodySm.copyWith(
                                            color: t.fgPrimary,
                                            fontWeight: PFontWeight.semi)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('${top[i].count}회',
                                      style: PTypo.caption
                                          .copyWith(color: t.fgTertiary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 고정폭 우측 정렬 — 모든 행 amount 가 같은 X 에서 끝나도록
                            Text(
                              '${krwMasked(top[i].totalAmount, masked)}원',
                              textAlign: TextAlign.right,
                              style: PTypo.bodySm.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: PFontWeight.bold,
                                  fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: PRadius.brFull,
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
                borderRadius: PRadius.brLg,
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
                              fontWeight: PFontWeight.semi)),
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
                                fontWeight: PFontWeight.bold)),
                        Text(_heatRows[r].sub,
                            style: PTypo.micro.copyWith(
                                color: t.fgTertiary, fontSize: PFontSize.micro)),
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
                              borderRadius: PRadius.brMd,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _shortAmount(matrix[r][c]),
                              style: PTypo.micro.copyWith(
                                  color: fgFor(
                                      _heatBucket(matrix[r][c], maxV)),
                                  fontWeight: PFontWeight.bold,
                                  fontSize: PFontSize.micro),
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
                      borderRadius: PRadius.brXs,
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
                        fontWeight: PFontWeight.semi)),
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
    required this.rangeAsync,
    required this.categoriesAsync,
    required this.merchantAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<RangeSummary> rangeAsync;
  final AsyncValue<List<dynamic>> categoriesAsync;
  final AsyncValue<List<MerchantSummary>> merchantAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final s = state;

    // 카테고리 Top — 부모 카테고리 단위 합계
    final bd = rangeAsync.value?.categoryBreakdown ?? const <CategoryBreakdown>[];
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

    // 평균 계산 — 단일 월 또는 사용자 지정 기간이면 일평균, 그 외엔 월평균
    final periodTotal = rangeAsync.value?.totalExpense ?? 0;
    final monthlyBuckets = rangeAsync.value?.monthlyBuckets ?? const <RangeMonthlyBucket>[];
    final rangeDays = s._to.difference(s._from).inDays + 1;
    final divisor = s._useDailyAvg ? rangeDays : monthlyBuckets.length.clamp(1, 9999);
    final avgValue = divisor > 0 ? periodTotal ~/ divisor : 0;
    final avgLabel = s._avgLabel;

    String avgSub;
    if (s._segMode != _SegMode.month) {
      avgSub = '$rangeDays일 합계 ${krwMasked(periodTotal, masked)}원';
    } else {
      avgSub = '${s._periodLabel} 합계';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  color: t.fgTertiary, fontWeight: PFontWeight.medium)),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PTypo.h4.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
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
  AsyncValue<RangeSummary> rangeAsync,
  AsyncValue<List<Expense>> monthExpAsync,
) {
  final buckets = rangeAsync.value?.monthlyBuckets ?? const <RangeMonthlyBucket>[];
  final useDaily = s.useDailyTrend(buckets.length);

  if (useDaily) {
    final exps = monthExpAsync.value ?? const <Expense>[];
    final fromDay = DateTime(s._from.year, s._from.month, s._from.day);
    final toDay = DateTime(s._to.year, s._to.month, s._to.day);
    final days = toDay.difference(fromDay).inDays + 1;
    final byDate = <String, ({int income, int expense, String label})>{};
    for (var i = 0; i < days; i++) {
      final d = fromDay.add(Duration(days: i));
      final key = _ymd(d);
      byDate[key] = (
        income: 0,
        expense: 0,
        label: '${d.month}/${d.day}',
      );
    }
    for (final e in exps) {
      final raw = e.expenseDate ?? '';
      if (raw.length < 10) continue;
      final key = raw.substring(0, 10);
      final cur = byDate[key];
      if (cur == null) continue;
      if (e.expenseType == 'INCOME') {
        byDate[key] = (income: cur.income + e.amount, expense: cur.expense, label: cur.label);
      } else {
        byDate[key] = (income: cur.income, expense: cur.expense + e.amount, label: cur.label);
      }
    }
    return [
      for (final v in byDate.values)
        _TrendPoint(label: v.label, income: v.income, expense: v.expense),
    ];
  }

  // 모든 버킷이 같은 해면 'MM' 만 (년 prefix 생략) — 년/단일년도 사용자기간
  final allSameYear =
      buckets.isNotEmpty && buckets.every((b) => b.year == buckets.first.year);
  return [
    for (final b in buckets)
      _TrendPoint(
        label: allSameYear
            ? b.month.toString().padLeft(2, '0')
            : '${b.year}.${b.month.toString().padLeft(2, '0')}',
        income: b.totalIncome,
        expense: b.totalExpense,
      ),
  ];
}

String _fmtTick(double v) {
  final abs = v.abs();
  String body;
  if (abs >= 100000000) {
    body = '${(abs / 100000000).toStringAsFixed(1)}억';
  } else if (abs >= 10000) {
    body = '${(abs / 10000).round()}만';
  } else {
    body = abs.toStringAsFixed(0);
  }
  return v < 0 ? '−$body' : body;
}

/// fl_chart 의 x 라벨 스텝 필터 — interval 만으로는 BarChart 에서 잘 안 먹힘.
/// 12 이하면 전부, 그 이상이면 약 6~7 라벨만 (양 끝 + 균등 간격).
bool _showXLabel(int i, int n) {
  if (n <= 12) return true; // 년(12) / 분기(3) / 짧은 사용자기간 — 전부 표시
  if (i == 0 || i == n - 1) return true; // 양 끝 항상
  final step = (n / 6).ceil();
  return i % step == 0 && (n - 1 - i) >= (step ~/ 2);
}

/// fl_chart 툴팁 한 줄 ─ 색 스왓치(유니코드) + 레이블 + 금액.
/// 차트 위에 떠있는 커스텀 오버레이 툴팁.
///
/// fl_chart 1.2.0 의 RichText 기반 툴팁(`LineTooltipItem`/`BarTooltipItem`)은
/// 모든 자식이 `TextSpan` 이어야 해서 `SizedBox + textAlign:right` 같은
/// 레이아웃 기반 정렬이 불가능. `WidgetSpan` 은 placeholder dimensions 미설정
/// 으로 assertion 실패. → 기본 툴팁을 끄고 Stack 위에 직접 렌더한다.
class _ChartTooltipBox extends StatelessWidget {
  const _ChartTooltipBox({required this.title, required this.rows});
  final String title;
  final List<_ChartTooltipRowData> rows;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return IgnorePointer(
      ignoring: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.bgSurface,
          border: Border.all(color: t.borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: PShadow.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: PTypo.micro.copyWith(
                    color: t.fgTertiary, fontWeight: PFontWeight.semi)),
            const SizedBox(height: 6),
            for (final r in rows) ...[
              _ChartTooltipRow(data: r),
              if (r != rows.last) const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChartTooltipRowData {
  const _ChartTooltipRowData({
    required this.color,
    required this.label,
    required this.amount,
    this.amountColor,
  });
  final Color color;
  final String label;
  final String amount;
  final Color? amountColor;
}

class _ChartTooltipRow extends StatelessWidget {
  const _ChartTooltipRow({required this.data});
  final _ChartTooltipRowData data;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: data.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        // 라벨 폭 고정 — 한글 폭 차이 무시하고 amount 시작 위치를 고정.
        SizedBox(
          width: 36,
          child: Text(data.label,
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
        ),
        const SizedBox(width: 12),
        // amount 는 우측 정렬된 고정폭 박스 안에 둬서 행 간 우측 끝점 일치.
        SizedBox(
          width: 110,
          child: Text(
            data.amount,
            textAlign: TextAlign.right,
            style: PTypo.bodySm.copyWith(
              color: data.amountColor ?? t.fgPrimary,
              fontWeight: PFontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendBigCard extends ConsumerStatefulWidget {
  const _TrendBigCard({
    required this.state,
    required this.rangeAsync,
    required this.monthExpAsync,
  });
  final _StatsScreenState state;
  final AsyncValue<RangeSummary> rangeAsync;
  final AsyncValue<List<Expense>> monthExpAsync;

  @override
  ConsumerState<_TrendBigCard> createState() => _TrendBigCardState();
}

class _TrendBigCardState extends ConsumerState<_TrendBigCard> {
  int? _touchedIdx;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final data = _computeTrendData(
        widget.state, widget.rangeAsync, widget.monthExpAsync);
    final loading =
        widget.rangeAsync.isLoading || widget.monthExpAsync.isLoading;

    // 수입 ↔ 지출 스케일 차이가 크면 한 축에 그릴 때 작은 시리즈가 묻힘.
    // → 지출을 (incomeMax / expenseMax) 로 스케일링해 시각적으론 같은 높이 범위를 차지하게.
    //   좌축은 수입(raw), 우축 라벨은 표시값을 1/scale 로 되돌려 지출 실제값.
    final incomeMax =
        data.fold<int>(0, (m, p) => p.income > m ? p.income : m);
    final expenseMax =
        data.fold<int>(0, (m, p) => p.expense > m ? p.expense : m);
    final useDualAxis = incomeMax > 0 && expenseMax > 0;
    final scale = useDualAxis ? incomeMax / expenseMax : 1.0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
              title: _CardTitle('${widget.state._periodLabel} 수입·지출 추이')),
          _PeriodSelectorRow(state: widget.state),
          const SizedBox(height: 16),
          if (loading && data.isEmpty)
            const _EmptyBox(text: '불러오는 중…')
          else if (data.isEmpty || data.every((p) => p.income == 0 && p.expense == 0))
            const _EmptyBox(text: '추이 데이터가 없습니다')
          else ...[
            SizedBox(
              height: 200,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
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
                      final spots = response?.lineBarSpots;
                      if (spots == null || spots.isEmpty) {
                        if (_touchedIdx != null) {
                          setState(() => _touchedIdx = null);
                        }
                        return;
                      }
                      final i = spots.first.x.toInt();
                      if (i != _touchedIdx && i >= 0 && i < data.length) {
                        setState(() => _touchedIdx = i);
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      // fl_chart 의 RichText 툴팁은 한글 라벨 폭 차이로 정렬 불가.
                      // → 기본 툴팁 끄고 Stack 위에 직접 그린다 (아래 Positioned).
                      getTooltipColor: (_) => Colors.transparent,
                      tooltipBorder: BorderSide.none,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 0,
                      getTooltipItems: (touched) =>
                          List<LineTooltipItem?>.filled(touched.length, null),
                    ),
                  ),
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
                    // 좌축: 수입 (raw)
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(_fmtTick(v),
                              style: PTypo.micro.copyWith(
                                  color: useDualAxis ? t.fgBrand : t.fgTertiary,
                                  fontSize: PFontSize.micro)),
                        ),
                      ),
                    ),
                    // 우축: 지출 — 표시값을 역스케일해 원래 지출값 복원
                    rightTitles: useDualAxis
                        ? AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              getTitlesWidget: (v, _) => Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(_fmtTick(v / scale),
                                    style: PTypo.micro.copyWith(
                                        color: t.fgExpense,
                                        fontSize: PFontSize.micro)),
                              ),
                            ),
                          )
                        : const AxisTitles(
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
                          if (!_showXLabel(i, data.length)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(data[i].label,
                                style: PTypo.micro.copyWith(
                                    color: t.fgTertiary, fontSize: PFontSize.micro)),
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
                      color: t.fgIncome,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, _, _, _) => FlDotCirclePainter(
                            radius: 2.5,
                            color: t.fgIncome,
                            strokeWidth: 2,
                            strokeColor: t.bgSurface),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: t.fgIncome.withValues(alpha: 0.18),
                      ),
                    ),
                    // 지출 — 좌축에 함께 그리되 시각적 비율은 수입 max 에 맞춰 스케일링
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < data.length; i++)
                          FlSpot(i.toDouble(), data[i].expense * scale),
                      ],
                      isCurved: true,
                      color: t.fgExpense,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, _, _, _) => FlDotCirclePainter(
                            radius: 2.5,
                            color: t.fgExpense,
                            strokeWidth: 2,
                            strokeColor: t.bgSurface),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: t.fgExpense.withValues(alpha: 0.16),
                      ),
                    ),
                  ],
                ),
              ),
                  if (_touchedIdx != null && _touchedIdx! < data.length)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _ChartTooltipBox(
                        title: data[_touchedIdx!].label,
                        rows: [
                          _ChartTooltipRowData(
                            color: t.fgIncome,
                            label: '수입',
                            amount: '${krw(data[_touchedIdx!].income)}원',
                          ),
                          _ChartTooltipRowData(
                            color: t.fgExpense,
                            label: '지출',
                            amount: '${krw(data[_touchedIdx!].expense)}원',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendChip(color: t.fgIncome, label: '수입'),
                const SizedBox(width: 16),
                _LegendChip(color: t.fgExpense, label: '지출'),
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
            borderRadius: PRadius.brXs,
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
    required this.rangeAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<RangeSummary> rangeAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final buckets = rangeAsync.value?.monthlyBuckets ?? const <RangeMonthlyBucket>[];
    final sumIn = buckets.fold<int>(0, (sum, b) => sum + b.totalIncome);
    final sumOut = buckets.fold<int>(0, (sum, b) => sum + b.totalExpense);
    final n = buckets.isEmpty ? 1 : buckets.length;
    final avgIn = sumIn ~/ n;
    final avgOut = sumOut ~/ n;
    final avgSave = avgIn - avgOut;
    final isSingle = s._segMode == _SegMode.month;

    final saveRate = avgIn > 0
        ? '${((avgSave / avgIn) * 100).toStringAsFixed(1)}%'
        : '—';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.0,
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
                  color: t.fgTertiary, fontWeight: PFontWeight.medium)),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PTypo.h4.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.heavy,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _SavingsBarsCard extends ConsumerStatefulWidget {
  const _SavingsBarsCard({
    required this.state,
    required this.rangeAsync,
    required this.monthExpAsync,
  });
  final _StatsScreenState state;
  final AsyncValue<RangeSummary> rangeAsync;
  final AsyncValue<List<Expense>> monthExpAsync;

  @override
  ConsumerState<_SavingsBarsCard> createState() => _SavingsBarsCardState();
}

class _SavingsBarsCardState extends ConsumerState<_SavingsBarsCard> {
  int? _touchedIdx;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final data = _computeTrendData(
        widget.state, widget.rangeAsync, widget.monthExpAsync);
    final useDaily = widget.state
        .useDailyTrend(widget.rangeAsync.value?.monthlyBuckets.length ?? 0);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: _CardTitle(useDaily ? '일별 순저축' : '월별 순저축'),
            trailing: Text('수입 − 지출',
                style: PTypo.caption.copyWith(color: t.fgTertiary)),
          ),
          if (data.isEmpty)
            const _EmptyBox(text: '데이터가 없습니다')
          else
            SizedBox(
              height: 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
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
                      if (i != _touchedIdx && i >= 0 && i < data.length) {
                        setState(() => _touchedIdx = i);
                      }
                    },
                    touchTooltipData: BarTouchTooltipData(
                      // 기본 툴팁 OFF — Stack 위에 직접 그린다 (아래 Positioned)
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
                                  color: t.fgTertiary, fontSize: PFontSize.micro)),
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
                          if (!_showXLabel(i, data.length)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(data[i].label,
                                style: PTypo.micro.copyWith(
                                    color: t.fgTertiary, fontSize: PFontSize.micro)),
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
                                ? t.fgIncome
                                : t.fgExpense,
                            width: data.length > 20 ? 4 : 12,
                            borderRadius: PRadius.brXs,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
                  if (_touchedIdx != null && _touchedIdx! < data.length)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Builder(builder: (_) {
                        final p = data[_touchedIdx!];
                        final v = p.savings;
                        final sign = v >= 0 ? '+' : '−';
                        return _ChartTooltipBox(
                          title: p.label,
                          rows: [
                            _ChartTooltipRowData(
                              color: v >= 0 ? t.fgIncome : t.fgExpense,
                              label: '순저축',
                              amount: '$sign${krw(v.abs())}원',
                              amountColor:
                                  v >= 0 ? t.fgIncome : t.fgExpense,
                            ),
                          ],
                        );
                      }),
                    ),
                ],
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
    required this.rangeAsync,
    required this.prevRangeAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<RangeSummary> rangeAsync;
  final AsyncValue<RangeSummary> prevRangeAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = state;

    final now = rangeAsync.value?.totalExpense ?? 0;
    final prev = prevRangeAsync.value?.totalExpense ?? 0;
    final diff = now - prev;
    final up = diff >= 0;
    final pct = prev > 0
        ? '${((diff.abs() / prev) * 100).toStringAsFixed(1)}%'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      color: t.fgTertiary, fontWeight: PFontWeight.medium)),
              const SizedBox(height: 8),
              Text(
                prev > 0 ? '${up ? '+' : '−'}$pct' : '—',
                style: PTypo.h3.copyWith(
                    color: prev <= 0
                        ? t.fgPrimary
                        : (up ? t.fgExpense : t.fgIncome),
                    fontWeight: PFontWeight.heavy,
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

/// 양쪽 끝 모두 라운드 처리된 progress bar (LinearProgressIndicator 의 fill 우측이
/// 항상 square 인 한계 우회). 트랙은 투명.
class _RoundedBar extends StatelessWidget {
  const _RoundedBar({
    required this.value,
    required this.height,
    required this.color,
  });
  final double value; // 0.0 ~ 1.0
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (ctx, c) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: c.maxWidth * clamped,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          );
        },
      ),
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
                  color: t.fgTertiary, fontWeight: PFontWeight.medium)),
          const SizedBox(height: 8),
          Text(amount,
              style: PTypo.h3.copyWith(
                  color: muted ? t.fgSecondary : t.fgPrimary,
                  fontWeight: PFontWeight.heavy,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _CompareCategoryCard extends StatelessWidget {
  const _CompareCategoryCard({
    required this.state,
    required this.rangeAsync,
    required this.prevRangeAsync,
    required this.categoriesAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<RangeSummary> rangeAsync;
  final AsyncValue<RangeSummary> prevRangeAsync;
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

    addBd('now', rangeAsync.value?.categoryBreakdown ?? const <CategoryBreakdown>[]);
    addBd('prev', prevRangeAsync.value?.categoryBreakdown ?? const <CategoryBreakdown>[]);

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
                borderRadius: PRadius.brLg,
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
                      color: t.fgPrimary, fontWeight: PFontWeight.semi)),
            ),
            Text('${krwMasked(row.now, masked)}원',
                style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
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
                        : (up ? t.fgExpense : t.fgIncome),
                    fontWeight: PFontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 42),
          child: Column(
            children: [
              // 트랙 투명, fill 양 끝 round — 웹과 매칭
              _RoundedBar(
                value: row.now / maxAmt,
                height: 10,
                color: t.fgBrand,
              ),
              const SizedBox(height: 4),
              _RoundedBar(
                value: row.prev / maxAmt,
                height: 6,
                color: t.bgBrandMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

