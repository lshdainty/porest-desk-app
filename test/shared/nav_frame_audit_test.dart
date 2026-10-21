// 틀 대조 — 상단 바 · 가계부 Tabs · 하단 탭 바 · 본문 바닥이 스펙 값(DESIGN.desk.md 화면 틀 ·
// Safe Area · Elevation, top/bottom-navigation · tabs 스펙)과 같은지 폭 360 · 390 · 768 ×
// 라이트 · 다크 × 안전 영역 없음 · 있음으로 잰다. 표(audit-app.md)의 값 원본이다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart' show TextScaler;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/money/presentation/money_bundle_screen.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/widgets/mobile_scaffold.dart';

class _Body extends StatelessWidget {
  const _Body(this.name);
  final String name;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('$name$i')),
    ],
  );
}

GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => MobileScaffold(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (_, _) => const _Body('h'))],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expense',
              builder: (_, s) => MoneyBundleScreen(
                tab: MoneyTab.fromQuery(s.uri.queryParameters['tab']),
                pages: const [_Body('e'), _Body('a'), _Body('s'), _Body('b')],
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/calendar', builder: (_, _) => const _Body('c')),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/more', builder: (_, _) => const _Body('m'))],
        ),
      ],
    ),
  ],
);

final List<String> _rows = [];
int _bad = 0;

void _check(String where, String name, Object? actual, Object? expected) {
  final ok = actual == expected;
  if (!ok) _bad++;
  _rows.add(
    '${ok ? "OK " : "BAD"} | $where | $name | 스펙 $expected | 구현 $actual',
  );
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

double _lum(Color c) {
  double f(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
}

double _contrast(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  final hi = math.max(x, y), lo = math.min(x, y);
  return (hi + 0.05) / (lo + 0.05);
}

String _style(TextStyle s) =>
    '${s.fontSize}/${(s.height! * s.fontSize!).round()}/${s.fontWeight?.value}';

/// 읽기 트리의 모든 노드(병합된 데이터).
Iterable<SemanticsData> _nodes(WidgetTester tester) sync* {
  final out = <SemanticsData>[];
  void walk(SemanticsNode n) {
    out.add(n.getSemanticsData());
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  yield* out;
}

void main() {
  tearDownAll(() {
    // ignore: avoid_print
    print('AUDIT\n${_rows.join('\n')}\nBAD=$_bad');
  });

  for (final width in [360.0, 390.0, 768.0]) {
    for (final dark in [false, true]) {
      for (final safe in [(top: 0.0, bottom: 0.0), (top: 47.0, bottom: 34.0)]) {
        final where =
            '${width.toInt()} ${dark ? "다크" : "라이트"} 안전 ${safe.top.toInt()}/${safe.bottom.toInt()}';
        testWidgets('틀 · $where', (tester) async {
          tester.view.physicalSize = Size(width * 3, 844 * 3);
          tester.view.devicePixelRatio = 3.0;
          tester.view.padding = FakeViewPadding(
            top: safe.top * 3,
            bottom: safe.bottom * 3,
          );
          tester.view.viewPadding = tester.view.padding;
          addTearDown(tester.view.reset);
          final router = _router('/home');
          addTearDown(router.dispose);
          final theme = dark ? GrooTheme.dark() : GrooTheme.light();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [unreadCountProvider.overrideWith((ref) async => 0)],
              child: MaterialApp.router(
                routerConfig: router,
                theme: theme,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('ko'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final c = theme.extension<PColors>()!;
          final screen = Size(width, 844);

          // ── 본문 바닥 · 바
          final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
          _check(
            where,
            '셸 바닥색(Elevation 층 0)',
            _hex(scaffold.backgroundColor!),
            _hex(c.bgLayerBasement),
          );
          _check(
            where,
            'basement 값',
            _hex(c.bgLayerBasement),
            dark ? '#1A1F2E' : '#F5F6FA',
          );
          _check(
            where,
            'default 값',
            _hex(c.bgLayerDefault),
            dark ? '#242938' : '#FFFFFF',
          );

          // ── 상단 바(root)
          final bar = tester.getRect(
            find.byKey(const ValueKey('top-navigation')),
          );
          _check(where, '상단 바 높이(56 + 위 안전 영역)', bar.height, 56 + safe.top);
          _check(where, '상단 바 폭 = 화면 폭(바탕 끝까지)', bar.width, width);
          _check(where, '상단 바 위치 top', bar.top, 0.0);
          final barBox = tester.widget<Container>(
            find.byKey(const ValueKey('top-navigation')),
          );
          _check(
            where,
            '상단 바 바탕(불투명 bg-layer-default)',
            _hex(barBox.color!),
            _hex(c.bgLayerDefault),
          );
          _check(where, '상단 바 선 · 그림자 없음', barBox.decoration == null, true);
          final title = tester.widget<Text>(
            find.byKey(const ValueKey('top-navigation-title')),
          );
          _check(where, '제목 글자 크기(root t8)', title.style!.fontSize, 22.0);
          _check(
            where,
            '제목 줄 높이 30',
            (title.style!.height! * title.style!.fontSize!).round(),
            30,
          );
          _check(where, '제목 굵기 700', title.style!.fontWeight, FontWeight.w700);
          _check(
            where,
            '제목 색 fg-neutral',
            _hex(title.style!.color!),
            _hex(c.fgNeutral),
          );
          final titleRect = tester.getRect(
            find.byKey(const ValueKey('top-navigation-title')),
          );
          _check(where, '제목 왼쪽(화면 끝 16)', titleRect.left, 16.0);
          _check(
            where,
            '제목 세로 중심이 안전 영역 아래 56 의 가운데',
            (titleRect.center.dy - (safe.top + 28)).abs() < 1,
            true,
          );
          final buttons = find.byKey(
            const ValueKey('top-navigation-icon-button'),
          );
          final last = tester.getRect(buttons.last);
          _check(where, '맨 끝 버튼 상자 오른쪽 여백 6', width - last.right, 6.0);
          _check(where, '아이콘 버튼 상자 44', last.size, const Size(44, 44));
          _check(where, '버튼 상자는 안전 영역 아래', last.top >= safe.top, true);

          // ── 하단 탭 바
          final pill = tester.getRect(
            find.byKey(const ValueKey('bottom-navigation-bar')),
          );
          final expectBottom = (safe.bottom - 6) > 14 ? safe.bottom - 6 : 14.0;
          _check(where, '탭 바 높이 66', pill.height, 66.0);
          final w = width - 28;
          _check(
            where,
            '탭 바 폭(좌우 14 · 최대 480)',
            pill.width,
            w > 480 ? 480.0 : w,
          );
          _check(
            where,
            '탭 바 아래 여백(max(14, 안전 − 6))',
            844 - pill.bottom,
            expectBottom,
          );
          _check(
            where,
            '탭 바 가운데 정렬',
            ((pill.center.dx) - width / 2).abs() < 0.5,
            true,
          );
          final pillBox = tester.widget<AnimatedContainer>(
            find.byKey(const ValueKey('bottom-navigation-bar')),
          );
          final deco = pillBox.decoration! as BoxDecoration;
          _check(
            where,
            '탭 바 바탕 bg-layer-floating(불투명)',
            _hex(deco.color!),
            _hex(c.bgLayerFloating),
          );
          _check(
            where,
            '탭 바 그림자 s3',
            deco.boxShadow,
            theme.extension<PShadows>()!.s3,
          );
          _check(
            where,
            '탭 바 안쪽 1px stroke-neutral-subtle',
            _hex(
              ((pillBox.foregroundDecoration! as BoxDecoration).border!
                      as Border)
                  .top
                  .color,
            ),
            _hex(c.strokeNeutralSubtle),
          );
          final cells = find.byKey(const ValueKey('bottom-navigation-item'));
          final cell0 = tester.getRect(cells.first);
          _check(
            where,
            '칸 누르는 영역 ≥ 44',
            cell0.height >= 44 && cell0.width >= 44,
            true,
          );
          _check(
            where,
            '탭 바는 안전 영역 아래 칸 끝(누르는 칸이 홈 표시줄 위)',
            cell0.bottom <= 844 - safe.bottom + 0.01,
            true,
          );

          // ── 본문 아래 여백
          final ctx = tester.element(find.byType(PBottomNavigation));
          _check(
            where,
            '본문 아래 여백(바 아래 자리 + 66 + 24)',
            bottomNavigationInset(ctx),
            expectBottom + 66 + 24,
          );
          // 맨 끝까지 내리면 마지막 줄이 바 위 24 에서 끝난다 — 셸 본문 높이
          final bodyRect = tester.getRect(find.byType(ListView).first);
          _check(where, '본문이 상단 바 바로 아래에서 시작', bodyRect.top, bar.bottom);

          // ── 읽기
          final handle = tester.ensureSemantics();
          await tester.pump();
          _check(
            where,
            '탭 바 이름 "주 메뉴"',
            find.bySemanticsLabel('주 메뉴').evaluate().isNotEmpty,
            true,
          );
          _check(
            where,
            '제목은 header 노드(이름 = 제목)',
            _nodes(
              tester,
            ).any((n) => n.label == '홈' && n.flagsCollection.isHeader),
            true,
          );
          handle.dispose();

          // ── 가계부 묶음 — Tabs
          router.go('/expense');
          await tester.pumpAndSettle();
          final tabs = tester.getRect(find.byType(PTabs<MoneyTab>));
          _check(where, 'Tabs 높이 medium 44(막대 포함 목록)', tabs.height, 44.0);
          _check(where, 'Tabs 위치 = 상단 바 바로 아래', tabs.top, bar.bottom);
          _check(where, 'Tabs 폭 = 화면 폭', tabs.width, width);
          _check(
            where,
            '가계부 제목',
            tester.widget<PTopNavigation>(find.byType(PTopNavigation)).title,
            '가계부',
          );
          final textScaler = tester.widget<PTopNavigation>(
            find.byType(PTopNavigation),
          );
          _check(
            where,
            '제목 글자 크기 설정 1.2 배 상한',
            kTopNavigationMaxTextScale,
            1.2,
          );
          textScaler.hashCode;
          TextScaler.noScaling;
        });
      }
    }
  }

  // ── 글자 — 상단 바 제목 · 하단 바 라벨 · Tabs 라벨 · 배율 · 대비
  for (final dark in [false, true]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      final where = '390 ${dark ? "다크" : "라이트"} 글자 ×$scale';
      testWidgets('글자 · $where', (tester) async {
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final router = _router('/expense');
        addTearDown(router.dispose);
        final theme = dark ? GrooTheme.dark() : GrooTheme.light();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [unreadCountProvider.overrideWith((ref) async => 3)],
            child: MaterialApp.router(
              routerConfig: router,
              theme: theme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ko'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final c = theme.extension<PColors>()!;
        _check(where, '넘침 · 예외 없음', tester.takeException(), null);

        final title = tester.widget<Text>(
          find.byKey(const ValueKey('top-navigation-title')),
        );
        _check(
          where,
          '상단 바 제목 크기/줄/굵기 t8·700',
          _style(title.style!),
          '22.0/30/700',
        );
        final titleBox = tester.getSize(
          find.byKey(const ValueKey('top-navigation-title')),
        );
        _check(
          where,
          '상단 바 제목 한 줄 높이 ≤ 56 (배율 상한 1.2)',
          titleBox.height <= 56,
          true,
        );
        _check(
          where,
          '상단 바 높이 배율과 무관 56',
          tester.getSize(find.byKey(const ValueKey('top-navigation'))).height,
          56.0,
        );
        _check(
          where,
          '제목 대비 ≥ 4.5',
          _contrast(c.fgNeutral, c.bgLayerDefault) >= 4.5,
          true,
        );

        // 하단 바 라벨 — t1 11/15 500, 글자 크기 설정을 따르지 않음
        final bar = find.byKey(const ValueKey('bottom-navigation-bar'));
        final labels = tester
            .widgetList<Text>(
              find.descendant(of: bar, matching: find.byType(Text)),
            )
            .toList();
        _check(where, '하단 바 라벨 4개', labels.length, 4);
        for (final t in labels) {
          _check(
            where,
            '하단 바 라벨 "${t.data}" 크기/줄/굵기 t1·500',
            _style(t.style!),
            '11.0/15/500',
          );
          _check(
            where,
            '하단 바 라벨 "${t.data}" 배율 고정',
            t.textScaler,
            TextScaler.noScaling,
          );
        }
        final cur = labels[1].style!.color!;
        final other = labels[0].style!.color!;
        _check(where, '지금 탭 라벨 색 fg-neutral', _hex(cur), _hex(c.fgNeutral));
        _check(
          where,
          '다른 탭 라벨 색 fg-neutral-subtle',
          _hex(other),
          _hex(c.fgNeutralSubtle),
        );
        _check(
          where,
          '지금 탭 라벨 대비 ≥ 4.5',
          _contrast(cur, c.bgLayerFloating) >= 4.5,
          true,
        );
        _check(
          where,
          '다른 탭 라벨 대비 ≥ 4.5',
          _contrast(other, c.bgLayerFloating) >= 4.5,
          true,
        );

        // Tabs medium — t5 16/22 700, 고른 fg-neutral · 안 고른 fg-neutral-subtle
        final tabTexts = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(PTabs<MoneyTab>),
                matching: find.byType(Text),
              ),
            )
            .toList();
        _check(where, 'Tabs 라벨 4개', tabTexts.length, 4);
        for (final t in tabTexts) {
          _check(
            where,
            'Tabs 라벨 "${t.data}" 크기/줄/굵기 t5·700',
            _style(t.style!),
            '16.0/22/700',
          );
        }
        _check(
          where,
          'Tabs 고른 라벨 색',
          _hex(tabTexts[0].style!.color!),
          _hex(c.fgNeutral),
        );
        _check(
          where,
          'Tabs 안 고른 라벨 색',
          _hex(tabTexts[1].style!.color!),
          _hex(c.fgNeutralSubtle),
        );
        _check(
          where,
          'Tabs 안 고른 라벨 대비 ≥ 4.5',
          _contrast(c.fgNeutralSubtle, c.bgLayerDefault) >= 4.5,
          true,
        );

        // 읽기 — 알림 점이 이름에 들어간다
        router.go('/home');
        await tester.pumpAndSettle();
        final h = tester.ensureSemantics();
        await tester.pump();
        _check(
          where,
          '벨 이름 "알림, 새 알림 있음"',
          _nodes(tester).any((n) => n.label.contains('알림, 새 알림 있음')),
          true,
        );
        h.dispose();
      });
    }
  }
}
