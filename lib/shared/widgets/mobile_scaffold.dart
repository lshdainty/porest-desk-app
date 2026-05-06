import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../features/expense/presentation/add_tx_sheet.dart';
import 'mobile_header.dart';
import 'mobile_tab_bar.dart';

/// 모바일 셸 — 헤더 + 본문(navigationShell) + 5칸 탭바.
/// FAB 는 [MobileTabBar] 안에 인라인.
class MobileScaffold extends StatelessWidget {
  const MobileScaffold({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  static const _titles = ['홈', '가계부', '통계', '전체'];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final idx = navigationShell.currentIndex;
    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: MobileHeader(title: _titles[idx]),
      body: navigationShell,
      bottomNavigationBar: MobileTabBar(
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
