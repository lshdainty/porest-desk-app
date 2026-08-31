import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/calendar/presentation/calendar_event_dialog.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/shared/widgets/mobile_header.dart';
import 'package:porest_desk_app/shared/widgets/p_tab_bar.dart';

/// 모바일 셸 — 헤더 + 본문(navigationShell) + 5칸 탭바.
/// FAB 는 [MobileTabBar] 안에 인라인.
class MobileScaffold extends ConsumerStatefulWidget {
  const MobileScaffold({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MobileScaffold> createState() => _MobileScaffoldState();
}

class _MobileScaffoldState extends ConsumerState<MobileScaffold> {
  String? _lastPath;
  // iOS 27 Liquid Glass tabBarMinimizeBehavior — 스크롤 방향 누적 판정.
  final PTabBarCompactController _tabBarCompact = PTabBarCompactController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 셸(IndexedStack) 화면은 계속 mount 되어 initState 진입 갱신이 안 되므로,
    // 라우트가 바뀔 때 진입 경로가 watch 하는 keepAlive provider 를 갱신한다.
    // build 직전 호출이라 provider 변경은 microtask 로 다음 프레임에 미룬다.
    final path = GoRouterState.of(context).matchedLocation;
    if (path != _lastPath) {
      _lastPath = path;
      Future.microtask(() {
        if (mounted) invalidateKeepAliveForRoute(ref, path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final navigationShell = widget.navigationShell;
    final idx = navigationShell.currentIndex;
    // 가계부 branch (idx=1) 는 money sub-nav 표시 — ← / 가계부 / 자산 / 통계 / 예산.
    // 다른 branch 는 기본 5칸 (홈 / 가계부 / + / 캘린더 / 전체).
    final isMoneyBranch = idx == 1;
    // money branch 안 path 별 sub-tab 분기 — shell scaffold 가 한 번 build 되어
    // 4 sub-tab 전환 시에도 bottom bar 가 안 끊김 (사라졌다 다시 안 나타남).
    final routePath = GoRouterState.of(context).matchedLocation;
    // shell appBar title — money branch 의 4 path 별 분기 (각 screen 자체 AppBar
    // 제거됨 — actions(theme/eye/bell/search) 는 모든 path 에서 MobileHeader 가 일관 표시).
    final titles = [l.navHome, l.navExpense, l.navCalendar, l.navMore];
    final title = isMoneyBranch
        ? switch (routePath) {
            '/assets' => l.navAsset,
            '/stats' => l.moreItemStats,
            '/budget' => l.navBudget,
            _ => l.navExpense,
          }
        : titles[idx];
    void goMoney(String target) {
      if (target != routePath) context.go(target);
    }

    void onAddTx() {
      if (idx == 2) {
        // 캘린더 탭 — 일정 등록
        showCalendarEventDialog(context, defaultDate: DateTime.now());
      } else {
        showAddTxSheet(context);
      }
    }

    return Scaffold(
      backgroundColor: t.bgSurface,
      // Liquid Glass 플로팅 탭바 — 콘텐츠가 바 뒤로 지나가며 블러에 비친다.
      extendBody: true,
      // 헤더 아이콘은 페이지당 1개 — 홈=알림 벨, 그 외=검색 (클로드 디자인 정합).
      appBar: MobileHeader(
        title: title,
        trailingIcon: idx == 0 ? LucideIcons.bell : LucideIcons.search,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _tabBarCompact.onScroll,
        child: navigationShell,
      ),
      // 한 인스턴스로 두 모드를 렌더 — 모드 전환 스태거 안무(공유 탭 = 가계부).
      bottomNavigationBar: PTabBar(
        controller: _tabBarCompact,
        modeKey: isMoneyBranch ? 'money' : 'default',
        sharedIndexes: const {1},
        children: isMoneyBranch
            ? [
                PTabBarBack(onTap: () => navigationShell.goBranch(0)),
                PTabBarItem(
                  icon: LucideIcons.receiptText,
                  label: l.navExpense,
                  selected: routePath == '/expense',
                  onTap: () => goMoney('/expense'),
                ),
                PTabBarItem(
                  icon: LucideIcons.wallet,
                  label: l.navAsset,
                  selected: routePath == '/assets',
                  onTap: () => goMoney('/assets'),
                ),
                PTabBarItem(
                  icon: LucideIcons.chartPie,
                  label: l.moreItemStats,
                  selected: routePath == '/stats',
                  onTap: () => goMoney('/stats'),
                ),
                PTabBarItem(
                  icon: LucideIcons.filePen,
                  label: l.navBudget,
                  selected: routePath == '/budget',
                  onTap: () => goMoney('/budget'),
                ),
              ]
            : [
                PTabBarItem(
                  icon: LucideIcons.home,
                  label: l.navHome,
                  selected: idx == 0,
                  onTap: () =>
                      navigationShell.goBranch(0, initialLocation: idx == 0),
                ),
                PTabBarItem(
                  icon: LucideIcons.receiptText,
                  label: l.navExpense,
                  selected: idx == 1,
                  onTap: () =>
                      navigationShell.goBranch(1, initialLocation: idx == 1),
                ),
                PTabBarFab(onTap: onAddTx),
                PTabBarItem(
                  icon: LucideIcons.calendar1,
                  label: l.navCalendar,
                  selected: idx == 2,
                  onTap: () =>
                      navigationShell.goBranch(2, initialLocation: idx == 2),
                ),
                PTabBarItem(
                  icon: LucideIcons.menu,
                  label: l.navMore,
                  selected: idx == 3,
                  onTap: () =>
                      navigationShell.goBranch(3, initialLocation: idx == 3),
                ),
              ],
      ),
    );
  }
}
