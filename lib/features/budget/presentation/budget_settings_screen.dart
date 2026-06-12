import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/budget/domain/budget.dart';
import 'package:porest_desk_app/features/budget/presentation/budget_edit_dialog.dart';
import 'package:porest_desk_app/features/budget/presentation/budget_screen.dart'
    show showMonthPickerSheet;

/// 카테고리별 예산 상태 경고 임계값 — 웹 `BudgetManager.tsx` 정합 (관리 화면은 고정 85%).
/// (개요 화면 `BudgetScreen` 은 사용자 설정 임계값을 따름.)
const double _warnThreshold = 85;

/// 예산 설정 화면 — 웹 `BudgetManager.tsx`(설정 > 예산 설정) 미러.
///
/// 예산 개요(`BudgetScreen`)의 설정 버튼·"예산 설정하러 가기"·설정 메뉴 '예산 설정'
/// 에서 push 진입한다. 월 선택 + 지난달 복사, 월 총 예산 카드(수정), 카테고리별
/// 예산 리스트(추가·수정·삭제)를 한 페이지에서 제공한다.
class BudgetSettingsScreen extends ConsumerStatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  ConsumerState<BudgetSettingsScreen> createState() =>
      _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends ConsumerState<BudgetSettingsScreen> {
  late DateTime _month = monthStart(DateTime.now());
  // 지난달 복사 진행 중 — 버튼 스피너 표시 (웹 ConfirmDialog loading 정합).
  bool _copying = false;

  BudgetMonthKey get _key => (year: _month.year, month: _month.month);

  String get _monthStartStr => _ymd(_month.year, _month.month, 1);
  String get _monthEndStr => _ymd(
    _month.year,
    _month.month,
    DateTime(_month.year, _month.month + 1, 0).day,
  );

  /// 지난달 예산 복사 — 웹 BudgetManager `copyFromLastMonth` 정합.
  ///
  /// 클릭 즉시(이미 로드된 [prevBudgets] 사용, 재조회 없음) 확인 다이얼로그를 띄우고,
  /// 확인 시 버튼에 스피너(`_copying`)를 표시한 채 복사한다. 같은 key(전체 상한 |
  /// 카테고리)의 이번 달 예산은 **덮어쓰기**(update), 없으면 생성(create).
  Future<void> _copyFromPreviousMonth(
    List<Budget> prevBudgets,
    List<Budget> curBudgets,
  ) async {
    if (prevBudgets.isEmpty) return; // 버튼이 비활성이라 도달 불가 — 방어.
    final prevMonth = DateTime(_month.year, _month.month - 1, 1);
    final ok = await showPConfirmDialog(
      context,
      title: '지난달 예산 복사',
      message:
          '${prevMonth.year}년 ${prevMonth.month}월 예산 한도(${prevBudgets.length}개)를 '
          '${_key.year}년 ${_key.month}월로 복사해요. 이번 달에 이미 있는 예산은 덮어써집니다.',
      confirmLabel: '복사',
    );
    if (!ok || !mounted) return;
    setState(() => _copying = true);
    try {
      final repo = await ref.read(budgetRepositoryProvider.future);
      // 이번 달 기존 예산 key(overall|categoryRowId) → 같은 key 는 덮어쓰기.
      final existingByKey = <String, Budget>{
        for (final b in curBudgets) '${b.categoryRowId ?? 'overall'}': b,
      };
      for (final p in prevBudgets) {
        final existing = existingByKey['${p.categoryRowId ?? 'overall'}'];
        if (existing != null) {
          await repo.update(id: existing.rowId, budgetAmount: p.budgetAmount);
        } else {
          await repo.create(
            categoryRowId: p.categoryRowId,
            budgetAmount: p.budgetAmount,
            budgetYear: _key.year,
            budgetMonth: _key.month,
          );
        }
      }
      ref.invalidate(monthBudgetsProvider(_key));
      ref.invalidate(budgetComplianceProvider(6));
      if (!mounted) return;
      showPSnackBar(
        context,
        '${prevBudgets.length}개 예산을 복사했습니다',
        severity: PSnackSeverity.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '복사 실패: ${e.message}',
        severity: PSnackSeverity.error,
      );
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  void _editOverall(Budget? overallBudget) {
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
  }

  void _addCategory(List<Budget> budgets) {
    showBudgetEditDialog(
      context,
      year: _key.year,
      month: _key.month,
      usedCategoryIds:
          budgets.map((b) => b.categoryRowId).whereType<int>().toSet(),
    );
  }

  void _editCategory(Budget budget, List<Budget> budgets) {
    showBudgetEditDialog(
      context,
      year: _key.year,
      month: _key.month,
      edit: budget,
      usedCategoryIds:
          budgets.map((b) => b.categoryRowId).whereType<int>().toSet(),
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
    // 지난달 복사 버튼 사전 비활성 — 전월 예산이 없거나 로딩 중이면 끈다 (웹 정합).
    final prevMonth = DateTime(_month.year, _month.month - 1, 1);
    final prevBudgetsAsync =
        ref.watch(monthBudgetsProvider((year: prevMonth.year, month: prevMonth.month)));
    final prevBudgets = prevBudgetsAsync.value ?? const <Budget>[];
    final curBudgets = budgetsAsync.value ?? const <Budget>[];
    final copyEnabled = prevBudgets.isNotEmpty;

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: const Text('예산 설정'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
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
          await ref.read(monthBudgetsProvider(_key).future);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x20,
            vertical: PSpace.x24,
          ),
          children: [
            // 월 선택 + 지난달 복사 (웹 BudgetManager 모바일 헤더 정합).
            _MonthBar(
              month: _month,
              onPrev: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1, 1),
              ),
              onNext: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1, 1),
              ),
              onPickMonth: (m) => setState(() => _month = m),
              copyEnabled: copyEnabled,
              copying: _copying,
              onCopyPrev: () =>
                  _copyFromPreviousMonth(prevBudgets, curBudgets),
            ),
            const SizedBox(height: PSpace.x12),
            budgetsAsync.when(
              loading: () => const _LoadingSkeleton(),
              error: (e, _) => _ErrorBox(
                message: '예산을 불러오지 못했습니다\n$e',
                onRetry: () => ref.invalidate(monthBudgetsProvider(_key)),
              ),
              data: (budgets) {
                final categories = categoriesAsync.value ?? const [];
                final summary = summaryAsync.value;
                final spentByCategory = _spentByCategoryFromSummary(summary);
                final totalSpent = summary?.totalExpense ?? 0;

                Budget? overallBudget;
                final categoryBudgets = <Budget>[];
                for (final b in budgets) {
                  if (b.categoryRowId == null) {
                    overallBudget = b;
                  } else {
                    categoryBudgets.add(b);
                  }
                }

                final monthlyLimit = overallBudget?.budgetAmount ?? 0;
                final categoryLimitSum =
                    categoryBudgets.fold<int>(0, (s, b) => s + b.budgetAmount);
                // 할당 가능 = 월 전체 상한 − 카테고리 한도 합 (음수면 초과 할당).
                final remaining = monthlyLimit - categoryLimitSum;

                // 예산 추가 가능 카테고리 = EXPENSE 최상위(부모)만 — 전부 보유 시 비활성화.
                final usedIds =
                    categoryBudgets.map((b) => b.categoryRowId).whereType<int>().toSet();
                final selectable = categories
                    .where((c) => c.expenseType == 'EXPENSE' && c.parentRowId == null)
                    .toList();
                final allBudgeted = selectable.isNotEmpty &&
                    selectable.every((c) => usedIds.contains(c.rowId));

                return Column(
                  children: [
                    _TotalBudgetCard(
                      month: _month.month,
                      overallBudget: overallBudget,
                      monthlyLimit: monthlyLimit,
                      totalSpent: totalSpent,
                      categoryLimitSum: categoryLimitSum,
                      remaining: remaining,
                      masked: settings.hideAmounts,
                      tokens: t,
                      onEdit: () => _editOverall(overallBudget),
                    ),
                    const SizedBox(height: PSpace.x16),
                    _CategoryListCard(
                      budgets: categoryBudgets,
                      categories: categories,
                      spentByCategory: spentByCategory,
                      masked: settings.hideAmounts,
                      loading: summaryAsync.isLoading,
                      // 웹 정합: 카테고리 로딩 중에도 추가 비활성(빈 칩 다이얼로그 방지).
                      addDisabled: allBudgeted || categoriesAsync.isLoading,
                      tokens: t,
                      onAdd: () => _addCategory(budgets),
                      onTap: (b) => _editCategory(b, budgets),
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

/// 월 선택 bar — prev/picker/next + 지난달 복사 버튼.
class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onPickMonth,
    required this.copyEnabled,
    required this.copying,
    required this.onCopyPrev,
  });
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onPickMonth;
  final bool copyEnabled;
  final bool copying;
  final VoidCallback onCopyPrev;

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
          label: '지난달 복사',
          icon: LucideIcons.copy,
          variant: PButtonVariant.secondary,
          size: PButtonSize.sm,
          loading: copying,
          onPressed: copyEnabled ? onCopyPrev : null,
        ),
      ],
    );
  }
}

/// 월 총 예산 카드 — 웹 BudgetManager 상단 카드 정합 (brand-tint, 수정 버튼, 3 통계).
class _TotalBudgetCard extends StatelessWidget {
  const _TotalBudgetCard({
    required this.month,
    required this.overallBudget,
    required this.monthlyLimit,
    required this.totalSpent,
    required this.categoryLimitSum,
    required this.remaining,
    required this.masked,
    required this.tokens,
    required this.onEdit,
  });
  final int month;
  final Budget? overallBudget;
  final int monthlyLimit;
  final int totalSpent;
  final int categoryLimitSum;
  final int remaining;
  final bool masked;
  final PorestTokens tokens;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final pct = monthlyLimit > 0 ? (totalSpent / monthlyLimit) * 100 : 0.0;
    return PCard(
      // 디자인 p-card--brand: surface 위 cobalt @12% 알파 합성 (라이트/다크 자동).
      variant: PCardVariant.shadow,
      color: Color.alphaBlend(tokens.bgBrandTint, tokens.bgSurface),
      padding: const EdgeInsets.all(PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$month월 총 예산',
                      style: PTypo.caption.copyWith(
                        color: tokens.fgBrandStrong,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (overallBudget != null)
                      Text(
                        masked
                            ? '••••'
                            : '${krwMasked(monthlyLimit, masked)}원',
                        style: PTypo.h2.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: PFontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        '설정되지 않음',
                        style: PTypo.bodyLg.copyWith(
                          color: tokens.fgTertiary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: PSpace.x8),
              PButton(
                label: overallBudget != null ? '수정' : '예산 설정',
                icon: overallBudget != null
                    ? LucideIcons.pencil
                    : LucideIcons.plus,
                variant: PButtonVariant.ghost,
                size: PButtonSize.sm,
                onPressed: onEdit,
              ),
            ],
          ),
          if (overallBudget != null) ...[
            const SizedBox(height: PSpace.x12),
            LinearProgressIndicator(
              borderRadius: PRadius.brFull,
              value: (pct / 100).clamp(0, 1).toDouble(),
              minHeight: 10,
              backgroundColor: tokens.bgTrack,
              // 웹 BudgetManager 상단 카드 진행바는 상태 클래스 없이 base
              // `.budget-bar__fill`(--status-info-fg) 고정 — 초과해도 색 안 바뀜.
              color: tokens.statusInfoFg,
            ),
          ],
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
                    label: '사용',
                    value: krwMasked(totalSpent, masked, mask: '••••'),
                    color: tokens.fgPrimary,
                    tokens: tokens,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: '할당됨',
                    value: krwMasked(categoryLimitSum, masked, mask: '••••'),
                    color: tokens.fgPrimary,
                    tokens: tokens,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: '할당 가능',
                    value: krwSigned(
                      remaining.abs(),
                      masked,
                      sign: remaining >= 0 ? '+' : '−',
                      mask: '••••',
                    ),
                    color: remaining < 0 ? tokens.fgExpense : tokens.fgIncome,
                    tokens: tokens,
                  ),
                ),
              ],
            ),
          ),
          if (overallBudget != null && remaining < 0) ...[
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
                          ? '카테고리 한도 합이 전체 상한을 ${krwMasked(-remaining, masked, mask: '••••')} 초과했어요. 전체 상한을 올리거나 카테고리 한도를 줄여주세요.'
                          : '카테고리 한도 합이 전체 상한을 ${krwMasked(-remaining, masked)}원 초과했어요. 전체 상한을 올리거나 카테고리 한도를 줄여주세요.',
                      style: PTypo.caption.copyWith(color: tokens.statusDangerFg),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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

/// 카테고리별 예산 리스트 — 헤더(개수 + 예산 추가) + 행 리스트(탭하여 수정/삭제).
class _CategoryListCard extends StatelessWidget {
  const _CategoryListCard({
    required this.budgets,
    required this.categories,
    required this.spentByCategory,
    required this.masked,
    required this.loading,
    required this.addDisabled,
    required this.tokens,
    required this.onAdd,
    required this.onTap,
  });
  final List<Budget> budgets;
  final List<ExpenseCategory> categories;
  final Map<int, int> spentByCategory;
  final bool masked;
  final bool loading;
  final bool addDisabled;
  final PorestTokens tokens;
  final VoidCallback onAdd;
  final void Function(Budget) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '카테고리별 예산 · ${budgets.length}개',
              style: PTypo.body.copyWith(
                color: tokens.fgPrimary,
                fontWeight: PFontWeight.bold,
              ),
            ),
            const Spacer(),
            PButton(
              label: '예산 추가',
              icon: LucideIcons.plus,
              variant: PButtonVariant.accent,
              size: PButtonSize.sm,
              onPressed: addDisabled ? null : onAdd,
            ),
          ],
        ),
        const SizedBox(height: PSpace.x8),
        PCard(
          padding: const EdgeInsets.all(PSpace.x16),
          variant: PCardVariant.shadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loading && budgets.isEmpty)
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
                  child: Center(
                    child: Text(
                      '설정된 카테고리 예산이 없어요',
                      style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
                    ),
                  ),
                )
              else
                for (int i = 0; i < budgets.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: PSpace.x12),
                    Divider(height: 1, thickness: 1, color: tokens.borderSubtle),
                    const SizedBox(height: PSpace.x12),
                  ],
                  _CategoryRow(
                    budget: budgets[i],
                    category: categories.byRowId(budgets[i].categoryRowId!),
                    spent: spentByCategory[budgets[i].categoryRowId] ?? 0,
                    masked: masked,
                    tokens: tokens,
                    onTap: () => onTap(budgets[i]),
                  ),
                ],
            ],
          ),
        ),
      ],
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
        ? tokens.statusDangerFg
        : warn
        ? tokens.statusWarningFg
        : tokens.statusInfoFg;
    final fg = resolveChartColor(context, category?.color, fallback: tokens.fgBrand);
    final bg = softBg(context, fg);
    final name = category?.categoryName ??
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
                child: Icon(lucideByName(category?.icon), size: 18, color: fg),
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
                          ? (masked
                                ? '한도 ${krwMasked(spent - limit, masked, mask: '••••')} 초과'
                                : '한도 ${krwMasked(spent - limit, masked)}원 초과')
                          : (masked
                                ? '남은 예산 ${krwMasked((limit - spent).clamp(0, limit), masked, mask: '••••')}'
                                : '남은 예산 ${krwMasked((limit - spent).clamp(0, limit), masked)}원'),
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
      ),
    );
  }
}

/// 로딩 스켈레톤 — 월 총 예산 카드 + 카테고리 리스트 3행.
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PCard(
          padding: const EdgeInsets.all(PSpace.x16),
          variant: PCardVariant.shadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              PSkeleton.line(width: 72, height: 12),
              SizedBox(height: PSpace.x8),
              PSkeleton.line(width: 160, height: 28),
              SizedBox(height: PSpace.x12),
              PSkeleton(height: 10, borderRadius: PRadius.brFull),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),
        const PSkeleton.line(width: 140, height: 16),
        const SizedBox(height: PSpace.x8),
        PCard(
          padding: const EdgeInsets.all(PSpace.x16),
          variant: PCardVariant.shadow,
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
                const PSkeleton(height: 6, borderRadius: PRadius.brFull),
              ],
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
    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      variant: PCardVariant.shadow,
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: PTypo.bodySm.copyWith(color: t.fgSecondary),
          ),
          const SizedBox(height: PSpace.x12),
          PButton(
            label: '다시 시도',
            icon: LucideIcons.refreshCw,
            variant: PButtonVariant.secondary,
            size: PButtonSize.sm,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
