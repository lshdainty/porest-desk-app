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
import '../../../core/network/api_exception.dart';
import '../application/budget_providers.dart';
import '../domain/budget.dart';
import '../domain/budget_compliance.dart';
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

  /// 전월 예산을 모두 복사. 이미 등록된 카테고리는 건너뛴다 (#258).
  Future<void> _copyFromPreviousMonth(
      BuildContext context, WidgetRef ref) async {
    final prevMonth = DateTime(_month.year, _month.month - 1, 1);
    final prevKey = (year: prevMonth.year, month: prevMonth.month);
    final repo = await ref.read(budgetRepositoryProvider.future);
    try {
      final prev = await repo.list(year: prevKey.year, month: prevKey.month);
      if (prev.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${prevKey.month}월에 등록된 예산이 없습니다')),
        );
        return;
      }
      final cur = await repo.list(year: _key.year, month: _key.month);
      final existingCats = cur.map((b) => b.categoryRowId).toSet();
      final toCreate = prev
          .where((b) => !existingCats.contains(b.categoryRowId))
          .toList();
      if (toCreate.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 모든 카테고리가 복사되어 있습니다')),
        );
        return;
      }
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
      if (ok != true || !context.mounted) return;
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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${toCreate.length}개 예산을 복사했습니다')),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('복사 실패: ${e.message}')),
      );
    }
  }

  /// 이번 달 모든 예산 삭제 (#258).
  Future<void> _clearMonth(BuildContext context, WidgetRef ref) async {
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
    if (ok != true || !context.mounted) return;
    try {
      final repo = await ref.read(budgetRepositoryProvider.future);
      final list = await repo.list(year: _key.year, month: _key.month);
      for (final b in list) {
        await repo.delete(b.rowId);
      }
      ref.invalidate(monthBudgetsProvider(_key));
      ref.invalidate(budgetComplianceProvider(6));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${list.length}개 예산을 삭제했습니다')),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final budgetsAsync = ref.watch(monthBudgetsProvider(_key));
    final expensesAsync = ref.watch(monthExpensesProvider(
        (year: _month.year, month: _month.month)));
    final categoriesAsync = ref.watch(categoriesProvider);
    final complianceAsync = ref.watch(budgetComplianceProvider(6));

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
        actions: [
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.moreVertical, color: t.fgSecondary),
            onSelected: (v) async {
              if (v == 'copyFromPrev') {
                await _copyFromPreviousMonth(context, ref);
              } else if (v == 'clearMonth') {
                await _clearMonth(context, ref);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'copyFromPrev', child: Text('전월 예산 복사')),
              PopupMenuItem(
                value: 'clearMonth',
                child: Text('이번 달 전체 삭제',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
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
                  final cid = e.categoryRowId;
                  if (cid == null) continue;
                  spentByCat.update(cid, (v) => v + e.amount,
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
                    _ComplianceCard(async: complianceAsync, tokens: t),
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

/// 최근 N개월 예산 준수율 카드 — front `BudgetPage` `ComplianceTooltip` 미러.
/// 막대 1개 = 1개월. compliancePercent 100 미만(아래) = 한도 내(success),
/// 100 초과 = 초과(danger). 막대 높이는 percent / 150 비율.
class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.async, required this.tokens});
  final AsyncValue<List<BudgetComplianceMonth>> async;
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
              Icon(LucideIcons.activity, size: 16, color: tokens.fgSecondary),
              const SizedBox(width: 6),
              Text('최근 6개월 예산 준수율',
                  style: PTypo.bodySm.copyWith(
                      color: tokens.fgPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          if (async.isLoading && list.isEmpty)
            const SizedBox(
                height: 120, child: Center(child: CircularProgressIndicator()))
          else if (list.isEmpty)
            SizedBox(
              height: 80,
              child: Center(
                child: Text('데이터 없음',
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final m in list)
                    Expanded(
                      child: _ComplianceBar(month: m, tokens: tokens),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComplianceBar extends StatelessWidget {
  const _ComplianceBar({required this.month, required this.tokens});
  final BudgetComplianceMonth month;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    // 한도 100% 까지는 success, 그 이상은 danger.
    final p = month.compliancePercent.clamp(0, 200).toDouble();
    final overLimit = p > 100;
    final h = (p / 150).clamp(0.05, 1.0); // 시각 비율 (max 150%)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: 80 * h,
                decoration: BoxDecoration(
                  color: overLimit ? tokens.statusDanger : tokens.fgBrand,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('${p.toStringAsFixed(0)}%',
              style: PTypo.micro.copyWith(
                color: overLimit ? tokens.statusDanger : tokens.fgSecondary,
                fontWeight: FontWeight.w700,
              )),
          Text('${month.month}월',
              style: PTypo.micro.copyWith(color: tokens.fgTertiary)),
        ],
      ),
    );
  }
}
