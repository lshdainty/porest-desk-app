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
    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: MobileHeader(title: _titles[idx]),
      body: navigationShell,
      bottomNavigationBar: isMoneyBranch
          ? MoneyTabBar(
              current: MoneyTab.expense,
              onTap: (tab) => switch (tab) {
                MoneyTab.expense => null, // 이미 현재 — no-op
                MoneyTab.assets => context.go('/assets'),
                MoneyTab.stats => context.go('/stats'),
                MoneyTab.budget => context.go('/budget'),
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
