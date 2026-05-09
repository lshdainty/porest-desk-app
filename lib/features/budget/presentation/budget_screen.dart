import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense_category.dart';
import '../../stats/application/stats_providers.dart';
import '../../stats/domain/stats_models.dart';
import '../application/budget_providers.dart';
import '../domain/budget.dart';
import '../domain/budget_compliance.dart';
import 'budget_edit_dialog.dart';

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
  String get _monthEndStr => _ymd(_month.year, _month.month,
      DateTime(_month.year, _month.month + 1, 0).day);

  Future<void> _copyFromPreviousMonth() async {
    final prevMonth = DateTime(_month.year, _month.month - 1, 1);
    final prevKey = (year: prevMonth.year, month: prevMonth.month);
    final repo = await ref.read(budgetRepositoryProvider.future);
    try {
      final prev = await repo.list(year: prevKey.year, month: prevKey.month);
      if (prev.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${prevKey.month}월에 등록된 예산이 없습니다')),
        );
        return;
      }
      final cur = await repo.list(year: _key.year, month: _key.month);
      final existingCats = cur.map((b) => b.categoryRowId).toSet();
      final toCreate =
          prev.where((b) => !existingCats.contains(b.categoryRowId)).toList();
      if (toCreate.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 모든 카테고리가 복사되어 있습니다')),
        );
        return;
      }
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('전월 예산 복사'),
          content: Text(
              '${prevKey.month}월의 ${toCreate.length}개 카테고리를 ${_key.month}월로 복사할까요?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('복사')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${toCreate.length}개 예산을 복사했습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('복사 실패: ${e.message}')),
      );
    }
  }

  Future<void> _clearMonth() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이번 달 전체 삭제'),
        content: Text('${_key.month}월에 등록된 예산을 모두 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: context.tokens.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final repo = await ref.read(budgetRepositoryProvider.future);
      final list = await repo.list(year: _key.year, month: _key.month);
      for (final b in list) {
        await repo.delete(b.rowId);
      }
      ref.invalidate(monthBudgetsProvider(_key));
      ref.invalidate(budgetComplianceProvider(6));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${list.length}개 예산을 삭제했습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
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
        padding: const EdgeInsets.fromLTRB(
            PSpace.x16, 0, PSpace.x16, PSpace.x16),
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
    final settings =
        ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final budgetsAsync = ref.watch(monthBudgetsProvider(_key));
    final summaryAsync = ref.watch(rangeSummaryProvider(
        (startDate: _monthStartStr, endDate: _monthEndStr)));
    final categoriesAsync = ref.watch(categoriesProvider);
    final complianceAsync = ref.watch(budgetComplianceProvider(6));

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('예산'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(monthBudgetsProvider(_key));
          ref.invalidate(rangeSummaryProvider(
              (startDate: _monthStartStr, endDate: _monthEndStr)));
          ref.invalidate(budgetComplianceProvider(6));
          await ref.read(monthBudgetsProvider(_key).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              PSpace.x16, PSpace.x4, PSpace.x16, PSpace.x32),
          children: [
            _MonthBar(
              month: _month,
              onPrev: () => setState(() =>
                  _month = DateTime(_month.year, _month.month - 1, 1)),
              onNext: () => setState(() =>
                  _month = DateTime(_month.year, _month.month + 1, 1)),
              onSettings: () => _openSettings(budgetsAsync.value ?? []),
            ),
            const SizedBox(height: PSpace.x12),
            budgetsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: PSpace.x32),
                child: Center(child: CircularProgressIndicator()),
              ),
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
                    0, (s, b) => s + b.budgetAmount);
                final overallLimit = overallBudget?.budgetAmount ?? 0;
                final totalLimit = overallBudget != null
                    ? overallLimit
                    : categoryLimitSum;
                final pct = totalLimit > 0
                    ? (totalExpense / totalLimit) * 100
                    : 0.0;
                final allocable = overallLimit - categoryLimitSum;
                final overAllocated = overallBudget != null &&
                    categoryLimitSum > overallLimit;

                final today = DateTime.now();
                final daysInMonth =
                    DateTime(_month.year, _month.month + 1, 0).day;
                final dayOfMonth = (today.year == _month.year &&
                        today.month == _month.month)
                    ? today.day
                    : daysInMonth;
                final daysElapsedPct = (dayOfMonth / daysInMonth) * 100;
                final daysRemaining = (daysInMonth - dayOfMonth)
                    .clamp(1, daysInMonth)
                    .toInt();
                final dailyActual =
                    (totalExpense / dayOfMonth.clamp(1, daysInMonth))
                        .round();
                final dailyTarget = ((totalLimit - totalExpense)
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
                      (spent / b.budgetAmount) * 100 <= _warnThreshold;
                }).toList();

                final hasNoData = overallBudget == null &&
                    categoryBudgets.isEmpty;

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
      map.update(cid, (v) => v + c.totalAmount,
          ifAbsent: () => c.totalAmount);
    }
    final pid = c.parentCategoryRowId;
    if (pid != null) {
      map.update(pid, (v) => v + c.totalAmount,
          ifAbsent: () => c.totalAmount);
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
  });
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: Icon(LucideIcons.chevronLeft, color: t.fgSecondary),
        ),
        Expanded(
          child: Center(
            child: Text(yearMonth(month),
                style: PTypo.h4.copyWith(color: t.fgPrimary)),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(LucideIcons.chevronRight, color: t.fgSecondary),
        ),
        const SizedBox(width: PSpace.x4),
        FilledButton.tonalIcon(
          onPressed: onSettings,
          icon: const Icon(LucideIcons.settings, size: 16),
          label: const Text('예산 설정'),
          style: FilledButton.styleFrom(
            backgroundColor: t.bgBrandSubtle,
            foregroundColor: t.fgBrandStrong,
            padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x12, vertical: PSpace.x8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: PRadius.brMd),
          ),
        ),
      ],
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
            horizontal: PSpace.x4, vertical: PSpace.x8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: bg, borderRadius: PRadius.brMd),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: PTypo.body.copyWith(
                          color: fg, fontWeight: PFontWeight.semi)),
                  const SizedBox(height: 2),
                  Text(description,
                      style:
                          PTypo.caption.copyWith(color: t.fgTertiary)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: t.fgTertiary),
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

  @override
  Widget build(BuildContext context) {
    final color = pct > 100
        ? tokens.statusDanger
        : pct > _warnThreshold
            ? tokens.statusWarning
            : tokens.fgBrand;

    return InkWell(
      borderRadius: PRadius.brXl,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(PSpace.x16),
        decoration: BoxDecoration(
          color: tokens.surfaceHero,
          borderRadius: PRadius.brXl,
          border: Border.all(
              color: tokens.borderBrand.withValues(alpha: 0.3)),
        ),
        child: overallBudget == null
            ? _emptyOverall(context)
            : _filledOverall(color),
      ),
    );
  }

  Widget _emptyOverall(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$month월 전체 상한',
            style: PTypo.caption.copyWith(
                color: tokens.fgBrandStrong,
                fontWeight: PFontWeight.semi)),
        const SizedBox(height: 4),
        Text('이번 달 전체 지출의 상한이에요 (카테고리 예산이 없는 지출도 포함).',
            style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
        const SizedBox(height: PSpace.x12),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x12, vertical: PSpace.x8),
          decoration: BoxDecoration(
              color: tokens.bgSurface,
              borderRadius: PRadius.brMd,
              border: Border.all(color: tokens.borderSubtle)),
          child: Row(
            children: [
              Icon(LucideIcons.target, size: 14, color: tokens.fgBrand),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '전체 상한이 아직 설정되지 않았어요. 탭해서 한도를 지정하세요.',
                  style: PTypo.bodySm
                      .copyWith(color: tokens.fgSecondary),
                ),
              ),
            ],
          ),
        ),
        if (categoryLimitSum > 0) ...[
          const SizedBox(height: PSpace.x8),
          Text(
              '현재 카테고리 한도 합계: ${krwMasked(categoryLimitSum, masked)}원',
              style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
        ],
      ],
    );
  }

  Widget _filledOverall(Color color) {
    final remaining = totalLimit - totalSpent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$month월 전체 상한',
            style: PTypo.caption.copyWith(
                color: tokens.fgBrandStrong,
                fontWeight: PFontWeight.semi)),
        const SizedBox(height: 4),
        Text('이번 달 전체 지출의 상한이에요 (카테고리 예산이 없는 지출도 포함).',
            style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
        const SizedBox(height: PSpace.x12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(krwMasked(totalSpent, masked),
                  style: PTypo.h2.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.heavy),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(' / ${krwMasked(totalLimit, masked)}원',
                  style: PTypo.bodySm.copyWith(color: tokens.fgSecondary)),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x12),
        ClipRRect(
          borderRadius: PRadius.brSm,
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0, 1).toDouble(),
            minHeight: 10,
            backgroundColor: tokens.bgTrack,
            color: color,
          ),
        ),
        const SizedBox(height: PSpace.x8),
        Row(
          children: [
            Text('${pct.toStringAsFixed(0)}% 사용',
                style:
                    PTypo.caption.copyWith(color: tokens.fgSecondary)),
            const Spacer(),
            Text(
                remaining >= 0
                    ? '남은 예산 ${krwMasked(remaining, masked)}원'
                    : '한도 ${krwMasked(-remaining, masked)}원 초과',
                style: PTypo.caption.copyWith(
                    color: remaining >= 0
                        ? tokens.fgSecondary
                        : tokens.fgExpense)),
          ],
        ),
        const SizedBox(height: PSpace.x12),
        Container(
          padding: const EdgeInsets.only(top: PSpace.x12),
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: tokens.borderSubtle)),
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
                  color: overAllocated
                      ? tokens.fgExpense
                      : tokens.fgIncome,
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
                horizontal: PSpace.x12, vertical: PSpace.x8),
            decoration: BoxDecoration(
              color: tokens.statusDangerSubtle,
              borderRadius: PRadius.brMd,
              border: Border.all(
                  color: tokens.fgExpense.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.alertTriangle,
                    size: 14, color: tokens.statusDangerFg),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '카테고리 한도 합이 전체 상한을 ${krwMasked(categoryLimitSum - overallLimit, masked)}원 초과했어요. 전체 상한을 올리거나 카테고리 한도를 줄여주세요.',
                    style: PTypo.caption
                        .copyWith(color: tokens.statusDangerFg),
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
        Text(label,
            style: PTypo.micro.copyWith(
                color: tokens.fgTertiary,
                fontWeight: PFontWeight.medium)),
        const SizedBox(height: 2),
        Text(value,
            style: PTypo.bodySm.copyWith(
                color: color, fontWeight: PFontWeight.bold),
            overflow: TextOverflow.ellipsis),
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
          Row(
            children: [
              Text('지출 페이스',
                  style: PTypo.body.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: PSpace.x8, vertical: 2),
                decoration: BoxDecoration(
                  color: onTrack
                      ? tokens.statusSuccessSubtle
                      : tokens.statusWarningSubtle,
                  borderRadius: PRadius.brPill,
                ),
                child: Text(onTrack ? '정상 속도' : '빠른 속도',
                    style: PTypo.micro.copyWith(
                      color: onTrack
                          ? tokens.statusSuccessFg
                          : tokens.statusWarningFg,
                      fontWeight: PFontWeight.semi,
                    )),
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
                      child: ClipRRect(
                        borderRadius: PRadius.brPill,
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0, 1).toDouble(),
                          minHeight: 12,
                          backgroundColor: tokens.bgTrack,
                          color: pct > 100
                              ? tokens.fgExpense
                              : tokens.bgBrand,
                        ),
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
                          borderRadius: PRadius.brXs2,
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
              Text('${pct.toStringAsFixed(0)}% 사용',
                  style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
              const Spacer(),
              Text('이번 달 ${daysElapsedPct.toStringAsFixed(0)}% 경과 ↑',
                  style:
                      PTypo.caption.copyWith(color: tokens.fgTertiary)),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          Container(
            padding: const EdgeInsets.only(top: PSpace.x12),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: tokens.borderSubtle)),
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
        Text(label,
            style: PTypo.micro.copyWith(
                color: tokens.fgTertiary,
                fontWeight: PFontWeight.medium)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(krwMasked(amount, masked),
                  style: PTypo.h4.copyWith(
                      color: color, fontWeight: PFontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('원',
                  style: PTypo.caption.copyWith(
                      color: tokens.fgTertiary,
                      fontWeight: PFontWeight.semi)),
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
          Text('예산 현황',
              style: PTypo.body.copyWith(
                  color: tokens.fgPrimary,
                  fontWeight: PFontWeight.bold)),
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
                : tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
              Text(label,
                  style: PTypo.caption.copyWith(
                      color: fg, fontWeight: PFontWeight.semi)),
            ],
          ),
          const SizedBox(height: PSpace.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$count',
                  style: PTypo.h2.copyWith(
                      color: count > 0 ? activeColor : tokens.fgPrimary,
                      fontWeight: PFontWeight.heavy)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('카테고리',
                    style: PTypo.bodySm.copyWith(
                        color: tokens.fgTertiary,
                        fontWeight: PFontWeight.semi)),
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
  });
  final List<Budget> budgets;
  final List<ExpenseCategory> categories;
  final Map<int, int> spentByCategory;
  final bool masked;
  final bool loading;
  final PorestTokens tokens;
  final VoidCallback onAdd;
  final void Function(Budget) onTap;

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
          Row(
            children: [
              Text('카테고리별 예산',
                  style: PTypo.body.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.bold)),
              const SizedBox(width: PSpace.x8),
              Text('${budgets.length}개 설정됨',
                  style:
                      PTypo.caption.copyWith(color: tokens.fgTertiary)),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          if (loading && budgets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
              child: Center(
                child: Text('불러오는 중…',
                    style: PTypo.bodySm
                        .copyWith(color: tokens.fgTertiary)),
              ),
            )
          else if (budgets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
              child: Column(
                children: [
                  Text('카테고리별 예산이 없어요',
                      style: PTypo.bodySm
                          .copyWith(color: tokens.fgTertiary)),
                  const SizedBox(height: PSpace.x8),
                  TextButton(
                    onPressed: onAdd,
                    style: TextButton.styleFrom(
                        foregroundColor: tokens.fgBrandStrong),
                    child: const Text('예산 설정하러 가기 →'),
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
              ),
              if (i < budgets.length - 1)
                const SizedBox(height: PSpace.x16),
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
  });
  final Budget budget;
  final ExpenseCategory? category;
  final int spent;
  final bool masked;
  final PorestTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final limit = budget.budgetAmount;
    final p = limit > 0 ? (spent / limit) * 100 : 0.0;
    final over = p > 100;
    final warn = p > _warnThreshold && !over;
    final stateColor = over
        ? tokens.fgExpense
        : warn
            ? tokens.statusWarning
            : tokens.fgBrand;
    final iconRaw = category?.icon;
    final colorRaw = category?.color;
    final fg = parseColor(colorRaw, fallback: tokens.fgBrand);
    final bg = softBg(fg);
    final name =
        category?.categoryName ?? budget.categoryName ?? '카테고리 #${budget.categoryRowId}';

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
                decoration:
                    BoxDecoration(color: bg, borderRadius: PRadius.brMd),
                child: Icon(lucideByName(iconRaw), size: 18, color: fg),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: PTypo.body.copyWith(
                            color: tokens.fgPrimary,
                            fontWeight: PFontWeight.semi),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      over
                          ? '한도 ${krwMasked(spent - limit, masked)}원 초과'
                          : '남은 예산 ${krwMasked((limit - spent).clamp(0, limit), masked)}원',
                      style: PTypo.caption.copyWith(
                          color: over
                              ? tokens.fgExpense
                              : tokens.fgTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PSpace.x8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(krwMasked(spent, masked),
                      style: PTypo.body.copyWith(
                        color:
                            over ? tokens.fgExpense : tokens.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      )),
                  Text('/ ${krwMasked(limit, masked)}',
                      style: PTypo.micro.copyWith(
                          color: tokens.fgTertiary,
                          fontWeight: PFontWeight.medium)),
                ],
              ),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          ClipRRect(
            borderRadius: PRadius.brSm,
            child: LinearProgressIndicator(
              value: (p / 100).clamp(0, 1).toDouble(),
              minHeight: 7,
              backgroundColor: tokens.bgTrack,
              color: stateColor,
            ),
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
          Row(
            children: [
              Text('최근 6개월 예산 이행률',
                  style: PTypo.body.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.bold)),
              const Spacer(),
              Text('한도 대비 지출 %',
                  style:
                      PTypo.caption.copyWith(color: tokens.fgTertiary)),
            ],
          ),
          const SizedBox(height: PSpace.x16),
          if (async.isLoading && list.isEmpty)
            const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()))
          else if (list.isEmpty)
            SizedBox(
              height: 80,
              child: Center(
                child: Text('아직 이행률 데이터가 없어요',
                    style:
                        PTypo.caption.copyWith(color: tokens.fgTertiary)),
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
        100, (m, r) => r.compliancePercent > m ? r.compliancePercent : m);
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
                horizontal: 10, vertical: 6),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final r = rows[group.x];
              return BarTooltipItem(
                '${r.month}월\n',
                PTypo.micro.copyWith(
                    color: tokens.fgTertiary,
                    fontWeight: PFontWeight.semi),
                children: [
                  TextSpan(
                    text:
                        '${r.compliancePercent.toStringAsFixed(1)}%',
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
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
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
                          fontWeight: PFontWeight.bold)),
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
                final last =
                    r.year == currentYear && r.month == currentMonth;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${r.month}월',
                      style: PTypo.micro.copyWith(
                        color: last
                            ? tokens.fgPrimary
                            : tokens.fgTertiary,
                        fontWeight: last
                            ? PFontWeight.bold
                            : PFontWeight.medium,
                      )),
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
                      top: Radius.circular(PRadius.xs)),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x32),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.target, size: 48, color: tokens.fgDisabled),
          const SizedBox(height: PSpace.x12),
          Text('이 달 예산이 없습니다',
              style: PTypo.body.copyWith(color: tokens.fgTertiary)),
          const SizedBox(height: PSpace.x4),
          Text('전체 상한 또는 카테고리 예산을 설정하세요',
              style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
          const SizedBox(height: PSpace.x12),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(LucideIcons.settings, size: 16),
            label: const Text('예산 설정'),
            style: FilledButton.styleFrom(
              backgroundColor: tokens.bgBrandSubtle,
              foregroundColor: tokens.fgBrandStrong,
            ),
          ),
        ],
      ),
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
          Text(message,
              style:
                  PTypo.bodySm.copyWith(color: t.statusDangerFg)),
          const SizedBox(height: PSpace.x8),
          OutlinedButton(
              onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
