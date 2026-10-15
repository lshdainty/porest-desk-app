// 모바일 셸의 틀 — 상단 바(root) · 가계부 Line Tabs · 하단 탭 바(+ 이름 · 다시 누르기).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/widgets/mobile_scaffold.dart';

class _Screen extends StatelessWidget {
  const _Screen(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Text(name),
      for (var i = 0; i < 60; i++) SizedBox(height: 60, child: Text('$name$i')),
    ],
  );
}

GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => MobileScaffold(navigationShell: shell),
      branches: [
        for (final paths in [
          ['/home'],
          ['/expense', '/assets', '/stats', '/budget'],
          ['/calendar'],
          ['/more'],
        ])
          StatefulShellBranch(
            routes: [
              for (final p in paths)
                GoRoute(path: p, builder: (_, _) => _Screen(p.substring(1))),
            ],
          ),
      ],
    ),
  ],
);

void main() {
  Future<GoRouter> pump(
    WidgetTester tester,
    String initial, {
    int unread = 0,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final router = _router(initial);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [unreadCountProvider.overrideWith((ref) async => unread)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Finder tab(String name) => find.bySemanticsLabel(name);

  testWidgets('홈 — root 상단 바 제목 · 검색 + 알림, + 는 거래 추가', (tester) async {
    final h = tester.ensureSemantics();
    await pump(tester, '/home');
    final bar = tester.widget<PTopNavigation>(find.byType(PTopNavigation));
    expect(bar.type, PTopNavigationType.root);
    expect(bar.title, '홈');
    expect(bar.actions, hasLength(2));
    expect(find.byType(PTabs<String>), findsNothing);
    expect(find.bySemanticsLabel('거래 추가'), findsOneWidget);
    h.dispose();
  });

  testWidgets('안 읽은 알림이 있으면 벨에 점과 이름이 붙는다', (tester) async {
    await pump(tester, '/home', unread: 3);
    final bell = tester
        .widgetList<PTopNavigationIconButton>(
          find.byType(PTopNavigationIconButton),
        )
        .last;
    expect(bell.notification, isTrue);
    expect(bell.label, '알림 새 소식');
  });

  testWidgets('캘린더 — 검색만, + 는 일정 추가', (tester) async {
    final h = tester.ensureSemantics();
    await pump(tester, '/calendar');
    final bar = tester.widget<PTopNavigation>(find.byType(PTopNavigation));
    expect(bar.title, '캘린더');
    expect(bar.actions, hasLength(1));
    expect(find.bySemanticsLabel('일정 추가'), findsOneWidget);
    h.dispose();
  });

  testWidgets('가계부 — 탭 바는 "가계부" 현재, 위 Line Tabs 가 네 화면을 오간다', (tester) async {
    final router = await pump(tester, '/assets');
    final tabs = tester.widget<PTabs<String>>(find.byType(PTabs<String>));
    expect(tabs.value, '/assets');
    expect(tabs.items.map((t) => t.label), ['가계부', '자산', '통계·분석', '예산']);
    expect(
      tester.widget<PTopNavigation>(find.byType(PTopNavigation)).title,
      '가계부',
    );
    final bar = tester.widget<PBottomNavigation>(
      find.byType(PBottomNavigation),
    );
    expect(bar.items.map((i) => i.current), [false, true, false, false]);

    await tester.tap(find.text('예산').first);
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, '/budget');
    expect(
      tester.widget<PTabs<String>>(find.byType(PTabs<String>)).value,
      '/budget',
    );
  });

  testWidgets('가계부 탭을 다시 누르면 첫 화면(/expense)으로 간다', (tester) async {
    final router = await pump(tester, '/stats');
    await tester.tap(
      find.byKey(const ValueKey('bottom-navigation-item')).at(1),
    );
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, '/expense');
  });

  testWidgets('지금 탭을 다시 누르면 맨 위로 올라간다', (tester) async {
    await pump(tester, '/home');
    final list = find.byType(ListView).first;
    await tester.drag(list, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      greaterThan(0),
    );

    await tester.tap(
      find.byKey(const ValueKey('bottom-navigation-item')).at(0),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      0,
    );
  });

  testWidgets('다른 탭을 누르면 그 branch 로 간다', (tester) async {
    final router = await pump(tester, '/home');
    await tester.tap(
      find.byKey(const ValueKey('bottom-navigation-item')).at(3),
    );
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, '/more');
  });
}
