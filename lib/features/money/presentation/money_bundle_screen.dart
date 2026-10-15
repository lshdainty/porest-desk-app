import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';

/// 가계부 묶음의 탭 — 가계부 · 자산 · 통계 · 예산. 값은 `/expense?tab=` 쿼리 값이다.
enum MoneyTab {
  expense('expense', '/expense'),
  assets('assets', '/assets'),
  stats('stats', '/stats'),
  budget('budget', '/budget');

  const MoneyTab(this.query, this.legacyPath);

  /// `/expense?tab=<query>` 의 값 — 없으면 [expense].
  final String query;

  /// 묶음이 갈라지기 전 라우트 경로 — 화면 보임 판정(`activeShellRouteProvider`)과
  /// 진입 갱신(`tabQueries`)이 이 이름으로 키를 잡는다.
  final String legacyPath;

  static MoneyTab fromQuery(String? value) => MoneyTab.values.firstWhere(
    (t) => t.query == value,
    orElse: () => MoneyTab.expense,
  );

  /// 묶음으로 들어가는 주소 — 어디서든 이 주소로 탭을 고른다.
  String get location =>
      this == MoneyTab.expense ? '/expense' : '/expense?tab=$query';
}

/// 셸이 지금 보이는 라우트로 적을 이름 — 가계부 묶음(`/expense`)이면 고른 탭의 경로.
String shellActivePath(Uri uri, String matchedLocation) =>
    matchedLocation == '/expense'
    ? MoneyTab.fromQuery(uri.queryParameters['tab']).legacyPath
    : matchedLocation;

/// 가계부 묶음 — 한 화면 안 Tabs(가계부 · 자산 · 통계 · 예산).
///
/// 네 화면은 모두 계속 mount 되어 있다 — 탭을 옮겨도 앞 탭의 스크롤 · 입력이 남는다.
/// 좌우로 밀어도 옮겨진다. 고른 탭은 주소(`/expense?tab=`)가 쥔다: 탭을 누르거나
/// 밀면 같은 라우트의 쿼리만 바뀌어 페이지(와 그 안 상태)는 그대로다. 기존 경로
/// (`/assets` · `/stats` · `/budget`)는 router 가 이 주소로 보낸다.
class MoneyBundleScreen extends StatefulWidget {
  const MoneyBundleScreen({required this.tab, required this.pages, super.key})
    : assert(pages.length == 4, '가계부 · 자산 · 통계 · 예산 네 화면');

  final MoneyTab tab;

  /// [MoneyTab.values] 순서의 네 화면.
  final List<Widget> pages;

  @override
  State<MoneyBundleScreen> createState() => _MoneyBundleScreenState();
}

class _MoneyBundleScreenState extends State<MoneyBundleScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.tab.index,
  );
  bool _animating = false;

  @override
  void didUpdateWidget(MoneyBundleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final page = _controller.page?.round() ?? _controller.initialPage;
    if (widget.tab.index != page) _showPage(widget.tab.index);
  }

  Future<void> _showPage(int index) async {
    if (!_controller.hasClients) return;
    _animating = true;
    try {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _controller.jumpToPage(index);
      } else {
        await _controller.animateToPage(
          index,
          duration: PDuration.d4,
          curve: PEasing.easing,
        );
      }
    } finally {
      _animating = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 같은 라우트에서 탭만 바꾼다 — 다른 쿼리(month · txId · assetId)는 그대로 둔다.
  void _select(MoneyTab tab) {
    if (tab == widget.tab) return;
    final uri = GoRouterState.of(context).uri;
    final query = {...uri.queryParameters};
    if (tab == MoneyTab.expense) {
      query.remove('tab');
    } else {
      query['tab'] = tab.query;
    }
    context.go(
      Uri(
        path: uri.path,
        queryParameters: query.isEmpty ? null : query,
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = [l.navExpense, l.navAsset, l.moreItemStats, l.navBudget];
    return Column(
      children: [
        PTabs<MoneyTab>(
          semanticLabel: l.navExpense,
          size: PTabsSize.medium,
          value: widget.tab,
          onChanged: _select,
          items: [
            for (final t in MoneyTab.values)
              PTab(value: t, label: labels[t.index]),
          ],
        ),
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (i) {
              if (!_animating) _select(MoneyTab.values[i]);
            },
            children: [for (final p in widget.pages) _KeepAlive(child: p)],
          ),
        ),
      ],
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
