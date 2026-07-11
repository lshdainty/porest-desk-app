import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_axis.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart' as cp;
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/format_locale.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/app/theme/chart_palette.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_chart_tooltip.dart';
import 'package:porest_desk_app/shared/widgets/p_chip.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';

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

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _tabIndex = 0;
  late DateTime _from;
  late DateTime _to;
  _SegMode _segMode = _SegMode.month;

  @override
  void initState() {
    super.initState();
    final r = _monthRangeOf(DateTime.now());
    _from = r.from;
    _to = r.to;
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
    if (_segMode == _SegMode.month) return yearMonth(_from);
    if (_segMode == _SegMode.quarter) {
      final q = (_from.month - 1) ~/ 3 + 1;
      // 분기는 중앙 헬퍼 부재 → ko 유지 + en 분기(en "Q3 2026").
      return localeIsEn() ? 'Q$q ${_from.year}' : '${_from.year}년 $q분기';
    }
    if (_segMode == _SegMode.year) return yearOnly(_from);
    final sameYear = _from.year == _to.year;
    return sameYear
        ? '${_from.month}/${_from.day} ~ ${_to.month}/${_to.day}'
        : '${_ymd(_from)} ~ ${_ymd(_to)}';
  }

  String get _periodNow {
    final l = AppLocalizations.of(context);
    return switch (_segMode) {
      _SegMode.month => l.expThisMonth,
      _SegMode.quarter => l.statsThisQuarter,
      _SegMode.year => l.statsThisYear,
      _SegMode.custom => l.statsCustomPeriod,
    };
  }
  String get _periodPrev {
    final l = AppLocalizations.of(context);
    return switch (_segMode) {
      _SegMode.month => l.statsLastMonth,
      _SegMode.quarter => l.statsLastQuarter,
      _SegMode.year => l.statsLastYear,
      _SegMode.custom => l.statsPrevPeriod,
    };
  }
  String get _momLabel {
    final l = AppLocalizations.of(context);
    return switch (_segMode) {
      _SegMode.month => l.statsMomMonth,
      _SegMode.quarter => l.statsMomQuarter,
      _SegMode.year => l.statsMomYear,
      _SegMode.custom => l.statsMomCustom,
    };
  }
  String get _momPrevLabel {
    final l = AppLocalizations.of(context);
    return switch (_segMode) {
      _SegMode.month => l.statsMomPrevMonth,
      _SegMode.quarter => l.statsMomPrevQuarter,
      _SegMode.year => l.statsMomPrevYear,
      _SegMode.custom => l.statsPrevPeriod,
    };
  }
  String get _avgLabel {
    final l = AppLocalizations.of(context);
    return _useDailyAvg ? l.statsDailyAvg : l.statsMonthlyAvg;
  }

  void setSegMode(_SegMode m) {
    setState(() {
      _segMode = m;
      final now = DateTime.now();
      switch (m) {
        case _SegMode.month:
          final r = _monthRangeOf(now);
          _from = r.from;
          _to = r.to;
        case _SegMode.quarter:
          final r = _quarterRangeOf(now);
          _from = r.from;
          _to = r.to;
        case _SegMode.year:
          final r = _yearRangeOf(now);
          _from = r.from;
          _to = r.to;
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
    // 가계부 FilterDialog 패턴 정합 — 상단 ToggleGroup (월/분기/년/직접) +
    // 항상 date range PDateInput + custom 시만 quick chips. apply 시 segMode +
    // from/to 모두 반영. shrinkWrap: true — content 자연 합산.
    final l = AppLocalizations.of(context);
    final controller = PSheetController();
    _SegMode draftSeg = _segMode;
    DateTime draftFrom = _from;
    DateTime draftTo = _to;
    controller.setCanSubmit(!draftTo.isBefore(draftFrom));

    final picked = await showPSheet<({_SegMode seg, DateTimeRange range})>(
      context,
      title: l.statsPeriodPickerTitle,
      shrinkWrap: true,
      contentBuilder: (sheetCtx, _) {
        controller.onSubmit ??= () async {
          Navigator.pop(sheetCtx, (
            seg: draftSeg,
            range: DateTimeRange(start: draftFrom, end: draftTo),
          ));
        };
        final quickRanges = <({String label, int days})>[
          (label: l.statsRange7d, days: 7),
          (label: l.statsRange30d, days: 30),
          (label: l.statsRange3m, days: 90),
          (label: l.statsRange6m, days: 180),
          (label: l.statsRange1y, days: 365),
        ];
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void syncCan() =>
                controller.setCanSubmit(!draftTo.isBefore(draftFrom));
            void setSeg(_SegMode v) {
              setSheet(() {
                draftSeg = v;
                final now = DateTime.now();
                if (v == _SegMode.month) {
                  draftFrom = DateTime(now.year, now.month, 1);
                  draftTo = DateTime(now.year, now.month + 1, 0);
                } else if (v == _SegMode.quarter) {
                  final q = (now.month - 1) ~/ 3;
                  draftFrom = DateTime(now.year, q * 3 + 1, 1);
                  draftTo = DateTime(now.year, q * 3 + 4, 0);
                } else if (v == _SegMode.year) {
                  draftFrom = DateTime(now.year, 1, 1);
                  draftTo = DateTime(now.year, 12, 31);
                }
              });
              syncCan();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x20,
                vertical: PSpace.x12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PTabs<_SegMode>(
                    value: draftSeg,
                    variant: PTabsVariant.container,
                    size: PTabsSize.sm,
                    expand: true,
                    items: [
                      PTabItem(value: _SegMode.month, label: l.statsSegMonth),
                      PTabItem(value: _SegMode.quarter, label: l.statsSegQuarter),
                      PTabItem(value: _SegMode.year, label: l.statsSegYear),
                      PTabItem(value: _SegMode.custom, label: l.statsSegCustom),
                    ],
                    onChanged: setSeg,
                  ),
                  const SizedBox(height: PSpace.lg),
                  Row(
                    children: [
                      Expanded(
                        child: PDateInput(
                          value: draftFrom,
                          onChanged: (d) {
                            if (d != null) {
                              setSheet(() {
                                draftFrom = d;
                                draftSeg = _SegMode.custom;
                              });
                              syncCan();
                            }
                          },
                          firstDate: DateTime(2020),
                          lastDate: DateTime(DateTime.now().year + 5, 12, 31),
                        ),
                      ),
                      const SizedBox(width: PSpace.sm),
                      Text(
                        '~',
                        style: PTypo.body.copyWith(
                          color: ctx.tokens.fgTertiary,
                        ),
                      ),
                      const SizedBox(width: PSpace.sm),
                      Expanded(
                        child: PDateInput(
                          value: draftTo,
                          onChanged: (d) {
                            if (d != null) {
                              setSheet(() {
                                draftTo = d;
                                draftSeg = _SegMode.custom;
                              });
                              syncCan();
                            }
                          },
                          firstDate: DateTime(2020),
                          lastDate: DateTime(DateTime.now().year + 5, 12, 31),
                        ),
                      ),
                    ],
                  ),
                  if (draftSeg == _SegMode.custom) ...[
                    const SizedBox(height: PSpace.lg),
                    Wrap(
                      spacing: PSpace.sm,
                      runSpacing: PSpace.sm,
                      children: [
                        for (final q in quickRanges)
                          PChip(
                            label: q.label,
                            selected: false,
                            onTap: () {
                              final today = DateTime.now();
                              setSheet(() {
                                draftFrom = today.subtract(
                                  Duration(days: q.days - 1),
                                );
                                draftTo = today;
                                draftSeg = _SegMode.custom;
                              });
                              syncCan();
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      footerBuilder: (ctx) =>
          PSheetFooter(controller: controller, submitLabel: l.actionApply),
    ).whenComplete(controller.dispose);
    if (picked != null) {
      if (picked.seg == _SegMode.custom) {
        setCustomRange(picked.range.start, picked.range.end);
      } else {
        setSegMode(picked.seg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: t.bgSurface,
      // appBar 제거 — shell MobileScaffold 의 MobileHeader 가 title='통계·분석' +
      // actions(theme/eye/bell/search) 일관 표시.
      body: Column(
        children: [
          Container(
            color: t.bgSurface,
            child: PTabs<int>(
              items: [
                PTabItem(value: 0, label: l.expCategory),
                PTabItem(value: 1, label: l.statsTabTrend),
                PTabItem(value: 2, label: l.statsTabCompare),
              ],
              value: _tabIndex,
              onChanged: (v) => setState(() => _tabIndex = v),
              variant: PTabsVariant.underline,
              expand: true,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _CategoryTab(state: this),
                _TrendTab(state: this),
                _CompareTab(state: this),
              ],
            ),
          ),
        ],
      ),
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
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final rangeAsync = ref.watch(rangeSummaryProvider(state._range));
    final categoriesAsync = ref.watch(categoriesProvider);
    final merchantAsync = ref.watch(
      merchantSummaryProvider((
        startDate: state._range.startDate,
        endDate: state._range.endDate,
      )),
    );
    final heatmapAsync = ref.watch(heatmapProvider(state._range));
    // 가맹점 대표 카테고리 아이콘 역산용 원시 거래
    final expensesAsync = ref.watch(rangeExpensesProvider(state._range));
    // 하루 평균 전월 대비용 이전 기간
    final prevRangeAsync = ref.watch(rangeSummaryProvider(state._prevRangeKey));

    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(state._range));
        ref.invalidate(
          merchantSummaryProvider((
            startDate: state._range.startDate,
            endDate: state._range.endDate,
          )),
        );
        ref.invalidate(heatmapProvider(state._range));
        ref.invalidate(rangeExpensesProvider(state._range));
      },
      child: ListView(
        // 카드 다이어트 — design StatsScreen: padding 16/20/24 + 섹션 gap 36.
        padding: const EdgeInsets.fromLTRB(
          PSpace.x20,
          PSpace.x16,
          PSpace.x20,
          PSpace.x24,
        ),
        children: [
          _DonutCard(
            state: state,
            rangeAsync: rangeAsync,
            categoriesAsync: categoriesAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: 36),
          _TopMerchantsCard(async: merchantAsync, masked: settings.hideAmounts),
          const SizedBox(height: 36),
          _HeatmapCard(async: heatmapAsync, masked: settings.hideAmounts),
          const SizedBox(height: 36),
          _HighlightsGrid(
            state: state,
            rangeAsync: rangeAsync,
            categoriesAsync: categoriesAsync,
            merchantAsync: merchantAsync,
            expensesAsync: expensesAsync,
            prevRangeAsync: prevRangeAsync,
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
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final rangeAsync = ref.watch(rangeSummaryProvider(state._range));
    final monthExpAsync = ref.watch(rangeExpensesProvider(state._range));
    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(state._range));
        ref.invalidate(rangeExpensesProvider(state._range));
      },
      child: ListView(
        // 카드 다이어트 — design StatsScreen: padding 16/20/24 + 섹션 gap 36.
        padding: const EdgeInsets.fromLTRB(
          PSpace.x20,
          PSpace.x16,
          PSpace.x20,
          PSpace.x24,
        ),
        children: [
          _TrendBigCard(
            state: state,
            rangeAsync: rangeAsync,
            monthExpAsync: monthExpAsync,
          ),
          const SizedBox(height: 36),
          _TrendStatsGrid(
            state: state,
            rangeAsync: rangeAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: 36),
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
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final rangeAsync = ref.watch(rangeSummaryProvider(state._range));
    final prevRangeAsync = ref.watch(rangeSummaryProvider(state._prevRangeKey));
    final categoriesAsync = ref.watch(categoriesProvider);
    // 요일별 지출 비교 — 이번/지난 기간 원시 거래로 요일 집계.
    final nowExpAsync = ref.watch(rangeExpensesProvider(state._range));
    final prevExpAsync = ref.watch(rangeExpensesProvider(state._prevRangeKey));
    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(state._range));
        ref.invalidate(rangeSummaryProvider(state._prevRangeKey));
        ref.invalidate(rangeExpensesProvider(state._range));
        ref.invalidate(rangeExpensesProvider(state._prevRangeKey));
      },
      child: ListView(
        // 카드 다이어트 — design StatsScreen: padding 16/20/24 + 섹션 gap 36.
        padding: const EdgeInsets.fromLTRB(
          PSpace.x20,
          PSpace.x16,
          PSpace.x20,
          PSpace.x24,
        ),
        children: [
          _CompareSummaryGrid(
            state: state,
            rangeAsync: rangeAsync,
            prevRangeAsync: prevRangeAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: 36),
          _CompareCategoryCard(
            state: state,
            rangeAsync: rangeAsync,
            prevRangeAsync: prevRangeAsync,
            categoriesAsync: categoriesAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: 36),
          _CompareWeekdayCard(
            nowExpAsync: nowExpAsync,
            prevExpAsync: prevExpAsync,
            masked: settings.hideAmounts,
          ),
        ],
      ),
    );
  }
}

// ─── 공용 위젯 ─────────────────────────────────────────────

/// 섹션 컨테이너 — 카드 다이어트(design app.css `.m-scroll .p-card` 플랫):
/// 카드 배경/그림자/radius 없이 콘텐츠 inset(가로 10)만. 섹션 내부 헤더는
/// 각 섹션이 자체 렌더 — 섹션 사이 여백(36)이 구분을 담당한다.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10),
      child: child,
    );
  }
}

/// 카테고리 카드 우측 trigger — 가계부 FilterDialog 패턴 정합.
/// 작은 outline button (Calendar icon + periodLabel + chevron). 클릭 시 _pickRange().
class _PeriodTrigger extends StatelessWidget {
  const _PeriodTrigger({required this.state});
  final _StatsScreenState state;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: state._pickRange,
        borderRadius: PRadius.brMd,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x12,
            vertical: PSpace.x8,
          ),
          decoration: BoxDecoration(
            color: t.bgSurface,
            border: Border.all(color: t.borderSubtle),
            borderRadius: PRadius.brMd,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.calendar, size: 14, color: t.fgSecondary),
              const SizedBox(width: PSpace.x4),
              // custom + 다른 year 시 'YYYY-MM-DD ~ YYYY-MM-DD' 너무 길어 wrap. ~ 다음 명시 break.
              Text(
                state._segMode == _SegMode.custom &&
                        state._from.year != state._to.year
                    ? '${_ymd(state._from)} ~\n${_ymd(state._to)}'
                    : state._periodLabel,
                textAlign: TextAlign.center,
                style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.medium,
                  height: 1.3,
                ),
              ),
              const SizedBox(width: PSpace.x4),
              Icon(LucideIcons.chevronDown, size: 12, color: t.fgTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// _RangePickerDialog 제거 — showPSheet (bottom drawer) 패턴으로 전환됨.
// _pickRange method 안에서 직접 showPSheet 호출 + StatefulBuilder 로 draft state 관리.
// _PeriodSelectorRow / _SelectedRangeCard 도 제거 — _PeriodTrigger 로 통합.

/// chart 카드 안의 header (title + optional trailing) — PCardHeader 직접
/// 사용 대신 _Card 의 내부 padding 컨텍스트와 맞춰 bottom 14 만 유지.
/// (PCardHeader 의 all(xl=24) 는 _Card 의 dense 18 padding 안에서 너무 큼.)
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

/// chart 카드 title — PCardTitle 위임.
class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => PCardTitle(text);
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({this.text});
  final String? text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(text ?? l.statsNoData,
            style: PTypo.caption.copyWith(color: t.fgTertiary)),
      ),
    );
  }
}

// ─── 로딩 placeholder helpers — Web StatsPageSkeleton 미러 ───────────────
// 각 카드의 isLoading 분기에서 _EmptyBox(text:'불러오는 중…') 대신 사용.
// Web 의 SkeletonBase 모양과 1:1 정합 (도넛 circle / 5 legend rows / chart bar 등).

class _DonutCardSkeleton extends StatelessWidget {
  const _DonutCardSkeleton();
  @override
  Widget build(BuildContext context) {
    // 실제: SizedBox(height:200) 도넛(centerSpace 60 + radius 28 → ø176) +
    // SizedBox(height:14) + N _DonutLegendRow(padding h4/v8: dot10 / 10 /
    // Expanded(name) / pct / 12 / amount).
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Center(child: PSkeleton.circle(size: 176)),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                PSkeleton.circle(size: 10),
                const SizedBox(width: 10),
                const Expanded(child: PSkeleton.line(height: 14)),
                const PSkeleton.line(width: 36, height: 12),
                const SizedBox(width: 12),
                const PSkeleton.line(width: 56, height: 14),
              ],
            ),
          ),
      ],
    );
  }
}

class _MerchantListSkeleton extends StatelessWidget {
  const _MerchantListSkeleton();
  @override
  Widget build(BuildContext context) {
    // 실제 _TopMerchantsCard 행: rank(width24·텍스트, 원 아님) / 8 /
    // Expanded(Row[name+count … amount] + 6 + LinearProgress minHeight4 brFull).
    return Column(
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(
                width: 24,
                child: Center(child: PSkeleton.line(width: 12, height: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Expanded(child: PSkeleton.line(width: 120, height: 14)),
                        SizedBox(width: 8),
                        PSkeleton.line(width: 64, height: 14),
                      ],
                    ),
                    const SizedBox(height: 6),
                    PSkeleton(height: 4, borderRadius: PRadius.brFull),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// _CompareCategoryCard 의 _CompareRow placeholder — icon tile(32) + name +
/// amount + pct, 그 아래 좌측 42 들여쓴 2 stacked 막대(10 / 6). 행간 16.
class _CompareListSkeleton extends StatelessWidget {
  const _CompareListSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PSkeleton(
                    width: 32,
                    height: 32,
                    borderRadius: PRadius.tile(32),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: PSkeleton.line(height: 14)),
                  const SizedBox(width: 10),
                  const PSkeleton.line(width: 64, height: 14),
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 56,
                    child: PSkeleton.line(height: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 42),
                child: Column(
                  children: [
                    PSkeleton(height: 10, borderRadius: PRadius.brFull),
                    SizedBox(height: 4),
                    PSkeleton(height: 6, borderRadius: PRadius.brFull),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HeatmapSkeleton extends StatelessWidget {
  const _HeatmapSkeleton();
  @override
  Widget build(BuildContext context) {
    // 실제 히트맵: 헤더(56 spacer + 7 요일) + 6행(56 라벨열 + 7 셀 AspectRatio1
    // padding all2 radius brSm, 행간 4) + 범례행.
    Widget cellRow() => Row(
          children: [
            // 라벨열(56) — 실제는 label+sub 2줄
            const SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PSkeleton.line(width: 28, height: 12),
                  SizedBox(height: 2),
                  PSkeleton.line(width: 40, height: 9),
                ],
              ),
            ),
            for (var c = 0; c < _heatCols.length; c++)
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: AspectRatio(aspectRatio: 1, child: PSkeleton()),
                ),
              ),
          ],
        );
    return Column(
      children: [
        // 헤더 행 — 56 코너 + 7 요일 라벨
        Row(
          children: [
            const SizedBox(width: 56),
            for (var c = 0; c < _heatCols.length; c++)
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Center(child: PSkeleton.line(width: 12, height: 12)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < _heatRows.length; r++) ...[
          cellRow(),
          if (r < _heatRows.length - 1) const SizedBox(height: 4),
        ],
        const SizedBox(height: 14),
        // 범례 행
        Row(
          children: const [
            PSkeleton.line(width: 130, height: 14),
            Spacer(),
            PSkeleton.line(width: 70, height: 12),
          ],
        ),
      ],
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton({required this.height, this.showLegend = true});
  final double height;

  /// 추이 카드는 차트 아래 2개 _LegendChip 범례가 있음(showLegend). 순저축
  /// 카드는 범례가 헤더 trailing 에 있어 차트 영역만(showLegend:false).
  final bool showLegend;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PSkeleton(height: height),
        if (showLegend) ...[
          const SizedBox(height: 12),
          Row(
            children: const [
              // _LegendChip(swatch 10 brXs + 6 + label) ×2, gap 16
              _LegendChipSkeleton(),
              SizedBox(width: 16),
              _LegendChipSkeleton(),
            ],
          ),
        ],
      ],
    );
  }
}

/// _LegendChip placeholder — swatch(10·brXs) + 6 + label line.
class _LegendChipSkeleton extends StatelessWidget {
  const _LegendChipSkeleton();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        PSkeleton(width: 10, height: 10, borderRadius: PRadius.brXs),
        SizedBox(width: 6),
        PSkeleton.line(width: 28, height: 12),
      ],
    );
  }
}

// ─── DONUT CARD ────────────────────────────────────────────

/// Donut 차트 카테고리 색 — `cat.color` 우선, 없으면 [PorestChartPalette] fallback.
/// chart base hex 면 라이트/다크 variant 자동 swap (resolveChartColor).
Color _donutColor(BuildContext context, int idx, [String? rawColor]) {
  final fallback = PorestChartPalette.category(context, idx);
  return cp.resolveChartColor(context, rawColor, fallback: fallback);
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
    final raw =
        widget.rangeAsync.value?.categoryBreakdown ??
        const <CategoryBreakdown>[];
    return [
      for (final c in raw)
        if (c.expenseType == 'EXPENSE') c,
    ];
  }

  List<_DonutRow> _aggregateParent(List<CategoryBreakdown> bd) {
    final l = AppLocalizations.of(context);
    final map = <int, _DonutRow>{};
    final cats = (widget.categoriesAsync.value ?? const []).cast<dynamic>();
    for (final c in bd) {
      final groupId = c.parentCategoryRowId ?? c.categoryRowId;
      if (groupId == null) continue;
      final groupName = c.parentCategoryName ?? c.categoryName ?? l.statsUnassigned;
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

  List<_DonutRow> _aggregateChildren(List<CategoryBreakdown> bd, int parentId) {
    final l = AppLocalizations.of(context);
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
          name: c.categoryName ?? l.statsUnassigned,
          amount: 0,
          icon: cat?.icon as String?,
          color: cat?.color as String?,
        );
        map[id] = row;
      }
      row.amount += c.totalAmount;
    }
    return map.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final t = context.tokens;
    final l = AppLocalizations.of(context);
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
    final centerPeriodLbl = s._segMode == _SegMode.custom
        ? l.statsCustomPeriod
        : s._periodLabel;
    final centerLbl = isDrilled && activeParent != null
        ? l.statsCategoryDetail(activeParent.name)
        : l.statsPeriodSpending(centerPeriodLbl);

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
                        child: Text(
                          l.statsSpendingByCategory,
                          style: TextStyle(
                            fontSize: PFontSize.bodyLg,
                            color: t.fgSecondary,
                            fontWeight: PFontWeight.medium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '›',
                        style: PTypo.body.copyWith(color: t.fgTertiary),
                      ),
                      const SizedBox(width: 4),
                      Flexible(child: _CardTitle(activeParent?.name ?? '')),
                    ],
                  )
                : _CardTitle(l.statsSpendingByCategory),
            trailing: _PeriodTrigger(state: s),
          ),
          const SizedBox(height: PSpace.x12),
          if (loading)
            const _DonutCardSkeleton()
          else if (view.isEmpty)
            _EmptyBox(text: l.statsNoCategoryData)
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
                            color: _donutColor(context, i, view[i].color),
                            radius: 28,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerLbl,
                        style: PTypo.caption.copyWith(color: t.fgSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        krwSigned(total, widget.masked, unit: true),
                        style: PTypo.h4.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.bold,
                        ),
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
                    ? () => setState(() => _activeParentId = view[i].rowId)
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
                color: _donutColor(context, index, row.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.medium,
                ),
              ),
            ),
            Text(
              '${pct.toStringAsFixed(1)}%',
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
            const SizedBox(width: 12),
            Text(
              krwMasked(row.amount, masked, mask: '••••'),
              style: PTypo.bodySm.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
            if (clickable) ...[
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, size: 13, color: t.fgTertiary),
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
    final l = AppLocalizations.of(context);
    final list = async.value ?? const <MerchantSummary>[];
    final sorted = (List.of(list)
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)));
    final top = sorted.take(5).toList();
    final maxAmt = top.isEmpty ? 1 : top.first.totalAmount;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: _CardTitle(l.statsTopMerchantsTitle)),
          if (async.isLoading && top.isEmpty)
            const _MerchantListSkeleton()
          else if (top.isEmpty)
            _EmptyBox(text: l.statsNoMerchantData)
          else
            for (var i = 0; i < top.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.center,
                      style: PTypo.caption.copyWith(
                        color: i < 3 ? t.fgIncome : t.fgTertiary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
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
                                    child: Text(
                                      top[i].merchant ?? l.statsNoName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: PTypo.bodySm.copyWith(
                                        color: t.fgPrimary,
                                        fontWeight: PFontWeight.semi,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l.expTimesCount(top[i].count),
                                    style: PTypo.caption.copyWith(
                                      color: t.fgTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 고정폭 우측 정렬 — 모든 행 amount 가 같은 X 에서 끝나도록
                            Text(
                              krwSigned(top[i].totalAmount, masked, unit: true),
                              textAlign: TextAlign.right,
                              style: PTypo.bodySm.copyWith(
                                color: t.fgPrimary,
                                fontWeight: PFontWeight.bold,
                              ),
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
  const _HeatmapRow(this.sub, this.hours);
  final String sub;
  final List<int> hours;
}

const _heatRows = [
  _HeatmapRow('06–10시', [6, 7, 8, 9]),
  _HeatmapRow('10–14시', [10, 11, 12, 13]),
  _HeatmapRow('14–18시', [14, 15, 16, 17]),
  _HeatmapRow('18–22시', [18, 19, 20, 21]),
  _HeatmapRow('22–02시', [22, 23, 0, 1]),
  _HeatmapRow('02–06시', [2, 3, 4, 5]),
];

/// 히트맵 행(시간대) 라벨 — const 데이터라 렌더 시점에 인덱스로 로컬라이즈.
String _heatRowLabel(AppLocalizations l, int i) => switch (i) {
  0 => l.statsTimeMorning,
  1 => l.statsTimeLunch,
  2 => l.statsTimeAfternoon,
  3 => l.statsTimeEvening,
  4 => l.statsTimeLateNight,
  _ => l.statsTimeDawn,
};

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
  const _HeatmapCard({required this.async, required this.masked});
  final AsyncValue<List<HeatmapCell>> async;
  final bool masked;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final cells = async.value ?? const <HeatmapCell>[];
    // matrix [row][col]
    final matrix = List.generate(
      _heatRows.length,
      (_) => List.filled(_heatCols.length, 0),
    );
    for (final c in cells) {
      final colIdx = _heatCols.indexWhere((col) => col.$2 == c.dayOfWeek);
      final rowIdx = _heatRows.indexWhere((row) => row.hours.contains(c.hour));
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
          _CardHeader(title: _CardTitle(l.statsPatternTitle)),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              l.statsPatternDesc,
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
          ),
          if (async.isLoading && cells.isEmpty)
            const _HeatmapSkeleton()
          else if (total == 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: PRadius.brLg,
              ),
              alignment: Alignment.center,
              child: Text(
                l.statsTooFewTx,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
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
                      child: Text(
                        weekdayLabels(mondayFirst: true)[_heatCols.indexOf(col)],
                        textAlign: TextAlign.center,
                        style: PTypo.caption.copyWith(
                          color: t.fgTertiary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
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
                        Text(
                          _heatRowLabel(l, r),
                          style: PTypo.caption.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                        Text(
                          _heatRows[r].sub,
                          style: PTypo.micro.copyWith(
                            color: t.fgTertiary,
                            fontSize: PFontSize.micro,
                          ),
                        ),
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
                              // web 히트맵 셀 radius-sm 정합 (md 는 과하게 둥글었음)
                              borderRadius: PRadius.brSm,
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(3),
                            // 셀 폭 초과 시 폰트 자동 축소(한 줄 유지) — 가계부 캘린더형 FittedBox 정합
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                // 금액 숨김 — web MaskAmount(value>0?••:—) 정합
                                masked
                                    ? (matrix[r][c] > 0 ? '••' : '—')
                                    : _shortAmount(matrix[r][c]),
                                maxLines: 1,
                                style: PTypo.micro.copyWith(
                                  color: fgFor(_heatBucket(matrix[r][c], maxV)),
                                  fontWeight: PFontWeight.bold,
                                  fontSize: PFontSize.micro,
                                ),
                              ),
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
                Text(l.statsLegendLow,
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
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
                Text(l.statsLegendHigh,
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
                const Spacer(),
                Text(
                  masked
                      ? '${l.statsTotalPrefix} ••••••'
                      : '${l.statsTotalPrefix} ${krwSigned(total, false, unit: true)}',
                  style: PTypo.caption.copyWith(
                    color: t.fgSecondary,
                    fontWeight: PFontWeight.semi,
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

String _shortAmount(int v) {
  if (v <= 0) return '—';
  // en: 로케일 compact(52M·120K). ko: 천/만 축약(기존 유지).
  if (localeIsEn()) return formatChartAxis(v.toDouble());
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
    required this.expensesAsync,
    required this.prevRangeAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<RangeSummary> rangeAsync;
  final AsyncValue<List<dynamic>> categoriesAsync;
  final AsyncValue<List<MerchantSummary>> merchantAsync;
  final AsyncValue<List<Expense>> expensesAsync;
  final AsyncValue<RangeSummary> prevRangeAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    // 카테고리 Top — 부모 카테고리 단위 합계
    final bd =
        rangeAsync.value?.categoryBreakdown ?? const <CategoryBreakdown>[];
    final groupTotals = <int, ({int id, String name, int amount})>{};
    for (final c in bd) {
      if (c.expenseType != 'EXPENSE') continue;
      final id = c.parentCategoryRowId ?? c.categoryRowId;
      if (id == null) continue;
      final name = c.parentCategoryName ?? c.categoryName ?? l.statsUnassigned;
      final cur = groupTotals[id];
      groupTotals[id] = cur == null
          ? (id: id, name: name, amount: c.totalAmount)
          : (id: id, name: cur.name, amount: cur.amount + c.totalAmount);
    }
    final topCat = groupTotals.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final topCategory = topCat.firstOrNull;

    // 카테고리 아이콘/색 룩업 — 도넛(_aggregateParent)과 동일 방식
    final cats = (categoriesAsync.value ?? const []).cast<dynamic>();
    final topCatMeta = topCategory == null
        ? null
        : cats.where((x) => x.rowId == topCategory.id).firstOrNull;
    final catFg = cp.resolveChartColor(
      context,
      topCatMeta?.color as String?,
      fallback: t.fgBrand,
    );
    final catIcon =
        lucideByName(topCatMeta?.icon as String?, fallback: LucideIcons.tag);

    // 가맹점 Top
    final merchants =
        (merchantAsync.value ?? const <MerchantSummary>[]).toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final topMerchant = merchants.firstOrNull;

    // 가맹점 대표 카테고리 아이콘 — 원시 거래에서 해당 가맹점의
    // 지배적(최다 지출) 카테고리를 역산. 못 찾으면 상점 아이콘 fallback.
    IconData merchantIcon = LucideIcons.store;
    Color merchantFg = t.fgBrand;
    final mName = topMerchant?.merchant;
    if (mName != null) {
      final exps = expensesAsync.value ?? const <Expense>[];
      final catTotals = <int, ({int amount, String? icon, String? color})>{};
      for (final e in exps) {
        if (e.merchant != mName || e.expenseType != 'EXPENSE') continue;
        final cid = e.categoryRowId;
        if (cid == null) continue;
        final cur = catTotals[cid];
        catTotals[cid] = cur == null
            ? (amount: e.amount, icon: e.categoryIcon, color: e.categoryColor)
            : (amount: cur.amount + e.amount, icon: cur.icon, color: cur.color);
      }
      ({int amount, String? icon, String? color})? best;
      for (final v in catTotals.values) {
        if (best == null || v.amount > best.amount) best = v;
      }
      if (best != null) {
        merchantFg = cp.resolveChartColor(
          context,
          best.color,
          fallback: t.fgBrand,
        );
        merchantIcon = lucideByName(best.icon, fallback: LucideIcons.store);
      }
    }

    // 평균 계산 — 단일 월 또는 사용자 지정 기간이면 일평균, 그 외엔 월평균
    final periodTotal = rangeAsync.value?.totalExpense ?? 0;
    final monthlyBuckets =
        rangeAsync.value?.monthlyBuckets ?? const <RangeMonthlyBucket>[];
    final rangeDays = s._to.difference(s._from).inDays + 1;
    final divisor = s._useDailyAvg
        ? rangeDays
        : monthlyBuckets.length.clamp(1, 9999);
    final avgValue = divisor > 0 ? periodTotal ~/ divisor : 0;
    final avgLabel = s._avgLabel;

    // 하루 평균 부제 — 월 모드는 전월 대비(증가=지출색 / 감소=수입색, _CompareTab 동일
    // 컨벤션), 그 외 기간은 합계 표시
    String avgSub = '';
    Widget? avgSubWidget;
    if (s._segMode != _SegMode.month) {
      avgSub = masked
          ? '${l.statsDaysTotal(rangeDays)} ${krwMasked(periodTotal, masked)}'
          : '${l.statsDaysTotal(rangeDays)} ${krwSigned(periodTotal, masked, unit: true)}';
    } else {
      final prevTotal = prevRangeAsync.value?.totalExpense ?? 0;
      if (prevTotal > 0) {
        final diff = periodTotal - prevTotal;
        final up = diff >= 0;
        final pct = ((diff.abs() / prevTotal) * 100).toStringAsFixed(0);
        avgSubWidget = Text.rich(
          TextSpan(
            style: PTypo.caption.copyWith(color: t.fgTertiary),
            children: [
              TextSpan(text: '${l.statsMomMonth} '),
              TextSpan(
                text: '${up ? '↑' : '↓'}$pct%',
                style: TextStyle(
                  color: up ? t.fgExpense : t.fgIncome,
                  fontWeight: PFontWeight.semi,
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      } else {
        avgSub =
            prevRangeAsync.isLoading ? l.statsMomCalculating : l.statsMomUnavailable;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HighlightCard(
          label: l.statsTopCategory,
          value: topCategory?.name ?? '—',
          sub: topCategory != null
              ? krwSigned(topCategory.amount, masked, unit: true)
              : l.statsNoDataShort,
          icon: catIcon,
          iconFg: catFg,
        ),
        const SizedBox(height: 10),
        _HighlightCard(
          label: l.statsTopMerchant,
          value: topMerchant?.merchant ?? '—',
          sub: topMerchant != null
              ? (masked
                    ? '${l.expTimesCount(topMerchant.count)} · ${krwMasked(topMerchant.totalAmount, masked)}'
                    : '${l.expTimesCount(topMerchant.count)} · ${krwSigned(topMerchant.totalAmount, masked, unit: true)}')
              : l.statsNoDataShort,
          // 가맹점이 속한 대표 카테고리 아이콘(역산), 없으면 상점 아이콘
          icon: merchantIcon,
          iconFg: merchantFg,
        ),
        const SizedBox(height: 10),
        _HighlightCard(
          label: avgLabel,
          value: krwSigned(avgValue, masked, unit: true),
          sub: avgSub,
          subWidget: avgSubWidget,
          valueIsAmount: true,
          icon: LucideIcons.calendarDays,
          iconFg: t.fgBrand,
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.label,
    required this.value,
    this.sub,
    this.subWidget,
    required this.icon,
    required this.iconFg,
    this.valueIsAmount = false,
  });
  final String label;
  final String value;
  final String? sub;
  final Widget? subWidget;
  final IconData icon;
  final Color iconFg;
  final bool valueIsAmount;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: PTypo.caption.copyWith(
              color: t.fgTertiary,
              fontWeight: PFontWeight.medium,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cp.softBg(context, iconFg),
                  borderRadius: PRadius.tile(40),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconFg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.h4.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                        fontFamily: valueIsAmount ? 'monospace' : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    subWidget ??
                        Text(
                          sub ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
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

// ─── TREND TAB CARDS ───────────────────────────────────────

class _TrendPoint {
  const _TrendPoint({
    required this.label,
    required this.income,
    required this.expense,
  });
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
  final buckets =
      rangeAsync.value?.monthlyBuckets ?? const <RangeMonthlyBucket>[];
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
      byDate[key] = (income: 0, expense: 0, label: '${d.month}/${d.day}');
    }
    for (final e in exps) {
      final raw = e.expenseDate ?? '';
      if (raw.length < 10) continue;
      final key = raw.substring(0, 10);
      final cur = byDate[key];
      if (cur == null) continue;
      if (e.expenseType == 'INCOME') {
        byDate[key] = (
          income: cur.income + e.amount,
          expense: cur.expense,
          label: cur.label,
        );
      } else {
        byDate[key] = (
          income: cur.income,
          expense: cur.expense + e.amount,
          label: cur.label,
        );
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
  // en: 로케일 compact 축약(중앙 formatChartAxis en 경로와 동일). ko: 억/만(기존 유지).
  if (localeIsEn()) return formatChartAxis(v);
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

/// recharts 의 "nice number" 알고리즘 — [rawMax] 를 [ticks] 단계 깔끔한
/// step 으로 ceil. (max=step*(ticks-1)). Web (recharts YAxis) 자동 tick 과
/// 시각적으로 동일한 결과 (0/200/400/600/800 같은 균등 단계).
({double max, double step}) _niceCeil(double rawMax, {int ticks = 5}) {
  if (rawMax <= 0) return (max: 1.0, step: 1.0 / (ticks - 1));
  final roughStep = rawMax / (ticks - 1);
  final magnitude = math
      .pow(10, (math.log(roughStep) / math.ln10).floor())
      .toDouble();
  final mantissa = roughStep / magnitude;
  final niceMantissa = mantissa <= 1
      ? 1.0
      : mantissa <= 2
      ? 2.0
      : mantissa <= 2.5
      ? 2.5
      : mantissa <= 5
      ? 5.0
      : 10.0;
  final step = niceMantissa * magnitude;
  return (max: step * (ticks - 1), step: step);
}

/// fl_chart 의 x 라벨 스텝 필터 — interval 만으로는 BarChart 에서 잘 안 먹힘.
/// 모바일 chart area (~300 px) 폭 대비 라벨 'YYYY.MM' (~70 px) — 4 라벨이
/// 적정 (~280 px). threshold 를 12 → 4 로 낮춰 5~8 구간은 양 끝 + 가운데 1개
/// (총 3 라벨), 9+ 구간은 기존 thinning 알고리즘 (약 4~5 라벨) 적용.
bool _showXLabel(int i, int n) {
  if (n <= 4) return true; // 분기(3) / 짧은 사용자기간 — 전부 표시
  if (i == 0 || i == n - 1) return true; // 양 끝 항상
  if (n <= 8) return i == (n - 1) ~/ 2; // 5~8: 가운데 1개 → 총 3 라벨
  final step = (n / 6).ceil();
  return i % step == 0 && (n - 1 - i) >= (step ~/ 2);
}

/// fl_chart 툴팁 한 줄 ─ 색 스왓치(유니코드) + 레이블 + 금액.
// 차트 커스텀 오버레이 툴팁은 shared/widgets/p_chart_tooltip.dart 로 공용화
// (PChartTooltipBox / PChartTooltipRowData — 자산 상세·순자산 차트와 공유).

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
  Offset? _touchPos;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final data = _computeTrendData(
      widget.state,
      widget.rangeAsync,
      widget.monthExpAsync,
    );
    final loading =
        widget.rangeAsync.isLoading || widget.monthExpAsync.isLoading;

    // 수입 ↔ 지출 스케일 차이가 크면 한 축에 그릴 때 작은 시리즈가 묻힘.
    // → 지출을 (incomeNiceMax / expenseNiceMax) 로 스케일링해 시각적으론 같은 높이 범위를 차지하게.
    //   좌축은 수입(raw), 우축 라벨은 표시값을 1/scale 로 되돌려 지출 실제값.
    // recharts (Web YAxis) 와 동일한 nice-number ceil 로 5-tick 균등 간격 보장.
    final incomeMax = data.fold<int>(0, (m, p) => p.income > m ? p.income : m);
    final expenseMax = data.fold<int>(
      0,
      (m, p) => p.expense > m ? p.expense : m,
    );
    final useDualAxis = incomeMax > 0 && expenseMax > 0;
    final niceIncome = _niceCeil(incomeMax.toDouble());
    final niceExpense = _niceCeil(expenseMax.toDouble());
    final scale = useDualAxis ? niceIncome.max / niceExpense.max : 1.0;
    // single-axis 일 땐 income 만 또는 expense 만 있는 케이스 — 있는 쪽의 nice 적용.
    final axisMax = useDualAxis || incomeMax > 0
        ? niceIncome.max
        : niceExpense.max;
    final axisStep = useDualAxis || incomeMax > 0
        ? niceIncome.step
        : niceExpense.step;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: _CardTitle(l.statsIncomeExpenseTrend),
            trailing: _PeriodTrigger(state: widget.state),
          ),
          if (loading && data.isEmpty)
            const _ChartSkeleton(height: 200)
          else if (data.isEmpty ||
              data.every((p) => p.income == 0 && p.expense == 0))
            _EmptyBox(text: l.statsNoTrendData)
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
                      minY: 0,
                      maxY: axisMax,
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
                          final pos = event.localPosition;
                          if (i >= 0 &&
                              i < data.length &&
                              (i != _touchedIdx || pos != _touchPos)) {
                            setState(() {
                              _touchedIdx = i;
                              if (pos != null) _touchPos = pos;
                            });
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
                              List<LineTooltipItem?>.filled(
                                touched.length,
                                null,
                              ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: axisStep,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: t.borderSubtle,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        // 좌축: 수입 (raw) — interval=axisStep 로 0/step/2step/3step/4step=max 5 ticks 균등.
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            interval: axisStep,
                            getTitlesWidget: (v, _) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                _fmtTick(v),
                                style: PTypo.micro.copyWith(
                                  color: useDualAxis ? t.statusInfoFg : t.fgTertiary,
                                  fontSize: PFontSize.micro,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 우축: 지출 — 좌축과 같은 5 tick 자리에 표시값 v/scale 로 원래 지출값 복원
                        // (scale = niceIncome.max / niceExpense.max → v/scale 도 niceExpense.step 단위 균등).
                        rightTitles: useDualAxis
                            ? AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  interval: axisStep,
                                  getTitlesWidget: (v, _) => Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(
                                      _fmtTick(v / scale),
                                      style: PTypo.micro.copyWith(
                                        color: t.fgExpense,
                                        fontSize: PFontSize.micro,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: ((data.length - 1) / 5)
                                .clamp(1, 1000)
                                .toDouble(),
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
                                child: Text(
                                  data[i].label,
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
                      lineBarsData: [
                        // 수입
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < data.length; i++)
                              FlSpot(i.toDouble(), data[i].income.toDouble()),
                          ],
                          isCurved: true,
                          color: t.statusInfoFg,
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (s, _, _, _) => FlDotCirclePainter(
                              radius: 2.5,
                              color: t.statusInfoFg,
                              strokeWidth: 2,
                              strokeColor: t.bgSurface,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: t.statusInfoFg.withValues(alpha: 0.18),
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
                              strokeColor: t.bgSurface,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: t.fgExpense.withValues(alpha: 0.16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_touchedIdx != null &&
                      _touchedIdx! < data.length &&
                      _touchPos != null)
                    PChartTooltipLayer(
                      anchor: _touchPos!,
                      child: PChartTooltipBox(
                        title: data[_touchedIdx!].label,
                        rows: [
                          PChartTooltipRowData(
                            color: t.statusInfoFg,
                            label: l.expTypeIncome,
                            amount: krwSigned(data[_touchedIdx!].income, false, unit: true),
                          ),
                          PChartTooltipRowData(
                            color: t.fgExpense,
                            label: l.expTypeExpense,
                            amount: krwSigned(data[_touchedIdx!].expense, false, unit: true),
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
                _LegendChip(color: t.statusInfoFg, label: l.expTypeIncome),
                const SizedBox(width: 16),
                _LegendChip(color: t.fgExpense, label: l.expTypeExpense),
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
          decoration: BoxDecoration(color: color, borderRadius: PRadius.brXs),
        ),
        const SizedBox(width: 6),
        Text(label, style: PTypo.caption.copyWith(color: t.fgSecondary)),
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
    final l = AppLocalizations.of(context);
    final buckets =
        rangeAsync.value?.monthlyBuckets ?? const <RangeMonthlyBucket>[];
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

    // web TrendStats 정합 — 고정 비율 GridView 대신 content 높이 2×2, gap 12
    final tiles = [
      _StatCard(
        label: isSingle ? l.expTypeIncome : l.statsAvgIncome,
        value: krwSigned(avgIn, masked, unit: true),
      ),
      _StatCard(
        label: isSingle ? l.expTypeExpense : l.statsAvgExpense,
        value: krwSigned(avgOut, masked, unit: true),
      ),
      _StatCard(
        label: isSingle ? l.statsNetSavings : l.statsAvgSavings,
        value: krwSigned(avgSave, masked, unit: true),
      ),
      _StatCard(label: l.statsSavingsRate, value: saveRate),
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 12),
            Expanded(child: tiles[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: tiles[2]),
            const SizedBox(width: 12),
            Expanded(child: tiles[3]),
          ],
        ),
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
    // web stat 타일 정합 — padding 16 / 라벨 badge(11)·500·gap6 / 값 16·bold
    return _Card(
      padding: const EdgeInsets.all(PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: PTypo.micro.copyWith(
              color: t.fgTertiary,
              fontWeight: PFontWeight.medium,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PTypo.bodyLg.copyWith(
              color: t.fgPrimary,
              fontWeight: PFontWeight.bold,
              letterSpacing: -0.35,
            ),
          ),
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
  Offset? _touchPos;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final loading =
        widget.rangeAsync.isLoading || widget.monthExpAsync.isLoading;
    final data = _computeTrendData(
      widget.state,
      widget.rangeAsync,
      widget.monthExpAsync,
    );
    final useDaily = widget.state.useDailyTrend(
      widget.rangeAsync.value?.monthlyBuckets.length ?? 0,
    );
    // Y축: 웹 정합 0기준 nice 눈금 (순저축은 음수 가능 → 0 아래로도 nice 확장).
    final savingsVals = data.map((p) => p.savings.toDouble()).toList();
    final savingsAxis = savingsVals.isEmpty
        ? (min: 0.0, max: 1.0, interval: 1.0)
        : niceAxis(savingsVals.reduce(math.min), savingsVals.reduce(math.max));
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: _CardTitle(useDaily ? l.statsDailyNetSavings : l.statsMonthlyNetSavings),
            trailing: Text(
              l.statsIncomeMinusExpense,
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
          ),
          if (loading && data.isEmpty)
            const _ChartSkeleton(height: 180, showLegend: false)
          else if (data.isEmpty)
            _EmptyBox(text: l.statsNoData)
          else
            SizedBox(
              height: 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      minY: savingsAxis.min,
                      maxY: savingsAxis.max,
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
                              i < data.length &&
                              (i != _touchedIdx || pos != _touchPos)) {
                            setState(() {
                              _touchedIdx = i;
                              if (pos != null) _touchPos = pos;
                            });
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
                        horizontalInterval: savingsAxis.interval,
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
                            interval: savingsAxis.interval,
                            getTitlesWidget: (v, _) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                _fmtTick(v),
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
                            interval: ((data.length - 1) / 5)
                                .clamp(1, 1000)
                                .toDouble(),
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
                                child: Text(
                                  data[i].label,
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
                        for (var i = 0; i < data.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: data[i].savings.toDouble(),
                                color: data[i].savings >= 0
                                    ? t.statusInfoFg
                                    : t.fgExpense,
                                width: data.length > 20 ? 4 : 12,
                                borderRadius: PRadius.brXs,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (_touchedIdx != null &&
                      _touchedIdx! < data.length &&
                      _touchPos != null)
                    PChartTooltipLayer(
                      anchor: _touchPos!,
                      child: Builder(
                        builder: (_) {
                          final p = data[_touchedIdx!];
                          final v = p.savings;
                          final sign = v >= 0 ? '+' : '−';
                          return PChartTooltipBox(
                            title: p.label,
                            rows: [
                              PChartTooltipRowData(
                                color: v >= 0 ? t.statusInfoFg : t.fgExpense,
                                label: l.statsNetSavings,
                                amount: krwSigned(v.abs(), false, sign: sign, unit: true),
                                amountColor: v >= 0 ? t.statusInfoFg : t.fgExpense,
                              ),
                            ],
                          );
                        },
                      ),
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
    final l = AppLocalizations.of(context);

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
          label: l.statsPeriodSpending(s._periodNow),
          amount: krwSigned(now, masked, unit: true),
        ),
        const SizedBox(height: 10),
        _CompareCard(
          label: l.statsPeriodSpending(s._periodPrev),
          amount: krwSigned(prev, masked, unit: true),
          muted: true,
        ),
        const SizedBox(height: 10),
        _Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s._momLabel,
                style: PTypo.caption.copyWith(
                  color: t.fgTertiary,
                  fontWeight: PFontWeight.medium,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                prev > 0 ? '${up ? '+' : '−'}$pct' : '—',
                style: PTypo.h3.copyWith(
                  color: prev <= 0
                      ? t.fgPrimary
                      : (up ? t.fgExpense : t.fgIncome),
                  fontWeight: PFontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prev > 0
                    ? krwSigned(diff.abs(), masked, sign: up ? '+' : '−', unit: true)
                    : l.statsNoDataFor(s._momPrevLabel),
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 요일별 지출 비교 — 이번 달(파랑) vs 지난 달(회색 track) grouped bar.
/// design StatsScreen `CompareWeekday` 미러: 월~일, 토·일 라벨 빨강, 하단 인사이트.
class _CompareWeekdayCard extends StatelessWidget {
  const _CompareWeekdayCard({
    required this.nowExpAsync,
    required this.prevExpAsync,
    required this.masked,
  });
  final AsyncValue<List<Expense>> nowExpAsync;
  final AsyncValue<List<Expense>> prevExpAsync;
  final bool masked;

  /// EXPENSE 만 요일별 합산. index 0=월 .. 6=일 (DateTime.weekday 1=월~7=일).
  static List<int> _byWeekday(List<Expense> exps) {
    final res = List<int>.filled(7, 0);
    for (final e in exps) {
      if (e.expenseType != 'EXPENSE') continue;
      final d = DateTime.tryParse(e.expenseDate ?? '');
      if (d == null) continue;
      res[d.weekday - 1] += e.amount;
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final now = _byWeekday(nowExpAsync.value ?? const []);
    final prev = _byWeekday(prevExpAsync.value ?? const []);
    final labels = weekdayLabels(mondayFirst: true);
    final maxV = [
      ...now,
      ...prev,
    ].fold<int>(1, (m, v) => v > m ? v : m);
    const chartH = 120.0;

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
      insight = l.statsWeekdayInsightDown(
        labels[dropIdx],
        krwSigned(bestDrop, masked, unit: true),
      );
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
          ? l.statsWeekdayInsightUp(
              labels[riseIdx],
              krwSigned(bestRise, masked, unit: true),
            )
          : l.statsWeekdayInsightSame;
    }

    Widget bar(int v, Color color, {Color? border}) => Container(
      width: 10,
      height: ((v / maxV) * chartH).clamp(3.0, chartH),
      decoration: BoxDecoration(
        color: color,
        border: border == null ? null : Border.all(color: border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _CardTitle(l.statsWeekdayTitle)),
              _WeekdayLegend(color: t.bgBrand, label: l.statsThisMonthShort),
              const SizedBox(width: 12),
              _WeekdayLegend(
                color: t.bgSunken,
                label: l.statsLastMonthShort,
                border: t.borderDefault,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: chartH + 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: chartH,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              bar(now[i], t.bgBrand),
                              const SizedBox(width: 3),
                              bar(prev[i], t.bgSunken, border: t.borderDefault),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[i],
                          style: PTypo.micro.copyWith(
                            color: i >= 5 ? t.fgExpense : t.fgTertiary,
                            fontWeight: PFontWeight.semi,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.sparkles, size: 12, color: t.bgBrand),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    insight,
                    style: PTypo.caption.copyWith(
                      color: t.fgSecondary,
                      fontWeight: PFontWeight.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLegend extends StatelessWidget {
  const _WeekdayLegend({required this.color, required this.label, this.border});
  final Color color;
  final String label;
  final Color? border;

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
            color: color,
            border: border == null ? null : Border.all(color: border!),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: PTypo.micro.copyWith(color: t.fgTertiary),
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
          Text(
            label,
            style: PTypo.caption.copyWith(
              color: t.fgTertiary,
              fontWeight: PFontWeight.medium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: PTypo.h3.copyWith(
              color: muted ? t.fgSecondary : t.fgPrimary,
              fontWeight: PFontWeight.bold,
            ),
          ),
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
    final s = state;
    final l = AppLocalizations.of(context);
    final loading = rangeAsync.isLoading || prevRangeAsync.isLoading;

    final cats = categoriesAsync.value ?? const <dynamic>[];
    dynamic catBy(int id) => cats
        .cast<dynamic>()
        .where((c) => c.rowId == id)
        .cast<dynamic>()
        .firstOrNull;

    final byId =
        <
          int,
          ({String name, String? icon, String? color, int now, int prev})
        >{};
    void addBd(String which, List<CategoryBreakdown> list) {
      for (final c in list) {
        if (c.expenseType != 'EXPENSE') continue;
        final id = c.parentCategoryRowId ?? c.categoryRowId;
        if (id == null) continue;
        final cur = byId[id];
        final name = c.parentCategoryName ?? c.categoryName ?? l.statsUnassigned;
        final cat = catBy(id);
        var rec =
            cur ??
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

    addBd(
      'now',
      rangeAsync.value?.categoryBreakdown ?? const <CategoryBreakdown>[],
    );
    addBd(
      'prev',
      prevRangeAsync.value?.categoryBreakdown ?? const <CategoryBreakdown>[],
    );

    final rows = byId.entries.toList()
      ..sort((a, b) {
        final c = b.value.now.compareTo(a.value.now);
        return c != 0 ? c : b.value.prev.compareTo(a.value.prev);
      });
    final top = rows.take(10).toList();
    final maxAmt = top.isEmpty
        ? 1
        : top
              .map(
                (e) => e.value.now > e.value.prev ? e.value.now : e.value.prev,
              )
              .reduce((a, b) => a > b ? a : b)
              .clamp(1, 1 << 62);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: _CardTitle(l.statsCategoryByMom(s._momLabel)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendChip(
                    color: cp.resolveChartColor(context, '#2c70bf'),
                    label: s._periodNow),
                const SizedBox(width: 10),
                _LegendChip(
                    color: const Color(0xFFABC8EE), label: s._periodPrev),
              ],
            ),
          ),
          if (loading && top.isEmpty)
            const _CompareListSkeleton()
          else if (top.isEmpty)
            _EmptyBox(text: l.statsNoCompareData)
          else
            for (var i = 0; i < top.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _CompareRow(row: top[i].value, maxAmt: maxAmt, masked: masked),
            ],
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.row,
    required this.maxAmt,
    required this.masked,
  });
  final ({String name, String? icon, String? color, int now, int prev}) row;
  final int maxAmt;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = cp.resolveChartColor(context, row.color, fallback: t.fgBrand);
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
                borderRadius: PRadius.tile(32),
              ),
              alignment: Alignment.center,
              child: Icon(iconData, size: 16, color: fg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
            ),
            Text(
              krwSigned(row.now, masked, unit: true),
              style: PTypo.bodySm.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
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
                  fontWeight: PFontWeight.bold,
                ),
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
                color: cp.resolveChartColor(context, '#2c70bf'),
              ),
              const SizedBox(height: 4),
              _RoundedBar(
                value: row.prev / maxAmt,
                height: 6,
                color: const Color(0xFFABC8EE),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
