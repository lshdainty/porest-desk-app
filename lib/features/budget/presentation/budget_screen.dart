import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_badge.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense_category.dart';
import '../../stats/application/stats_providers.dart';
import '../../stats/domain/stats_models.dart';
import '../application/budget_providers.dart';
import '../domain/budget.dart';
import '../domain/budget_compliance.dart';
import 'budget_edit_dialog.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';

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

  Future<void> _copyFromPreviousMonth() async {
    final prevMonth = DateTime(_month.year, _month.month - 1, 1);
    final prevKey = (year: prevMonth.year, month: prevMonth.month);
    final repo = await ref.read(budgetRepositoryProvider.future);
    try {
      final prev = await repo.list(year: prevKey.year, month: prevKey.month);
      if (prev.isEmpty) {
        if (!mounted) return;
        showPSnackBar(context, '${prevKey.month}월에 등록된 예산이 없습니다');
        return;
      }
      final cur = await repo.list(year: _key.year, month: _key.month);
      final existingCats = cur.map((b) => b.categoryRowId).toSet();
      final toCreate = prev
          .where((b) => !existingCats.contains(b.categoryRowId))
          .toList();
      if (toCreate.isEmpty) {
        if (!mounted) return;
        showPSnackBar(context, '이미 모든 카테고리가 복사되어 있습니다');
        return;
      }
      if (!mounted) return;
      final ok = await showPConfirmDialog(
        context,
        title: '전월 예산 복사',
        message:
            '${prevKey.month}월의 ${toCreate.length}개 카테고리를 ${_key.month}월로 복사할까요?',
        confirmLabel: '복사',
      );
      if (!ok || !mounted) return;
      for (final b in toCreate) {
        await repo.create(
          categoryRowId: b.categoryRowId,
          budgetAmount: b.budgetAmount,
          budgetYear: _key.year,
          budgetMonth: _key.month,
        );
      }
      ref.invalidate(monthBudgetsProvider(_key));
      ref.invalidate(budgetComplianceProvider(6));
      if (!mounted) return;
      showPSnackBar(
        context,
        '${toCreate.length}개 예산을 복사했습니다',
        severity: PSnackSeverity.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '복사 실패: ${e.message}',
        severity: PSnackSeverity.error,
      );
    }
  }

  Future<void> _clearMonth() async {
    final ok = await showPConfirmDialog(
      context,
      title: '이번 달 전체 삭제',
      message: '${_key.month}월에 등록된 예산을 모두 삭제할까요?',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      final repo = await ref.read(budgetRepositoryProvider.future);
      final list = await repo.list(year: _key.year, month: _key.month);
      for (final b in list) {
        await repo.delete(b.rowId);
      }
      ref.invalidate(monthBudgetsProvider(_key));
      ref.invalidate(budgetComplianceProvider(6));
      if (!mounted) return;
      showPSnackBar(context, '${list.length}개 예산을 삭제했습니다');
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '삭제 실패: ${e.message}',
        severity: PSnackSeverity.error,
      );
    }
  }

  void _openSettings(List<Budget> budgets) {
    final overall = budgets.where((b) => b.categoryRowId == null).toList();
    final hasOverall = overall.isNotEmpty;
    showPSheet<void>(
      context,
      title: '예산 설정',
      contentBuilder: (ctx, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x20,
          vertical: PSpace.x24,
        ),
        children: [
          _SheetTile(
            icon: LucideIcons.target,
            label: hasOverall ? '월 전체 상한 수정' : '월 전체 상한 설정',
            description: '${_key.month}월 전체 지출 상한을 정해요',
            onTap: () {
              Navigator.of(ctx).pop();
              showBudgetEditDialog(
                context,
                year: _key.year,
                month: _key.month,
                edit: hasOverall ? overall.first : null,
                overallNew: !hasOverall,
              );
            },
          ),
          const SizedBox(height: PSpace.x8),
          _SheetTile(
            icon: LucideIcons.plus,
            label: '카테고리 예산 추가',
            description: '카테고리별 한도를 설정해요',
            onTap: () {
              Navigator.of(ctx).pop();
              showBudgetEditDialog(
                context,
                year: _key.year,
                month: _key.month,
                usedCategoryIds: budgets
                    .map((b) => b.categoryRowId)
                    .whereType<int>()
                    .toSet(),
              );
            },
          ),
          const Divider(height: PSpace.x24),
          _SheetTile(
            icon: LucideIcons.copy,
            label: '전월 예산 복사',
            description: '지난달 예산을 그대로 가져와요',
            onTap: () {
              Navigator.of(ctx).pop();
              _copyFromPreviousMonth();
            },
          ),
          const SizedBox(height: PSpace.x8),
          _SheetTile(
            icon: LucideIcons.trash2,
            label: '이번 달 전체 삭제',
            description: '이 달의 모든 예산을 삭제해요',
            destructive: true,
            onTap: () {
              Navigator.of(ctx).pop();
              _clearMonth();
            },
          ),
        ],
      ),
      initialChildSize: 0.55,
      minChildSize: 0.4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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
      backgroundColor: t.bgCanvas,
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
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x20,
            vertical: PSpace.x24,
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
              onSettings: () => _openSettings(budgetsAsync.value ?? []),
            ),
            const SizedBox(height: PSpace.x12),
            budgetsAsync.when(
              loading: () => const _BudgetLoadingSkeleton(),
              error: (e, _) => _ErrorBox(
                message: '예산을 불러오지 못했습니다\n$e',
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
                      onTap: () {
                        if (overallBudget != null) {
                          showBudgetEditDialog(
                            context,
                            year: _key.year,
                            month: _key.month,
                            edit: overallBudget,
                          );
                        } else {
                          showBudgetEditDialog(
                            context,
                            year: _key.year,
                            month: _key.month,
                            overallNew: true,
                          );
                        }
                      },
                    ),
                    if (hasNoData) ...[
                      const SizedBox(height: PSpace.x12),
                      _EmptyState(
                        tokens: t,
                        onAdd: () => _openSettings(budgets),
                      ),
                    ] else ...[
                      const SizedBox(height: PSpace.x12),
                      _PaceCard(
                        pct: pct,
                        daysElapsedPct: daysElapsedPct,
                        dailyActual: dailyActual,
                        dailyTarget: dailyTarget,
                        onTrack: onTrack,
                        masked: settings.hideAmounts,
                        tokens: t,
                      ),
                      const SizedBox(height: PSpace.x12),
                      _StatusTiles(
                        overCount: overList.length,
                        healthyCount: healthyList.length,
                        tokens: t,
                      ),
                      const SizedBox(height: PSpace.x12),
                      _CategoryListCard(
                        budgets: categoryBudgets,
                        categories: categories,
                        spentByCategory: spentByCategory,
                        warnThreshold: warnThreshold,
                        masked: settings.hideAmounts,
                        loading: summaryAsync.isLoading,
                        tokens: t,
                        onAdd: () => _openSettings(budgets),
                        onTap: (b) => showBudgetEditDialog(
                          context,
                          year: _key.year,
                          month: _key.month,
                          edit: b,
                          usedCategoryIds: budgets
                              .map((bb) => bb.categoryRowId)
                              .whereType<int>()
                              .toSet(),
                        ),
                      ),
                      const SizedBox(height: PSpace.x12),
                      _ComplianceCard(
                        async: complianceAsync,
                        currentYear: _month.year,
                        currentMonth: _month.month,
                        tokens: t,
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
          label: '설정',
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
  return showPSheet<DateTime>(
    context,
    title: '월 선택',
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
                          '$viewYear년',
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
                        label: '$m월',
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
                      label: '오늘로',
                      icon: LucideIcons.locateFixed,
                      variant: PButtonVariant.ghost,
                      size: PButtonSize.sm,
                      onPressed: () => Navigator.of(
                        ctx,
                      ).pop(DateTime(now.year, now.month, 1)),
                    ),
                    const Spacer(),
                    PButton(
                      label: '닫기',
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

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = destructive ? t.statusDangerFg : t.fgPrimary;
    final bg = destructive ? t.statusDangerSubtle : t.bgMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x4,
          vertical: PSpace.x8,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, borderRadius: PRadius.tile(36)),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: PTypo.body.copyWith(
                      color: fg,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: t.fgTertiary),
          ],
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
    required this.onTap,
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
  final VoidCallback onTap;
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

    return PCard(
      // 디자인 p-card--brand: surface(#242938) 위에 cobalt @12% 알파 합성 → #2B374D.
      // alphaBlend(틴트, surface) 로 "surface 위 알파"를 명시(라이트/다크 자동).
      variant: PCardVariant.shadow,
      color: Color.alphaBlend(tokens.bgBrandTint, tokens.bgSurface),
      padding: const EdgeInsets.all(PSpace.x16),
      onTap: onTap,
      child: overallBudget == null
          ? _emptyOverall(context)
          : _filledOverall(color),
    );
  }

  Widget _emptyOverall(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$month월 전체 상한',
          style: PTypo.caption.copyWith(
            color: tokens.fgBrandStrong,
            fontWeight: PFontWeight.semi,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '이번 달 전체 지출의 상한이에요 (카테고리 예산이 없는 지출도 포함).',
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
                  '전체 상한이 아직 설정되지 않았어요. 탭해서 한도를 지정하세요.',
                  style: PTypo.bodySm.copyWith(color: tokens.fgSecondary),
                ),
              ),
            ],
          ),
        ),
        if (categoryLimitSum > 0) ...[
          const SizedBox(height: PSpace.x8),
          Text(
            '현재 카테고리 한도 합계: ${krwMasked(categoryLimitSum, masked)}원',
            style: PTypo.caption.copyWith(color: tokens.fgTertiary),
          ),
        ],
      ],
    );
  }

  Widget _filledOverall(Color color) {
    final remaining = totalLimit - totalSpent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$month월 전체 상한',
          style: PTypo.caption.copyWith(
            color: tokens.fgBrandStrong,
            fontWeight: PFontWeight.semi,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '이번 달 전체 지출의 상한이에요 (카테고리 예산이 없는 지출도 포함).',
          style: PTypo.caption.copyWith(color: tokens.fgTertiary),
        ),
        const SizedBox(height: PSpace.x12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                krwMasked(totalSpent, masked),
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
                ' / ${krwMasked(totalLimit, masked)}원',
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
              '${pct.toStringAsFixed(0)}% 사용',
              style: PTypo.caption.copyWith(color: tokens.fgSecondary),
            ),
            const Spacer(),
            Text(
              remaining >= 0
                  ? '남은 예산 ${krwMasked(remaining, masked)}원'
                  : '한도 ${krwMasked(-remaining, masked)}원 초과',
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
                  label: '전체 상한',
                  value: '${krwMasked(overallLimit, masked)}원',
                  color: tokens.fgPrimary,
                  tokens: tokens,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: '카테고리 할당',
                  value: '${krwMasked(categoryLimitSum, masked)}원',
                  color: tokens.fgPrimary,
                  tokens: tokens,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: '할당 가능',
                  value:
                      '${overAllocated ? '−' : '+'}${krwMasked(allocable.abs(), masked)}원',
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
                    '카테고리 한도 합이 전체 상한을 ${krwMasked(categoryLimitSum - overallLimit, masked)}원 초과했어요. 전체 상한을 올리거나 카테고리 한도를 줄여주세요.',
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
    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      variant: PCardVariant.shadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '지출 페이스',
                style: PTypo.body.copyWith(
                  color: tokens.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
              const Spacer(),
              PBadge(
                label: onTrack ? '정상 속도' : '빠른 속도',
                variant: onTrack
                    ? PBadgeVariant.softSuccess
                    : PBadgeVariant.softWarning,
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
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
                '${pct.toStringAsFixed(0)}% 사용',
                style: PTypo.caption.copyWith(color: tokens.fgTertiary),
              ),
              const Spacer(),
              Text(
                '이번 달 ${daysElapsedPct.toStringAsFixed(0)}% 경과 ↑',
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
                    label: '일평균 지출',
                    amount: dailyActual,
                    color: tokens.fgPrimary,
                    masked: masked,
                    tokens: tokens,
                  ),
                ),
                Expanded(
                  child: _PaceStat(
                    label: '남은 일 권장 지출',
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
                krwMasked(amount, masked),
                style: PTypo.h4.copyWith(
                  color: color,
                  fontWeight: PFontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '원',
                style: PTypo.caption.copyWith(
                  color: tokens.fgTertiary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
            ),
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
    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      variant: PCardVariant.shadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '예산 현황',
            style: PTypo.body.copyWith(
              color: tokens.fgPrimary,
              fontWeight: PFontWeight.bold,
            ),
          ),
          const SizedBox(height: PSpace.x12),
          Row(
            children: [
              Expanded(
                child: _StatusBox(
                  icon: LucideIcons.alertTriangle,
                  label: '초과',
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
                  label: '여유',
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
                  '카테고리',
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

class _CategoryListCard extends StatelessWidget {
  const _CategoryListCard({
    required this.budgets,
    required this.categories,
    required this.spentByCategory,
    required this.masked,
    required this.loading,
    required this.tokens,
    required this.onAdd,
    required this.onTap,
    this.warnThreshold = _warnThreshold,
  });
  final List<Budget> budgets;
  final List<ExpenseCategory> categories;
  final Map<int, int> spentByCategory;
  final double warnThreshold;
  final bool masked;
  final bool loading;
  final PorestTokens tokens;
  final VoidCallback onAdd;
  final void Function(Budget) onTap;

  @override
  Widget build(BuildContext context) {
    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      variant: PCardVariant.shadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '카테고리별 예산',
                style: PTypo.body.copyWith(
                  color: tokens.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${budgets.length}개 설정됨',
                style: PTypo.caption.copyWith(color: tokens.fgTertiary),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
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
                    '카테고리별 예산이 없어요',
                    style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
                  ),
                  const SizedBox(height: PSpace.x8),
                  PButton(
                    label: '예산 설정하러 가기 →',
                    variant: PButtonVariant.ghost,
                    size: PButtonSize.sm,
                    onPressed: onAdd,
                  ),
                ],
              ),
            )
          else
            for (int i = 0; i < budgets.length; i++) ...[
              _CategoryRow(
                budget: budgets[i],
                category: categories.byRowId(budgets[i].categoryRowId!),
                spent: spentByCategory[budgets[i].categoryRowId] ?? 0,
                masked: masked,
                tokens: tokens,
                onTap: () => onTap(budgets[i]),
                warnThreshold: warnThreshold,
              ),
              if (i < budgets.length - 1) const SizedBox(height: PSpace.x16),
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
    required this.onTap,
    this.warnThreshold = _warnThreshold,
  });
  final Budget budget;
  final ExpenseCategory? category;
  final int spent;
  final bool masked;
  final PorestTokens tokens;
  final VoidCallback onTap;
  final double warnThreshold;

  @override
  Widget build(BuildContext context) {
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
        '카테고리 #${budget.categoryRowId}';

    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brSm,
      child: Column(
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
                          ? '한도 ${krwMasked(spent - limit, masked)}원 초과'
                          : '남은 예산 ${krwMasked((limit - spent).clamp(0, limit), masked)}원',
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
                    krwMasked(spent, masked),
                    style: PTypo.body.copyWith(
                      color: over ? tokens.fgExpense : tokens.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                  Text(
                    '/ ${krwMasked(limit, masked)}',
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
      ),
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({
    required this.async,
    required this.currentYear,
    required this.currentMonth,
    required this.tokens,
  });
  final AsyncValue<List<BudgetComplianceMonth>> async;
  final int currentYear;
  final int currentMonth;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <BudgetComplianceMonth>[];
    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      variant: PCardVariant.shadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '최근 6개월 예산 이행률',
                style: PTypo.body.copyWith(
                  color: tokens.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '한도 대비 지출 %',
                style: PTypo.caption.copyWith(color: tokens.fgTertiary),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x16),
          if (async.isLoading && list.isEmpty)
            const PSkeleton(width: double.infinity, height: 140)
          else if (list.isEmpty)
            SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  '아직 이행률 데이터가 없어요',
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
              ),
            ),
        ],
      ),
    );
  }
}

class _ComplianceBarChart extends StatelessWidget {
  const _ComplianceBarChart({
    required this.rows,
    required this.currentYear,
    required this.currentMonth,
    required this.tokens,
  });
  final List<BudgetComplianceMonth> rows;
  final int currentYear;
  final int currentMonth;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final maxY = rows.fold<double>(
      100,
      (m, r) => r.compliancePercent > m ? r.compliancePercent : m,
    );
    final yMax = (maxY * 1.15).clamp(100, 1000).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yMax,
        minY: 0,
        groupsSpace: 18,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => tokens.bgSurface,
            tooltipBorder: BorderSide(color: tokens.borderSubtle),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final r = rows[group.x];
              return BarTooltipItem(
                '${r.month}월\n',
                PTypo.micro.copyWith(
                  color: tokens.fgTertiary,
                  fontWeight: PFontWeight.semi,
                ),
                children: [
                  TextSpan(
                    text: '${r.compliancePercent.toStringAsFixed(1)}%',
                    style: PTypo.caption.copyWith(
                      color: r.compliancePercent > 100
                          ? tokens.fgExpense
                          : tokens.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                ],
              );
            },
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
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= rows.length) {
                  return const SizedBox.shrink();
                }
                final r = rows[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${r.compliancePercent.toStringAsFixed(0)}%',
                    style: PTypo.micro.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                );
              },
            ),
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
                    '${r.month}월',
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
              barRods: [
                BarChartRodData(
                  toY: rows[i].compliancePercent,
                  color: rows[i].compliancePercent > 100
                      ? tokens.fgExpense
                      : (rows[i].year == currentYear &&
                            rows[i].month == currentMonth)
                      ? tokens.bgBrand
                      : tokens.borderSubtle,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(PRadius.xs),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tokens, required this.onAdd});
  final PorestTokens tokens;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    return PCard(
      variant: PCardVariant.shadow,
      child: PEmptyState(
        icon: LucideIcons.target,
        message: '이 달 예산이 없습니다',
        subMessage: '전체 상한 또는 카테고리 예산을 설정하세요',
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x16,
          vertical: PSpace.x32,
        ),
        action: FilledButton.tonalIcon(
          onPressed: onAdd,
          icon: const Icon(LucideIcons.settings, size: 16),
          label: const Text('예산 설정'),
          style: FilledButton.styleFrom(
            backgroundColor: tokens.bgBrandSubtle,
            foregroundColor: tokens.fgBrandStrong,
          ),
        ),
      ),
    );
  }
}

/// 예산 리스트 로딩 skeleton — 요약 헤더 카드 + 카테고리 예산 행 4개.
class _BudgetLoadingSkeleton extends StatelessWidget {
  const _BudgetLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        // 헤더 요약 카드
        PCard(
          variant: PCardVariant.shadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PSkeleton.line(width: 80),
                  const Spacer(),
                  PSkeleton.line(width: 56, height: 12),
                ],
              ),
              const SizedBox(height: PSpace.x8),
              PSkeleton(
                width: double.infinity,
                height: 8,
                borderRadius: PRadius.brXs,
              ),
              const SizedBox(height: PSpace.x8),
              Row(
                children: [
                  const PSkeleton.line(width: 60),
                  const Spacer(),
                  PSkeleton.line(width: 48, height: 12),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x12),
        // 카테고리 예산 행
        PCard(
          variant: PCardVariant.bordered,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < 4; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i < 3
                        ? Border(bottom: BorderSide(color: t.borderSubtle))
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: PSpace.x16,
                    vertical: PSpace.x12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const PSkeleton(width: 24, height: 24),
                          const SizedBox(width: PSpace.x8),
                          const PSkeleton.line(width: 80),
                          const Spacer(),
                          PSkeleton.line(width: 60, height: 12),
                        ],
                      ),
                      const SizedBox(height: 6),
                      PSkeleton(
                        width: double.infinity,
                        height: 4,
                        borderRadius: PRadius.brXs,
                      ),
                    ],
                  ),
                ),
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
            label: '다시 시도',
            variant: PButtonVariant.outline,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
