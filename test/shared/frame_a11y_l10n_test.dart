// 틀의 낭독 — 화면 제목은 headingLevel 1, 목록 제목은 2, 하단 바 이름 · 벨 이름 · + 이름은 로케일을 따른다(02-003 · 02-004).
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/widgets/mobile_scaffold.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => MobileScaffold(navigationShell: shell),
      branches: [
        for (final p in ['/home', '/expense', '/calendar', '/more'])
          StatefulShellBranch(
            routes: [
              GoRoute(path: p, builder: (_, _) => const SizedBox.shrink()),
            ],
          ),
      ],
    ),
  ],
);

Iterable<SemanticsData> _nodes(WidgetTester tester) {
  final out = <SemanticsData>[];
  void walk(SemanticsNode n) {
    out.add(n.getSemanticsData());
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return out;
}

void main() {
  for (final lang in ['ko', 'en']) {
    testWidgets('셸 낭독 [$lang] — 제목 1단계 · 주 메뉴 · 벨 · +', (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      final router = _router();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [unreadCountProvider.overrideWith((ref) async => 2)],
          child: MaterialApp.router(
            routerConfig: router,
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(lang),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final nodes = _nodes(tester).toList();
      final want = lang == 'ko'
          ? (title: '홈', menu: '주 메뉴', bell: '알림, 새 알림 있음', add: '거래 추가')
          : (
              title: 'Home',
              menu: 'Main menu',
              bell: 'Notifications, new notifications',
              add: 'Add transaction',
            );
      expect(
        nodes.any((n) => n.label == want.title && n.headingLevel == 1),
        isTrue,
        reason: '화면 제목은 headingLevel 1',
      );
      expect(nodes.any((n) => n.label == want.menu), isTrue);
      expect(nodes.any((n) => n.label.contains(want.bell)), isTrue);
      expect(nodes.any((n) => n.label == want.add), isTrue);
      handle.dispose();
    });
  }

  testWidgets('목록 제목은 headingLevel 2', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: const Scaffold(body: PListHeader(title: '카테고리별 예산')),
      ),
    );
    await tester.pump();
    expect(
      _nodes(tester).any((n) => n.label == '카테고리별 예산' && n.headingLevel == 2),
      isTrue,
    );
    handle.dispose();
  });
}
