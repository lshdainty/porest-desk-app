import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_card.dart';
import '../../asset/application/asset_providers.dart';
import '../../budget/application/budget_providers.dart';
import '../../budget/domain/budget.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../../expense/domain/expense_category.dart';
import '../../stats/application/stats_providers.dart';
import '../../stats/domain/stats_models.dart';
import '../application/dashboard_providers.dart';
import '../domain/dashboard_summary.dart';

const _categoryPalette = <Color>[
  Color(0xFFB48A4A), // mossy/orange-ish (cf. CSS oklch palette)
  Color(0xFFB04F8A),
  Color(0xFF5C9F6E),
  Color(0xFF8C6BB4),
  Color(0xFF5A8FB7),
  Color(0xFFC75A4F),
  Color(0xFF4F8A98),
  Color(0xFF8B7B5A),
];

/// 홈 / 대시보드 — porest-desk-front HomeMobile 정확 미러.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

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

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      helpText: '월 선택',
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month, 1));
    }
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
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
            onPickMonth: _pickMonth,
          ),
          const SizedBox(height: 16),
          _CategoryDonutCard(
            summary: summaryRangeAsync.value,
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
      return PCard(
        padding: const EdgeInsets.all(18),
        child: const SizedBox(
            height: 80, child: Center(child: CircularProgressIndicator())),
      );
    }
    final s = async.value;
    if (s == null) return const SizedBox.shrink();
    final events = s.upcomingEvents.take(3).toList();
    final todos = s.recentTodos.take(3).toList();
    if (events.isEmpty && todos.isEmpty) return const SizedBox.shrink();

    return PCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PorestPalette.mossy700, PorestPalette.mossy900],
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
                      fontWeight: PFontWeight.heavy,
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
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 13,
                    color: isUp
                        ? PorestPalette.heroChgUp
                        : PorestPalette.heroChgDown,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${isUp ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isUp
                          ? PorestPalette.heroChgUp
                          : PorestPalette.heroChgDown,
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
                  colors: [
                    PorestPalette.heroSpot.withValues(alpha: 0.25),
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
    return PCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      borderRadius: PRadius.brXl,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokens.bgBrandSubtle,
              borderRadius: PRadius.brTile,
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
    required this.onPickMonth,
  });
  final DateTime month;
  final AsyncValue<List<Expense>> expensesAsync;
  final RangeSummary? currentSummary;
  final RangeSummary? prevSummary;
  final bool masked;
  final VoidCallback onPickMonth;

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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${month.month}월 가계부',
                style: TextStyle(
                  color: t.fgPrimary,
                  fontSize: PFontSize.bodyLg,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.225,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onPickMonth,
                icon: Icon(LucideIcons.calendar,
                    size: 13, color: t.fgSecondary),
                label: Text(
                  '${month.year}년 ${month.month}월',
                  style: TextStyle(
                    color: t.fgPrimary,
                    fontSize: PFontSize.caption,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: t.borderSubtle),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: PRadius.brMd),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasError)
            Text(
              '이번달 거래를 불러오지 못했습니다',
              style: TextStyle(
                  color: t.statusDanger, fontSize: PFontSize.bodySm),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _IncomeExpenseCol(
                    label: '수입',
                    value: '+${krwMasked(income, masked)}',
                    color: t.statusSuccessFg,
                  ),
                ),
                Expanded(
                  child: _IncomeExpenseCol(
                    label: '지출',
                    value: '-${krwMasked(expense, masked)}',
                    color: t.statusDangerFg,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: t.borderSubtle)),
            ),
            child: RichText(
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
                      text: '${savingsPct.abs().toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: saving ? t.fgBrandStrong : t.fgExpense,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                    TextSpan(
                        text: saving
                            ? ' 절약 중이에요.'
                            : (savingsPct < 0 ? ' 더 썼어요.' : ' 동일해요.')),
                  ],
                ],
              ),
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
    required this.loading,
    required this.masked,
  });
  final RangeSummary? summary;
  final bool loading;
  final bool masked;

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
    final segs = rolled.entries.map((e) => (
          rowId: e.key,
          name: e.value.name,
          totalAmount: e.value.total,
        )).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final topSegs = segs.take(4).toList();
    final total = topSegs.fold<int>(0, (s, c) => s + c.totalAmount);

    return PCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('카테고리',
                  style: TextStyle(
                    color: t.fgPrimary,
                    fontSize: PFontSize.bodyLg,
                    fontWeight: PFontWeight.bold,
                    letterSpacing: -0.225,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/stats'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('자세히',
                        style: TextStyle(
                            color: t.fgTertiary,
                            fontSize: PFontSize.bodySm)),
                    const SizedBox(width: 2),
                    Icon(LucideIcons.chevronRight,
                        size: 14, color: t.fgTertiary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                                color:
                                    _categoryPalette[i % _categoryPalette.length],
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
                            masked
                                ? '••••'
                                : '${(total / 10000).toStringAsFixed(0)}만',
                            style: TextStyle(
                                color: t.fgPrimary,
                                fontSize: PFontSize.body,
                                fontWeight: PFontWeight.heavy,
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
                                  color:
                                      _categoryPalette[i % _categoryPalette.length],
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
                                masked
                                    ? '••••'
                                    : '${(topSegs[i].totalAmount / 10000).toStringAsFixed(0)}만',
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
    final items = budgets.take(3).toList();

    return PCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('예산',
                  style: TextStyle(
                    color: t.fgPrimary,
                    fontSize: PFontSize.bodyLg,
                    fontWeight: PFontWeight.bold,
                    letterSpacing: -0.225,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/budget'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('전체',
                        style: TextStyle(
                            color: t.fgTertiary,
                            fontSize: PFontSize.bodySm)),
                    const SizedBox(width: 2),
                    Icon(LucideIcons.chevronRight,
                        size: 14, color: t.fgTertiary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                    budgetsAsync.isLoading ? '불러오는 중…' : '등록된 예산이 없어요',
                    style: TextStyle(
                        color: t.fgTertiary, fontSize: PFontSize.caption)),
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
              if (i < items.length - 1) const SizedBox(height: 14),
            ],
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
    final fg = parseColor(category?.color, fallback: tokens.fgBrand);
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
                  BoxDecoration(color: bg, borderRadius: PRadius.brTile),
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '오늘 쓴 돈',
                style: TextStyle(
                  color: t.fgPrimary,
                  fontSize: PFontSize.bodyLg,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.225,
                ),
              ),
              if (todayTotal > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '-${krwMasked(todayTotal, masked)}원',
                  style: TextStyle(
                    color: t.statusDangerFg,
                    fontSize: PFontSize.caption,
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
                  style: TextStyle(
                    color: t.fgTertiary,
                    fontSize: PFontSize.bodySm,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (todayTx.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                    expensesAsync.hasError
                        ? '거래를 불러오지 못했습니다'
                        : '오늘은 아직 쓴 돈이 없어요',
                    style: TextStyle(
                        color: t.fgTertiary,
                        fontSize: PFontSize.caption)),
              ),
            )
          else
            for (final e in todayTx)
              _ExpenseRow(
                expense: e,
                category: _findCategory(categories, e.categoryRowId),
                masked: masked,
                tokens: t,
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

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.category,
    required this.masked,
    required this.tokens,
  });
  final Expense expense;
  final dynamic category;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final fg = parseColor((category?.color as String?) ?? expense.categoryColor,
        fallback: tokens.fgBrand);
    final bg = softBg(fg);
    final isExpense = expense.expenseType == 'EXPENSE';
    // 오늘 쓴 돈 카드는 모두 오늘 거래라 날짜 대신 시각만 표시
    final time = expense.expenseDate != null && expense.expenseDate!.length >= 16
        ? expense.expenseDate!.substring(11, 16)
        : null;

    return InkWell(
      onTap: () {
        final dateStr = expense.expenseDate?.substring(0, 7);
        if (dateStr != null && dateStr.length == 7) {
          context.go('/expense?month=$dateStr&txId=${expense.rowId}');
        } else {
          context.go('/expense?txId=${expense.rowId}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: bg, borderRadius: PRadius.brLg),
              alignment: Alignment.center,
              child: Icon(
                lucideByName(
                    (category?.icon as String?) ?? expense.categoryIcon,
                    fallback: LucideIcons.tag),
                size: 18,
                color: fg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.merchant ??
                        expense.description ??
                        expense.categoryName ??
                        '거래',
                    style: TextStyle(
                      color: tokens.fgPrimary,
                      fontSize: PFontSize.body,
                      fontWeight: PFontWeight.semi,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      expense.categoryName,
                      expense.assetName,
                      ?time,
                    ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isExpense ? '-' : '+'}${krwMasked(expense.amount, masked)}원',
              style: TextStyle(
                color: isExpense
                    ? tokens.statusDangerFg
                    : tokens.statusSuccessFg,
                fontSize: PFontSize.bodySm,
                fontWeight: PFontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
