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
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../expense/application/expense_providers.dart';
import '../application/budget_providers.dart';
import '../domain/budget.dart';
import 'budget_edit_dialog.dart';

/// 예산 화면 (More → 예산 push).
///
/// - 월 선택기 + 합계 카드 (총 예산 vs 실제 지출)
/// - 카테고리별 진행률 게이지 (한도 vs 실제)
/// - 행 탭 → BudgetEditDialog 수정/삭제
/// - + FAB → 새 카테고리 예산 추가
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late DateTime _month = monthStart(DateTime.now());

  BudgetMonthKey get _key => (year: _month.year, month: _month.month);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final budgetsAsync = ref.watch(monthBudgetsProvider(_key));
    final expensesAsync = ref.watch(monthExpensesProvider(
        (year: _month.year, month: _month.month)));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('예산'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      floatingActionButton: budgetsAsync.maybeWhen(
        data: (budgets) => FloatingActionButton(
          backgroundColor: t.bgBrand,
          foregroundColor: t.fgOnBrand,
          onPressed: () => showBudgetEditDialog(
            context,
            year: _month.year,
            month: _month.month,
            usedCategoryIds: budgets.map((b) => b.categoryRowId).toSet(),
          ),
          child: const Icon(LucideIcons.plus),
        ),
        orElse: () => null,
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(monthBudgetsProvider(_key));
          ref.invalidate(monthExpensesProvider(
              (year: _month.year, month: _month.month)));
          await ref.read(monthBudgetsProvider(_key).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x80),
          children: [
            // 월 선택기
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() =>
                      _month = DateTime(_month.year, _month.month - 1, 1)),
                  icon: Icon(LucideIcons.chevronLeft, color: t.fgSecondary),
                ),
                Text(yearMonth(_month),
                    style: PTypo.h4.copyWith(color: t.fgPrimary)),
                IconButton(
                  onPressed: () => setState(() =>
                      _month = DateTime(_month.year, _month.month + 1, 1)),
                  icon: Icon(LucideIcons.chevronRight, color: t.fgSecondary),
                ),
              ],
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
                if (budgets.isEmpty) {
                  return _EmptyState(tokens: t);
                }
                final expenses = expensesAsync.value ?? [];
                final spentByCat = <int, int>{};
                for (final e in expenses) {
                  if (e.expenseType != 'EXPENSE') continue;
                  spentByCat.update(
                      e.categoryRowId, (v) => v + e.amount,
                      ifAbsent: () => e.amount);
                }
                final totalLimit =
                    budgets.fold<int>(0, (s, b) => s + b.budgetAmount);
                final totalSpent = budgets.fold<int>(
                    0, (s, b) => s + (spentByCat[b.categoryRowId] ?? 0));

                return Column(
                  children: [
                    _OverallCard(
                      limit: totalLimit,
                      spent: totalSpent,
                      masked: settings.hideAmounts,
                      tokens: t,
                    ),
                    const SizedBox(height: PSpace.x16),
                    Container(
                      decoration: BoxDecoration(
                        color: t.bgSurface,
                        borderRadius: PRadius.brLg,
                        border: Border.all(color: t.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < budgets.length; i++) ...[
                            _BudgetRow(
                              budget: budgets[i],
                              spent: spentByCat[budgets[i].categoryRowId] ?? 0,
                              category: categoriesAsync.value
                                  ?.byRowId(budgets[i].categoryRowId),
                              masked: settings.hideAmounts,
                              tokens: t,
                              onTap: () => showBudgetEditDialog(
                                context,
                                year: _month.year,
                                month: _month.month,
                                edit: budgets[i],
                                usedCategoryIds:
                                    budgets.map((b) => b.categoryRowId).toSet(),
                              ),
                            ),
                            if (i < budgets.length - 1)
                              Divider(
                                  height: 1,
                                  color: t.borderSubtle,
                                  indent: PSpace.x16),
                          ],
                        ],
                      ),
                    ),
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

class _OverallCard extends StatelessWidget {
  const _OverallCard({
    required this.limit,
    required this.spent,
    required this.masked,
    required this.tokens,
  });
  final int limit;
  final int spent;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final pct = limit > 0 ? (spent / limit).clamp(0, 1.5) : 0.0;
    final over = spent > limit;
    final color = over
        ? tokens.statusDanger
        : pct > 0.8
            ? tokens.statusWarning
            : tokens.statusSuccess;
    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: tokens.surfaceHero,
        borderRadius: PRadius.brXl,
        border: Border.all(color: tokens.borderBrand.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('이번달 예산',
                  style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
              const Spacer(),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: PTypo.bodySm.copyWith(
                      color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: PSpace.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(krwMasked(spent, masked),
                  style: PTypo.h2.copyWith(
                      color: tokens.fgPrimary, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(' / ${krwMasked(limit, masked)}',
                    style: PTypo.bodySm.copyWith(color: tokens.fgTertiary)),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          ClipRRect(
            borderRadius: PRadius.brSm,
            child: LinearProgressIndicator(
              value: pct.toDouble().clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: tokens.bgTrack,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.budget,
    required this.spent,
    required this.category,
    required this.masked,
    required this.tokens,
    required this.onTap,
  });
  final Budget budget;
  final int spent;
  final dynamic category; // ExpenseCategory? — soft type
  final bool masked;
  final PorestTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct =
        budget.budgetAmount > 0 ? (spent / budget.budgetAmount).clamp(0, 1.5) : 0.0;
    final over = spent > budget.budgetAmount;
    final barColor = over
        ? tokens.statusDanger
        : pct > 0.8
            ? tokens.statusWarning
            : tokens.statusSuccess;

    final iconRaw = category?.icon as String?;
    final colorRaw = category?.color as String?;
    final fg = parseColor(colorRaw, fallback: tokens.fgBrand);
    final bg = softBg(fg);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(PSpace.x12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration:
                      BoxDecoration(color: bg, borderRadius: PRadius.brSm),
                  alignment: Alignment.center,
                  child: Icon(lucideByName(iconRaw), size: 16, color: fg),
                ),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Text(budget.categoryName ?? '카테고리',
                      style: PTypo.body.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: FontWeight.w500)),
                ),
                Text(
                  '${krwMasked(spent, masked)} / ${krwMasked(budget.budgetAmount, masked)}',
                  style: PTypo.caption.copyWith(color: tokens.fgSecondary),
                ),
              ],
            ),
            const SizedBox(height: PSpace.x8),
            ClipRRect(
              borderRadius: PRadius.brSm,
              child: LinearProgressIndicator(
                value: pct.toDouble().clamp(0, 1).toDouble(),
                minHeight: 6,
                backgroundColor: tokens.bgTrack,
                color: barColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tokens});
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x32),
      child: Column(
        children: [
          Icon(LucideIcons.target, size: 48, color: tokens.fgDisabled),
          const SizedBox(height: PSpace.x12),
          Text('이 달 예산이 없습니다',
              style: PTypo.body.copyWith(color: tokens.fgTertiary)),
          const SizedBox(height: PSpace.x4),
          Text('우하단 + 버튼으로 카테고리별 예산을 설정하세요',
              style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
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
          Text(message, style: PTypo.bodySm.copyWith(color: t.statusDangerFg)),
          const SizedBox(height: PSpace.x8),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
