import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_flat_section.dart';
import 'package:porest_desk_app/shared/widgets/p_chart_tooltip.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/budget/domain/budget.dart';
import 'package:porest_desk_app/features/budget/domain/budget_compliance.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';

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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final budgetsAsync = ref.watch(monthBudgetsProvider(_key));
    final summaryAsync = ref.watch(
      rangeSummaryProvider((startDate: _monthStartStr, endDate: _monthEndStr)),
    );
    final categoriesAsync = ref.watch(categoriesProvider);
    final complianceAsync = ref.watch(budgetComplianceProvider(6));
    // 경고 게이지 임계값 — 사용자 설정값(웹 정합). 미설정/로딩 시 _warnThreshold(85).
    final warnThreshold =
        ref.watch(budgetAlertThresholdProvider).value?.toDouble() ??
        _warnThreshold;

    return Scaffold(
      backgroundColor: t.bgSurface,
      // appBar 제거 — shell MobileScaffold 의 MobileHeader 가 title='예산' +
      // actions(theme/eye/bell/search) 일관 표시.
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(monthBudgetsProvider(_key));
          ref.invalidate(
            rangeSummaryProvider((
              startDate: _monthStartStr,
              endDate: _monthEndStr,
            )),
          );
          ref.invalidate(budgetComplianceProvider(6));
          await ref.read(monthBudgetsProvider(_key).future);
        },
        // 카드 다이어트 — design BudgetScreen mobile: padding 16/20/24 + 섹션 gap 36.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            PSpace.x20,
            PSpace.x16,
            PSpace.x20,
            PSpace.x24,
          ),
          children: [
            _MonthBar(
              month: _month,
              onPrev: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1, 1),
              ),
              onNext: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1, 1),
              ),
              onPickMonth: (m) => setState(() => _month = m),
              // 웹 정합: 설정 버튼 → 예산 설정 페이지 push (drawer 폐기).
              onSettings: () => context.push('/budget/settings'),
            ),
            const SizedBox(height: PSpace.x12),
            budgetsAsync.when(
              loading: () => const _BudgetLoadingSkeleton(),
              error: (e, _) => _ErrorBox(
                message: '${l.budgetLoadError}\n$e',
                onRetry: () => ref.invalidate(monthBudgetsProvider(_key)),
              ),
              data: (budgets) {
                final categories = categoriesAsync.value ?? const [];
                final summary = summaryAsync.value;
                final spentByCategory = _spentByCategoryFromSummary(summary);
                final totalExpense = summary?.totalExpense ?? 0;

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
                final totalLimit = overallBudget != null
                    ? overallLimit
                    : categoryLimitSum;
                final pct = totalLimit > 0
                    ? (totalExpense / totalLimit) * 100
                    : 0.0;
                final allocable = overallLimit - categoryLimitSum;
                final overAllocated =
                    overallBudget != null && categoryLimitSum > overallLimit;

                final today = DateTime.now();
                final daysInMonth = DateTime(
                  _month.year,
                  _month.month + 1,
                  0,
                ).day;
                final dayOfMonth =
                    (today.year == _month.year && today.month == _month.month)
                    ? today.day
                    : daysInMonth;
                final daysElapsedPct = (dayOfMonth / daysInMonth) * 100;
                final daysRemaining = (daysInMonth - dayOfMonth)
                    .clamp(1, daysInMonth)
                    .toInt();
                final dailyActual =
                    (totalExpense / dayOfMonth.clamp(1, daysInMonth)).round();
                final dailyTarget =
                    ((totalLimit - totalExpense)
                                .clamp(0, double.infinity)
                                .toDouble() /
                            daysRemaining)
                        .round();
                final onTrack = pct <= daysElapsedPct + 5;

                final overList = categoryBudgets.where((b) {
                  final cid = b.categoryRowId;
                  if (cid == null) return false;
                  final spent = spentByCategory[cid] ?? 0;
                  return spent > b.budgetAmount;
                }).toList();
                final healthyList = categoryBudgets.where((b) {
                  final cid = b.categoryRowId;
                  if (cid == null) return false;
                  final spent = spentByCategory[cid] ?? 0;
                  return b.budgetAmount > 0 &&
                      (spent / b.budgetAmount) * 100 <= warnThreshold;
                }).toList();

                final hasNoData =
                    overallBudget == null && categoryBudgets.isEmpty;

                return Column(
                  children: [
                    _HeaderCard(
                      month: _month.month,
                      overallBudget: overallBudget,
                      totalSpent: totalExpense,
                      totalLimit: totalLimit,
                      overallLimit: overallLimit,
                      categoryLimitSum: categoryLimitSum,
                      pct: pct,
                      warnThreshold: warnThreshold,
                      allocable: allocable,
                      overAllocated: overAllocated,
                      masked: settings.hideAmounts,
                      tokens: t,
                    ),
                    if (hasNoData) ...[
                      const SizedBox(height: 36),
                      _EmptyState(
                        tokens: t,
                        onAdd: () => context.push('/budget/settings'),
                      ),
                    ] else ...[
                      const SizedBox(height: 36),
                      _PaceCard(
                        pct: pct,
                        daysElapsedPct: daysElapsedPct,
                        dailyActual: dailyActual,
                        dailyTarget: dailyTarget,
                        onTrack: onTrack,
                        masked: settings.hideAmounts,
                        tokens: t,
                      ),
                      const SizedBox(height: 36),
                      _StatusTiles(
                        overCount: overList.length,
                        healthyCount: healthyList.length,
                        tokens: t,
                      ),
                      const SizedBox(height: 36),
                      _CategoryListCard(
                        budgets: categoryBudgets,
                        categories: categories,
                        spentByCategory: spentByCategory,
                        warnThreshold: warnThreshold,
                        masked: settings.hideAmounts,
                        loading: summaryAsync.isLoading,
                        tokens: t,
                        onGoSettings: () => context.push('/budget/settings'),
                      ),
                      const SizedBox(height: 36),
                      _ComplianceCard(
                        async: complianceAsync,
                        currentYear: _month.year,
                        currentMonth: _month.month,
                        tokens: t,
                        masked: settings.hideAmounts,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
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

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onSettings,
    required this.onPickMonth,
  });
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSettings;
  final ValueChanged<DateTime> onPickMonth;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        PButton.icon(
          icon: LucideIcons.chevronLeft,
          size: PButtonSize.sm,
          onPressed: onPrev,
        ),
        InkWell(
          borderRadius: PRadius.brMd,
          onTap: () async {
            final picked = await showMonthPickerSheet(context, month);
            if (picked != null) onPickMonth(picked);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x4,
              vertical: PSpace.x4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  yearMonth(month),
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(width: PSpace.x4),
                Icon(LucideIcons.chevronDown, size: 12, color: t.fgTertiary),
              ],
            ),
          ),
        ),
        PButton.icon(
          icon: LucideIcons.chevronRight,
          size: PButtonSize.sm,
          onPressed: onNext,
        ),
        const Spacer(),
        PButton(
          label: l.navSettings,
          icon: LucideIcons.settings,
          variant: PButtonVariant.accent,
          size: PButtonSize.sm,
          onPressed: onSettings,
        ),
      ],
    );
  }
}

/// Month picker bottom drawer — 디자이너 정합 (year header prev/next + 12 month grid + 오늘로/닫기).
/// mobile drawer 패턴 — showPSheet (공통 layout). desktop/tablet dialog 는 follow-up.
Future<DateTime?> showMonthPickerSheet(BuildContext context, DateTime initial) {
  final l = AppLocalizations.of(context);
  return showPSheet<DateTime>(
    context,
    title: l.budgetSelectMonth,
    shrinkWrap: true,
    contentBuilder: (sheetCtx, _) {
      final t = sheetCtx.tokens;
      final now = DateTime.now();
      int viewYear = initial.year;
      final selectedYear = initial.year;
      final selectedMonth = initial.month;
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpace.x20,
              PSpace.x4,
              PSpace.x20,
              PSpace.x20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // year header — prev / year text / next
                Row(
                  children: [
                    PButton.icon(
                      icon: LucideIcons.chevronLeft,
                      onPressed: () => setSheet(() => viewYear -= 1),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          yearOnly(DateTime(viewYear)),
                          style: PTypo.bodyLg.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    PButton.icon(
                      icon: LucideIcons.chevronRight,
                      onPressed: () => setSheet(() => viewYear += 1),
                    ),
                  ],
                ),
                const SizedBox(height: PSpace.x16),
                // 4x3 month grid (1월 ~ 12월)
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.0,
                  mainAxisSpacing: PSpace.x8,
                  crossAxisSpacing: PSpace.x8,
                  children: [
                    for (int m = 1; m <= 12; m++)
                      _MonthGridButton(
                        label: monthOnly(DateTime(viewYear, m)),
                        selected:
                            viewYear == selectedYear && m == selectedMonth,
                        onTap: () =>
                            Navigator.of(ctx).pop(DateTime(viewYear, m, 1)),
                      ),
                  ],
                ),
                const SizedBox(height: PSpace.x12),
                // footer: 오늘로 + 닫기
                Row(
                  children: [
                    PButton(
                      label: l.calGoToToday,
                      icon: LucideIcons.locateFixed,
                      variant: PButtonVariant.ghost,
                      size: PButtonSize.sm,
                      flush: PButtonFlush.left,
                      onPressed: () => Navigator.of(
                        ctx,
                      ).pop(DateTime(now.year, now.month, 1)),
                    ),
                    const Spacer(),
                    PButton(
                      label: l.actionClose,
                      variant: PButtonVariant.ghost,
                      size: PButtonSize.sm,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _MonthGridButton extends StatelessWidget {
  const _MonthGridButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: selected ? t.bgBrand : Colors.transparent,
      borderRadius: PRadius.brMd,
      child: InkWell(
        borderRadius: PRadius.brMd,
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: PTypo.bodySm.copyWith(
              color: selected ? t.fgOnBrand : t.fgPrimary,
              fontWeight: selected ? PFontWeight.bold : PFontWeight.medium,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.month,
    required this.overallBudget,
    required this.totalSpent,
    required this.totalLimit,
    required this.overallLimit,
    required this.categoryLimitSum,
    required this.pct,
    required this.allocable,
    required this.overAllocated,
    required this.masked,
    required this.tokens,
    this.warnThreshold = _warnThreshold,
  });
  final int month;
  final Budget? overallBudget;
  final int totalSpent;
  final int totalLimit;
  final int overallLimit;
  final int categoryLimitSum;
  final double pct;
  final int allocable;
  final bool overAllocated;
  final bool masked;
  final PorestTokens tokens;
  final double warnThreshold;

  @override
  Widget build(BuildContext context) {
    // 예산 상태 = semantic 색 (초과=error / 경고=warning / 일반=info).
    // *Fg 토큰은 dark에서 light variant 자동 분기.
    final color = pct > 100
        ? tokens.statusDangerFg
        : pct > warnThreshold
        ? tokens.statusWarningFg
        : tokens.statusInfoFg;
    final l = AppLocalizations.of(context);

    // 조회 전용 (web BudgetPage hero 정합) — 상한 수정은 예산 설정 페이지에서.
    // 카드 다이어트에서도 유지 — design `p-card--brand` 는 diet 제외 (브랜드 강조 카드).
    return PCard(
      // 디자인 p-card--brand: surface(#242938) 위에 cobalt @12% 알파 합성 → #2B374D.
      // alphaBlend(틴트, surface) 로 "surface 위 알파"를 명시(라이트/다크 자동).
      variant: PCardVariant.shadow,
      color: Color.alphaBlend(tokens.bgBrandTint, tokens.bgSurface),
      padding: const EdgeInsets.all(18),
      child: overallBudget == null
          ? _emptyOverall(context, l)
          : _filledOverall(color, l),
    );
  }

  Widget _emptyOverall(BuildContext context, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.budgetMonthOverallCap(month),
          style: PTypo.caption.copyWith(
            color: tokens.fgBrandStrong,
            fontWeight: PFontWeight.semi,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.budgetOverallCapDesc,
          style: PTypo.caption.copyWith(color: tokens.fgTertiary),
        ),
        const SizedBox(height: PSpace.x12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x12,
            vertical: PSpace.x8,
          ),
          decoration: BoxDecoration(
            color: tokens.bgSurface,
            borderRadius: PRadius.brMd,
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.target, size: 14, color: tokens.fgBrand),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.budgetOverallCapEmptyHint,
                  style: PTypo.bodySm.copyWith(color: tokens.fgSecondary),
                ),
              ),
            ],
          ),
        ),
        if (categoryLimitSum > 0) ...[
          const SizedBox(height: PSpace.x8),
          Text(
            masked
                ? '${l.budgetCurrentCategorySum}: ${krwMasked(categoryLimitSum, masked, mask: '••••')}'
                : '${l.budgetCurrentCategorySum}: ${krwSigned(categoryLimitSum, false, unit: true)}',
            style: PTypo.caption.copyWith(color: tokens.fgTertiary),
          ),
        ],
      ],
    );
  }

  Widget _filledOverall(Color color, AppLocalizations l) {
    final remaining = totalLimit - totalSpent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.budgetMonthOverallCap(month),
          style: PTypo.caption.copyWith(
            color: tokens.fgBrandStrong,
            fontWeight: PFontWeight.semi,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.budgetOverallCapDesc,
          style: PTypo.caption.copyWith(color: tokens.fgTertiary),
        ),
        const SizedBox(height: PSpace.x12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                krwMasked(totalSpent, masked, mask: '••••'),
                style: PTypo.h2.copyWith(
                  color: tokens.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                masked
                    ? ' / ${krwMasked(totalLimit, masked, mask: '••••')}'
                    : ' / ${krwSigned(totalLimit, false, unit: true)}',
                style: PTypo.bodySm.copyWith(color: tokens.fgSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x12),
        LinearProgressIndicator(
          borderRadius: PRadius.brFull,
          value: (pct / 100).clamp(0, 1).toDouble(),
          minHeight: 10,
          backgroundColor: tokens.bgTrack,
          color: color,
        ),
        const SizedBox(height: PSpace.x8),
        Row(
          children: [
            Text(
              l.budgetPercentUsed(pct.toStringAsFixed(0)),
              style: PTypo.caption.copyWith(color: tokens.fgSecondary),
            ),
            const Spacer(),
            Text(
              remaining >= 0
                  ? l.budgetRemaining(masked
                        ? krwMasked(remaining, masked, mask: '••••')
                        : krwSigned(remaining, false, unit: true))
                  : l.budgetOverBy(masked
                        ? krwMasked(-remaining, masked, mask: '••••')
                        : krwSigned(-remaining, false, unit: true)),
              style: PTypo.caption.copyWith(
                color: remaining >= 0 ? tokens.fgSecondary : tokens.fgExpense,
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x12),
        Container(
          padding: const EdgeInsets.only(top: PSpace.x12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: tokens.borderSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: l.budgetOverallCapLabel,
                  value: krwSigned(
                    overallLimit,
                    masked,
                    unit: true,
                    mask: '••••',
                  ),
                  color: tokens.fgPrimary,
                  tokens: tokens,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: l.budgetCategoryAllocated,
                  value: krwSigned(
                    categoryLimitSum,
                    masked,
                    unit: true,
                    mask: '••••',
                  ),
                  color: tokens.fgPrimary,
                  tokens: tokens,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: l.budgetAllocatable,
                  value: krwSigned(
                    allocable.abs(),
                    masked,
                    sign: overAllocated ? '−' : '+',
                    unit: true,
                    mask: '••••',
                  ),
                  color: overAllocated ? tokens.fgExpense : tokens.fgIncome,
                  tokens: tokens,
                ),
              ),
            ],
          ),
        ),
        if (overAllocated) ...[
          const SizedBox(height: PSpace.x8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x12,
              vertical: PSpace.x8,
            ),
            decoration: BoxDecoration(
              color: tokens.statusDangerSubtle,
              borderRadius: PRadius.brMd,
              border: Border.all(
                color: tokens.fgExpense.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.alertTriangle,
                  size: 14,
                  color: tokens.statusDangerFg,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    masked
                        ? l.budgetOverAllocatedWarning(krwMasked(categoryLimitSum - overallLimit, masked, mask: '••••'))
                        : l.budgetOverAllocatedWarning(
                            krwSigned(categoryLimitSum - overallLimit, false, unit: true)),
                    style: PTypo.caption.copyWith(color: tokens.statusDangerFg),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.tokens,
  });
  final String label;
  final String value;
  final Color color;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: PTypo.micro.copyWith(
            color: tokens.fgTertiary,
            fontWeight: PFontWeight.medium,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: PTypo.bodySm.copyWith(
            color: color,
            fontWeight: PFontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PaceCard extends StatelessWidget {
  const _PaceCard({
    required this.pct,
    required this.daysElapsedPct,
    required this.dailyActual,
    required this.dailyTarget,
    required this.onTrack,
    required this.masked,
    required this.tokens,
  });
  final double pct;
  final double daysElapsedPct;
  final int dailyActual;
  final int dailyTarget;
  final bool onTrack;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 카드 다이어트 — 플랫 섹션 (헤드 + 콘텐츠 inset 10).
    return PFlatSection(
      title: l.budgetSpendingPace,
      trailing: PBadge(
        label: onTrack ? l.budgetPaceOnTrack : l.budgetPaceFast,
        variant: onTrack
            ? PBadgeVariant.softSuccess
            : PBadgeVariant.softWarning,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (ctx, c) {
              final w = c.maxWidth;
              return SizedBox(
                height: 18,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 3,
                      child: LinearProgressIndicator(
                        borderRadius: PRadius.brFull,
                        value: (pct / 100).clamp(0, 1).toDouble(),
                        minHeight: 12,
                        backgroundColor: tokens.bgTrack,
                        color: pct > 100 ? tokens.fgExpense : tokens.bgBrand,
                      ),
                    ),
                    Positioned(
                      left: ((daysElapsedPct / 100).clamp(0, 1) * w) - 1,
                      top: 0,
                      child: Container(
                        width: 2,
                        height: 18,
                        decoration: BoxDecoration(
                          color: tokens.fgPrimary,
                          borderRadius: PRadius.brXs,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: PSpace.x8),
          Row(
            children: [
              Text(
                l.budgetPercentUsed(pct.toStringAsFixed(0)),
                style: PTypo.caption.copyWith(color: tokens.fgTertiary),
              ),
              const Spacer(),
              Text(
                l.budgetMonthElapsed(daysElapsedPct.toStringAsFixed(0)),
                style: PTypo.caption.copyWith(color: tokens.fgTertiary),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          Container(
            padding: const EdgeInsets.only(top: PSpace.x12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PaceStat(
                    label: l.budgetDailyAvg,
                    amount: dailyActual,
                    color: tokens.fgPrimary,
                    masked: masked,
                    tokens: tokens,
                  ),
                ),
                Expanded(
                  child: _PaceStat(
                    label: l.budgetDailyRecommended,
                    amount: dailyTarget,
                    color: tokens.fgBrandStrong,
                    masked: masked,
                    tokens: tokens,
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

class _PaceStat extends StatelessWidget {
  const _PaceStat({
    required this.label,
    required this.amount,
    required this.color,
    required this.masked,
    required this.tokens,
  });
  final String label;
  final int amount;
  final Color color;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: PTypo.micro.copyWith(
            color: tokens.fgTertiary,
            fontWeight: PFontWeight.medium,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                krwMasked(amount, masked, mask: '••••'),
                style: PTypo.h4.copyWith(
                  color: color,
                  fontWeight: PFontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!masked) ...[
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  wonUnit(),
                  style: PTypo.caption.copyWith(
                    color: tokens.fgTertiary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatusTiles extends StatelessWidget {
  const _StatusTiles({
    required this.overCount,
    required this.healthyCount,
    required this.tokens,
  });
  final int overCount;
  final int healthyCount;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 카드 다이어트 — 플랫 섹션.
    return PFlatSection(
      title: l.budgetStatusTitle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatusBox(
                  icon: LucideIcons.alertTriangle,
                  label: l.budgetOver,
                  count: overCount,
                  active: overCount > 0,
                  activeColor: tokens.fgExpense,
                  bg: tokens.statusDangerSubtle,
                  tokens: tokens,
                ),
              ),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: _StatusBox(
                  icon: LucideIcons.checkCircle2,
                  label: l.budgetHealthy,
                  count: healthyCount,
                  active: true,
                  activeColor: tokens.fgIncome,
                  bg: tokens.bgSurface,
                  tokens: tokens,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({
    required this.icon,
    required this.label,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.bg,
    required this.tokens,
  });
  final IconData icon;
  final String label;
  final int count;
  final bool active;
  final Color activeColor;
  final Color bg;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final fg = active ? activeColor : tokens.fgTertiary;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(PSpace.x12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PRadius.brLg,
        border: Border.all(
          color: active && bg != tokens.bgSurface
              ? activeColor.withValues(alpha: 0.3)
              : tokens.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: PTypo.caption.copyWith(
                  color: fg,
                  fontWeight: PFontWeight.semi,
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: PTypo.h2.copyWith(
                  color: count > 0 ? activeColor : tokens.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l.expCategory,
                  style: PTypo.bodySm.copyWith(
                    color: tokens.fgTertiary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 카테고리별 예산 카드 — 웹 BudgetPage `ListCard` 정합.
///
/// 개요 페이지는 조회 전용: 헤더는 카드 안('카테고리별 예산' + 'N개 설정됨'),
/// '예산 추가' 버튼·행 탭 편집 없음 — 관리는 상단 설정 버튼 → 예산 설정 페이지에서.
class _CategoryListCard extends StatelessWidget {
  const _CategoryListCard({
    required this.budgets,
    required this.categories,
    required this.spentByCategory,
    required this.masked,
    required this.loading,
    required this.tokens,
    required this.onGoSettings,
    this.warnThreshold = _warnThreshold,
  });
  final List<Budget> budgets;
  final List<ExpenseCategory> categories;
  final Map<int, int> spentByCategory;
  final double warnThreshold;
  final bool masked;
  final bool loading;
  final PorestTokens tokens;
  final VoidCallback onGoSettings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 카드 다이어트 — design 카테고리별 예산: 플랫 섹션(헤드 gap 14) + budget-row 리듬.
    return PFlatSection(
      title: l.budgetByCategory,
      headGap: 14,
      trailing: Text(
        l.budgetCountSet(budgets.length),
        style: PTypo.caption.copyWith(color: tokens.fgTertiary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loading && budgets.isEmpty)
            // 예산 list placeholder — 3 rows (label + progress).
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(height: PSpace.x16),
                    Row(
                      children: const [
                        PSkeleton.line(width: 96, height: 13),
                        Spacer(),
                        PSkeleton.line(width: 80, height: 13),
                      ],
                    ),
                    const SizedBox(height: PSpace.x8),
                    PSkeleton(height: 6, borderRadius: PRadius.brFull),
                  ],
                ],
              ),
            )
          else if (budgets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
              child: Column(
                children: [
                  Text(
                    l.budgetNoCategoryBudgets,
                    style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
                  ),
                  const SizedBox(height: PSpace.x8),
                  // 웹은 ghost + fg-brand-strong override — 앱은 brand quiet 의
                  // 정규 변형인 accent 사용 (fgBrand = fgBrandStrong, 같은 값).
                  PButton(
                    label: l.budgetGoToSettings,
                    variant: PButtonVariant.accent,
                    size: PButtonSize.sm,
                    onPressed: onGoSettings,
                  ),
                ],
              ),
            )
          else
            // 행 리스트 — 구분선 없이 간격 분리 (web rows gap 18 → x16 토큰 보정).
            for (int i = 0; i < budgets.length; i++) ...[
              if (i > 0) const SizedBox(height: PSpace.x16),
              _CategoryRow(
                budget: budgets[i],
                category: categories.byRowId(budgets[i].categoryRowId!),
                spent: spentByCategory[budgets[i].categoryRowId] ?? 0,
                masked: masked,
                tokens: tokens,
                warnThreshold: warnThreshold,
              ),
            ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.budget,
    required this.category,
    required this.spent,
    required this.masked,
    required this.tokens,
    this.warnThreshold = _warnThreshold,
  });
  final Budget budget;
  final ExpenseCategory? category;
  final int spent;
  final bool masked;
  final PorestTokens tokens;
  final double warnThreshold;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final limit = budget.budgetAmount;
    final p = limit > 0 ? (spent / limit) * 100 : 0.0;
    final over = p > 100;
    final warn = p > warnThreshold && !over;
    // 예산 상태 = semantic 색 (초과=error / 경고=warning / 일반=info).
    // *Fg 토큰은 dark에서 light variant 자동 분기.
    final stateColor = over
        ? tokens.statusDangerFg
        : warn
        ? tokens.statusWarningFg
        : tokens.statusInfoFg;
    final iconRaw = category?.icon;
    final colorRaw = category?.color;
    final fg = resolveChartColor(context, colorRaw, fallback: tokens.fgBrand);
    final bg = softBg(context, fg);
    final name =
        category?.categoryName ??
        budget.categoryName ??
        l.budgetCategoryFallback(budget.categoryRowId!);

    // 조회 전용 행 (web BudgetPage 정합) — 편집은 예산 설정 페이지에서.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: PRadius.tile(36),
              ),
              child: Icon(lucideByName(iconRaw), size: 18, color: fg),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: PTypo.body.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    over
                        ? l.budgetOverBy(masked
                              ? krwMasked(spent - limit, masked, mask: '••••')
                              : krwSigned(spent - limit, false, unit: true))
                        : l.budgetRemaining(masked
                              ? krwMasked((limit - spent).clamp(0, limit), masked, mask: '••••')
                              : krwSigned((limit - spent).clamp(0, limit), false, unit: true)),
                    style: PTypo.caption.copyWith(
                      color: over ? tokens.fgExpense : tokens.fgTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  krwMasked(spent, masked, mask: '••••'),
                  style: PTypo.body.copyWith(
                    color: over ? tokens.fgExpense : tokens.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                Text(
                  '/ ${krwMasked(limit, masked, mask: '••••')}',
                  style: PTypo.micro.copyWith(
                    color: tokens.fgTertiary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: PSpace.x8),
        LinearProgressIndicator(
          borderRadius: PRadius.brFull,
          value: (p / 100).clamp(0, 1).toDouble(),
          minHeight: 7,
          backgroundColor: tokens.bgTrack,
          color: stateColor,
        ),
      ],
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({
    required this.async,
    required this.currentYear,
    required this.currentMonth,
    required this.tokens,
    required this.masked,
  });
  final AsyncValue<List<BudgetComplianceMonth>> async;
  final int currentYear;
  final int currentMonth;
  final PorestTokens tokens;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <BudgetComplianceMonth>[];
    final l = AppLocalizations.of(context);
    // 카드 다이어트 — 플랫 섹션.
    return PFlatSection(
      title: l.budgetComplianceTitle,
      headGap: 16,
      trailing: Text(
        l.budgetComplianceSubtitle,
        style: PTypo.caption.copyWith(color: tokens.fgTertiary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (async.isLoading && list.isEmpty)
            const PSkeleton(width: double.infinity, height: 200)
          else if (list.isEmpty)
            SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  l.budgetNoComplianceData,
                  style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: _ComplianceBarChart(
                rows: list,
                currentYear: currentYear,
                currentMonth: currentMonth,
                tokens: tokens,
                masked: masked,
              ),
            ),
        ],
      ),
    );
  }
}

class _ComplianceBarChart extends StatefulWidget {
  const _ComplianceBarChart({
    required this.rows,
    required this.currentYear,
    required this.currentMonth,
    required this.tokens,
    required this.masked,
  });
  final List<BudgetComplianceMonth> rows;
  final int currentYear;
  final int currentMonth;
  final PorestTokens tokens;
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
    final tokens = widget.tokens;
    final currentYear = widget.currentYear;
    final currentMonth = widget.currentMonth;
    final masked = widget.masked;
    final l = AppLocalizations.of(context);
    final maxY = rows.fold<double>(
      100,
      (m, r) => r.compliancePercent > m ? r.compliancePercent : m,
    );
    final yMax = (maxY * 1.15).clamp(100, 1000).toDouble();

    final chart = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yMax,
        minY: 0,
        // % 라벨을 각 막대 바로 위에 상시 표시 — web LabelList(position top) 정합.
        // 툴팁 메커니즘은 상시 라벨에 사용하고(handleBuiltInTouches:false 로 터치가
        // 라벨을 덮지 않게), 터치 상세는 touchCallback → Stack 위 PChartTooltipBox.
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            // tap-up 등 종료 이벤트로 닫으면 탭 직후 바로 사라져 안 보임 →
            // 종료 이벤트는 무시하고, 막대 탭이면 표시 유지 / 빈 영역 탭이면 닫기.
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
              PTypo.micro.copyWith(
                color: tokens.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: tokens.borderSubtle,
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
          // % 라벨은 막대 위 상시 툴팁으로 이동 (web 정합) — 고정 top 행 제거.
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
                    style: PTypo.micro.copyWith(
                      color: last ? tokens.fgPrimary : tokens.fgTertiary,
                      fontWeight: last ? PFontWeight.bold : PFontWeight.medium,
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
              // 상시 % 라벨 (위 barTouchData 투명 툴팁)
              showingTooltipIndicators: const [0],
              barRods: [
                BarChartRodData(
                  toY: rows[i].compliancePercent,
                  // web Cell 정합 — 초과 fg-expense / 이번 달 bg-brand / 과거 border-strong
                  color: rows[i].compliancePercent > 100
                      ? tokens.fgExpense
                      : (rows[i].year == currentYear &&
                            rows[i].month == currentMonth)
                      ? tokens.bgBrand
                      : tokens.borderStrong,
                  // web bar round([6,6,0,0] 리터럴) 정합 — 두께는 모바일 시각 보정 28
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

    // 터치 상세 툴팁 — web ComplianceTooltip 미러 (한도 대비 % + 지출/한도).
    // 위치는 터치 좌표 기준 동적 배치 (PChartTooltipLayer — 화면 밖 clamp/flip).
    return Stack(
      children: [
        chart,
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
                      color: over ? tokens.fgExpense : tokens.bgBrand,
                      label: l.budgetVsLimit,
                      amount: '${r.compliancePercent.toStringAsFixed(1)}%',
                      amountColor: over ? tokens.fgExpense : tokens.fgPrimary,
                    ),
                  ],
                  footer: [
                    PChartTooltipFooterRowData(
                      label: l.expSummaryExpense,
                      value:
                          masked ? '••••' : krwSigned(r.totalSpent, false, unit: true),
                    ),
                    PChartTooltipFooterRowData(
                      label: l.budgetLimit,
                      value:
                          masked ? '••••' : krwSigned(r.totalLimit, false, unit: true),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tokens, required this.onAdd});
  final PorestTokens tokens;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PCard(
      variant: PCardVariant.shadow,
      child: PEmptyState(
        icon: LucideIcons.target,
        message: l.budgetEmptyMonth,
        subMessage: l.budgetEmptyHint,
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x16,
          vertical: PSpace.x32,
        ),
        action: FilledButton.tonalIcon(
          onPressed: onAdd,
          icon: const Icon(LucideIcons.settings, size: 16),
          label: Text(l.budgetSetup),
          style: FilledButton.styleFrom(
            backgroundColor: tokens.bgBrandSubtle,
            foregroundColor: tokens.fgBrandStrong,
          ),
        ),
      ),
    );
  }
}

/// 예산 로딩 skeleton — 로딩-후 실제 렌더 구조(_HeaderCard → _PaceCard →
/// _StatusTiles → _CategoryListCard → _ComplianceCard)와 1:1 정합.
/// 모든 카드는 shadow variant(실제와 동일), 회색 박스는 PSkeleton 프리미티브.
class _BudgetLoadingSkeleton extends StatelessWidget {
  const _BudgetLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        // _HeaderCard — brand-tint surface(실제와 동일 합성, diet 제외).
        PCard(
          variant: PCardVariant.shadow,
          color: Color.alphaBlend(t.bgBrandTint, t.bgSurface),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // title caption
              const PSkeleton.line(width: 96, height: 13),
              const SizedBox(height: 6),
              // description line
              PSkeleton.line(width: double.infinity, height: 12),
              const SizedBox(height: PSpace.x12),
              // 큰 금액 / 상한 (h2 baseline)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  PSkeleton.line(width: 132, height: 28),
                  SizedBox(width: 8),
                  PSkeleton.line(width: 80, height: 14),
                ],
              ),
              const SizedBox(height: PSpace.x12),
              // progress (minHeight 10)
              PSkeleton(height: 10, borderRadius: PRadius.brFull),
              const SizedBox(height: PSpace.x8),
              // %/남은 예산 행
              Row(
                children: const [
                  PSkeleton.line(width: 64, height: 12),
                  Spacer(),
                  PSkeleton.line(width: 96, height: 12),
                ],
              ),
              const SizedBox(height: PSpace.x12),
              // 3-column MiniStat (전체 상한 / 카테고리 할당 / 할당 가능)
              Container(
                padding: const EdgeInsets.only(top: PSpace.x12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: t.borderSubtle)),
                ),
                child: Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: PSpace.x8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            PSkeleton.line(width: 48, height: 10),
                            SizedBox(height: 4),
                            PSkeleton.line(width: 64, height: 14),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        // _PaceCard — 플랫 섹션 스켈레톤 (header + 게이지 + 2-column PaceStat).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PSkeleton.line(width: 72, height: 14),
                  const Spacer(),
                  PSkeleton.line(width: 64, height: 22),
                ],
              ),
              const SizedBox(height: PSpace.x12),
              // 페이스 게이지 (minHeight 12)
              PSkeleton(height: 12, borderRadius: PRadius.brFull),
              const SizedBox(height: PSpace.x8),
              Row(
                children: const [
                  PSkeleton.line(width: 56, height: 12),
                  Spacer(),
                  PSkeleton.line(width: 112, height: 12),
                ],
              ),
              const SizedBox(height: PSpace.x12),
              Container(
                padding: const EdgeInsets.only(top: PSpace.x12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: t.borderSubtle)),
                ),
                child: Row(
                  children: [
                    for (int i = 0; i < 2; i++) ...[
                      if (i > 0) const SizedBox(width: PSpace.x8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            PSkeleton.line(width: 72, height: 10),
                            SizedBox(height: 4),
                            PSkeleton.line(width: 88, height: 20),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        // _StatusTiles — 플랫 섹션 스켈레톤 ('예산 현황' + 2칸 box).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PSkeleton.line(width: 72, height: 14),
              const SizedBox(height: PSpace.x12),
              Row(
                children: [
                  for (int i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: PSpace.x8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(PSpace.x12),
                        decoration: BoxDecoration(
                          color: t.bgSurface,
                          borderRadius: PRadius.brLg,
                          border: Border.all(color: t.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            PSkeleton.line(width: 48, height: 12),
                            SizedBox(height: PSpace.x4),
                            PSkeleton.line(width: 64, height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        // _CategoryListCard — 플랫 섹션 스켈레톤 (헤더 + 구분선 없는 행 리스트).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  PSkeleton.line(width: 128, height: 16),
                  Spacer(),
                  PSkeleton.line(width: 56, height: 12),
                ],
              ),
              const SizedBox(height: PSpace.x16),
              for (int i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(height: PSpace.x16),
                // _CategoryRow — 아이콘(36) + 이름/남은예산 + 금액/한도, progress.
                Row(
                  children: [
                    const PSkeleton(width: 36, height: 36),
                    const SizedBox(width: PSpace.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          PSkeleton.line(width: 96, height: 14),
                          SizedBox(height: 2),
                          PSkeleton.line(width: 72, height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(width: PSpace.x8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        PSkeleton.line(width: 56, height: 14),
                        SizedBox(height: 2),
                        PSkeleton.line(width: 40, height: 10),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: PSpace.x8),
                PSkeleton(height: 7, borderRadius: PRadius.brFull),
              ],
            ],
          ),
        ),
        const SizedBox(height: 36),
        // _ComplianceCard — 플랫 섹션 스켈레톤 (header + 차트 영역 height 200).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PSkeleton.line(width: 144, height: 14),
                  const Spacer(),
                  PSkeleton.line(width: 80, height: 12),
                ],
              ),
              const SizedBox(height: PSpace.x16),
              const PSkeleton(width: double.infinity, height: 200),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: t.statusDangerSubtle,
        borderRadius: PRadius.brLg,
      ),
      child: Column(
        children: [
          Text(message, style: PTypo.bodySm.copyWith(color: t.statusDangerFg)),
          const SizedBox(height: PSpace.x8),
          PButton(
            label: l.actionRetry,
            variant: PButtonVariant.outline,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
