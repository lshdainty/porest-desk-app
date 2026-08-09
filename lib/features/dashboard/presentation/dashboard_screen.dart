import 'dart:io' show Platform;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/env.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/core/update/app_update.dart';
import 'package:porest_desk_app/core/update/update_sheet.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_flat_section.dart';
import 'package:porest_desk_app/shared/widgets/p_expense_row.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
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
import 'package:porest_desk_app/shared/widgets/p_tab_bar.dart';

/// 홈 / 대시보드 — porest-desk-front HomeMobile 정확 미러.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  /// 이번 실행에서 업데이트 시트를 이미 띄웠는지. 화면이 다시 build 될 때마다
  /// 시트가 겹쳐 뜨는 걸 막는다.
  bool _updateSheetShown = false;

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

    // 새 버전이 확인되면 한 번 크게 알린다. 확인은 비동기라 첫 build 시점에는 값이
    // 없다 — 값이 도착하는 순간을 듣는다.
    ref.listen(appUpdateProvider, (_, next) {
      final release = next.value;
      if (release == null || _updateSheetShown) return;
      _updateSheetShown = true;
      // build 중에 시트를 열 수 없다. 이 프레임이 끝난 뒤로 미룬다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) maybeShowUpdateSheet(context, ref, release);
      });
    });

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
      // 카드 다이어트 — design HomeMobile: padding 20/20/24 + 섹션 gap 36.
      // 카드 대신 페이지 padding + 섹션 간 넓은 여백이 콘텐츠를 구분한다.
      child: ListView(
        // 하단 — 플로팅 탭바 보상(pTabBarBottomInset).
        padding: EdgeInsets.fromLTRB(
            PSpace.x24, PSpace.x20, PSpace.x24, pTabBarBottomInset(context)),
        children: [
          // 개발 서버를 보는 빌드에만 붙인다.
          //
          // dev·prod 는 bundle ID 가 같아 한 번에 하나만 깔리고 서로 덮어쓴다. 아이콘도
          // 이름도 같아서 열기 전에는 어느 쪽인지 알 길이 없다 — 홈 첫 줄에 못을 박아 둔다.
          // 운영 빌드에서는 아무것도 그리지 않는다.
          if (Env.appEnv != 'prod') ...[
            Align(
              alignment: Alignment.centerLeft,
              child: PBadge(
                label: Env.appEnv.toUpperCase(),
                variant: PBadgeVariant.softWarning,
              ),
            ),
            const SizedBox(height: PSpace.x12),
          ],
          // 새 버전 알림 — 스토어를 안 쓰니 자동 업데이트가 없다. 여기서만 알 수 있다.
          const _UpdateBanner(),
          _BalanceHero(
              summaryAsync: summaryAsync,
              masked: ref.watch(hideCardProvider('home.netWorth')),
              // 헤더 eye 버튼과 동일 — 숨김 해제 시 unlock 다이얼로그.
              onToggleMask: () => context.push('/settings/appearance?hide=1')),
          const SizedBox(height: PSpace.x32),
          _MonthExpenseCard(
            month: _month,
            expensesAsync: expensesAsync,
            currentSummary: summaryRangeAsync.value,
            prevSummary: prevSummaryAsync.value,
            masked: ref.watch(hideCardProvider('home.monthExpense')),
          ),
          const SizedBox(height: PSpace.x32),
          _CategoryDonutCard(
            summary: summaryRangeAsync.value,
            categoriesAsync: categoriesAsync,
            loading: summaryRangeAsync.isLoading,
            masked: ref.watch(hideCardProvider('home.categoryDonut')),
          ),
          const SizedBox(height: PSpace.x32),
          _BudgetCard(
            budgetsAsync: budgetsAsync,
            categoriesAsync: categoriesAsync,
            summary: summaryRangeAsync.value,
            masked: ref.watch(hideCardProvider('home.budget')),
            warnThreshold:
                ref.watch(budgetAlertThresholdProvider).value?.toDouble() ?? 85,
          ),
          const SizedBox(height: PSpace.x32),
          // 각 위젯이 자체적으로 숨을 수 있어 아래 gap(36)을 스스로 관리 — gap 중복 방지.
          _HomeUpcomingWidget(async: dashboardAsync),
          _HomeTodosWidget(async: dashboardAsync),
          _TodaySpendCard(
            expensesAsync: expensesAsync,
            categoriesAsync: categoriesAsync,
            masked: ref.watch(hideCardProvider('home.todaySpend')),
          ),
        ],
      ),
    );
  }
}

// 모바일 홈 전용 위젯 — design screens-home.jsx HomeUpcoming/HomeTodos 미러.
// 각각 독립 섹션(헤더 15/bold + 아이콘16 + chevron16), 항목은 widget-row(탭).

/// 위젯 섹션 헤더 — 아이콘16(fgSecondary) + 제목(15/bold) + [뱃지] + chevron16.
class _WidgetHead extends StatelessWidget {
  const _WidgetHead({
    required this.icon,
    required this.title,
    required this.onAll,
    this.badge,
  });
  final IconData icon;
  final String title;
  final VoidCallback onAll;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: t.fgSecondary),
          const SizedBox(width: 7),
          Text(title,
              style: PTypo.body.copyWith(
                  fontSize: PFontSize.bodyMd,
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold)),
          if (badge != null) ...[const SizedBox(width: 6), badge!],
          const Spacer(),
          GestureDetector(
            // 셸 브랜치 라우트는 go 로 전환(push 금지 — web 정합).
            onTap: onAll,
            child: Icon(LucideIcons.chevronRight, size: 16, color: t.fgTertiary),
          ),
        ],
      ),
    );
  }
}

/// 위젯 행 — leading(dot/체크) + 제목(14/500) + trailing(D-day/날짜). full-width 탭.
class _WidgetRow extends StatelessWidget {
  const _WidgetRow({
    required this.onTap,
    required this.leading,
    required this.title,
    required this.trailing,
    this.strike = false,
  });
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final Widget trailing;
  final bool strike;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                    decoration:
                        strike ? TextDecoration.lineThrough : null,
                  )),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// 위젯 로딩 스켈레톤 — 헤더 + 2행 (아래 gap 36 자체 관리).
class _WidgetSkeleton extends StatelessWidget {
  const _WidgetSkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: PSpace.x32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: const [
                PSkeleton(width: 16, height: 16),
                SizedBox(width: 7),
                PSkeleton.line(width: 80),
                Spacer(),
                PSkeleton(width: 16, height: 16),
              ],
            ),
          ),
          for (int i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  PSkeleton(width: 18, height: 18, borderRadius: BorderRadius.circular(9)),
                  const SizedBox(width: 12),
                  PSkeleton.line(width: i == 0 ? 120 : 96),
                  const Spacer(),
                  const PSkeleton.line(width: 40, height: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 모바일 홈 — 다가오는 일정.
class _HomeUpcomingWidget extends StatelessWidget {
  const _HomeUpcomingWidget({required this.async});
  final AsyncValue<DashboardSummary> async;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    if (async.isLoading && !async.hasValue) return _WidgetSkeleton(tokens: t);
    final s = async.value;
    if (s == null) return const SizedBox.shrink();
    final events = s.upcomingEvents.take(3).toList();
    if (events.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: PSpace.x32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WidgetHead(
            icon: LucideIcons.calendarClock,
            title: l.dashUpcoming,
            onAll: () => context.go('/calendar'),
          ),
          for (final e in events)
            _WidgetRow(
              onTap: () => context.go('/calendar'),
              leading: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: resolveChartColor(context, e.color,
                        fallback: t.fgBrand),
                    shape: BoxShape.circle),
              ),
              title: e.title,
              trailing: Text(
                e.daysUntil == 0
                    ? l.dashTodayLabel
                    : (e.daysUntil == 1
                        ? l.dashTomorrowLabel
                        : l.dashDaysLeft(e.daysUntil)),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: PFontWeight.bold,
                  color: e.daysUntil <= 3 ? t.fgExpense : t.fgTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 모바일 홈 — 최근 할 일.
class _HomeTodosWidget extends StatelessWidget {
  const _HomeTodosWidget({required this.async});
  final AsyncValue<DashboardSummary> async;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    if (async.isLoading && !async.hasValue) return const SizedBox.shrink();
    final s = async.value;
    if (s == null) return const SizedBox.shrink();
    final todos = s.recentTodos.take(3).toList();
    if (todos.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final overdue = s.todoSummary.overDueCount;

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: PSpace.x32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WidgetHead(
            icon: LucideIcons.squareCheckBig,
            title: l.dashRecentTodos,
            onAll: () => context.go('/todos'),
            // badge SoT = pill(brFull) + softError(subtle 배경 + statusDangerFg). square 는 spec 외.
            badge: overdue > 0
                ? PBadge(
                    label: l.dashOverdue(overdue),
                    variant: PBadgeVariant.softError,
                  )
                : null,
          ),
          for (final tdo in todos)
            () {
              final done = tdo.status == 'COMPLETED';
              final isOver = !done &&
                  tdo.dueDate != null &&
                  tdo.dueDate!.substring(0, 10).compareTo(todayStr) < 0;
              return _WidgetRow(
                onTap: () => context.go('/todos'),
                strike: done,
                leading: done
                    ? Icon(LucideIcons.checkCircle,
                        size: 18, color: t.statusSuccess)
                    : Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isOver ? t.fgExpense : t.borderStrong,
                            width: 2,
                          ),
                        ),
                      ),
                title: tdo.title,
                trailing: tdo.dueDate != null
                    ? Text(
                        tdo.dueDate!.substring(5, 10),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: PFontWeight.semi,
                          color: isOver ? t.fgExpense : t.fgTertiary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            }(),
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

    // 카드 다이어트 — design HomeMobile 월 가계부: 헤드(15/bold) + 콘텐츠 inset 10.
    return PFlatSection(
      title: l.dashMonthLedger(month.month),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
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
          const SizedBox(height: 14),
          const PDivider(),
          const SizedBox(height: 14),
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

    // 카드 다이어트 — design HomeMobile 카테고리: 헤드 + 도넛·범례 (inset 10).
    return PFlatSection(
      title: l.expCategory,
      trailing: PFlatSectionLink(
        label: l.dashSeeMore,
        onTap: () => context.go('/stats'),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
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

    // 카드 다이어트 — design HomeMobile 예산: 헤드(gap 14) + budget-flat 행(14/10).
    return PFlatSection(
      title: l.navBudget,
      headGap: 14,
      trailing: PFlatSectionLink(
        label: l.expFilterAll,
        // 셸 브랜치 라우트 — push 가 아닌 go 로 브랜치 전환 (가계부 nav 활성).
        onTap: () => context.go('/budget'),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (budgetsAsync.isLoading && items.isEmpty)
                  // 예산 카드 placeholder — _BudgetRow 1:1: 행 상하 14 / 40 icon + name + amount / 8px pill.
                  Column(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  PSkeleton(
                                    width: 40,
                                    height: 40,
                                    borderRadius: PRadius.tile(40),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: PSkeleton.line(width: 80, height: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  const PSkeleton.line(width: 110, height: 16),
                                ],
                              ),
                              const SizedBox(height: 10),
                              PSkeleton(
                                height: 8,
                                borderRadius: PRadius.brFull,
                              ),
                            ],
                          ),
                        ),
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
                  for (var i = 0; i < items.length; i++)
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

    // 웹 모바일 예산 행(DashboardPage 1471~) 정합 — 행 상하 14 / 아이콘 40·18 /
    // gap 14 / 금액 body-lg(16)·700 / 바 marginTop 10.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: bg, borderRadius: PRadius.tile(40)),
              child: Icon(lucideByName(category?.icon),
                  size: 18, color: fg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(name,
                  style: TextStyle(
                      color: tokens.fgPrimary,
                      fontSize: PFontSize.bodySm,
                      fontWeight: PFontWeight.semi,
                      letterSpacing: -0.13),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: PFontSize.bodyLg,
                  fontWeight: PFontWeight.bold,
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
        const SizedBox(height: 10),
        // 웹 .budget-bar(8px pill) 정합 — Flutter 3.41 M3 LinearProgressIndicator 는
        // track gap/stop indicator 가 붙어 디자인보다 두껍게 렌더돼 커스텀 pill 로 대체.
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: tokens.bgTrack)),
                // heightFactor:1 필수 — Stack 안 FractionallySizedBox 는 heightFactor 없으면
                // 높이가 0이라 fill(색)이 렌더되지 않음(track 만 보이던 버그).
                // fill 자체 borderRadius — 100% 미만일 때 fill 오른쪽 끝도 둥글게(웹 .budget-bar__fill
                // border-radius:inherit 정합). track ClipRRect 만으론 bar 양끝만 클립돼 각졌음.
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (p / 100).clamp(0, 1).toDouble(),
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: stateColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      ),
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

    // 카드 다이어트 — design HomeMobile 오늘 쓴 돈: 헤드(gap 6) + tx-flat 행(12/10).
    return PFlatSection(
      title: l.dashTodaySpend,
      headGap: 6,
      titleSuffix: todayTotal > 0
          ? Text(
              krwSigned(todayTotal, masked, sign: '-', unit: true, mask: '••••'),
              style: PTypo.caption.copyWith(
                color: t.fgExpense,
                fontWeight: PFontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            )
          : null,
      trailing: PFlatSectionLink(
        label: l.expFilterAll,
        chevron: false,
        onTap: () => context.go('/expense'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (todayTx.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
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

/// 새 버전이 올라와 있으면 알린다. 없거나 못 읽으면 아무것도 그리지 않는다.
class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(appUpdateProvider).value;
    if (release == null) return const SizedBox.shrink();

    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: PSpace.x20),
      child: InkWell(
        borderRadius: PRadius.brLg,
        // 밖으로 넘긴다 — 시트의 [업데이트] 와 같은 길을 쓴다.
        onTap: () => openReleaseExternally(release),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x16, vertical: PSpace.x12),
          decoration: BoxDecoration(
            color: t.bgBrandSubtle,
            borderRadius: PRadius.brLg,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.download, size: 18, color: t.fgBrand),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.updateAvailable(release.version),
                        style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.semi)),
                    const SizedBox(height: 2),
                    Text(
                        Platform.isIOS
                            ? l.updateAvailableDescIos
                            : l.updateAvailableDesc,
                        style: PTypo.caption.copyWith(color: t.fgSecondary)),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: t.fgTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
