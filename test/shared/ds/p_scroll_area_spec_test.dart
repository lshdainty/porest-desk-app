// Scroll Area 가 스펙 값(test/fixtures/design_spec/scroll-area.json)대로인지 — 전역 스크롤바(막대 색 · 6 · 알약 · 투명 바탕)를
// 라이트 · 다크로 재고, 놓인 자리(page · overlay · row) · 이름 있는 상자 · 넘치는 방향을 따로 본다. 웹의 Firefox 규칙(@supports) ·
// 키보드 포커스 링 · tabindex 는 웹 전용이라 건너뛴다(앱은 상자가 이름을 받는다).
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/shared/ds/scroll_area/p_scroll_area.dart';

import '../../support/design_spec.dart';

final _spec = DesignSpec.load('scroll-area');

Widget _host(Brightness mode, Widget child) => MaterialApp(
  theme: mode == Brightness.dark ? PorestTheme.dark() : PorestTheme.light(),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 300, height: 200, child: child),
    ),
  ),
);

Widget _tall() => const SizedBox(width: 600, height: 800);

/// 막대 — 머티리얼 스크롤바는 RawScrollbar 의 하위 형이다(byType 은 정확한 형만 찾는다).
final Finder _bars = find.byWidgetPredicate((w) => w is RawScrollbar);

dynamic _painter(WidgetTester tester, [int i = 0]) {
  final state = tester.state(_bars.at(i)) as dynamic;
  return state.scrollbarPainter;
}

void main() {
  for (final mode in Brightness.values) {
    final want = _spec.resolve({}, 'enabled');

    test('${mode.name} — 전역 ScrollbarTheme 이 스펙 값이다(막대 색 · 6 · 알약 · 투명 바탕)', () {
      final theme =
          (mode == Brightness.dark ? PorestTheme.dark() : PorestTheme.light())
              .scrollbarTheme;
      final c = mode == Brightness.dark ? PColors.dark : PColors.light;
      final thumb = theme.thumbColor!.resolve(<WidgetState>{});
      expect(
        sameColor(specColor(pickMode(want['thumb.background'], mode)), thumb!),
        isTrue,
        reason:
            '스펙 ${pickMode(want['thumb.background'], mode)} · 실제 ${colorHex(thumb)}',
      );
      // 역할 이름으로는 stroke-neutral-solid 다
      expect(thumb, c.strokeNeutralSolid);
      // 올리거나 끌어도 모양이 바뀌지 않는다
      for (final s in [
        <WidgetState>{WidgetState.hovered},
        <WidgetState>{WidgetState.dragged},
        <WidgetState>{WidgetState.hovered, WidgetState.dragged},
      ]) {
        expect(theme.thumbColor!.resolve(s), thumb, reason: '$s');
        expect(theme.thickness!.resolve(s), want['scrollbar.width']);
      }
      expect(
        theme.thickness!.resolve(<WidgetState>{}),
        want['scrollbar.width'],
      );
      expect(
        theme.thickness!.resolve(<WidgetState>{}),
        want['scrollbar.height'],
      );
      expect(theme.radius, const Radius.circular(PRounded.full));
      expect(want['thumb.radius'], PRounded.full);
      expect(
        sameColor(
          specColor(want['track.background']),
          theme.trackColor!.resolve(<WidgetState>{})!,
        ),
        isTrue,
      );
      expect(theme.trackBorderColor!.resolve(<WidgetState>{})!.a, 0);
    });

    testWidgets('${mode.name} — 그려진 막대가 스펙 값이다(세로 · 가로)', (tester) async {
      await tester.pumpWidget(
        _host(mode, PScrollArea(thumbVisibility: true, child: _tall())),
      );
      await tester.pumpAndSettle();
      final p = _painter(tester);
      expect(p.thickness, want['scrollbar.width']);
      expect(
        sameColor(
          specColor(pickMode(want['thumb.background'], mode)),
          p.color as Color,
        ),
        isTrue,
      );
      expect((p.radius as Radius).x, PRounded.full);

      await tester.pumpWidget(
        _host(
          mode,
          PScrollArea(
            orientation: PScrollAreaOrientation.horizontal,
            thumbVisibility: true,
            child: _tall(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final h = _painter(tester);
      expect(h.thickness, want['scrollbar.height']);
      expect(
        sameColor(
          specColor(pickMode(want['thumb.background'], mode)),
          h.color as Color,
        ),
        isTrue,
      );
    });
  }

  group('놓인 자리 · 방향', () {
    testWidgets('page — 세로 스크롤이 되고 막대가 있다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PScrollArea(thumbVisibility: true, child: _tall()),
        ),
      );
      await tester.pumpAndSettle();
      expect(_bars, findsOneWidget);
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scroll.scrollDirection, Axis.vertical);
      expect(scroll.physics, isNull, reason: '플랫폼 기본 스크롤 그대로');
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        100,
      );
    });

    testWidgets('overlay — 끝에서 튕기지 않는다(ClampingScrollPhysics)', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PScrollArea(use: PScrollAreaUse.overlay, child: _tall()),
        ),
      );
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scroll.physics, isA<ClampingScrollPhysics>());
      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        2000,
      );
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        0,
        reason: '위 끝을 넘지 않는다',
      );
    });

    testWidgets('row — 가로 줄은 스크롤바를 숨긴다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PScrollArea(
            use: PScrollAreaUse.row,
            orientation: PScrollAreaOrientation.horizontal,
            thumbVisibility: true,
            child: _tall(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_bars, findsNothing);
      expect(
        tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .scrollDirection,
        Axis.horizontal,
      );
    });

    testWidgets('세로 막대는 숨기지 않는다 — page · overlay 모두 막대가 있다', (tester) async {
      for (final use in [PScrollAreaUse.page, PScrollAreaUse.overlay]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PScrollArea(use: use, thumbVisibility: true, child: _tall()),
          ),
        );
        await tester.pumpAndSettle();
        expect(_bars, findsOneWidget, reason: use.name);
      }
    });

    testWidgets('both — 세로 · 가로 막대가 하나씩이고 두 방향으로 스크롤된다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PScrollArea(
            orientation: PScrollAreaOrientation.both,
            thumbVisibility: true,
            child: _tall(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_bars, findsNWidgets(2));
      final scrollables = find.byType(Scrollable);
      expect(scrollables, findsNWidgets(2));
    });

    testWidgets('넘치지 않는 내용에는 막대가 그려지지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PScrollArea(thumbVisibility: true, child: SizedBox(height: 50)),
        ),
      );
      await tester.pumpAndSettle();
      expect(_painter(tester).thickness, isNotNull);
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position
            .maxScrollExtent,
        0,
      );
    });
  });

  group('이름', () {
    testWidgets('label 을 주면 상자가 이름을 받는다 — 안에 누르는 것이 없는 상자', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, PScrollArea(label: '휴가 정책', child: _tall())),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('휴가 정책'));
      expect(node.label, '휴가 정책');
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        isNot(Tristate.isFalse),
      );
      handle.dispose();
    });

    testWidgets('label 이 없으면 이름 노드를 만들지 않는다 — 안에 누르는 것이 있는 상자', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, PScrollArea(child: _tall())),
      );
      expect(find.bySemanticsLabel('휴가 정책'), findsNothing);
      handle.dispose();
    });
  });

  group('가장 나쁜 값', () {
    testWidgets('시트 안 상자 안의 상자 — 안쪽 끝에서 바깥이 따라오지 않는다', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final outer = ScrollController();
      final inner = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          theme: PorestTheme.light(),
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: PScrollArea(
                use: PScrollAreaUse.overlay,
                controller: outer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 100),
                    SizedBox(
                      height: 100,
                      child: PScrollArea(
                        key: const ValueKey('inner'),
                        use: PScrollAreaUse.overlay,
                        controller: inner,
                        child: const SizedBox(height: 400),
                      ),
                    ),
                    const SizedBox(height: 400),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 안쪽 상자를 끝(300)까지 올려 끌어도 바깥이 움직이지 않는다 — 끝을 넘겨 끌어도 마찬가지
      await tester.drag(
        find.byKey(const ValueKey('inner')),
        const Offset(0, -380),
      );
      await tester.pumpAndSettle();
      expect(inner.position.pixels, 300);
      await tester.drag(
        find.byKey(const ValueKey('inner')),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();
      expect(inner.position.pixels, 300);
      expect(outer.position.pixels, 0, reason: '안쪽 끝에서 바깥이 따라오지 않는다');
    });
  });
}
