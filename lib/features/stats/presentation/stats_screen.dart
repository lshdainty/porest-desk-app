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
import 'package:porest_desk_app/features/expense/domain/expense_aggregates.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';
import 'package:porest_desk_app/shared/widgets/p_tab_bar.dart';

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
          // design .m-chip-tabs + .tg--pill — 컴팩트 pill toggle(선택=bg-brand 채움,
          // 가로스크롤). 예전 underline TabBar → toggle 스타일로 변경(디자인 최신본).
          Container(
            width: double.infinity,
            color: t.bgSurface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final e in [
                    (0, l.expCategory),
                    (1, l.statsTabTrend),
                    (2, l.statsTabCompare),
                  ]) ...[
                    _StatsChipTab(
                      label: e.$2,
                      active: _tabIndex == e.$1,
                      onTap: () => setState(() => _tabIndex = e.$1),
                    ),
                    if (e.$1 < 2) const SizedBox(width: 4),
                  ],
                ],
              ),
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
        // 카드 다이어트 — design StatsScreen: padding 24/16/24/24 (LTRB) + 섹션 gap 32.
        padding: EdgeInsets.fromLTRB(
          PSpace.x24,
          PSpace.x16,
          PSpace.x24,
          // 플로팅 탭바 보상
          pTabBarBottomInset(context),
        ),
        children: [
          _DonutCard(
            state: state,
            rangeAsync: rangeAsync,
            categoriesAsync: categoriesAsync,
            masked: ref.watch(hideCardProvider('stats.category')),
          ),
          const SizedBox(height: PSpace.x32),
          _TopMerchantsCard(async: merchantAsync, masked: ref.watch(hideCardProvider('stats.category'))),
          const SizedBox(height: PSpace.x32),
          _HeatmapCard(async: heatmapAsync, masked: ref.watch(hideCardProvider('stats.category'))),
          const SizedBox(height: PSpace.x32),
          _HighlightsGrid(
            state: state,
            rangeAsync: rangeAsync,
            categoriesAsync: categoriesAsync,
            merchantAsync: merchantAsync,
            expensesAsync: expensesAsync,
            prevRangeAsync: prevRangeAsync,
            masked: ref.watch(hideCardProvider('stats.category')),
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
    final rangeAsync = ref.watch(rangeSummaryProvider(state._range));
    final monthExpAsync = ref.watch(rangeExpensesProvider(state._range));
    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(rangeSummaryProvider(state._range));
        ref.invalidate(rangeExpensesProvider(state._range));
      },
      child: ListView(
        // 카드 다이어트 — design StatsScreen: padding 24/16/24/24 (LTRB) + 섹션 gap 32.
        padding: EdgeInsets.fromLTRB(
          PSpace.x24,
          PSpace.x16,
          PSpace.x24,
          // 플로팅 탭바 보상
          pTabBarBottomInset(context),
        ),
        children: [
          _TrendBigCard(
            state: state,
            rangeAsync: rangeAsync,
            monthExpAsync: monthExpAsync,
          ),
          const SizedBox(height: PSpace.x32),
          _SavingsRateCard(
            state: state,
            rangeAsync: rangeAsync,
            masked: ref.watch(hideCardProvider('stats.trend')),
          ),
          const SizedBox(height: PSpace.x32),
          _SavingsBarsCard(
            state: state,
            rangeAsync: rangeAsync,
            monthExpAsync: monthExpAsync,
          ),
          // 카테고리 월별 추이는 여러 달(2+)일 때만 노출 — 단일 월은 카테고리 탭 도넛이
          // 담당(web showCatTrend: monthlyBuckets >= 2 정합).
          if (((rangeAsync.value?.monthlyBuckets.length) ?? 0) >= 2) ...[
            const SizedBox(height: PSpace.x32),
            _CatTrendCard(state: state, rangeAsync: rangeAsync),
          ],
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
        // 카드 다이어트 — design StatsScreen: padding 24/16/24/24 (LTRB) + 섹션 gap 32.
        padding: EdgeInsets.fromLTRB(
          PSpace.x24,
          PSpace.x16,
          PSpace.x24,
          // 플로팅 탭바 보상
          pTabBarBottomInset(context),
        ),
        children: [
          _CompareSummaryGrid(
            state: state,
            rangeAsync: rangeAsync,
            prevRangeAsync: prevRangeAsync,
            masked: ref.watch(hideCardProvider('stats.compare')),
          ),
          const SizedBox(height: PSpace.x32),
          _CompareMetricsCard(
            state: state,
            rangeAsync: rangeAsync,
            prevRangeAsync: prevRangeAsync,
            nowExpAsync: nowExpAsync,
            prevExpAsync: prevExpAsync,
            masked: ref.watch(hideCardProvider('stats.compare')),
          ),
          const SizedBox(height: PSpace.x32),
          _CompareCategoryCard(
            rangeAsync: rangeAsync,
            prevRangeAsync: prevRangeAsync,
            categoriesAsync: categoriesAsync,
            masked: ref.watch(hideCardProvider('stats.compare')),
          ),
          const SizedBox(height: PSpace.x32),
          _CompareWeekdayCard(
            state: state,
            nowExpAsync: nowExpAsync,
            prevExpAsync: prevExpAsync,
            masked: ref.watch(hideCardProvider('stats.compare')),
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
  // 웹 Section 정합 — 라벨·콘텐츠 모두 페이지 inset에서 시작(추가 inset 0).
  // 웹 contentInset(+8)을 쓰는 도넛 범례·비교 증감은 행 자체 padding이 흡수.
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
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
///
/// 라벨(헤더)은 page padding edge(0)에, content 는 _Card 의 inset(8) 안쪽에 —
/// 자산 `flat-group__head`(0) + `.acc-card`(inset) 리듬 정합. _Card 의 가로 inset(8=web spacing-sm)을
/// Transform(paint-only, 레이아웃·높이 영향 없음)으로 상쇄: title 좌 −8, trailing 우 +8.
class _CardHeader extends StatelessWidget {
  // 라벨·trailing 은 페이지 inset(24)에서 그대로 시작 — 웹 Section 헤더 정합.
  // (_Card 가 inset 8 을 갖던 시절의 Transform(-8/+8) edge-escape 는 제거.)
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

/// _CompareCategoryCard 의 _CompareDeltaRow placeholder — 행마다 icon tile(32) +
/// [이름 라인 + "지난→이번" 서브라인] + [증감액 + 증감률]. 세로 padding 12 +
/// 하단 구분선(마지막 제외). (증감 방식 전환 — 기존 2 stacked 막대 placeholder 폐기.)
class _CompareListSkeleton extends StatelessWidget {
  const _CompareListSkeleton();
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: i < 4
                ? BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.borderSubtle)),
                  )
                : null,
            child: Row(
              children: [
                PSkeleton(
                  width: 32,
                  height: 32,
                  borderRadius: PRadius.tile(32),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PSkeleton.line(width: 80, height: 14),
                      SizedBox(height: 4),
                      PSkeleton.line(width: 120, height: 11),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PSkeleton.line(width: 72, height: 13),
                    SizedBox(height: 4),
                    PSkeleton.line(width: 32, height: 10),
                  ],
                ),
              ],
            ),
          ),
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
                  PSkeleton.line(width: 28, height: 13),
                  SizedBox(height: 2),
                  PSkeleton.line(width: 40, height: 12),
                ],
              ),
            ),
            for (var c = 0; c < _heatCols.length; c++)
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(3),
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
                  padding: EdgeInsets.only(bottom: 4),
                  child: Center(child: PSkeleton.line(width: 12, height: 12)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < _heatRows.length; r++) cellRow(),
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

/// _SavingsRateCard 로딩 placeholder — 실제 렌더 정합: 도넛 링(108)+인사이트
/// 문구 / 구성 스택바(10·pill) / 평균 3행(dot 8 + 라벨 + 금액). 형제 추이 카드
/// (_ChartSkeleton)와 같은 리듬으로 로딩 점프 0.
class _SavingsRateSkeleton extends StatelessWidget {
  const _SavingsRateSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 도넛 링(108) + 인사이트 문구 placeholder.
        Row(
          children: [
            PSkeleton.circle(size: 108),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PSkeleton.line(height: 16),
                  SizedBox(height: 8),
                  PSkeleton.line(width: 150, height: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // 구성 스택바 placeholder (pill).
        const PSkeleton(height: 10, borderRadius: PRadius.brFull),
        const SizedBox(height: 14),
        // 평균 수입/지출/저축 3행 placeholder.
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              PSkeleton.circle(size: 8),
              const SizedBox(width: 8),
              const PSkeleton.line(width: 100, height: 13),
              const Spacer(),
              const PSkeleton.line(width: 64, height: 13),
            ],
          ),
        ],
      ],
    );
  }
}

/// _CatTrendCard 로딩 placeholder — 실제 렌더 정합: 범례 Wrap(차트 **위**,
/// top2/bottom4·spacing14/runSpacing6·TOP3 chip) + 차트(top16/bottom4·height132).
/// (공용 _ChartSkeleton 은 범례를 차트 아래 2개로 그려 이 카드와 어긋나 전용 분리.)
class _CatTrendSkeleton extends StatelessWidget {
  const _CatTrendSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 2, bottom: 4),
          child: Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendChipSkeleton(),
              _LegendChipSkeleton(),
              _LegendChipSkeleton(),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 16, bottom: 4),
          child: PSkeleton(height: 132),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            const SizedBox(width: 4),
            // 화살표는 하위 카테고리가 있을 때만 뜬다. 자리는 늘 잡아 둔다 —
            // 조건부로 넣으면 금액 오른쪽 끝이 행마다 달라져 목록이 들쭉날쭉해진다.
            SizedBox(
              width: 13,
              child: clickable
                  ? Icon(LucideIcons.chevronRight,
                      size: 13, color: t.fgTertiary)
                  : null,
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: _CardTitle(l.statsPatternTitle)),
          Padding(
            padding: const EdgeInsets.only(bottom: PSpace.x16),
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
                      padding: const EdgeInsets.only(bottom: 4),
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
                          style: PTypo.bodySm.copyWith(
                            // 웹 라벨 label-sm(13)/700 정합
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                        Text(
                          _heatRows[r].sub,
                          // 웹 서브 caption(12) 정합
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
                        ),
                      ],
                    ),
                  ),
                  for (var c = 0; c < _heatCols.length; c++)
                    Expanded(
                      child: Padding(
                        // 웹 grid gap 6 정합 — 인접 셀 사이 3+3
                        padding: const EdgeInsets.all(3),
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
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text(l.statsLegendLow,
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
                const SizedBox(width: 8),
                for (var i = 1; i <= 5; i++) ...[
                  Container(
                    // web 범례 셀 정합 — 18×10 가로 막대(얇게) + border-subtle 1px.
                    width: 18,
                    height: 10,
                    decoration: BoxDecoration(
                      color: bgFor(i),
                      borderRadius: PRadius.brXs,
                      border: Border.all(color: t.borderSubtle),
                    ),
                  ),
                  const SizedBox(width: 3),
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
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
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
    // 웹 MTile(mobile=flat div) 정합 — 하이라이트는 개별 카드가 아니라 한 묶음 안의 flat 항목.
    // _Card(배경/패딩) 벗겨 flat Column, 항목 구분은 _HighlightsGrid 의 gap 이 담당.
    return Column(
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
    // 서버 집계와 같은 규칙 — 환불은 지출 상계, 아직 안 온 건 세지 않는다.
    // 안 그러면 같은 화면의 저축률 위젯(서버 값)과 선 그래프가 어긋난다.
    for (final e in exps) {
      final raw = e.expenseDate ?? '';
      if (raw.length < 10) continue;
      final key = raw.substring(0, 10);
      final cur = byDate[key];
      if (cur == null) continue;
      if (isScheduledTx(raw)) continue;
      if (isRefundTx(e)) {
        byDate[key] = (
          income: cur.income,
          expense: cur.expense - e.amount.abs(),
          label: cur.label,
        );
      } else if (e.expenseType == 'INCOME') {
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

class _SavingsRateCard extends StatelessWidget {
  const _SavingsRateCard({
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
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final buckets =
        rangeAsync.value?.monthlyBuckets ?? const <RangeMonthlyBucket>[];
    // 첫 로딩(캐시 없음) — 형제 추이 카드처럼 도넛형 스켈레톤. _CatTrendCard 와
    // 동일하게 rangeAsync 만으로 판정 (이 카드는 monthExpAsync 미사용).
    if (rangeAsync.isLoading && buckets.isEmpty) {
      return const _Card(child: _SavingsRateSkeleton());
    }
    final sumIn = buckets.fold<int>(0, (sum, b) => sum + b.totalIncome);
    final sumOut = buckets.fold<int>(0, (sum, b) => sum + b.totalExpense);
    final n = buckets.isEmpty ? 1 : buckets.length;
    final avgIn = sumIn ~/ n;
    final avgOut = sumOut ~/ n;
    final avgSave = avgIn - avgOut;
    final isSingle = s._segMode == _SegMode.month;

    // web StatsScreen TrendStats 정합 — 저축률 도넛 게이지 + 구성 스택바 + 평균 3행.
    final saveRate =
        avgIn > 0 ? (avgSave / avgIn * 100).clamp(0.0, 100.0) : 0.0;
    final spendRate =
        avgIn > 0 ? (avgOut / avgIn * 100).clamp(0.0, 100.0) : 0.0;

    // 평균 수입/지출/저축 3행 — (라벨, 금액, dot 색, 비율%|null).
    final rows = <(String, int, Color, double?)>[
      (isSingle ? l.expTypeIncome : l.statsAvgIncome, avgIn, t.fgTertiary, null),
      (isSingle ? l.expTypeExpense : l.statsAvgExpense, avgOut, t.fgExpense,
          spendRate),
      (isSingle ? l.statsNetSavings : l.statsAvgSavings, avgSave, t.fgBrand,
          saveRate),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 저축률 도넛 게이지 + 인사이트 문구.
          Row(
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(108, 108),
                      painter: _SavingsRingPainter(
                        rate: saveRate,
                        track: t.bgTrack,
                        progress: t.fgBrand,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.statsSavingsRate,
                          style: PTypo.micro.copyWith(
                            color: t.fgTertiary,
                            fontWeight: PFontWeight.semi,
                          ),
                        ),
                        Text(
                          '${saveRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: t.fgPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l.statsSavingsInsight(saveRate.round()),
                  style: PTypo.bodyLg.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 구성 스택바 (지출 / 저축 비율) — 각 세그먼트 pill.
          SizedBox(
            height: 10,
            child: Row(
              // Expanded 세그먼트가 세로(높이 10)를 꽉 채우도록 stretch. 기본 center 면
              // child 없는 DecoratedBox 의 세로가 0 이 돼 스택바가 안 보였음.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (spendRate > 0)
                  Expanded(
                    flex: (spendRate * 100).round(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.fgExpense,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                if (spendRate > 0 && saveRate > 0) const SizedBox(width: 2),
                if (saveRate > 0)
                  Expanded(
                    flex: (saveRate * 100).round(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.fgBrand,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 평균 수입 / 지출 / 저축 3행 (dot·라벨·%·금액).
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: r.$3, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  r.$4 != null ? '${r.$1} ${r.$4!.round()}%' : r.$1,
                  style: PTypo.caption.copyWith(color: t.fgSecondary),
                ),
                const Spacer(),
                Text(
                  krwSigned(r.$2, masked, unit: true),
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
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

/// 저축률 도넛 게이지 페인터 — track 전체 원 + progress 호(top 시작, round cap).
/// web StatsScreen 의 svg(circle track + strokeDasharray arc, rotate -90) 정합.
class _SavingsRingPainter extends CustomPainter {
  _SavingsRingPainter({
    required this.rate,
    required this.track,
    required this.progress,
  });
  final double rate; // 0~100
  final Color track;
  final Color progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    const r = 48.0;
    final center = Offset(size.width / 2, size.height / 2);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, r, trackPaint);
    if (rate > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        (rate / 100) * 2 * math.pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SavingsRingPainter old) =>
      old.rate != rate || old.track != track || old.progress != progress;
}

// ─── 주요 카테고리 월별 추이 (추이 탭) — 지출 TOP3 stacked bar ────
class _CatTrendCard extends ConsumerStatefulWidget {
  const _CatTrendCard({required this.state, required this.rangeAsync});
  final _StatsScreenState state;
  final AsyncValue<RangeSummary> rangeAsync;

  @override
  ConsumerState<_CatTrendCard> createState() => _CatTrendCardState();
}

class _CatTrendCardState extends ConsumerState<_CatTrendCard> {
  // 순저축 카드(_SavingsBarsCard)와 동일한 터치 상태 패턴 — 터치 위치/인덱스로 툴팁.
  int? _touchedIdx;
  Offset? _touchPos;

  // fl_chart 가 아닌 커스텀 바(Row of _CatTrendBar)라 터치를 직접 계산:
  // 각 바는 Expanded(등폭)이므로 슬롯폭 = 전체폭/개수, 인덱스 = dx / 슬롯폭.
  void _onTouch(Offset pos, double slotW, int n) {
    if (n <= 0 || slotW <= 0) return;
    final i = (pos.dx ~/ slotW).clamp(0, n - 1).toInt();
    if (i != _touchedIdx || pos != _touchPos) {
      setState(() {
        _touchedIdx = i;
        _touchPos = pos;
      });
    }
  }

  void _clearTouch() {
    if (_touchedIdx != null) setState(() => _touchedIdx = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final range = widget.rangeAsync.value;
    final breakdown = range?.categoryBreakdown ?? const <CategoryBreakdown>[];
    final buckets = range?.monthlyBuckets ?? const <RangeMonthlyBucket>[];

    // 기간 전체 지출 TOP3 카테고리
    final top =
        (breakdown.where((b) => b.expenseType == 'EXPENSE').toList()
              ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)))
            .take(3)
            .toList();

    // TOP3 각 카테고리의 실제 설정 색(hex) — categoriesProvider 에서 rowId 매칭 룩업.
    // 웹과 동일하게 팔레트 인덱스가 아닌 카테고리 색 사용(없으면 _donutColor fallback).
    final cats = ref.watch(categoriesProvider).value ?? const [];
    final colors = <String?>[
      for (final c in top)
        cats.where((cat) => cat.rowId == c.categoryRowId).firstOrNull?.color,
    ];

    // 월별 parts = TOP3 각 카테고리의 그 달 지출액(매칭 없으면 0)
    final allSameYear =
        buckets.isNotEmpty &&
        buckets.every((b) => b.year == buckets.first.year);
    final rows = <({String label, List<int> parts})>[
      for (final b in buckets)
        (
          label: allSameYear
              ? b.month.toString().padLeft(2, '0')
              : '${b.year}.${b.month.toString().padLeft(2, '0')}',
          parts: [
            for (final c in top)
              b.categoryExpenses
                  .firstWhere(
                    (ce) => ce.categoryRowId == c.categoryRowId,
                    orElse: () => const CategoryAmount(),
                  )
                  .amount,
          ],
        ),
    ];
    final maxSum = rows.fold<int>(
      0,
      (m, r) => math.max(m, r.parts.fold<int>(0, (s, v) => s + v)),
    );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: _CardTitle(l.statsCatTrendTitle),
            trailing: Text(
              l.statsCatTrendTop3,
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
          ),
          if (widget.rangeAsync.isLoading && buckets.isEmpty)
            const _CatTrendSkeleton()
          else if (top.isEmpty || maxSum <= 0)
            _EmptyBox(text: l.statsNoData)
          else ...[
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < top.length; i++)
                    _LegendChip(
                      color: _donutColor(context, i, colors[i]),
                      label: top[i].categoryName ?? l.statsUnassigned,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: SizedBox(
                // 바(최대100)+6+월라벨(~14) + 상단 여유. web height 150 정합 유지
                // (값라벨 제거로 여유 늘어 오버플로우 없음). 바 하단 기준 정렬은 Row end.
                height: 150,
                // 순저축 카드처럼 Stack 위에 커스텀 툴팁을 얹는다. StackFit.expand 로
                // 바 영역이 150 을 꽉 채워(=기존 SizedBox 동작) 바 하단정렬을 유지.
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final n = rows.length;
                        final slotW = n == 0 ? 0.0 : constraints.maxWidth / n;
                        return Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (e) =>
                              _onTouch(e.localPosition, slotW, n),
                          onPointerMove: (e) =>
                              _onTouch(e.localPosition, slotW, n),
                          onPointerUp: (_) => _clearTouch(),
                          onPointerCancel: (_) => _clearTouch(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < rows.length; i++) ...[
                                // 웹 카테고리 바 gap(mobile 10) 정합 — slot 폭↓ → 바 두께↓.
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(
                                  child: _CatTrendBar(
                                    row: rows[i],
                                    maxSum: maxSum,
                                    isCurrent: i == rows.length - 1,
                                    colors: colors,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    if (_touchedIdx != null &&
                        _touchedIdx! < rows.length &&
                        _touchPos != null)
                      PChartTooltipLayer(
                        anchor: _touchPos!,
                        child: Builder(
                          builder: (context) {
                            final r = rows[_touchedIdx!];
                            return PChartTooltipBox(
                              title: r.label,
                              // 카테고리명(최대 ~4자)까지 들어가게 라벨폭 확장(기본 36→52).
                              labelWidth: 52,
                              rows: [
                                for (var i = 0; i < top.length; i++)
                                  if (r.parts[i] > 0)
                                    PChartTooltipRowData(
                                      color: _donutColor(context, i, colors[i]),
                                      label: top[i].categoryName ?? l.statsUnassigned,
                                      amount: krwSigned(
                                        r.parts[i],
                                        false,
                                        unit: true,
                                      ),
                                    ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 카테고리 추이 막대 하나 — 상단 합계('N만')·stacked 세그먼트·하단 월 라벨.
class _CatTrendBar extends StatelessWidget {
  const _CatTrendBar({
    required this.row,
    required this.maxSum,
    required this.isCurrent,
    required this.colors,
  });
  final ({String label, List<int> parts}) row;
  final int maxSum;
  final bool isCurrent;
  // TOP3 인덱스별 카테고리 실제 색(hex, 없으면 null → _donutColor fallback).
  final List<String?> colors;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final sum = row.parts.fold<int>(0, (s, v) => s + v);
    final barH = maxSum <= 0 ? 8.0 : math.max(8.0, sum / maxSum * 100.0);
    // 값이 있는 세그먼트 인덱스만 — 0 인 카테고리는 바에서 제외.
    final visible = [
      for (var i = 0; i < row.parts.length; i++)
        if (row.parts[i] > 0) i,
    ];
    return Column(
      // 값라벨 제거 — 금액은 터치 툴팁으로만 확인. Row.end + 이 mainAxisAlignment.end
      // 로 바가 값 높이와 무관하게 항상 하단(월 라벨) 기준 고정.
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          // 폭은 부모 Expanded(Row gap 반영)에 맞춰 채움 — 두께는 slot 폭이 결정(웹 gap+maxWidth 정합).
          width: double.infinity,
          height: barH,
          // 통짜 바 — 외곽(최상단·최하단)만 round(ClipRRect), 세그먼트는 사이 간격
          // 없이 붙어 색상 경계만으로 구분. 순저축 단일 바와 동일한 통짜 톤.
          child: ClipRRect(
              borderRadius: PRadius.brSm,
              // TOP1이 아래에 오도록 column-reverse (디자인 정합)
              child: Column(
                // 세그먼트(ColoredBox, child 없음)가 가로(24)를 채우도록 stretch.
                // 기본 center 면 교차축이 0 이 돼 바가 아예 안 보였음.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                verticalDirection: VerticalDirection.up,
                children: [
                  for (var vi = 0; vi < visible.length; vi++)
                    Expanded(
                      flex: row.parts[visible[vi]],
                      child: ColoredBox(
                        color: _donutColor(
                          context,
                          visible[vi],
                          colors[visible[vi]],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          row.label,
          style: PTypo.micro.copyWith(
            color: isCurrent ? t.fgPrimary : t.fgTertiary,
            fontWeight: isCurrent ? PFontWeight.bold : PFontWeight.regular,
            fontSize: PFontSize.micro,
          ),
        ),
      ],
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
                                // 월별 바 두께 24 로 통일(카테고리 월별 추이 _CatTrendBar width 24 기준). 일별(>20)만 얇게 4.
                                width: data.length > 20 ? 4 : 18,
                                // 위·아래 모두 둥글게(상하 대칭 round) — brSm(4) 전 모서리 적용.
                                // 얇은 일별 바(width 4)도 동일 처리(반경은 폭 절반으로 자동 clamp).
                                borderRadius: PRadius.brSm,
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
                              // 금액 텍스트는 기본색(fgPrimary) — web 툴팁은 색점만 증감색, 금액은 흰색.
                              PChartTooltipRowData(
                                color: v >= 0 ? t.statusInfoFg : t.fgExpense,
                                label: l.statsNetSavings,
                                amount: krwSigned(v.abs(), false, sign: sign, unit: true),
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
    final l = AppLocalizations.of(context);

    final now = rangeAsync.value?.totalExpense ?? 0;
    final prev = prevRangeAsync.value?.totalExpense ?? 0;
    final diff = now - prev;
    final less = diff <= 0; // 지출 감소 = 좋음(파랑)
    final good = less ? t.fgIncome : t.fgExpense;
    final pct = prev > 0
        ? '${((diff.abs() / prev) * 100).toStringAsFixed(1)}%'
        : '—';
    final barMax = [now, prev, 1].reduce((a, b) => a > b ? a : b);

    Widget cmpBar(String label, int amt, {required bool muted}) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: PTypo.micro.copyWith(
                color: t.fgTertiary,
                fontWeight: PFontWeight.semi,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 14,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (amt / barMax).clamp(0.0, 1.0),
                  // heightFactor 없으면 DecoratedBox(자식 없음)가 loose 높이 제약에서
                  // 0px 로 접혀 막대가 안 보임 → 트랙 높이(14) 를 꽉 채우도록 1.0 고정.
                  heightFactor: 1.0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      // web CompareSummary 막대: 이번=fg-brand, 지난=surface-input(bgTrack)+border.
                      color: muted ? t.bgTrack : t.fgBrand,
                      border: muted
                          ? Border.all(color: t.borderDefault)
                          : null,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              krwSigned(amt, masked, unit: true),
              textAlign: TextAlign.right,
              style: PTypo.caption.copyWith(
                color: muted ? t.fgSecondary : t.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // design/web CompareSummary 헤더는 기간 모드별 동적 라벨("이번 달/분기/해/기간 지출").
            // web: t('compare.periodExpense', {period: periodNow}). 앱 statsPeriodSpending('{period} 지출') 재사용.
            l.statsPeriodSpending(state._periodNow),
            style: PTypo.caption.copyWith(
              color: t.fgSecondary,
              fontWeight: PFontWeight.medium,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  krwSigned(now, masked, unit: true),
                  style: PTypo.h2.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
              ),
              if (prev > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: good.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${less ? '▼' : '▲'} $pct',
                    style: PTypo.micro.copyWith(
                      color: good,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (prev > 0) ...[
            const SizedBox(height: 10),
            // 강조는 web 정합 — "{금액} 더/덜"만 증감색+bold, 앞뒤("…보다"/"썼어요")는 일반 굵기.
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${l.statsVsLastPrefix(state._periodPrev)} '),
                  TextSpan(
                    text:
                        '${krwSigned(diff.abs(), masked, unit: true)} ${less ? l.statsVsLastDirLess : l.statsVsLastDirMore}',
                    style: TextStyle(color: good, fontWeight: PFontWeight.bold),
                  ),
                  TextSpan(text: ' ${l.statsVsLastSuffix(state._periodPrev)}'),
                ],
              ),
              style: PTypo.body.copyWith(color: t.fgPrimary),
            ),
          ],
          const SizedBox(height: 8),
          // 막대 라벨도 기간 모드별 동적("이번 달/분기/해/기간" · "지난 …") — web periodNow/periodPrev 정합.
          cmpBar(state._periodNow, now, muted: false),
          cmpBar(state._periodPrev, prev, muted: true),
        ],
      ),
    );
  }
}

/// 비교 지표 — 하루 평균 / 거래 건수 / 건당 평균 (이번/지난 기간).
/// design StatsScreen `CompareMetrics` 미러: 좌 라벨+이번 값, 우 ▲▼ 증감+지난 값.
/// ▲(증가)=지출색 빨강, ▼(감소)=수입색 파랑 (지출성이라 증가가 나쁨).
class _CompareMetricsCard extends StatelessWidget {
  const _CompareMetricsCard({
    required this.state,
    required this.rangeAsync,
    required this.prevRangeAsync,
    required this.nowExpAsync,
    required this.prevExpAsync,
    required this.masked,
  });
  final _StatsScreenState state;
  final AsyncValue<RangeSummary> rangeAsync;
  final AsyncValue<RangeSummary> prevRangeAsync;
  final AsyncValue<List<Expense>> nowExpAsync;
  final AsyncValue<List<Expense>> prevExpAsync;
  final bool masked;

  static int _txCount(List<Expense> e) =>
      e.where((x) => x.expenseType == 'EXPENSE').length;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final now = rangeAsync.value?.totalExpense ?? 0;
    final prev = prevRangeAsync.value?.totalExpense ?? 0;
    final txNow = _txCount(nowExpAsync.value ?? const []);
    final txPrev = _txCount(prevExpAsync.value ?? const []);

    final today = DateTime.now();
    DateTime dOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    var nowEnd = state._to;
    if (nowEnd.isAfter(today)) nowEnd = today;
    final nowDays = (dOnly(nowEnd).difference(dOnly(state._from)).inDays + 1)
        .clamp(1, 100000);
    final prevDays = (dOnly(state._prevRange.to)
                .difference(dOnly(state._prevRange.from))
                .inDays +
            1)
        .clamp(1, 100000);

    final rows = <({String label, int now, int prev, bool count})>[
      // 반올림도 web(Math.round) 정합 — `~/`(내림)는 web과 1원 차이 발생.
      (
        label: l.statsCompareDailyAvg,
        now: (now / nowDays).round(),
        prev: (prev / prevDays).round(),
        count: false,
      ),
      (label: l.statsCompareTxCount, now: txNow, prev: txPrev, count: true),
      (
        label: l.statsComparePerTx,
        now: txNow > 0 ? (now / txNow).round() : 0,
        prev: txPrev > 0 ? (prev / txPrev).round() : 0,
        count: false,
      ),
    ];

    String fmt(int v, bool count) =>
        count ? l.statsCountValue(v) : krwSigned(v, masked, unit: true);

    return _Card(
      child: Column(
        children: [
          for (final (i, m) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: 18),
            Builder(
              builder: (_) {
                final d = m.now - m.prev;
                final up = d > 0;
                final c = up ? t.fgExpense : t.fgIncome;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.label,
                          style: PTypo.caption.copyWith(
                            color: t.fgTertiary,
                            fontWeight: PFontWeight.semi,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          fmt(m.now, m.count),
                          style: PTypo.h3.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          d == 0 ? '—' : '${up ? '▲' : '▼'} ${fmt(d.abs(), m.count)}',
                          style: PTypo.caption.copyWith(
                            color: d == 0 ? t.fgTertiary : c,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          // 접미어("지난 달 …")도 기간 모드별 동적("지난 분기/해/이전 기간 …").
                          '${state._periodPrev} ${fmt(m.prev, m.count)}',
                          style: PTypo.micro.copyWith(color: t.fgTertiary),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// 요일별 지출 비교 — 이번 달(파랑) vs 지난 달(회색 track) grouped bar.
/// design StatsScreen `CompareWeekday` 미러: 월~일, 토·일 라벨 빨강, 하단 인사이트.
class _CompareWeekdayCard extends StatefulWidget {
  const _CompareWeekdayCard({
    required this.state,
    required this.nowExpAsync,
    required this.prevExpAsync,
    required this.masked,
  });
  final _StatsScreenState state;
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
  State<_CompareWeekdayCard> createState() => _CompareWeekdayCardState();
}

class _CompareWeekdayCardState extends State<_CompareWeekdayCard> {
  // 순저축/카테고리 추이 카드와 동일한 터치 툴팁 패턴 — 터치 위치/인덱스.
  int? _touchedIdx;
  Offset? _touchPos;

  // 커스텀 바(Row of Expanded ×7)라 터치를 직접 계산: 슬롯폭 = 전체폭/7.
  void _onTouch(Offset pos, double slotW) {
    if (slotW <= 0) return;
    final i = (pos.dx ~/ slotW).clamp(0, 6).toInt();
    if (i != _touchedIdx || pos != _touchPos) {
      setState(() {
        _touchedIdx = i;
        _touchPos = pos;
      });
    }
  }

  void _clearTouch() {
    if (_touchedIdx != null) setState(() => _touchedIdx = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final now = _CompareWeekdayCard._byWeekday(widget.nowExpAsync.value ?? const []);
    final prev = _CompareWeekdayCard._byWeekday(widget.prevExpAsync.value ?? const []);
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
        krwSigned(bestDrop, widget.masked, unit: true),
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
              krwSigned(bestRise, widget.masked, unit: true),
            )
          : l.statsWeekdayInsightSame;
    }

    // 막대 두께 — web `width: 42%, maxWidth: 16` 은 모바일 컬럼 폭에서 상한 16 에 근접.
    // 고정폭 16 으로 web 모바일 실두께 정합(design mobile 10 보다 두껍게).
    Widget bar(int v, Color color, {Color? border}) => Container(
      width: 16,
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
          _CardHeader(
            title: _CardTitle(l.statsWeekdayTitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 범례 라벨도 기간 모드별 동적 — web periodNow/periodPrev 정합.
                _WeekdayLegend(color: t.fgBrand, label: widget.state._periodNow),
                const SizedBox(width: 12),
                _WeekdayLegend(
                  color: t.bgTrack,
                  label: widget.state._periodPrev,
                  border: t.borderDefault,
                ),
              ],
            ),
          ),
          SizedBox(
            // 막대(chartH) + gap6 + 월라벨(micro ~17) 이 chartH+22 를 1px 초과("BOTTOM
            // OVERFLOWED BY 1.0px") → 여유 확보.
            height: chartH + 26,
            // 순저축/카테고리 추이 카드처럼 Stack 위에 커스텀 툴팁을 얹는다.
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final slotW = constraints.maxWidth / 7;
                    return Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) => _onTouch(e.localPosition, slotW),
                      onPointerMove: (e) => _onTouch(e.localPosition, slotW),
                      onPointerUp: (_) => _clearTouch(),
                      onPointerCancel: (_) => _clearTouch(),
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
                                        bar(now[i], t.fgBrand),
                                        const SizedBox(width: 3),
                                        bar(prev[i], t.bgTrack, border: t.borderDefault),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    labels[i],
                                    style: PTypo.micro.copyWith(
                                      // web CompareWeekday: 토(i==5)=fg-brand(파랑), 일(i==6)=fg-expense(빨강), 평일=fg-tertiary.
                                      color: i == 6
                                          ? t.fgExpense
                                          : (i == 5 ? t.fgBrand : t.fgTertiary),
                                      fontWeight: PFontWeight.semi,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                if (_touchedIdx != null && _touchPos != null)
                  PChartTooltipLayer(
                    anchor: _touchPos!,
                    child: PChartTooltipBox(
                      title: labels[_touchedIdx!],
                      // 기간 라벨(이번 해/지난 분기 등 최대 4자+공백) 폭 — 카테고리 추이와 동일.
                      labelWidth: 52,
                      rows: [
                        PChartTooltipRowData(
                          color: t.fgBrand,
                          label: widget.state._periodNow,
                          amount: krwSigned(now[_touchedIdx!], widget.masked, unit: true),
                        ),
                        PChartTooltipRowData(
                          color: t.bgTrack,
                          borderColor: t.borderDefault,
                          label: widget.state._periodPrev,
                          amount: krwSigned(prev[_touchedIdx!], widget.masked, unit: true),
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

class _CompareCategoryCard extends StatelessWidget {
  const _CompareCategoryCard({
    required this.rangeAsync,
    required this.prevRangeAsync,
    required this.categoriesAsync,
    required this.masked,
  });
  final AsyncValue<RangeSummary> rangeAsync;
  final AsyncValue<RangeSummary> prevRangeAsync;
  final AsyncValue<List<dynamic>> categoriesAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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

    // design CompareCategory `deltaRows` — 증감액(now-prev) 절댓값 큰 순 정렬.
    final rows = byId.entries.toList()
      ..sort((a, b) {
        final da = (a.value.now - a.value.prev).abs();
        final db = (b.value.now - b.value.prev).abs();
        final c = db.compareTo(da);
        return c != 0 ? c : b.value.now.compareTo(a.value.now);
      });
    final top = rows.take(10).toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: _CardTitle(l.statsCategoryDelta),
            trailing: Text(
              l.statsSortByChange,
              style: PTypo.caption.copyWith(color: t.fgTertiary),
            ),
          ),
          if (loading && top.isEmpty)
            const _CompareListSkeleton()
          else if (top.isEmpty)
            _EmptyBox(text: l.statsNoCompareData)
          else
            for (var i = 0; i < top.length; i++)
              _CompareDeltaRow(
                row: top[i].value,
                masked: masked,
                showDivider: i < top.length - 1,
              ),
        ],
      ),
    );
  }
}

/// design CompareCategory 행 — 아이콘 + [카테고리명 + "{지난}→{이번}" 서브라인] +
/// [증감액(증가=지출 빨강/감소=브랜드 파랑) + 증감률(tertiary)]. 하단 구분선.
///
/// diverging bar 는 디자인상 태블릿+ 전용이나 앱은 화면 크기 분기 인프라가 없어
/// 모바일 방식(막대 없이 증감액)만 구현 — 태블릿 대응은 별도.
class _CompareDeltaRow extends StatelessWidget {
  const _CompareDeltaRow({
    required this.row,
    required this.masked,
    required this.showDivider,
  });
  final ({String name, String? icon, String? color, int now, int prev}) row;
  final bool masked;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final iconColor = cp.resolveChartColor(
      context,
      row.color,
      fallback: t.fgBrand,
    );
    final iconData = lucideByName(row.icon ?? 'tag');
    final diff = row.now - row.prev;
    final up = diff > 0;
    final pct = row.prev > 0 ? ((diff / row.prev) * 100).round() : 0;
    // 증가(지출↑)=지출색 빨강(fgExpense) / 감소=수입색 파랑(fgIncome — 형제 CompareSummary·
    // Metrics 및 웹과 톤 통일) / 무변동=tertiary.
    final deltaColor = diff == 0
        ? t.fgTertiary
        : (up ? t.fgExpense : t.fgIncome);
    // U+2212(−) minus — formatChartAxis 부호 표기 정합.
    final sign = diff > 0 ? '+' : (diff < 0 ? '−' : '');

    return Container(
      // 웹 contentInset(+8) 흡수 — 라벨은 0, 행만 살짝 inset.
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: t.borderSubtle)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: PRadius.tile(32),
            ),
            alignment: Alignment.center,
            child: Icon(iconData, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${krwSigned(row.prev, masked, unit: true)} → '
                  '${krwSigned(row.now, masked, unit: true)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // 클로드 디자인(11.5) 정수 스냅 11 — web badge(11) 동값(caption 12는 web과 1px 불일치).
                  style: PTypo.micro.copyWith(color: t.fgTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                krwSigned(diff.abs(), masked, sign: sign, unit: true),
                style: PTypo.bodySm.copyWith(
                  color: deltaColor,
                  fontWeight: PFontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                row.prev > 0 ? '${up ? '▲' : '▼'} ${pct.abs()}%' : '—',
                style: PTypo.micro.copyWith(color: t.fgTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// design .tg--pill 모바일 — 컴팩트 pill toggle 버튼.
/// 선택=bg-brand 채움 + fg-on-brand/600, 기본=transparent + fg-secondary/500.
class _StatsChipTab extends StatelessWidget {
  const _StatsChipTab({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          // active fill 은 다크에서도 primary 고정(bgBrandSolid) — pills/월그리드 정합. bgBrand(다크 light)는 fill 부적합.
          color: active ? t.bgBrandSolid : Colors.transparent,
          borderRadius: PRadius.brMd,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: PTypo.sans,
            fontSize: PFontSize.bodySm,
            fontWeight: active ? PFontWeight.semi : PFontWeight.medium,
            color: active ? t.fgOnBrand : t.fgSecondary,
          ),
        ),
      ),
    );
  }
}
