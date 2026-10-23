// 띠 화면(02-005 / Q-019-3) — 회색 바닥(basement) 위에 화면 폭 흰 띠(default)를 8 띄워 쌓는다. 띠 사이 8 만(맨 위 · 맨 아래 틈 0) ·
// 띠 안은 위 4 · 아래 8. 라이트 · 다크, 폭 360 · 390 · 768.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';

void main() {
  for (final dark in [false, true]) {
    for (final width in [360.0, 390.0, 768.0]) {
      testWidgets('띠 간격 · 폭 · 바탕 — ${dark ? "다크" : "라이트"} $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);
        final theme = dark ? GrooTheme.dark() : GrooTheme.light();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              backgroundColor: theme.extension<PColors>()!.bgLayerBasement,
              body: ListView(
                children: PScreenBands.children(const [
                  PScreenBand(child: SizedBox(height: 40)),
                  PScreenBand(child: SizedBox(height: 40)),
                ]),
              ),
            ),
          ),
        );
        final c = theme.extension<PColors>()!;
        final bands = find.byKey(const ValueKey('screen-band'));
        expect(bands, findsNWidgets(2));
        final a = tester.getRect(bands.at(0));
        final b = tester.getRect(bands.at(1));
        expect(a.top, 0, reason: '맨 위 틈 0');
        expect(b.top - a.bottom, 8, reason: '띠 사이 8');
        expect(
          tester.getRect(find.byType(ListView)).bottom - b.bottom,
          greaterThan(0),
          reason: '마지막 띠 아래는 목록 끝(틈을 따로 두지 않는다)',
        );
        expect(a.width, width, reason: '화면 폭');
        expect(a.height, 4 + 40 + 8, reason: '띠 안 위 4 · 아래 8');
        final fill = tester.widget<ColoredBox>(bands.first).color;
        expect(fill, c.bgLayerDefault);
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          c.bgLayerBasement,
        );
      });
    }
  }

  for (final dark in [false, true]) {
    testWidgets('구역 띠 · 한 장 띠 — ${dark ? "다크" : "라이트"}', (tester) async {
      final theme = dark ? GrooTheme.dark() : GrooTheme.light();
      final c = theme.extension<PColors>()!;
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            backgroundColor: c.bgLayerBasement,
            body: Column(
              children: const [
                PScreenSection(child: SizedBox(height: 40)),
                Expanded(child: PScreenBandBody(child: SizedBox())),
              ],
            ),
          ),
        ),
      );
      // 구역 띠 — 화면 폭 · 안쪽 24 · 모서리 · 테두리 없음(I-01 결정 3)
      final section = tester.getRect(
        find.byKey(const ValueKey('screen-section')),
      );
      expect(section.width, 390, reason: '화면 폭');
      expect(section.top, 0, reason: '맨 위 틈 0');
      expect(section.height, 40 + 48, reason: '안쪽 24');
      expect(
        tester
            .widget<ColoredBox>(find.byKey(const ValueKey('screen-section')))
            .color,
        c.bgLayerDefault,
      );
      // 한 장 띠 — 앞 띠 바로 아래부터 화면 폭 흰 면(틈 0)
      final band = tester.getRect(
        find.byKey(const ValueKey('screen-band-body')),
      );
      expect(band.top - section.bottom, 0);
      expect(
        tester
            .widget<ColoredBox>(find.byKey(const ValueKey('screen-band-body')))
            .color,
        c.bgLayerDefault,
      );
    });
  }
}
