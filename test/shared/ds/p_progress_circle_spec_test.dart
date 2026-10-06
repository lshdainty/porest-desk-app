// Progress Circle 이 스펙 값(test/fixtures/design_spec/progress-circle.json)대로 그려지는지 — 크기 × 톤 × 값
// 없음 · 있음 × 라이트 · 다크, 그리고 움직임(도는 원 · 따라 차는 채움 · 모션 줄이기). 웹은 같은 JSON 을
// 크로미움에서 잰다(desk-front `npm run ds:check`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/ds/progress_circle/p_progress_circle.dart';

import '../../support/design_spec.dart';

final _spec = DesignSpec.load('progress-circle');

Widget _host(Brightness mode, Widget child, {bool reduceMotion = false}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? PorestTheme.dark() : PorestTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    );

PProgressCirclePainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(PProgressCircle),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as PProgressCirclePainter;

void main() {
  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 크기 × 톤 × 값 없음 · 있음이 스펙 값이다', (tester) async {
      final failures = <String>[];
      for (final combo in _spec.combos(['size', 'tone', 'mode'])) {
        // 부품이 정하는 inherit 는 Button 테스트가 본다
        if (combo['size'] == 'inherit' || combo['tone'] == 'inherit') continue;
        final determinate = combo['mode'] == 'determinate';
        await tester.pumpWidget(
          _host(
            mode,
            PProgressCircle(
              key: UniqueKey(),
              size: combo['size'] == '24'
                  ? PProgressCircleSize.s24
                  : PProgressCircleSize.s40,
              tone: PProgressCircleTone.values.byName(combo['tone']!),
              value: determinate ? 40 : null,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        final want = _spec.resolve(combo, 'enabled');
        final where = '${mode.name} $combo';
        final size = tester.getSize(
          find.descendant(
            of: find.byType(PProgressCircle),
            matching: find.byType(CustomPaint),
          ),
        );
        if (size.width != want['root.size'] ||
            size.height != want['root.size']) {
          failures.add(
            '$where — root.size: 스펙 ${want['root.size']} · 실제 $size',
          );
        }
        final p = _painter(tester);
        if (p.thickness != want['root.thickness']) {
          failures.add(
            '$where — root.thickness: 스펙 ${want['root.thickness']} · 실제 ${p.thickness}',
          );
        }
        for (final (key, actual) in [
          ('root.track', p.track),
          ('root.range', p.range),
        ]) {
          final w = pickMode(want[key], mode);
          if (!sameColor(specColor(w), actual)) {
            failures.add('$where — $key: 스펙 $w · 실제 ${colorHex(actual)}');
          }
        }
        if (determinate) {
          // 12시부터 값만큼
          final arc = p.currentArc;
          if (arc.start != 0 || arc.rotation != 0 || arc.sweep != 0.4) {
            failures.add('$where — 값 40 의 호가 12시부터 40% 가 아니다: $arc');
          }
        }
      }
      if (failures.isNotEmpty) {
        fail('${failures.length}개가 스펙과 다르다\n${failures.join('\n')}');
      }
    });
  }

  testWidgets('값 없는 원은 1.2초 박자로 돌며 호가 늘었다 줄어든다', (tester) async {
    await tester.pumpWidget(_host(Brightness.light, const PProgressCircle()));
    final seen = <({double start, double sweep, double rotation})>[];
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      seen.add(_painter(tester).currentArc);
    }
    // 처음에는 꼬리가 12시에 머물고(0 ~ 33%) 머리만 는다, 끝으로 갈수록 꼬리가 따라온다
    expect(seen.first.start, 0);
    expect(seen.map((a) => a.sweep).toSet().length, greaterThan(3));
    expect(seen.map((a) => a.rotation).toSet().length, greaterThan(3));
    // 한 바퀴(1.2초) 뒤에는 처음 모양으로 돌아온다
    await tester.pump(const Duration(milliseconds: 1200));
    final again = _painter(tester).currentArc;
    expect(again.sweep, closeTo(seen.last.sweep, 1e-6));
  });

  testWidgets('모션 줄이기면 돌지 않는다 — 12시부터 3/4 고정 호', (tester) async {
    await tester.pumpWidget(
      _host(Brightness.light, const PProgressCircle(), reduceMotion: true),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final arc = _painter(tester).currentArc;
    expect(arc.start, 0);
    expect(arc.rotation, 0);
    expect(arc.sweep, 0.75);
    // 도는 것이 없으니 settle 한다
    await tester.pumpAndSettle();
  });

  testWidgets('값이 바뀌면 채움이 300ms 로 따라 찬다 — 처음 그릴 때는 바로', (tester) async {
    Widget circle(double v) =>
        _host(Brightness.light, PProgressCircle(value: v));
    await tester.pumpWidget(circle(20));
    expect(_painter(tester).currentArc.sweep, 0.2);

    await tester.pumpWidget(circle(80));
    await tester.pump(const Duration(milliseconds: 150));
    final mid = _painter(tester).currentArc.sweep;
    expect(mid, greaterThan(0.2));
    expect(mid, lessThan(0.8));
    await tester.pumpAndSettle();
    expect(_painter(tester).currentArc.sweep, closeTo(0.8, 1e-9));
  });

  testWidgets('모션 줄이기면 채움이 바로 바뀐다', (tester) async {
    Widget circle(double v) =>
        _host(Brightness.light, PProgressCircle(value: v), reduceMotion: true);
    await tester.pumpWidget(circle(20));
    await tester.pumpWidget(circle(80));
    await tester.pump();
    expect(_painter(tester).currentArc.sweep, 0.8);
  });

  testWidgets('min · max 를 지키고, 벗어나면 끝에서 멈추고, 0 이면 호를 지운다', (tester) async {
    Future<double> sweep(double v, {double min = 0, double max = 100}) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PProgressCircle(key: UniqueKey(), value: v, min: min, max: max),
        ),
      );
      return _painter(tester).currentArc.sweep;
    }

    expect(await sweep(3, max: 5), closeTo(0.6, 1e-9));
    expect(await sweep(150), 1);
    expect(await sweep(-10), 0);
    expect(await sweep(0), 0);
  });

  testWidgets('이름은 기본 "불러오는 중", 값 있는 원은 값 글을 읽는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(Brightness.light, const PProgressCircle(value: 3, max: 5)),
    );
    expect(
      tester.getSemantics(find.byType(PProgressCircle)),
      matchesSemantics(label: '불러오는 중', value: '60%'),
    );
    await tester.pumpWidget(
      _host(
        Brightness.light,
        const PProgressCircle(
          semanticsLabel: '영수증 사진 올리는 중',
          value: 2,
          max: 4,
          valueText: '4장 중 2장',
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(PProgressCircle)),
      matchesSemantics(label: '영수증 사진 올리는 중', value: '4장 중 2장'),
    );
    semantics.dispose();
  });
}
