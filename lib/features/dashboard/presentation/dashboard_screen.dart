import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_expense_row.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_progress.dart';
import '../../asset/application/asset_providers.dart';
import '../../budget/application/budget_providers.dart';
import '../../budget/domain/budget.dart';
import '../../expense/application/expense_providers.dart';
import '../../../app/theme/chart_palette.dart';
import '../../expense/domain/expense.dart';
import '../../expense/domain/expense_category.dart';
import '../../stats/application/stats_providers.dart';
import '../../stats/domain/stats_models.dart';
import '../application/dashboard_providers.dart';
import '../domain/dashboard_summary.dart';

/// 홈 / 대시보드 — porest-desk-front HomeMobile 정확 미러.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  String get _ymdStart =>
      '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}-01';
  String get _ymdEnd {
    final last = DateTime(_month.year, _month.month + 1, 0).day;
    return '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}-${last.toString().padLeft(2, '0')}';
  }

  ({String start, String end}) _prevMonthRange() {
    final p = DateTime(_month.year, _month.month - 1, 1);
    final lastDay = DateTime(p.year, p.month + 1, 0).day;
    return (
      start:
          '${p.year.toString().padLeft(4, '0')}-${p.month.toString().padLeft(2, '0')}-01',
      end:
          '${p.year.toString().padLeft(4, '0')}-${p.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;

    final monthKey = (year: _month.year, month: _month.month);
    final summaryAsync =
        ref.watch(assetSummaryProvider((year: _month.year, month: _month.month)));
    final expensesAsync = ref.watch(monthExpensesProvider(monthKey));
    final categoriesAsync = ref.watch(categoriesProvider);
    final dashboardAsync = ref.watch(dashboardSummaryProvider);
    final summaryRangeAsync = ref.watch(rangeSummaryProvider(
        (startDate: _ymdStart, endDate: _ymdEnd)));
    final prevRange = _prevMonthRange();
    final prevSummaryAsync = ref.watch(rangeSummaryProvider(
        (startDate: prevRange.start, endDate: prevRange.end)));
    final budgetsAsync = ref.watch(monthBudgetsProvider(monthKey));

    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(
            assetSummaryProvider((year: _month.year, month: _month.month)));
        ref.invalidate(monthExpensesProvider(monthKey));
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(rangeSummaryProvider(
            (startDate: _ymdStart, endDate: _ymdEnd)));
        ref.invalidate(monthBudgetsProvider(monthKey));
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x20, vertical: PSpace.x24),
        children: [
          _BalanceHero(
              summaryAsync: summaryAsync, masked: settings.hideAmounts),
          const SizedBox(height: 16),
          const _QuickActions(),
          const SizedBox(height: 16),
          _MonthExpenseCard(
            month: _month,
            expensesAsync: expensesAsync,
            currentSummary: summaryRangeAsync.value,
            prevSummary: prevSummaryAsync.value,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: 16),
          _CategoryDonutCard(
            summary: summaryRangeAsync.value,
            categoriesAsync: categoriesAsync,
            loading: summaryRangeAsync.isLoading,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: 16),
          _BudgetCard(
            budgetsAsync: budgetsAsync,
            categoriesAsync: categoriesAsync,
            summary: summaryRangeAsync.value,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: 16),
          _UpcomingCard(async: dashboardAsync),
          const SizedBox(height: 16),
          _TodaySpendCard(
            expensesAsync: expensesAsync,
            categoriesAsync: categoriesAsync,
            masked: settings.hideAmounts,
          ),
        ],
      ),
    );
  }
}

/// 다가오는 일정 + 최근 할 일 카드 (#230 활용).
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.async});
  final AsyncValue<DashboardSummary> async;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (async.isLoading && !async.hasValue) {
      return const PCard(
        child: SizedBox(
            height: 80, child: Center(child: PCircularProgressIndicator())),
      );
    }
    final s = async.value;
    if (s == null) return const SizedBox.shrink();
    final events = s.upcomingEvents.take(3).toList();
    final todos = s.recentTodos.take(3).toList();
    if (events.isEmpty && todos.isEmpty) return const SizedBox.shrink();

    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (events.isNotEmpty) ...[
            Row(
              children: [
                Icon(LucideIcons.calendarClock,
                    size: 16, color: t.fgSecondary),
                const SizedBox(width: 6),
                Text('다가오는 일정',
                    style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/calendar'),
                  child: Icon(LucideIcons.chevronRight,
                      size: 14, color: t.fgTertiary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final e in events)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: parseColor(e.color, fallback: t.fgBrand),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.bodySm
                              .copyWith(color: t.fgPrimary)),
                    ),
                    Text(
                        e.daysUntil == 0
                            ? '오늘'
                            : (e.daysUntil == 1
                                ? '내일'
                                : 'D-${e.daysUntil}'),
                        style: PTypo.caption
                            .copyWith(color: t.fgTertiary)),
                  ],
                ),
              ),
            if (todos.isNotEmpty) const SizedBox(height: 12),
          ],
          if (todos.isNotEmpty) ...[
            Row(
              children: [
                Icon(LucideIcons.checkSquare,
                    size: 16, color: t.fgSecondary),
                const SizedBox(width: 6),
                Text('최근 할 일',
                    style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/todos'),
                  child: Icon(LucideIcons.chevronRight,
                      size: 14, color: t.fgTertiary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final tdo in todos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      tdo.status == 'COMPLETED'
                          ? LucideIcons.checkCircle
                          : LucideIcons.circle,
                      size: 14,
                      color: tdo.status == 'COMPLETED'
                          ? t.statusSuccess
                          : t.fgTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tdo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            decoration: tdo.status == 'COMPLETED'
                                ? TextDecoration.lineThrough
                                : null,
                          )),
                    ),
                    if (tdo.dueDate != null)
                      Text(tdo.dueDate!.substring(5),
                          style: PTypo.caption
                              .copyWith(color: t.fgTertiary)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── BalanceHero (gradient olive card) ─────────────────────

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.summaryAsync, required this.masked});
  final AsyncValue summaryAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final loading = summaryAsync.isLoading && !summaryAsync.hasValue;
    final s = summaryAsync.value;
    final netWorth = (s?.netWorth as int?) ?? 0;
    final totalAssets = (s?.totalAssets as int?) ?? 0;
    final totalDebt = (s?.totalDebt as int?) ?? 0;
    final changePct = (s?.changePercent as double?) ?? 0.0;
    final isUp = changePct >= 0;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [t.bgHeroGradientStart, t.bgHeroGradientEnd],
            ),
            borderRadius: PRadius.brXl2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.wallet,
                      size: 13, color: t.fgOnBrand.withValues(alpha: 0.72)),
                  const SizedBox(width: 8),
                  Text(
                    '순자산',
                    style: TextStyle(
                      color: t.fgOnBrand.withValues(alpha: 0.72),
                      fontSize: PFontSize.caption,
                      fontWeight: PFontWeight.medium,
                      letterSpacing: -0.06,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: t.fgOnBrand.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: t.fgOnBrand.withValues(alpha: 0.15)),
                    ),
                    child: Icon(
                      masked ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 13,
                      color: t.fgOnBrand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    loading ? '—' : krwMasked(netWorth, masked),
                    style: TextStyle(
                      color: t.fgOnBrand,
                      fontSize: PFontSize.displayMd,
                      fontWeight: PFontWeight.bold,
                      letterSpacing: -1.02,
                      height: PLineHeight.tight,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '원',
                    style: TextStyle(
                      color: t.fgOnBrand.withValues(alpha: 0.8),
                      fontSize: PFontSize.h4,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '지난달 대비',
                    style: TextStyle(
                      color: t.fgOnBrand.withValues(alpha: 0.78),
                      fontSize: PFontSize.bodySm,
                      fontWeight: PFontWeight.regular,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 14,
                    color: isUp ? t.fgOnHeroChgUp : t.fgOnHeroChgDown,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${isUp ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isUp ? t.fgOnHeroChgUp : t.fgOnHeroChgDown,
                      fontSize: PFontSize.bodySm,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.only(top: 18),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: t.fgOnBrand.withValues(alpha: 0.14)),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeroSplitCol(
                          label: '자산',
                          value: krwMasked(totalAssets, masked),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: t.fgOnBrand.withValues(alpha: 0.14),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _HeroSplitCol(
                            label: '부채',
                            value: '-${krwMasked(totalDebt, masked)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: -40,
          top: -80,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  // CSS radial-gradient 기본 익스텐트는 `farthest-corner`(=side×√2/2 ≈ 0.707).
                  // Flutter RadialGradient.radius 기본 0.5(closest-side)와 다름 — 명시적 정합.
                  radius: 0.707,
                  colors: [
                    t.fgOnHeroSpot.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSplitCol extends StatelessWidget {
  const _HeroSplitCol({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: t.fgOnBrand.withValues(alpha: 0.7),
            fontSize: PFontSize.caption,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: t.fgOnBrand,
            fontSize: PFontSize.bodyLg,
            fontWeight: PFontWeight.bold,
            letterSpacing: -0.24,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ─── Quick actions 4-grid ──────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final items = <(IconData, String, String)>[
      (LucideIcons.wallet, '자산', '/assets'),
      (LucideIcons.receipt, '가계부', '/expense'),
      (LucideIcons.target, '예산', '/budget'),
      (LucideIcons.users, '더치페이', '/dutch-pay'),
    ];
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(
            child: _QuickAction(
              icon: items[i].$1,
              label: items[i].$2,
              onTap: () => context.push(items[i].$3),
              tokens: t,
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tokens,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    // desk-front DashboardPage quick action 미러:
    // PCard.shadow (bg-surface + shadow-sm, no border) — _MonthExpenseCard와 동일 톤
    // 아이콘 컨테이너 radius-tile 10px / bg-brand-subtle / fg-brand-strong
    return PCard(
      variant: PCardVariant.shadow,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      // desk-front --radius-card(14px) 미러 — spec 외 desk custom 카드 톤
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokens.bgBrandSubtle,
              borderRadius: PRadius.brLg,
            ),
            child: Icon(icon, size: 18, color: tokens.fgBrandStrong),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: tokens.fgPrimary,
              fontSize: PFontSize.caption,
              fontWeight: PFontWeight.semi,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 가계부 카드 ──────────────────────────────────────

class _MonthExpenseCard extends StatelessWidget {
  const _MonthExpenseCard({
    required this.month,
    required this.expensesAsync,
    required this.currentSummary,
    required this.prevSummary,
    required this.masked,
  });
  final DateTime month;
  final AsyncValue<List<Expense>> expensesAsync;
  final RangeSummary? currentSummary;
  final RangeSummary? prevSummary;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final list = expensesAsync.value ?? const <Expense>[];
    final income = currentSummary?.totalIncome ??
        list
            .where((e) => e.expenseType == 'INCOME')
            .fold<int>(0, (s, e) => s + e.amount);
    final expense = currentSummary?.totalExpense ??
        list
            .where((e) => e.expenseType == 'EXPENSE')
            .fold<int>(0, (s, e) => s + e.amount);
    final prevExpense = prevSummary?.totalExpense ?? 0;
    final hasError = expensesAsync.hasError && !expensesAsync.hasValue;

    final today = DateTime.now();
    final isCurMonth =
        today.year == month.year && today.month == month.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final dayOfMonth = isCurMonth ? today.day : daysInMonth;
    final dailyAvg = expense ~/ (dayOfMonth < 1 ? 1 : dayOfMonth);
    final savingsPct = prevExpense > 0
        ? ((prevExpense - expense) / prevExpense) * 100
        : 0.0;
    final saving = savingsPct > 0;

    return PCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PCardHeader(child: PCardTitle('${month.month}월 가계부')),
          PCardContent(
            afterHeader: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasError)
                  Text(
                    '이번달 거래를 불러오지 못했습니다',
                    style: PTypo.bodySm.copyWith(color: t.statusDanger),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _IncomeExpenseCol(
                          label: '수입',
                          value: '+${krwMasked(income, masked)}',
                          color: t.fgIncome,
                        ),
                      ),
                      Expanded(
                        child: _IncomeExpenseCol(
                          label: '지출',
                          value: '-${krwMasked(expense, masked)}',
                          color: t.fgExpense,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: PSpace.x16),
                const PDivider(),
                const SizedBox(height: PSpace.x16),
                RichText(
                  text: TextSpan(
                    style: PTypo.caption.copyWith(
                        color: t.fgSecondary, height: 1.5),
                    children: [
                      const TextSpan(text: '하루 평균 '),
                      TextSpan(
                        text: krwMasked(dailyAvg, masked),
                        style: TextStyle(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const TextSpan(text: '원 썼어요.'),
                      if (prevExpense > 0) ...[
                        const TextSpan(text: ' 전월 대비 '),
                        TextSpan(
                          text:
                              '${savingsPct.abs().toStringAsFixed(0)}%',
                          style: TextStyle(
                            color:
                                saving ? t.fgBrandStrong : t.fgExpense,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                        TextSpan(
                            text: saving
                                ? ' 절약 중이에요.'
                                : (savingsPct < 0
                                    ? ' 더 썼어요.'
                                    : ' 동일해요.')),
                      ],
                    ],
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

class _IncomeExpenseCol extends StatelessWidget {
  const _IncomeExpenseCol(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: t.fgTertiary,
                fontSize: PFontSize.micro,
                fontWeight: PFontWeight.medium)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: PFontSize.h4,
                fontWeight: PFontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

// ─── 카테고리 도넛 카드 ───────────────────────────────────

class _CategoryDonutCard extends StatelessWidget {
  const _CategoryDonutCard({
    required this.summary,
    required this.categoriesAsync,
    required this.loading,
    required this.masked,
  });
  final RangeSummary? summary;
  final AsyncValue<List<ExpenseCategory>> categoriesAsync;
  final bool loading;
  final bool masked;

  /// 카테고리 자체 색을 1순위로 사용, 없으면 [PorestChartPalette] fallback.
  /// chart base hex 면 라이트/다크 variant 자동 swap (resolveChartColor).
  /// desk-front DashboardPage `donutSegs` 정합.
  Color _segmentColor(BuildContext context, int rowId, int fallbackIdx) {
    final cat = categoriesAsync.value?.byRowId(rowId);
    final raw = cat?.color;
    if (raw != null && raw.trim().isNotEmpty) {
      return resolveChartColor(
        context,
        raw,
        fallback: PorestChartPalette.category(context, fallbackIdx),
      );
    }
    return PorestChartPalette.category(context, fallbackIdx);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // 부모 카테고리로 롤업: 부모가 있으면 부모 ID/이름으로, 없으면 자기 자신.
    final rolled = <int, ({String name, int total})>{};
    for (final c in (summary?.categoryBreakdown ?? const <CategoryBreakdown>[])) {
      if (c.expenseType != 'EXPENSE') continue;
      final id = c.parentCategoryRowId ?? c.categoryRowId;
      final name = c.parentCategoryName ?? (c.categoryName ?? '-');
      if (id == null) continue;
      final cur = rolled[id];
      rolled[id] = (
        name: cur?.name ?? name,
        total: (cur?.total ?? 0) + c.totalAmount,
      );
    }
    final topSegs = rolled.entries.map((e) => (
          rowId: e.key,
          name: e.value.name,
          totalAmount: e.value.total,
        )).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final total = topSegs.fold<int>(0, (s, c) => s + c.totalAmount);

    return PCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PCardHeader(
            child: Row(
              children: [
                const PCardTitle('카테고리'),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/stats'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('자세히',
                          style: PTypo.bodySm
                              .copyWith(color: t.fgTertiary)),
                      const SizedBox(width: 2),
                      Icon(LucideIcons.chevronRight,
                          size: 14, color: t.fgTertiary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PCardContent(
            afterHeader: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          if (topSegs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                    loading ? '불러오는 중…' : '카테고리 데이터가 없어요',
                    style: TextStyle(
                        color: t.fgTertiary, fontSize: PFontSize.caption)),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 38,
                          startDegreeOffset: -90,
                          sections: [
                            for (var i = 0; i < topSegs.length; i++)
                              PieChartSectionData(
                                value: topSegs[i].totalAmount.toDouble(),
                                color: _segmentColor(context, topSegs[i].rowId, i),
                                radius: 18,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('지출',
                              style: TextStyle(
                                  color: t.fgTertiary,
                                  fontSize: PFontSize.micro)),
                          const SizedBox(height: 2),
                          Text(
                            krwMasked(total, masked),
                            style: TextStyle(
                                color: t.fgPrimary,
                                fontSize: PFontSize.caption,
                                fontWeight: PFontWeight.bold,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < topSegs.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _segmentColor(context, topSegs[i].rowId, i),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  topSegs[i].name,
                                  style: TextStyle(
                                      color: t.fgSecondary,
                                      fontSize: PFontSize.caption),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                krwMasked(topSegs[i].totalAmount, masked),
                                style: TextStyle(
                                  color: t.fgPrimary,
                                  fontSize: PFontSize.caption,
                                  fontWeight: PFontWeight.semi,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 예산 카드 ───────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budgetsAsync,
    required this.categoriesAsync,
    required this.summary,
    required this.masked,
  });
  final AsyncValue<List<Budget>> budgetsAsync;
  final AsyncValue<List<ExpenseCategory>> categoriesAsync;
  final RangeSummary? summary;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final budgets = budgetsAsync.value ?? const <Budget>[];
    final categories = categoriesAsync.value ?? const <ExpenseCategory>[];

    final spentByCat = <int, int>{};
    for (final c in summary?.categoryBreakdown ?? const <CategoryBreakdown>[]) {
      if (c.expenseType != 'EXPENSE') continue;
      final cid = c.categoryRowId;
      if (cid != null) {
        spentByCat.update(cid, (v) => v + c.totalAmount,
            ifAbsent: () => c.totalAmount);
      }
      final pid = c.parentCategoryRowId;
      if (pid != null) {
        spentByCat.update(pid, (v) => v + c.totalAmount,
            ifAbsent: () => c.totalAmount);
      }
    }
    final totalEx = summary?.totalExpense ?? 0;
    final items = budgets;

    return PCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PCardHeader(
            child: Row(
              children: [
                const PCardTitle('예산'),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/budget'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('전체',
                          style: PTypo.bodySm
                              .copyWith(color: t.fgTertiary)),
                      const SizedBox(width: 2),
                      Icon(LucideIcons.chevronRight,
                          size: 14, color: t.fgTertiary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PCardContent(
            afterHeader: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: PSpace.x12),
                    child: Center(
                      child: Text(
                          budgetsAsync.isLoading ? '불러오는 중…' : '등록된 예산이 없어요',
                          style: PTypo.caption.copyWith(color: t.fgTertiary)),
                    ),
                  )
                else
                  for (var i = 0; i < items.length; i++) ...[
                    _BudgetRow(
                      budget: items[i],
                      category: items[i].categoryRowId == null
                          ? null
                          : categories.byRowId(items[i].categoryRowId!),
                      spent: items[i].categoryRowId == null
                          ? totalEx
                          : (spentByCat[items[i].categoryRowId!] ?? 0),
                      masked: masked,
                      tokens: t,
                    ),
                    if (i < items.length - 1)
                      const SizedBox(height: PSpace.x16),
                  ],
              ],
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
    required this.category,
    required this.spent,
    required this.masked,
    required this.tokens,
  });
  final Budget budget;
  final ExpenseCategory? category;
  final int spent;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final p = budget.budgetAmount > 0
        ? (spent / budget.budgetAmount) * 100
        : 0.0;
    final over = p > 100;
    final warn = p > 85 && !over;
    final stateColor = over
        ? tokens.fgExpense
        : warn
            ? tokens.statusWarning
            : tokens.fgBrand;
    final fg = resolveChartColor(context, category?.color, fallback: tokens.fgBrand);
    final bg = softBg(fg);
    final name = category?.categoryName ??
        budget.categoryName ??
        (budget.categoryRowId == null ? '전체' : '카테고리');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: bg, borderRadius: PRadius.brLg),
              child: Icon(lucideByName(category?.icon),
                  size: 14, color: fg),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: TextStyle(
                      color: tokens.fgPrimary,
                      fontSize: PFontSize.bodySm,
                      fontWeight: PFontWeight.semi),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: PFontSize.caption,
                  fontWeight: PFontWeight.semi,
                  color: over ? tokens.fgExpense : tokens.fgPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                children: [
                  TextSpan(text: krwMasked(spent, masked)),
                  TextSpan(
                    text: ' / ${krwMasked(budget.budgetAmount, masked)}',
                    style: TextStyle(
                      color: tokens.fgTertiary,
                      fontWeight: PFontWeight.medium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: PRadius.brSm,
          child: LinearProgressIndicator(
            value: (p / 100).clamp(0, 1).toDouble(),
            minHeight: 6,
            backgroundColor: tokens.bgTrack,
            color: stateColor,
          ),
        ),
      ],
    );
  }
}

// ─── 오늘 쓴 돈 카드 ───────────────────────────────────────

class _TodaySpendCard extends StatelessWidget {
  const _TodaySpendCard({
    required this.expensesAsync,
    required this.categoriesAsync,
    required this.masked,
  });
  final AsyncValue<List<Expense>> expensesAsync;
  final AsyncValue categoriesAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final list = expensesAsync.value ?? const <Expense>[];
    final categories = categoriesAsync.value as List? ?? const [];

    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    // 오늘 거래만
    final todayTx = [...list]
      ..removeWhere((e) =>
          e.expenseDate == null ||
          e.expenseDate!.substring(0, 10) != todayStr)
      ..sort((a, b) =>
          (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''));
    final todayTotal = todayTx
        .where((e) => e.expenseType == 'EXPENSE')
        .fold<int>(0, (s, e) => s + e.amount);

    return PCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PCardHeader(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const PCardTitle('오늘 쓴 돈'),
                if (todayTotal > 0) ...[
                  const SizedBox(width: PSpace.x8),
                  Text(
                    '-${krwMasked(todayTotal, masked)}원',
                    style: PTypo.caption.copyWith(
                      color: t.fgExpense,
                      fontWeight: PFontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/expense'),
                  child: Text(
                    '전체',
                    style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                  ),
                ),
              ],
            ),
          ),
          PCardContent(
            afterHeader: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (todayTx.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: PSpace.x12),
                    child: Center(
                      child: Text(
                          expensesAsync.hasError
                              ? '거래를 불러오지 못했습니다'
                              : '오늘은 아직 쓴 돈이 없어요',
                          style: PTypo.caption.copyWith(color: t.fgTertiary)),
                    ),
                  )
                else
                  for (final e in todayTx)
                    PExpenseRow(
                      expense: e,
                      masked: masked,
                      categoryColorOverride:
                          _findCategory(categories, e.categoryRowId)?.color
                              as String?,
                      categoryIconOverride:
                          _findCategory(categories, e.categoryRowId)?.icon
                              as String?,
                      onTap: () {
                        final dateStr = e.expenseDate?.substring(0, 7);
                        if (dateStr != null && dateStr.length == 7) {
                          context.go('/expense?month=$dateStr&txId=${e.rowId}');
                        } else {
                          context.go('/expense?txId=${e.rowId}');
                        }
                      },
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  dynamic _findCategory(List categories, int? rowId) {
    if (rowId == null) return null;
    for (final c in categories) {
      try {
        if (c.rowId == rowId) return c;
      } catch (_) {}
    }
    return null;
  }
}

