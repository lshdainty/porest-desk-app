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
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_expense_row.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/budget/domain/budget.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/app/theme/chart_palette.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';
import 'package:porest_desk_app/features/dashboard/application/dashboard_providers.dart';
import 'package:porest_desk_app/features/dashboard/domain/dashboard_summary.dart';

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
              summaryAsync: summaryAsync,
              masked: settings.hideAmounts,
              // 헤더 eye 버튼과 동일 — 숨김 해제 시 unlock 다이얼로그.
              onToggleMask: () => toggleHideAmountsWithUnlock(context, ref)),
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
            warnThreshold:
                ref.watch(budgetAlertThresholdProvider).value?.toDouble() ?? 85,
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
    final l = AppLocalizations.of(context);
    if (async.isLoading && !async.hasValue) {
      return PCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PSkeleton(width: 16, height: 16),
                const SizedBox(width: 6),
                const PSkeleton.line(width: 80),
                const Spacer(),
                const PSkeleton(width: 14, height: 14),
              ],
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < 2; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    PSkeleton(
                      width: 8,
                      height: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 8),
                    PSkeleton.line(width: i == 0 ? 120 : 96),
                    const Spacer(),
                    PSkeleton.line(width: 40, height: 12),
                  ],
                ),
              ),
          ],
        ),
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
                Text(l.dashUpcoming,
                    style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  // 셸 브랜치 라우트는 push 금지 — push 하면 홈 브랜치 위에 얹혀
                  // 헤더/하단 nav 가 '홈'으로 남음. go 로 브랜치 전환 (web 정합).
                  onTap: () => context.go('/calendar'),
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
                          color: resolveChartColor(context, e.color, fallback: t.fgBrand),
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
                            ? l.dashTodayLabel
                            : (e.daysUntil == 1
                                ? l.dashTomorrowLabel
                                : l.dashDaysLeft(e.daysUntil)),
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
                Icon(LucideIcons.squareCheckBig,
                    size: 16, color: t.fgSecondary),
                const SizedBox(width: 6),
                Text(l.dashRecentTodos,
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
  const _BalanceHero({
    required this.summaryAsync,
    required this.masked,
    required this.onToggleMask,
  });
  final AsyncValue summaryAsync;
  final bool masked;
  final VoidCallback onToggleMask;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
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
                    l.assetNetWorth,
                    style: TextStyle(
                      color: t.fgOnBrand.withValues(alpha: 0.72),
                      fontSize: PFontSize.caption,
                      fontWeight: PFontWeight.medium,
                      letterSpacing: -0.06,
                    ),
                  ),
                  const Spacer(),
                  // 헤더 eye 버튼과 동일 기능 — 금액 숨김 토글.
                  GestureDetector(
                    onTap: onToggleMask,
                    behavior: HitTestBehavior.opaque,
                    child: Tooltip(
                      message: masked ? l.assetShowAmount : l.dashHideAmount,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 큰 금액 — 로딩 중 흰 반투명 skeleton 박스 (gradient 위 PSkeleton 색 부적합)
              if (loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _heroSkelBar(t, width: 180, height: 34),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      krwMasked(netWorth, masked),
                      style: TextStyle(
                        color: t.fgOnBrand,
                        fontSize: PFontSize.displayMd,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -1.02,
                        height: PLineHeight.tight,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    // 금액 숨김 시 '원' 단위도 숨김(web HideUnit 정합)
                    if (!masked) ...[
                      const SizedBox(width: 4),
                      Text(
                        wonUnit(),
                        style: TextStyle(
                          color: t.fgOnBrand.withValues(alpha: 0.8),
                          fontSize: PFontSize.h4,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 8),
              if (loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: _heroSkelBar(t, width: 120, height: 14),
                )
              else
                Row(
                  children: [
                    Text(
                      l.dashVsLastMonth,
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
                          label: l.navAsset,
                          value: krwMasked(totalAssets, masked, mask: '••••'),
                          loading: loading,
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
                            label: l.dashLiabilities,
                            value: krwSigned(totalDebt, masked, sign: '-', mask: '••••'),
                            loading: loading,
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

/// hero gradient 위 흰 반투명 skeleton 박스 (PSkeleton bgMuted 색이 gradient 위 부적합).
Widget _heroSkelBar(PorestTokens t, {required double width, required double height}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: t.fgOnBrand.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _HeroSplitCol extends StatelessWidget {
  const _HeroSplitCol({
    required this.label,
    required this.value,
    this.loading = false,
  });
  final String label;
  final String value;
  final bool loading;

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
        if (loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _heroSkelBar(t, width: 80, height: 16),
          )
        else
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
    final l = AppLocalizations.of(context);
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
          PCardHeader(child: PCardTitle(l.dashMonthLedger(month.month))),
          PCardContent(
            afterHeader: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasError)
                  Text(
                    l.dashMonthTxError,
                    style: PTypo.bodySm.copyWith(color: t.statusDanger),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _IncomeExpenseCol(
                          label: l.expTypeIncome,
                          value: krwSigned(income, masked, sign: '+'),
                          color: t.fgIncome,
                        ),
                      ),
                      Expanded(
                        child: _IncomeExpenseCol(
                          label: l.expTypeExpense,
                          value: krwSigned(expense, masked, sign: '-'),
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
                      TextSpan(text: l.dashDailyAvgPrefix),
                      TextSpan(
                        text: krwMasked(dailyAvg, masked),
                        style: TextStyle(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(text: masked ? l.dashSpentMasked : l.dashSpentUnit),
                      if (prevExpense > 0) ...[
                        TextSpan(text: l.dashVsPrevPrefix),
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
                                ? l.dashSaving
                                : (savingsPct < 0
                                    ? l.dashSpentMore
                                    : l.dashSame)),
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
    final l = AppLocalizations.of(context);
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
                PCardTitle(l.expCategory),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/stats'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.dashSeeMore,
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
          if (loading && topSegs.isEmpty)
            // 도넛 카드 placeholder — Web stats CategorySkeleton 미러 (작은 사이즈).
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PSkeleton.circle(size: 120),
                  const SizedBox(width: PSpace.lg),
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          Row(
                            children: [
                              PSkeleton.circle(size: 8),
                              const SizedBox(width: PSpace.sm),
                              const Expanded(child: PSkeleton.line(height: 11)),
                              const SizedBox(width: PSpace.sm),
                              const PSkeleton.line(width: 48, height: 11),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (topSegs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                    l.dashNoCategoryData,
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
                          Text(l.expTypeExpense,
                              style: TextStyle(
                                  color: t.fgTertiary,
                                  fontSize: PFontSize.micro)),
                          const SizedBox(height: 2),
                          Text(
                            krwMasked(total, masked, mask: '••••'),
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
                                krwMasked(topSegs[i].totalAmount, masked, mask: '••••'),
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
    this.warnThreshold = 85,
  });
  final AsyncValue<List<Budget>> budgetsAsync;
  final AsyncValue<List<ExpenseCategory>> categoriesAsync;
  final RangeSummary? summary;
  final bool masked;
  final double warnThreshold;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
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
                PCardTitle(l.navBudget),
                const Spacer(),
                GestureDetector(
                  // 셸 브랜치 라우트 — push 가 아닌 go 로 브랜치 전환 (가계부 nav 활성).
                  onTap: () => context.go('/budget'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.expFilterAll,
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
                if (budgetsAsync.isLoading && items.isEmpty)
                  // 예산 카드 placeholder — _BudgetRow 1:1: 28 icon + name + amount, 6px progress.
                  Column(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(height: PSpace.x16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                PSkeleton(
                                  width: 28,
                                  height: 28,
                                  borderRadius: PRadius.tile(28),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: PSkeleton.line(width: 80, height: 14),
                                ),
                                const SizedBox(width: 6),
                                const PSkeleton.line(width: 96, height: 12),
                              ],
                            ),
                            const SizedBox(height: 6),
                            PSkeleton(
                              height: 6,
                              borderRadius: PRadius.brFull,
                            ),
                          ],
                        ),
                      ],
                    ],
                  )
                else if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: PSpace.x12),
                    child: Center(
                      child: Text(
                          l.dashNoBudget,
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
                      warnThreshold: warnThreshold,
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
    this.warnThreshold = 85,
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
    final p = budget.budgetAmount > 0
        ? (spent / budget.budgetAmount) * 100
        : 0.0;
    final over = p > 100;
    final warn = p > warnThreshold && !over;
    // 예산 상태 = semantic 색 (초과=error / 경고=warning / 일반=info).
    // *Fg 토큰은 dark에서 light variant 자동 분기.
    final stateColor = over
        ? tokens.statusDangerFg
        : warn
            ? tokens.statusWarningFg
            : tokens.statusInfoFg;
    final fg = resolveChartColor(context, category?.color, fallback: tokens.fgBrand);
    final bg = softBg(context, fg);
    final name = category?.categoryName ??
        budget.categoryName ??
        (budget.categoryRowId == null ? l.expFilterAll : l.expCategory);

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
                  BoxDecoration(color: bg, borderRadius: PRadius.tile(28)),
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
                  TextSpan(text: krwMasked(spent, masked, mask: '••••')),
                  TextSpan(
                    text: ' / ${krwMasked(budget.budgetAmount, masked, mask: '••••')}',
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
        LinearProgressIndicator(
          borderRadius: PRadius.brFull,
          value: (p / 100).clamp(0, 1).toDouble(),
          minHeight: 6,
          backgroundColor: tokens.bgTrack,
          color: stateColor,
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
    final l = AppLocalizations.of(context);
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
                PCardTitle(l.dashTodaySpend),
                if (todayTotal > 0) ...[
                  const SizedBox(width: PSpace.x8),
                  Text(
                    krwSigned(todayTotal, masked, sign: '-', unit: true, mask: '••••'),
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
                    l.expFilterAll,
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
                              ? l.dashTxError
                              : l.dashNoTodaySpend,
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

