import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset_summary.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/dashboard/domain/dashboard_summary.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_aggregates.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/features/money/presentation/money_bundle_screen.dart';
import 'package:groo_damda_app/features/sms/presentation/sms_clipboard_banner.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

const _tabular = [FontFeature.tabularFigures()];
const _mask = '••••';

/// 홈 / 대시보드 — 폰 띠 화면(I-06 1A). 띠는 주제가 바뀌는 자리에서만 끊는다 — ① 순자산 ② 이번 달 돈(가계부 · 카테고리 ·
/// 예산) ③ 할 일 · 일정 ④ 오늘 쓴 돈. 한 띠 안 구역은 구역 제목 + 여백(48)으로 가른다. 머리 바로 아래 첫 띠 · 마지막 띠 아래에는
/// 틈을 두지 않고 8 은 띠 사이에만 둔다.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final DateTime _month = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

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
    final monthKey = (year: _month.year, month: _month.month);
    final summaryKey = (year: _month.year, month: _month.month);
    final rangeKey = (startDate: _ymdStart, endDate: _ymdEnd);
    final summaryAsync = ref.watch(assetSummaryProvider(summaryKey));
    final expensesAsync = ref.watch(monthExpensesProvider(monthKey));
    final categoriesAsync = ref.watch(categoriesProvider);
    final dashboardAsync = ref.watch(dashboardSummaryProvider);
    final summaryRangeAsync = ref.watch(rangeSummaryProvider(rangeKey));
    final prevRange = _prevMonthRange();
    final prevSummaryAsync = ref.watch(
      rangeSummaryProvider((
        startDate: prevRange.start,
        endDate: prevRange.end,
      )),
    );
    final budgetsAsync = ref.watch(monthBudgetsProvider(monthKey));
    final l = AppLocalizations.of(context);

    // 질의마다 그 질의만 다시 받는다(I-06 33) — 실패는 그 구역 안에서만 보인다.
    void retrySummary() => ref.invalidate(assetSummaryProvider(summaryKey));
    void retryRange() => ref.invalidate(rangeSummaryProvider(rangeKey));
    void retryBudgets() => ref.invalidate(monthBudgetsProvider(monthKey));
    void retryExpenses() => ref.invalidate(monthExpensesProvider(monthKey));
    void retryDashboard() => ref.invalidate(dashboardSummaryProvider);

    final dashFirstLoading =
        dashboardAsync.isLoading && !dashboardAsync.hasValue;
    final dash = dashboardAsync.value;
    final events = dash?.upcomingEvents.take(3).toList() ?? const [];
    final todos = dash?.recentTodos.take(3).toList() ?? const [];
    final dashFailed = dashboardAsync.hasError && !dashboardAsync.hasValue;
    // 띠 ③ — 일정 · 할 일이 모두 비면 띠 자체가 없다(빈 흰 띠 · 겹친 틈 0)
    final showSchedule =
        dashFirstLoading || dashFailed || events.isNotEmpty || todos.isNotEmpty;

    final bands = <Widget>[
      _NetWorthBand(
        summaryAsync: summaryAsync,
        masked: ref.watch(hideCardProvider('home.netWorth')),
        onToggleMask: () => context.push('/settings/hide-amounts'),
        onRetry: retrySummary,
      ),
      _band([
        _MonthSection(
          month: _month,
          rangeAsync: summaryRangeAsync,
          prevSummary: prevSummaryAsync.value,
          flags: ref.watch(maskFlagsProvider('home.monthExpense')),
          onRetry: retryRange,
        ),
        _CategorySection(
          month: _month,
          rangeAsync: summaryRangeAsync,
          categoriesAsync: categoriesAsync,
          masked: ref.watch(hideCardProvider('home.categoryDonut')),
          onRetry: retryRange,
        ),
        _BudgetSection(
          budgetsAsync: budgetsAsync,
          rangeAsync: summaryRangeAsync,
          categoriesAsync: categoriesAsync,
          masked: ref.watch(hideCardProvider('home.budget')),
          onRetry: () {
            retryBudgets();
            retryRange();
          },
        ),
      ]),
      if (showSchedule)
        _band([
          if (dashFirstLoading) ...[
            _SchedulePlaceholder(title: l.dashUpcoming),
            _SchedulePlaceholder(title: l.dashRecentTodos),
          ] else if (dashFailed)
            _TextSection(
              header: PCardHeader(title: l.dashUpcoming),
              body: _Failure(
                title: l.dashFailSchedule,
                onRetry: retryDashboard,
              ),
            )
          else ...[
            if (events.isNotEmpty) _UpcomingSection(events: events),
            if (todos.isNotEmpty)
              _TodosSection(
                todos: todos,
                overdue: dash?.todoSummary.overDueCount ?? 0,
              ),
          ],
        ]),
      _band([
        _TodaySection(
          expensesAsync: expensesAsync,
          categoriesAsync: categoriesAsync,
          masked: ref.watch(hideCardProvider('home.todaySpend')),
          onRetry: retryExpenses,
        ),
      ]),
    ];

    return PPullToRefresh(
      onRefresh: () async {
        ref.invalidate(assetSummaryProvider(summaryKey));
        ref.invalidate(monthExpensesProvider(monthKey));
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(rangeSummaryProvider(rangeKey));
        ref.invalidate(monthBudgetsProvider(monthKey));
        await Future.wait([
          ref.read(assetSummaryProvider(summaryKey).future),
          ref.read(monthExpensesProvider(monthKey).future),
          ref.read(dashboardSummaryProvider.future),
          ref.read(rangeSummaryProvider(rangeKey).future),
          ref.read(monthBudgetsProvider(monthKey).future),
        ]);
      },
      child: ListView(
        // 하단 — 떠 있는 하단 바 보상. 머리 바로 아래 첫 띠(순자산)에 틈이 없다.
        padding: EdgeInsets.only(bottom: bottomNavigationInset(context)),
        children: [
          // 개발 서버를 보는 빌드에만 붙인다.
          //
          // dev·prod 는 bundle ID 가 같아 한 번에 하나만 깔리고 서로 덮어쓴다. 아이콘도
          // 이름도 같아서 열기 전에는 어느 쪽인지 알 길이 없다 — 홈 첫 줄에 못을 박아 둔다.
          // 운영 빌드에서는 아무것도 그리지 않는다. 보일 때만 회색 바닥 위에 위 8 · 아래 8 이다.
          if (Env.appEnv != 'prod')
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpacing.x6,
                vertical: PSpacing.x2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PBadge(
                  label: Env.appEnv.toUpperCase(),
                  tone: PBadgeTone.warning,
                ),
              ),
            ),
          // 문자를 복사해 놓고 앱을 연 경우에만 뜬다(iOS). 클립보드 내용은
          // 여기서 읽지 않는다 — 누르기 전까지는 OS 붙여넣기 배너도 뜨지 않는다.
          const SmsClipboardBanner(),
          ...PScreenBands.children(bands),
        ],
      ),
    );
  }
}

// ─── 틀 ──────────────────────────────────────────────────

/// 띠 하나 — 화면 폭 흰 면. 구역이 제 위아래 여백을 가진다(글 구역 24 · 24, 목록 구역 24 · 12 + 줄 12).
Widget _band(List<Widget> sections) => PScreenSection(
  padding: EdgeInsets.zero,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: sections,
  ),
);

/// 구역 머리가 읽는 카드 값 — 글 구역은 머리 아래 8, 목록 구역은 위 24 · 좌우 24 · 아래 4. 머리 동작의 누르는 영역 44 도 준다.
class _SectionScope extends StatelessWidget {
  const _SectionScope({required this.body, required this.child});

  final PCardBody body;
  final Widget child;

  @override
  Widget build(BuildContext context) => PCardScope(
    variant: PCardVariant.standard,
    body: body,
    child: PTouchTargetScope(child: child),
  );
}

/// 글 · 숫자 · 차트 구역 — 사방 24, 머리 ↔ 본문 8.
class _TextSection extends StatelessWidget {
  const _TextSection({required this.header, required this.body});

  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) => _SectionScope(
    body: PCardBody.content,
    child: Padding(
      padding: const EdgeInsets.all(PSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, body],
      ),
    ),
  );
}

/// 목록 구역 — 머리 위 24 · 좌우 24 · 아래 4, 줄이 제 좌우 24 · 위아래 12, 구역 아래 12(마지막 줄 12 와 합쳐 24).
class _ListSection extends StatelessWidget {
  const _ListSection({required this.header, required this.children});

  final Widget header;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => _SectionScope(
    body: PCardBody.list,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        PList(children: children),
        const SizedBox(height: PSpacing.x3),
      ],
    ),
  );
}

/// 구역 머리 — 제목 R4 · 오른쪽 글 버튼 "전체 보기"(이름 "{제목} 전체 보기").
PCardHeader _head(
  BuildContext context,
  String title, {
  VoidCallback? onAll,
  Widget? suffix,
}) => PCardHeader(
  title: title,
  actionLabel: onAll == null ? null : AppLocalizations.of(context).dashViewAll,
  onAction: onAll,
  titleSuffix: suffix,
);

/// 한 질의가 실패한 구역 — 그 안에서 Result Section 으로 알리고 그 질의만 다시 받는다(0원으로 보이지 않는다).
class _Failure extends StatelessWidget {
  const _Failure({required this.title, required this.onRetry});

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PResultSection(
      kind: PResultKind.failure,
      size: PResultSize.medium,
      title: title,
      description: l.dashFailDesc,
      headingLevel: 3,
      placement: PResultPlacement.card,
      primaryAction: PResultAction(label: l.actionRetry, onPressed: onRetry),
    );
  }
}

/// 빈 구역 한 줄 — R9(t3 · 400 · fg-neutral-subtle) 가운데, 위아래 12.
class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: PSpacing.x6,
      vertical: PSpacing.x3,
    ),
    child: Center(
      child: Text(
        keepAll(text),
        textAlign: TextAlign.center,
        style: PTypography.t3.copyWith(color: context.colors.fgNeutralSubtle),
      ),
    ),
  );
}

String _won(int n, bool masked, {String sign = ''}) =>
    krwSigned(n, masked, sign: sign, unit: true, mask: _mask);

/// 금액 값 글 — R13(t5 · 700 · 고정폭), 쉼표 뒤에서만 줄을 바꾼다.
Widget _amount(String text, Color color, {TextStyle? base}) => Text(
  keepAllAmount(text),
  semanticsLabel: text,
  style: (base ?? PTypography.t5).copyWith(
    color: color,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  ),
);

// ─── 띠 ① 순자산 ─────────────────────────────────────────

class _NetWorthBand extends StatelessWidget {
  const _NetWorthBand({
    required this.summaryAsync,
    required this.masked,
    required this.onToggleMask,
    required this.onRetry,
  });

  final AsyncValue<AssetSummary> summaryAsync;
  final bool masked;
  final VoidCallback onToggleMask;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final loading = summaryAsync.isLoading && !summaryAsync.hasValue;
    if (summaryAsync.hasError && !summaryAsync.hasValue) {
      // 브랜드 채움 위에는 Result Section 색이 없다 — 이 구역만 흰 띠로 알린다(P 절)
      return _band([
        _TextSection(
          header: PCardHeader(title: l.assetNetWorth),
          body: _Failure(title: l.dashFailNetWorth, onRetry: onRetry),
        ),
      ]);
    }
    final s = summaryAsync.value;
    final netWorth = s?.netWorth ?? 0;
    final totalAssets = s?.totalAssets ?? 0;
    final totalDebt = s?.totalDebt ?? 0;
    final changePct = s?.changePercent ?? 0.0;
    final noLast = (s?.lastMonthNetWorth ?? 0) == 0;
    const white = Color(0xFFFFFFFF);

    // 면 — 순자산 카드(hero)의 그라디언트 · 장식 빛은 ds 값이다. 폰에서는 띠라 화면 폭 · 모서리 0.
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.x6,
        PSpacing.x4,
        PSpacing.x6,
        PSpacing.x6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(LucideIcons.wallet, size: 16, color: c.staticWhite),
              ),
              const SizedBox(width: PSpacing.x2),
              Expanded(child: PCardHeroLabel(l.assetNetWorth)),
              // 눈 보이는 40 · 아이콘 20 — 아이콘 오른쪽 끝이 글 가장자리 24 에 서게 10 만큼 바깥으로
              Transform.translate(
                offset: const Offset(PSpacing.x2_5, 0),
                child: _HeroEyeButton(
                  masked: masked,
                  label: l.dashHideAmountsSettings,
                  onTap: onToggleMask,
                ),
              ),
            ],
          ),
          if (loading)
            Padding(
              padding: const EdgeInsets.only(top: PSpacing.x1_5),
              child: _heroSkelBar(c, width: 200, height: 42),
            )
          else
            PCardHeroAmount(krwSigned(netWorth, masked, unit: true)),
          // 지난달 기록이 없으면 증감 대신 글(웹 QA #20 — 앱에도)
          if (loading)
            Padding(
              padding: const EdgeInsets.only(top: PSpacing.x1),
              child: _heroSkelBar(c, width: 120, height: 18),
            )
          else if (noLast)
            PCardHeroDetail(text: l.dashNoLastMonth)
          else
            // 브랜드 채움 위 증감 — 흰 ▲ · ▼ + 흰 기준 글(하나뿐인 예외)
            PCardScope(
              variant: PCardVariant.hero,
              body: PCardBody.content,
              child: PCardHeroDetail(
                child: PDelta(
                  direction: changePct > 0
                      ? PDeltaDirection.up
                      : (changePct < 0
                            ? PDeltaDirection.down
                            : PDeltaDirection.flat),
                  value: '${changePct.abs().toStringAsFixed(1)}%',
                  text: l.dashVsLastMonth,
                ),
              ),
            ),
          const SizedBox(height: PSpacing.x5),
          Container(
            padding: const EdgeInsets.only(top: PSpacing.x4_5),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: white.withValues(alpha: 0.14)),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _HeroSplitCol(
                      label: l.navAsset,
                      value: _won(totalAssets, masked),
                      loading: loading,
                    ),
                  ),
                  Container(width: 1, color: white.withValues(alpha: 0.14)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: PSpacing.x4),
                      child: _HeroSplitCol(
                        label: l.dashLiabilities,
                        value: _won(
                          totalDebt.abs(),
                          masked,
                          sign: minusOf(totalDebt),
                        ),
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
    );

    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              key: const ValueKey('home-hero-face'),
              decoration: BoxDecoration(
                gradient: PCardHeroGradient.of(c, Theme.brightnessOf(context)),
              ),
            ),
          ),
          Positioned(
            right: kCardHeroGlowRight,
            top: kCardHeroGlowTop,
            width: kCardHeroGlowSize,
            height: kCardHeroGlowSize,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      radius: math.sqrt2 / 2,
                      colors: [
                        c.staticWhite.withValues(alpha: 0.22),
                        c.staticWhite.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.7],
                    ),
                  ),
                ),
              ),
            ),
          ),
          PCardScope(
            variant: PCardVariant.hero,
            body: PCardBody.content,
            child: content,
          ),
        ],
      ),
    );
  }
}

/// 브랜드 채움 위 불러오는 자리 — 채움 위 Skeleton 짝이 ds 에 없어 흰 18% 막대를 쓴다(ds 짝 없음 — 결과표).
Widget _heroSkelBar(
  PColors c, {
  required double width,
  required double height,
}) => Container(
  width: width,
  height: height,
  decoration: BoxDecoration(
    color: c.staticWhite.withValues(alpha: 0.18),
    borderRadius: BorderRadius.circular(PRounded.r1_5),
  ),
);

/// 금액 가리기 설정 단추 — 보이는 40 · 누르는 44 · 아이콘 20, 흰 아이콘만(둘레 원 · 바탕 없음). 누르면 축소만. 이름은 고정이고
/// 토글이 아니다(`toggled` 없음) — 아이콘이 그 카드의 지금 상태(가렸으면 눈 꺼짐)를 그린다. 누르면 금액 가리기 설정으로 간다.
class _HeroEyeButton extends StatelessWidget {
  const _HeroEyeButton({
    required this.masked,
    required this.label,
    required this.onTap,
  });

  final bool masked;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PressArea(
      enabled: true,
      onTap: onTap,
      semantics: (child, enabled, tap) => Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: label,
        onTap: tap,
        child: child,
      ),
      builder: (context, pressed, size) => PressScale(
        pressed: pressed,
        size: const Size.square(40),
        child: SizedBox.square(
          key: const ValueKey('home-hero-eye'),
          dimension: 40,
          child: Center(
            child: ExcludeSemantics(
              child: Icon(
                masked ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 20,
                color: c.staticWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          keepAll(label),
          semanticsLabel: label,
          style: PTypography.t3.copyWith(
            color: c.staticWhite,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: PSpacing.x1),
        if (loading)
          _heroSkelBar(c, width: 96, height: 22)
        else
          _amount(value, c.staticWhite),
      ],
    );
  }
}

// ─── 띠 ② 이번 달 돈 ──────────────────────────────────────

/// 이번 달 가계부 — 머리 + 수입 · 지출 키-값 두 줄 + 안내 한 줄.
class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.month,
    required this.rangeAsync,
    required this.prevSummary,
    required this.flags,
    required this.onRetry,
  });

  final DateTime month;
  final AsyncValue<RangeSummary> rangeAsync;
  final RangeSummary? prevSummary;

  /// 수입·지출이 각자 종류를 갖는다. 하루평균은 `지출/일수` 라 지출 파생이다.
  final MaskFlags flags;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final head = _head(context, l.dashMonthLedger(month.month));
    final summary = rangeAsync.value;
    if (summary == null) {
      if (rangeAsync.hasError) {
        return _TextSection(
          header: head,
          body: _Failure(title: l.dashFailMonth, onRetry: onRetry),
        );
      }
      // 불러오는 중 — 머리는 그대로, 줄 둘 자리만 Skeleton
      return _ListSection(
        header: head,
        children: [
          for (var i = 0; i < 2; i++)
            const _SkeletonRow(titleWidth: 48, prefix: false),
        ],
      );
    }
    final income = summary.totalIncome;
    final expense = summary.totalExpense;
    final prevExpense = prevSummary?.totalExpense ?? 0;

    final today = DateTime.now();
    final isCurMonth = today.year == month.year && today.month == month.month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final dayOfMonth = isCurMonth ? today.day : daysInMonth;
    final dailyAvg = expense ~/ (dayOfMonth < 1 ? 1 : dayOfMonth);
    final savingsPct = prevExpense > 0
        ? ((prevExpense - expense) / prevExpense) * 100
        : 0.0;
    final saving = savingsPct > 0;
    final expenseMasked = flags.of(MaskKind.expense);

    final note = TextStyle(color: c.fgNeutralSubtle);
    final strong = TextStyle(
      color: c.fgNeutral,
      fontWeight: FontWeight.w700,
      fontFeatures: _tabular,
    );
    return _SectionScope(
      body: PCardBody.list,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          PList(
            children: [
              PListItem(
                title: l.expTypeIncome,
                suffix: PListValue.amount(
                  _won(
                    income,
                    flags.of(MaskKind.income),
                    sign: flags.of(MaskKind.income) ? '' : '+',
                  ),
                  style: TextStyle(
                    color: c.fgBrand,
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
              PListItem(
                title: l.expTypeExpense,
                suffix: PListValue.amount(
                  _won(expense.abs(), expenseMasked, sign: minusOf(expense)),
                  style: TextStyle(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                ),
              ),
            ],
          ),
          // 안내 한 줄 — R9, 금액만 700 · fg-neutral. 좋은지 나쁜지는 글이 말한다(% 색 없음).
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              0,
              PSpacing.x6,
              PSpacing.x6,
            ),
            child: Text.rich(
              TextSpan(
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                children: [
                  TextSpan(text: l.dashDailyAvgPrefix, style: note),
                  TextSpan(
                    text: krwMasked(dailyAvg, expenseMasked),
                    style: strong,
                  ),
                  TextSpan(
                    text: expenseMasked ? l.dashSpentMasked : l.dashSpentUnit,
                    style: note,
                  ),
                  if (prevExpense > 0) ...[
                    TextSpan(text: l.dashVsPrevPrefix, style: note),
                    TextSpan(
                      text: '${savingsPct.abs().toStringAsFixed(0)}%',
                      style: strong,
                    ),
                    TextSpan(
                      text: saving
                          ? l.dashSaving
                          : (savingsPct < 0 ? l.dashSpentMore : l.dashSame),
                      style: note,
                    ),
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

typedef _Seg = ({int? rowId, String name, int amount, String? hex});

/// 카테고리 — 도넛(폰은 가운데 글 없음) + 합계 줄 + 목록 범례.
class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.month,
    required this.rangeAsync,
    required this.categoriesAsync,
    required this.masked,
    required this.onRetry,
  });

  final DateTime month;
  final AsyncValue<RangeSummary> rangeAsync;
  final AsyncValue<List<ExpenseCategory>> categoriesAsync;
  final bool masked;
  final VoidCallback onRetry;

  static const double diameter = 120;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final head = _head(
      context,
      l.expCategory,
      onAll: () => context.go(MoneyTab.stats.location),
    );
    final summary = rangeAsync.value;
    if (summary == null) {
      if (rangeAsync.hasError) {
        return _TextSection(
          header: head,
          body: _Failure(title: l.dashFailCategory, onRetry: onRetry),
        );
      }
      // 첫 불러오기 — 도넛 지름 그대로 + 범례 줄 높이(44) 그대로
      return _TextSection(
        header: head,
        body: Column(
          children: [
            const PSkeleton(
              width: diameter,
              height: diameter,
              radius: PSkeletonRadius.full,
            ),
            const SizedBox(height: PSpacing.x4),
            for (var i = 0; i < 4; i++)
              const SizedBox(
                height: kChartDonutRowHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PSkeleton(height: 14),
                ),
              ),
          ],
        ),
      );
    }

    // 부모 카테고리로 롤업: 부모가 있으면 부모 ID/이름으로, 없으면 자기 자신.
    final rolled = <int, ({String name, int total})>{};
    for (final b in summary.categoryBreakdown) {
      if (b.expenseType != 'EXPENSE') continue;
      final id = b.parentCategoryRowId ?? b.categoryRowId;
      final name = b.parentCategoryName ?? (b.categoryName ?? '-');
      if (id == null) continue;
      final cur = rolled[id];
      rolled[id] = (
        name: cur?.name ?? name,
        total: (cur?.total ?? 0) + b.totalAmount,
      );
    }
    final cats = categoriesAsync.value;
    final segs = <_Seg>[
      for (final e in rolled.entries)
        (
          rowId: e.key,
          name: e.value.name,
          amount: e.value.total,
          hex: cats?.byRowId(e.key)?.color,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    final total = segs.fold<int>(0, (s, e) => s + e.amount);
    if (segs.isEmpty) {
      return _TextSection(header: head, body: _EmptyLine(l.dashNoCategoryData));
    }

    // 색 — 저장된 색(이름표) 먼저, 나머지는 안 쓴 색. 10개를 넘으면 상위 9 + 회색 "기타".
    final colored = assignChartColors<_Seg>(
      segs,
      colorOf: (s) {
        final key = chartKeyOfHex(s.hex);
        return key == null ? null : PChartColor.values.asNameMap()[key];
      },
      groupOthers: (rest) => (
        rowId: null,
        name: l.dashCategoryOthers,
        amount: rest.fold<int>(0, (s, e) => s + e.amount),
        hex: null,
      ),
    );
    String pct(int v) => '${total == 0 ? 0 : (v * 100 / total).round()}%';
    String money(int v) => masked ? _mask : formatWon(v);
    final totalText = masked ? _mask : formatWon(total);
    final label = l.dashCategoryChartLabel(month.month, totalText);

    return _TextSection(
      header: head,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: diameter,
              child: PDonutChart(
                label: label,
                diameter: diameter,
                slices: [
                  for (var i = 0; i < colored.length; i++)
                    PDonutSlice(
                      key: '${colored[i].item.rowId ?? 'others'}-$i',
                      label: colored[i].item.name,
                      amount: colored[i].item.amount.toDouble(),
                      color: colored[i].color,
                    ),
                ],
                valueFormatter: masked ? (_) => _mask : null,
              ),
            ),
          ),
          PChartDataTable(
            caption: label,
            columns: [
              PChartDataColumn(l.expCategory),
              PChartDataColumn(l.dashTableShare),
              PChartDataColumn(l.dashTableAmount),
            ],
            rows: [
              for (final s in colored)
                [s.item.name, pct(s.item.amount), money(s.item.amount)],
            ],
          ),
          const SizedBox(height: PSpacing.x4),
          // 합계 줄 — 폰은 값과 상관없이 늘 목록 위 한 줄(가운데 글 없음)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: PSpacing.x3,
            children: [
              Text(
                l.dashThisMonthExpense,
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _amount(totalText, c.fgNeutral),
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpacing.x1),
          PChartDonutLegend(
            items: [
              for (var i = 0; i < colored.length; i++)
                PChartDonutLegendItem(
                  key: '${colored[i].item.rowId ?? 'others'}-$i',
                  label: colored[i].item.name,
                  color: colored[i].color,
                  percent: pct(colored[i].item.amount),
                  amount: money(colored[i].item.amount),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 예산 — 줄마다 ds Progress(한도). 카테고리 타일 · 주의 구간 색 없음.
class _BudgetSection extends StatelessWidget {
  const _BudgetSection({
    required this.budgetsAsync,
    required this.rangeAsync,
    required this.categoriesAsync,
    required this.masked,
    required this.onRetry,
  });

  final AsyncValue<List<Budget>> budgetsAsync;
  final AsyncValue<RangeSummary> rangeAsync;
  final AsyncValue<List<ExpenseCategory>> categoriesAsync;
  final bool masked;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final head = _head(
      context,
      l.navBudget,
      // 셸 브랜치 라우트 — push 가 아닌 go 로 브랜치 전환 (가계부 nav 활성).
      onAll: () => context.go(MoneyTab.budget.location),
    );
    final budgets = budgetsAsync.value;
    final summary = rangeAsync.value;
    // 쓴 돈은 기간 합계에서 온다 — 기간 합계가 없으면 전부 0 으로 그리지 않고 실패로 알린다
    if (budgets == null || summary == null) {
      if (budgetsAsync.hasError || rangeAsync.hasError) {
        return _TextSection(
          header: head,
          body: _Failure(title: l.dashFailBudget, onRetry: onRetry),
        );
      }
      return _TextSection(
        header: head,
        body: Column(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(height: PSpacing.x5),
              const _ProgressSkeleton(),
            ],
          ],
        ),
      );
    }
    if (budgets.isEmpty) {
      return _TextSection(header: head, body: _EmptyLine(l.dashNoBudget));
    }
    final categories = categoriesAsync.value ?? const <ExpenseCategory>[];
    final spentByCat = <int, int>{};
    for (final b in summary.categoryBreakdown) {
      if (b.expenseType != 'EXPENSE') continue;
      final cid = b.categoryRowId;
      if (cid != null) {
        spentByCat.update(
          cid,
          (v) => v + b.totalAmount,
          ifAbsent: () => b.totalAmount,
        );
      }
      final pid = b.parentCategoryRowId;
      if (pid != null) {
        spentByCat.update(
          pid,
          (v) => v + b.totalAmount,
          ifAbsent: () => b.totalAmount,
        );
      }
    }
    final totalEx = summary.totalExpense;
    String fmt(double v) => masked ? _mask : _won(v.round(), false);
    return _TextSection(
      header: head,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < budgets.length; i++) ...[
            if (i > 0) const SizedBox(height: PSpacing.x5),
            () {
              final b = budgets[i];
              final cat = b.categoryRowId == null
                  ? null
                  : categories.byRowId(b.categoryRowId!);
              final name = b.categoryRowId == null
                  ? l.dashBudgetTotal
                  : l.dashBudgetOf(
                      cat?.categoryName ?? b.categoryName ?? l.expCategory,
                    );
              final spent = b.categoryRowId == null
                  ? totalEx
                  : (spentByCat[b.categoryRowId!] ?? 0);
              return PProgress(
                label: name,
                value: spent.toDouble(),
                max: b.budgetAmount.toDouble(),
                formatValue: fmt,
              );
            }(),
          ],
        ],
      ),
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: PSpacing.x1_5,
    children: [
      PSkeleton.text(PTypography.t4, width: 140),
      const PSkeleton(
        height: PProgressBar.height,
        radius: PSkeletonRadius.full,
      ),
      PSkeleton.text(PTypography.t2, width: 180),
    ],
  );
}

// ─── 띠 ③ 일정 · 할 일 ────────────────────────────────────

/// 한 줄 Skeleton — List 한 줄 46(위아래 12 + 글 22).
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({this.titleWidth = 160, this.prefix = true});

  final double titleWidth;
  final bool prefix;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: PSpacing.x6,
      vertical: PSpacing.x3,
    ),
    child: Row(
      spacing: PSpacing.x3,
      children: [
        if (prefix)
          const PSkeleton(width: 20, height: 20, radius: PSkeletonRadius.full),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: PSkeleton(width: titleWidth, height: 22),
          ),
        ),
        const PSkeleton(width: 40, height: 22),
      ],
    ),
  );
}

/// 첫 불러오기 — 구역 틀(제목) + 줄 Skeleton 둘.
class _SchedulePlaceholder extends StatelessWidget {
  const _SchedulePlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => _ListSection(
    header: PCardHeader(title: title),
    children: const [_SkeletonRow(), _SkeletonRow(titleWidth: 120)],
  );
}

/// 제목이 두 줄을 넘는 줄이 하나라도 있으면 그 목록은 위 맞춤(list.md — 한 목록 안 맞춤을 섞지 않는다).
PListAlign _alignFor(
  BuildContext context,
  double width, {
  required List<String> titles,
  required List<String> suffixes,
  required double prefixWidth,
}) {
  final scaler = MediaQuery.textScalerOf(context);
  double measure(String text, {double? maxWidth}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: PTypography.t5),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: maxWidth ?? double.infinity);
    final w = tp.width;
    tp.dispose();
    return w;
  }

  final suffixW = suffixes.isEmpty
      ? 0.0
      : suffixes.map(measure).reduce(math.max);
  final avail =
      width - 2 * PSpacing.x6 - prefixWidth - PSpacing.x3 - suffixW - 10;
  for (final t in titles) {
    final tp = TextPainter(
      text: TextSpan(text: keepAll(t), style: PTypography.t5),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: math.max(avail, 1));
    final lines = tp.computeLineMetrics().length;
    tp.dispose();
    if (lines > 2) return PListAlign.top;
  }
  return PListAlign.center;
}

String _dayLabel(AppLocalizations l, int daysUntil) => daysUntil == 0
    ? l.dashTodayLabel
    : (daysUntil == 1 ? l.dashTomorrowLabel : l.dashDaysLeft(daysUntil));

/// 다가오는 일정 — ds 누르는 줄. 제목은 줄을 바꾸고, 뒤는 값 글자("오늘" · "내일" · "D-n").
class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.events});

  final List<UpcomingEvent> events;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return _ListSection(
      header: _head(
        context,
        l.dashUpcoming,
        onAll: () => context.go('/calendar'),
      ),
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final align = _alignFor(
              context,
              box.maxWidth,
              titles: [for (final e in events) e.title],
              suffixes: [for (final e in events) _dayLabel(l, e.daysUntil)],
              prefixWidth: 16,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final e in events)
                  PListButtonItem(
                    title: e.title,
                    align: align,
                    onTap: () => context.go('/calendar'),
                    prefix: Padding(
                      padding: EdgeInsets.fromLTRB(
                        PSpacing.x1,
                        align == PListAlign.top ? 7 : 0,
                        PSpacing.x1,
                        0,
                      ),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: resolveChartColor(
                            context,
                            e.color,
                            fallback: c.fgBrand,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    suffix: Text(
                      _dayLabel(l, e.daysUntil),
                      style: TextStyle(
                        color: e.daysUntil <= 3 ? c.fgCritical : null,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// 최근 할 일 — ds 누르는 줄. 앞 원은 표시용(누르면 줄 전체가 할 일로 간다 — 체크가 아니다).
class _TodosSection extends StatelessWidget {
  const _TodosSection({required this.todos, required this.overdue});

  final List<RecentTodo> todos;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    bool isDone(RecentTodo t) => t.status == 'COMPLETED';
    bool isOver(RecentTodo t) =>
        !isDone(t) &&
        t.dueDate != null &&
        t.dueDate!.substring(0, 10).compareTo(todayStr) < 0;
    return _ListSection(
      header: _head(
        context,
        l.dashRecentTodos,
        onAll: () => context.go('/todos'),
        suffix: overdue > 0
            ? PBadge(label: l.dashOverdue(overdue), tone: PBadgeTone.critical)
            : null,
      ),
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final align = _alignFor(
              context,
              box.maxWidth,
              titles: [for (final t in todos) t.title],
              suffixes: [
                for (final t in todos)
                  if (t.dueDate != null) t.dueDate!.substring(5, 10),
              ],
              prefixWidth: 20,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final t in todos)
                  PListButtonItem(
                    title: t.title,
                    titleStrike: isDone(t),
                    align: align,
                    onTap: () => context.go('/todos'),
                    prefix: ExcludeSemantics(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: align == PListAlign.top ? 1 : 0,
                        ),
                        child: isDone(t)
                            ? Icon(
                                LucideIcons.circleCheck,
                                size: 20,
                                color: c.fgPositive,
                              )
                            : Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isOver(t)
                                        ? c.fgCritical
                                        : c.strokeNeutralSolid,
                                    width: 2,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    suffix: t.dueDate == null
                        ? null
                        : Text(
                            t.dueDate!.substring(5, 10),
                            style: TextStyle(
                              color: isOver(t) ? c.fgCritical : null,
                              fontFeatures: _tabular,
                            ),
                          ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── 띠 ④ 오늘 쓴 돈 ──────────────────────────────────────

class _TodaySection extends StatelessWidget {
  const _TodaySection({
    required this.expensesAsync,
    required this.categoriesAsync,
    required this.masked,
    required this.onRetry,
  });

  final AsyncValue<List<Expense>> expensesAsync;
  final AsyncValue<List<ExpenseCategory>> categoriesAsync;
  final bool masked;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final list = expensesAsync.value;
    void onAll() => context.go('/expense');
    if (list == null) {
      if (expensesAsync.hasError) {
        return _TextSection(
          header: _head(context, l.dashTodaySpend, onAll: onAll),
          body: _Failure(title: l.dashFailToday, onRetry: onRetry),
        );
      }
      return _ListSection(
        header: _head(context, l.dashTodaySpend, onAll: onAll),
        children: const [_SkeletonRow(), _SkeletonRow(titleWidth: 120)],
      );
    }
    final categories = categoriesAsync.value ?? const <ExpenseCategory>[];

    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    // 오늘 거래만
    final todayTx = [...list]
      ..removeWhere(
        (e) =>
            e.expenseDate == null ||
            e.expenseDate!.substring(0, 10) != todayStr,
      )
      ..sort((a, b) => (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''));
    // 합계는 집계 규칙 하나(`expenseSum`)로 — 환불한 거래·카드 이월·아직 안 온 거래는
    // 행으로는 보이되(환불은 취소선) 오늘 쓴 돈에는 안 든다(23차 12).
    final todayTotal = expenseSum(todayTx);

    final head = _head(
      context,
      l.dashTodaySpend,
      onAll: onAll,
      suffix: todayTotal > 0
          ? _amount(_won(todayTotal, masked, sign: '−'), c.fgNeutral)
          : null,
    );
    if (todayTx.isEmpty) {
      return _SectionScope(
        body: PCardBody.list,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            head,
            _EmptyLine(l.dashNoTodaySpend),
            const SizedBox(height: PSpacing.x3),
          ],
        ),
      );
    }
    return _ListSection(
      header: head,
      children: [
        for (final e in todayTx)
          // 가계부·검색·거래상세와 **같은 행 위젯**이다(앱에 행 위젯은 이것 하나).
          ExpenseRow(
            expense: e,
            category: _findCategory(categories, e.categoryRowId),
            // 종전 동작 그대로 — 화면 카드('home.todaySpend')만 본다.
            flags: MaskFlags.cardOnly(masked),
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
    );
  }

  ExpenseCategory? _findCategory(List<ExpenseCategory> categories, int? rowId) {
    if (rowId == null) return null;
    for (final c in categories) {
      if (c.rowId == rowId) return c;
    }
    return null;
  }
}
