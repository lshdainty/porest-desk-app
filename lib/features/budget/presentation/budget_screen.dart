import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/domain/budget_compliance.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/budget/presentation/month_picker_sheet.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/widgets/p_chart_tooltip.dart';

export 'package:groo_damda_app/features/budget/presentation/month_picker_sheet.dart'
    show showMonthPickerSheet;

const double _warnThreshold = 85;

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late DateTime _month = monthStart(DateTime.now());

  BudgetMonthKey get _key => (year: _month.year, month: _month.month);

  String get _monthStartStr => _ymd(_month.year, _month.month, 1);
  String get _monthEndStr => _ymd(
    _month.year,
    _month.month,
    DateTime(_month.year, _month.month + 1, 0).day,
  );

  ({String startDate, String endDate}) get _rangeKey =>
      (startDate: _monthStartStr, endDate: _monthEndStr);

  Future<void> _pickMonth() async {
    final picked = await showMonthPickerSheet(context, _month);
    if (picked != null) setState(() => _month = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final budgetsAsync = ref.watch(monthBudgetsProvider(_key));
    final summaryAsync = ref.watch(rangeSummaryProvider(_rangeKey));
    final categoriesAsync = ref.watch(categoriesProvider);
    final complianceAsync = ref.watch(budgetComplianceProvider(6));
    // 알림 기준 — 막대 색이 아니라 "여유" 카테고리 수를 셀 때만 쓴다(I-08 14). 미설정/로딩 시 85.
    final warnThreshold =
        ref.watch(budgetAlertThresholdProvider).value?.toDouble() ??
        _warnThreshold;

    final budgets = budgetsAsync.value;
    final summary = summaryAsync.value;
    void retryBudgets() => ref.invalidate(monthBudgetsProvider(_key));
    void retrySummary() => ref.invalidate(rangeSummaryProvider(_rangeKey));
    void retryCompliance() => ref.invalidate(budgetComplianceProvider(6));
    final budgetsFailed = budgetsAsync.hasError && budgets == null;
    final summaryFailed = summaryAsync.hasError && summary == null;
    final ready = budgets != null && summary != null;

    final monthRow = BudgetMonthRow(
      month: _month,
      onPrev: () =>
          setState(() => _month = DateTime(_month.year, _month.month - 1, 1)),
      onNext: () =>
          setState(() => _month = DateTime(_month.year, _month.month + 1, 1)),
      onPick: _pickMonth,
      trailing: BudgetMonthAction(
        label: l.navSettings,
        icon: LucideIcons.settings,
        // 웹 정합: 설정 버튼 → 예산 설정 페이지 push (drawer 폐기).
        onPressed: () => context.push('/budget/settings'),
      ),
    );

    final bands = <Widget>[];
    if (!ready) {
      // 질의가 실패해도 0원으로 그리지 않는다 — 그 구역 안에서 알리고 그 질의만 다시 받는다(I-08 17)
      final failed = budgetsFailed || summaryFailed;
      void retry() {
        if (budgetsFailed) retryBudgets();
        if (summaryFailed) retrySummary();
      }

      bands.add(
        budgetBand([
          monthRow,
          if (failed)
            BudgetSection(
              topPadding: PSpacing.x3,
              children: [
                BudgetFailure(title: l.dashFailBudget, onRetry: retry),
              ],
            )
          else ...const [_TotalSkeleton(), _PaceSkeleton()],
        ]),
      );
      if (!failed) {
        bands.add(budgetBand(const [_StatusSkeleton(), _ListSkeleton()]));
      }
      bands.add(
        budgetBand([
          _ComplianceSection(
            async: complianceAsync,
            currentYear: _month.year,
            currentMonth: _month.month,
            masked: ref.watch(hideCardProvider('budget.compliance')),
            onRetry: retryCompliance,
          ),
        ]),
      );
    } else {
      final categories = categoriesAsync.value ?? const <ExpenseCategory>[];
      final spentByCategory = _spentByCategoryFromSummary(summary);
      final totalExpense = summary.totalExpense;

      Budget? overallBudget;
      final categoryBudgets = <Budget>[];
      for (final b in budgets) {
        if (b.categoryRowId == null) {
          overallBudget = b;
        } else {
          categoryBudgets.add(b);
        }
      }
      final categoryLimitSum = categoryBudgets.fold<int>(
        0,
        (s, b) => s + b.budgetAmount,
      );
      final overallLimit = overallBudget?.budgetAmount ?? 0;
      final pct = overallLimit > 0 ? (totalExpense / overallLimit) * 100 : 0.0;
      final allocable = overallLimit - categoryLimitSum;
      final overAllocated =
          overallBudget != null && categoryLimitSum > overallLimit;
      final hasNoData = overallBudget == null && categoryBudgets.isEmpty;

      final today = DateTime.now();
      final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
      final dayOfMonth =
          (today.year == _month.year && today.month == _month.month)
          ? today.day
          : daysInMonth;
      final daysElapsedPct = (dayOfMonth / daysInMonth) * 100;
      final daysRemaining = (daysInMonth - dayOfMonth)
          .clamp(1, daysInMonth)
          .toInt();
      final dailyActual = (totalExpense / dayOfMonth.clamp(1, daysInMonth))
          .round();
      final dailyTarget =
          ((overallLimit - totalExpense).clamp(0, double.infinity).toDouble() /
                  daysRemaining)
              .round();
      final onTrack = pct <= daysElapsedPct + 5;

      final overCount = categoryBudgets.where((b) {
        final spent = spentByCategory[b.categoryRowId] ?? 0;
        return spent > b.budgetAmount;
      }).length;
      // "여유" 의 셈은 알림 기준 이하인 카테고리 수 그대로 — 막대 색에서 기준을 걷어도 남는다
      final healthyCount = categoryBudgets.where((b) {
        final spent = spentByCategory[b.categoryRowId] ?? 0;
        return b.budgetAmount > 0 &&
            (spent / b.budgetAmount) * 100 <= warnThreshold;
      }).length;

      final headerMasked = ref.watch(hideCardProvider('budget.header'));
      final paceMasked = ref.watch(hideCardProvider('budget.pace'));
      final categoriesMasked = ref.watch(hideCardProvider('budget.categories'));
      final complianceMasked = ref.watch(hideCardProvider('budget.compliance'));

      final complianceList = complianceAsync.value;
      final complianceHasLimit =
          complianceList?.any((r) => r.totalLimit > 0) ?? false;

      if (hasNoData) {
        // Q3 B — 달 줄 + 빈 결과 + 버튼. 이행률은 상한이 있는 달이 있을 때만 남는다
        bands.add(
          budgetBand([
            monthRow,
            BudgetSection(
              topPadding: PSpacing.x3,
              children: [
                PResultSection(
                  kind: PResultKind.empty,
                  size: PResultSize.medium,
                  icon: LucideIcons.target,
                  title: l.budgetEmptyMonth,
                  description: l.budgetEmptyHint,
                  headingLevel: 3,
                  placement: PResultPlacement.card,
                  primaryAction: PResultAction(
                    label: l.budgetSetup,
                    onPressed: () => context.push('/budget/settings'),
                  ),
                ),
              ],
            ),
          ]),
        );
        if (complianceAsync.isLoading && !complianceAsync.hasValue ||
            complianceAsync.hasError && !complianceAsync.hasValue ||
            complianceHasLimit) {
          bands.add(
            budgetBand([
              _ComplianceSection(
                async: complianceAsync,
                currentYear: _month.year,
                currentMonth: _month.month,
                masked: complianceMasked,
                onRetry: retryCompliance,
              ),
            ]),
          );
        }
      } else {
        bands.add(
          budgetBand([
            monthRow,
            _TotalSection(
              month: _month.month,
              overallBudget: overallBudget,
              totalSpent: totalExpense,
              overallLimit: overallLimit,
              categoryLimitSum: categoryLimitSum,
              pct: pct,
              allocable: allocable,
              overAllocated: overAllocated,
              masked: headerMasked,
            ),
            _PaceSection(
              pct: pct,
              daysElapsedPct: daysElapsedPct,
              dailyActual: dailyActual,
              dailyTarget: dailyTarget,
              onTrack: onTrack,
              masked: paceMasked,
            ),
          ]),
        );
        bands.add(
          budgetBand([
            _StatusSection(overCount: overCount, healthyCount: healthyCount),
            _CategoryListSection(
              budgets: categoryBudgets,
              categories: categories,
              spentByCategory: spentByCategory,
              masked: categoriesMasked,
              onGoSettings: () => context.push('/budget/settings'),
            ),
          ]),
        );
        bands.add(
          budgetBand([
            _ComplianceSection(
              async: complianceAsync,
              currentYear: _month.year,
              currentMonth: _month.month,
              masked: complianceMasked,
              onRetry: retryCompliance,
            ),
          ]),
        );
      }
    }

    return Scaffold(
      // 폰 구역 화면 — 띠 셋, 사이 8 은 회색 바닥(I-08 5). 머리 바로 아래 첫 띠에 틈이 없다.
      backgroundColor: c.bgLayerBasement,
      body: PPullToRefresh(
        onRefresh: () async {
          ref.invalidate(monthBudgetsProvider(_key));
          ref.invalidate(rangeSummaryProvider(_rangeKey));
          ref.invalidate(budgetComplianceProvider(6));
          await ref.read(monthBudgetsProvider(_key).future);
        },
        child: ListView(
          padding: EdgeInsets.only(
            // 떠 있는 하단 바 보상
            bottom: bottomNavigationInset(context),
          ),
          children: PScreenBands.children(bands),
        ),
      ),
    );
  }
}

Map<int, int> _spentByCategoryFromSummary(RangeSummary? summary) {
  final map = <int, int>{};
  if (summary == null) return map;
  for (final c in summary.categoryBreakdown) {
    final cid = c.categoryRowId;
    if (cid != null) {
      map.update(cid, (v) => v + c.totalAmount, ifAbsent: () => c.totalAmount);
    }
    final pid = c.parentCategoryRowId;
    if (pid != null) {
      map.update(pid, (v) => v + c.totalAmount, ifAbsent: () => c.totalAmount);
    }
  }
  return map;
}

String _ymd(int y, int m, int d) =>
    '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

/// 간격 한 칸 — [BudgetSection] 이 좌우 24 를 주지 않는다.
class _Gap extends StatelessWidget {
  const _Gap(this.height);

  final double height;

  @override
  Widget build(BuildContext context) =>
      BudgetFull(child: SizedBox(height: height));
}

// ─── 띠 ① 총 예산 · 지출 페이스 ───────────────────────────

class _TotalSection extends StatelessWidget {
  const _TotalSection({
    required this.month,
    required this.overallBudget,
    required this.totalSpent,
    required this.overallLimit,
    required this.categoryLimitSum,
    required this.pct,
    required this.allocable,
    required this.overAllocated,
    required this.masked,
  });

  final int month;
  final Budget? overallBudget;
  final int totalSpent;
  final int overallLimit;
  final int categoryLimitSum;
  final double pct;
  final int allocable;
  final bool overAllocated;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    String won(int n, {String sign = ''}) => budgetWon(n, masked, sign: sign);
    final head = <Widget>[
      BudgetEyebrow(l.budgetMonthOverallCap(month)),
      const _Gap(PSpacing.x1),
      BudgetDesc(l.budgetOverallCapDesc),
    ];
    if (overallBudget == null) {
      return BudgetSection(
        topPadding: PSpacing.x3,
        children: [
          ...head,
          const _Gap(PSpacing.x3),
          PCallout(description: l.budgetOverallCapEmptyHint),
          if (categoryLimitSum > 0) ...[
            const _Gap(PSpacing.x2),
            Text(
              '${l.budgetCurrentCategorySum}: ${won(categoryLimitSum)}',
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
          ],
        ],
      );
    }
    final remaining = overallLimit - totalSpent;
    return BudgetSection(
      topPadding: PSpacing.x3,
      children: [
        ...head,
        const _Gap(PSpacing.x3),
        BudgetBigAmount(amount: won(totalSpent), limit: won(overallLimit)),
        const _Gap(PSpacing.x4),
        BudgetBar(
          value: totalSpent.toDouble(),
          max: overallLimit.toDouble(),
          label: l.budgetMonthOverallCap(month),
        ),
        const _Gap(PSpacing.x2),
        BudgetBarCaption(
          left: l.budgetPercentUsed(pct.toStringAsFixed(0)),
          right: remaining >= 0
              ? l.budgetRemaining(won(remaining))
              : l.budgetOverBy(won(-remaining)),
          rightColor: remaining < 0 ? c.fgCritical : null,
          rightBold: remaining < 0,
        ),
        const _Gap(PSpacing.x3),
        budgetKvList(context, [
          BudgetKv(l.budgetOverallCapLabel, won(overallLimit)),
          BudgetKv(l.budgetCategoryAllocated, won(categoryLimitSum)),
          BudgetKv(
            l.budgetAllocatable,
            won(allocable.abs(), sign: overAllocated ? '−' : '+'),
            color: overAllocated ? c.fgCritical : c.fgBrand,
          ),
        ]),
        if (overAllocated) ...[
          const _Gap(PSpacing.x3),
          PCallout(
            tone: PCalloutTone.critical,
            description: l.budgetOverAllocatedWarning(
              won(categoryLimitSum - overallLimit),
            ),
          ),
        ],
      ],
    );
  }
}

class _PaceSection extends StatelessWidget {
  const _PaceSection({
    required this.pct,
    required this.daysElapsedPct,
    required this.dailyActual,
    required this.dailyTarget,
    required this.onTrack,
    required this.masked,
  });

  final double pct;
  final double daysElapsedPct;
  final int dailyActual;
  final int dailyTarget;
  final bool onTrack;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final used = pct.toStringAsFixed(0);
    final elapsed = daysElapsedPct.toStringAsFixed(0);
    return BudgetSection(
      header: BudgetHead(
        title: l.budgetSpendingPace,
        suffix: PBadge(
          label: onTrack ? l.budgetPaceOnTrack : l.budgetPaceFast,
          tone: onTrack ? PBadgeTone.positive : PBadgeTone.warning,
        ),
      ),
      children: [
        // 막대 8 + 오늘 표시선 2 × 14(막대 위로 3 — 장식)
        SizedBox(
          height: 14,
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 3,
                    child: BudgetBar(
                      value: pct,
                      max: 100,
                      label: l.budgetPaceBarName,
                      valueText: l.budgetPaceBarValue(used, elapsed),
                    ),
                  ),
                  Positioned(
                    left: ((daysElapsedPct / 100).clamp(0, 1) * w) - 1,
                    top: 0,
                    child: ExcludeSemantics(
                      child: Container(
                        key: const ValueKey('pace-marker'),
                        width: 2,
                        height: 14,
                        decoration: BoxDecoration(
                          color: c.fgNeutral,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const _Gap(PSpacing.x2),
        BudgetBarCaption(
          left: l.budgetPercentUsed(used),
          right: l.budgetMonthElapsed(elapsed),
        ),
        const _Gap(PSpacing.x3),
        budgetKvList(context, [
          BudgetKv(l.budgetDailyAvg, budgetWon(dailyActual, masked)),
          BudgetKv(l.budgetDailyRecommended, budgetWon(dailyTarget, masked)),
        ]),
      ],
    );
  }
}

// ─── 띠 ② 예산 현황 · 카테고리별 예산 ─────────────────────

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.overCount, required this.healthyCount});

  final int overCount;
  final int healthyCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return BudgetSection(
      header: BudgetHead(title: l.budgetStatusTitle),
      children: [
        budgetKvList(context, [
          BudgetKv(
            l.budgetOver,
            '$overCount ${l.expCategory}',
            color: overCount > 0 ? c.fgCritical : c.fgNeutral,
          ),
          BudgetKv(
            l.budgetHealthy,
            '$healthyCount ${l.expCategory}',
            color: c.fgBrand,
          ),
        ]),
      ],
    );
  }
}

/// 카테고리별 예산 — 조회 전용(관리는 위 설정 버튼 → 예산 설정). 줄 = 타일 · 이름(줄바꿈) · 남은 예산 · 쓴 돈 / 한도 + 막대.
class _CategoryListSection extends StatelessWidget {
  const _CategoryListSection({
    required this.budgets,
    required this.categories,
    required this.spentByCategory,
    required this.masked,
    required this.onGoSettings,
  });

  final List<Budget> budgets;
  final List<ExpenseCategory> categories;
  final Map<int, int> spentByCategory;
  final bool masked;
  final VoidCallback onGoSettings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BudgetListSection(
      header: BudgetHead(
        title: l.budgetByCategory,
        note: l.budgetCountSet(budgets.length),
      ),
      children: [
        if (budgets.isEmpty) ...[
          BudgetEmptyLine(l.budgetNoCategoryBudgets),
          Center(
            child: PTextButton(
              label: l.budgetGoToSettings,
              onPressed: onGoSettings,
            ),
          ),
        ] else
          PList(
            children: [
              for (final b in budgets)
                BudgetCategoryRow(
                  budget: b,
                  category: categories.byRowId(b.categoryRowId!),
                  spent: spentByCategory[b.categoryRowId] ?? 0,
                  masked: masked,
                ),
            ],
          ),
      ],
    );
  }
}

// ─── 띠 ③ 최근 6개월 이행률 ──────────────────────────────

class _ComplianceSection extends StatelessWidget {
  const _ComplianceSection({
    required this.async,
    required this.currentYear,
    required this.currentMonth,
    required this.masked,
    required this.onRetry,
  });

  final AsyncValue<List<BudgetComplianceMonth>> async;
  final int currentYear;
  final int currentMonth;
  final bool masked;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = async.value;
    final Widget body;
    if (list == null) {
      body = async.hasError
          ? BudgetFailure(title: l.dashFailBudget, onRetry: onRetry)
          : const PSkeleton(width: double.infinity, height: 200);
    } else if (list.isEmpty) {
      body = BudgetEmptyLine(l.budgetNoComplianceData);
    } else {
      body = SizedBox(
        height: 200,
        child: _ComplianceBarChart(
          rows: list,
          currentYear: currentYear,
          currentMonth: currentMonth,
          masked: masked,
        ),
      );
    }
    return BudgetSection(
      header: BudgetHead(
        title: l.budgetComplianceTitle,
        note: l.budgetComplianceSubtitle,
      ),
      children: [body],
    );
  }
}

// ─── 불러오는 중 — 실제 구역과 같은 틀 ────────────────────

class _TotalSkeleton extends StatelessWidget {
  const _TotalSkeleton();

  @override
  Widget build(BuildContext context) => BudgetSection(
    topPadding: PSpacing.x3,
    children: [
      PSkeleton.text(PTypography.t3, width: 96),
      const _Gap(PSpacing.x1),
      PSkeleton.text(PTypography.t3),
      const _Gap(PSpacing.x3),
      PSkeleton.text(PTypography.t9, width: 160),
      const _Gap(PSpacing.x4),
      const PSkeleton(
        height: PProgressBar.height,
        radius: PSkeletonRadius.full,
      ),
      const _Gap(PSpacing.x2),
      PSkeleton.text(PTypography.t3, width: 120),
      const _Gap(PSpacing.x3),
      for (var i = 0; i < 3; i++)
        PSkeleton.text(PTypography.t5, width: double.infinity),
    ],
  );
}

class _PaceSkeleton extends StatelessWidget {
  const _PaceSkeleton();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BudgetSection(
      header: BudgetHead(title: l.budgetSpendingPace),
      children: [
        const PSkeleton(
          height: PProgressBar.height,
          radius: PSkeletonRadius.full,
        ),
        const _Gap(PSpacing.x2),
        PSkeleton.text(PTypography.t3, width: 140),
        const _Gap(PSpacing.x3),
        for (var i = 0; i < 2; i++)
          PSkeleton.text(PTypography.t5, width: double.infinity),
      ],
    );
  }
}

class _StatusSkeleton extends StatelessWidget {
  const _StatusSkeleton();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BudgetSection(
      header: BudgetHead(title: l.budgetStatusTitle),
      children: [
        for (var i = 0; i < 2; i++)
          PSkeleton.text(PTypography.t5, width: double.infinity),
      ],
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BudgetListSection(
      header: BudgetHead(title: l.budgetByCategory),
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.x6,
              vertical: PSpacing.x3,
            ),
            child: Column(
              spacing: PSpacing.x4,
              children: [
                Row(
                  spacing: PSpacing.x3,
                  children: [
                    const PSkeleton(
                      width: 40,
                      height: 40,
                      radius: PSkeletonRadius.r12,
                    ),
                    Expanded(child: PSkeleton.text(PTypography.t5)),
                    PSkeleton.text(PTypography.t5, width: 72),
                  ],
                ),
                const PSkeleton(
                  height: PProgressBar.height,
                  radius: PSkeletonRadius.full,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── 이행률 차트 — 지금 차트 그대로(I-08 13: ds 막대가 막대별 색 · 막대 위 글 · 기준선을 못 받아 질문 대기) ───

class _ComplianceBarChart extends StatefulWidget {
  const _ComplianceBarChart({
    required this.rows,
    required this.currentYear,
    required this.currentMonth,
    required this.masked,
  });
  final List<BudgetComplianceMonth> rows;
  final int currentYear;
  final int currentMonth;
  final bool masked;

  @override
  State<_ComplianceBarChart> createState() => _ComplianceBarChartState();
}

class _ComplianceBarChartState extends State<_ComplianceBarChart> {
  int? _touchedIdx;
  Offset? _touchPos;

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    final c = context.colors;
    final currentYear = widget.currentYear;
    final currentMonth = widget.currentMonth;
    final masked = widget.masked;
    final l = AppLocalizations.of(context);
    final maxY = rows.fold<double>(
      100,
      (m, r) => r.compliancePercent > m ? r.compliancePercent : m,
    );
    // 상한을 두면 안 된다 — 이행률은 한도 대비 지출이라 2,855% 같은 값이 실제로 나온다.
    // ×1.15 는 막대 위 % 라벨 자리.
    final yMax = maxY * 1.15;

    final chart = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yMax,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent ||
                event is FlPanEndEvent ||
                event is FlPanCancelEvent ||
                event is FlLongPressEnd ||
                event is FlPointerExitEvent) {
              return;
            }
            final i = response?.spot?.touchedBarGroupIndex;
            if (i == null) {
              if (_touchedIdx != null) {
                setState(() => _touchedIdx = null);
              }
              return;
            }
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
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 4,
            getTooltipItem: (group, groupIdx, rod, rodIdx) => BarTooltipItem(
              '${rod.toY.toStringAsFixed(0)}%',
              PTypography.t2.copyWith(
                color: c.fgNeutral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: c.strokeNeutralSubtle,
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
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
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= rows.length) {
                  return const SizedBox.shrink();
                }
                final r = rows[i];
                final last = r.year == currentYear && r.month == currentMonth;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    monthOnly(DateTime(2000, r.month)),
                    style: PTypography.t2.copyWith(
                      color: last ? c.fgNeutral : c.fgNeutralSubtle,
                      fontWeight: last ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < rows.length; i++)
            BarChartGroupData(
              x: i,
              // 한도가 없는 달은 0% 막대로 그리지 않는다(Q3) — % 글도 없다
              showingTooltipIndicators: rows[i].totalLimit > 0
                  ? const [0]
                  : const [],
              barRods: [
                BarChartRodData(
                  toY: rows[i].totalLimit > 0 ? rows[i].compliancePercent : 0,
                  // 초과 차트 red / 이번 달 차트 blue / 지난 달 stroke-neutral-solid(옛 border-strong)
                  color: rows[i].compliancePercent > 100
                      ? PChartColor.red.of(c)
                      : (rows[i].year == currentYear &&
                            rows[i].month == currentMonth)
                      ? PChartColor.blue.of(c)
                      : c.strokeNeutralSolid,
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    return Stack(
      children: [
        ClipRect(child: chart),
        if (_touchedIdx != null &&
            _touchedIdx! < rows.length &&
            _touchPos != null)
          PChartTooltipLayer(
            anchor: _touchPos!,
            child: Builder(
              builder: (_) {
                final r = rows[_touchedIdx!];
                final over = r.compliancePercent > 100;
                return PChartTooltipBox(
                  title: monthOnly(DateTime(2000, r.month)),
                  labelWidth: 56,
                  rows: [
                    PChartTooltipRowData(
                      color: over ? c.fgCritical : c.fgBrand,
                      label: l.budgetVsLimit,
                      amount: '${r.compliancePercent.toStringAsFixed(1)}%',
                      amountColor: over ? c.fgCritical : c.fgNeutral,
                    ),
                  ],
                  footer: [
                    PChartTooltipFooterRowData(
                      label: l.expSummaryExpense,
                      value: budgetWon(r.totalSpent, masked),
                    ),
                    PChartTooltipFooterRowData(
                      label: l.budgetLimit,
                      value: budgetWon(r.totalLimit, masked),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
