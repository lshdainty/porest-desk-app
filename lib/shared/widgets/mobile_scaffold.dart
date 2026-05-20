import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../features/expense/presentation/add_tx_sheet.dart';
import 'mobile_header.dart';
import 'mobile_tab_bar.dart';
import 'money_tab_bar.dart';

/// 모바일 셸 — 헤더 + 본문(navigationShell) + 5칸 탭바.
/// FAB 는 [MobileTabBar] 안에 인라인.
class MobileScaffold extends StatelessWidget {
  const MobileScaffold({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  static const _titles = ['홈', '가계부', '캘린더', '전체'];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final idx = navigationShell.currentIndex;
    // 가계부 branch (idx=1) 는 money sub-nav 표시 — ← / 가계부 / 자산 / 통계 / 예산.
    // 다른 branch 는 기본 5칸 (홈 / 가계부 / + / 캘린더 / 전체).
    final isMoneyBranch = idx == 1;
    // money branch 안 path 별 sub-tab 분기 — shell scaffold 가 한 번 build 되어
    // 4 sub-tab 전환 시에도 bottom bar 가 안 끊김 (사라졌다 다시 안 나타남).
    final routePath = GoRouterState.of(context).matchedLocation;
    final moneyCurrent = switch (routePath) {
      '/assets' => MoneyTab.assets,
      '/stats' => MoneyTab.stats,
      '/budget' => MoneyTab.budget,
      _ => MoneyTab.expense,
    };
    // shell appBar 는 /expense (자체 AppBar 없음) 일 때만 표시 —
    // /assets, /stats, /budget 은 각 screen 자체 AppBar (title + actions 보존).
    final showShellAppBar = !isMoneyBranch || routePath == '/expense';
    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: showShellAppBar ? MobileHeader(title: _titles[idx]) : null,
      body: navigationShell,
      bottomNavigationBar: isMoneyBranch
          ? MoneyTabBar(
              current: moneyCurrent,
              onTap: (tab) {
                final target = switch (tab) {
                  MoneyTab.expense => '/expense',
                  MoneyTab.assets => '/assets',
                  MoneyTab.stats => '/stats',
                  MoneyTab.budget => '/budget',
                };
                if (target != routePath) context.go(target);
              },
              onBack: () => navigationShell.goBranch(0), // 홈으로
            )
          : MobileTabBar(
              currentBranch: idx,
              onTapBranch: (branch) => navigationShell.goBranch(
                branch,
                initialLocation: branch == idx,
              ),
              onAddTx: () => showAddTxSheet(context),
            ),
    );
  }
}
