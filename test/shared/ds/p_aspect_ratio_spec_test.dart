// Aspect Ratio 가 스펙 값(test/fixtures/design_spec/aspect-ratio.json)대로인지 — 비율 여덟 × 라이트 · 다크의 상자
// 크기(폭 ÷ 비율) · 모서리 0 · 바탕 없음 · 넘침 자르기 · 자식이 상자를 채움. 웹은 같은 JSON 을 크로미움에서 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/aspect_ratio/aspect_ratio_demo.dart';
import 'package:groo_damda_app/shared/ds/aspect_ratio/p_aspect_ratio.dart';

import '../../support/design_spec.dart';

final _spec = DesignSpec.load('aspect-ratio');

Widget _host(Brightness mode, Widget child, {double width = 300}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

/// "W / H" → W ÷ H — 스펙 JSON 의 비율 글(앱은 "/" 로 나눠 쓴다).
double _parse(Object? spec) {
  final parts = '$spec'.split('/').map((s) => double.parse(s.trim())).toList();
  return parts[0] / parts[1];
}

const _childKey = ValueKey('aspect-child');

void main() {
  test('비율은 스펙의 여덟 가지 — 이름 · 차례 · 기본이 같다', () {
    final names = _spec.axes['ratio']!;
    expect(names, hasLength(8));
    expect(PAspectRatioValue.values.map((v) => v.id), names);
    // 기본은 4:3 — 상자의 기본값도 같다
    expect(_spec.defaults['ratio'], '4:3');
    expect(
      const PAspectRatio(child: SizedBox()).ratio,
      PAspectRatioValue.values.firstWhere((v) => v.id == '4:3'),
    );
  });

  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 비율 여덟이 스펙 값이다 · 상자 · 모서리 · 바탕 · 자르기 · 자식', (
      tester,
    ) async {
      final failures = <String>[];
      for (final combo in _spec.combos(['ratio'])) {
        final ratio = PAspectRatioValue.values.firstWhere(
          (v) => v.id == combo['ratio'],
        );
        final want = _spec.resolve(combo, 'enabled');
        final where = '${mode.name} ${combo['ratio']}';
        await tester.pumpWidget(
          _host(
            mode,
            PAspectRatio(
              key: UniqueKey(),
              ratio: ratio,
              child: const SizedBox(key: _childKey),
            ),
          ),
        );

        // 비율 — 스펙 글("W / H")과 같은 값이고, 그려진 높이가 폭 ÷ 비율이다
        final expected = _parse(want['root.aspectRatio']);
        if ((ratio.ratio - expected).abs() > 1e-9) {
          failures.add(
            '$where — root.aspectRatio: 스펙 ${want['root.aspectRatio']} · 실제 ${ratio.ratio}',
          );
        }
        if (ratio.spec != want['root.aspectRatio']) {
          failures.add(
            '$where — root.aspectRatio 글: 스펙 ${want['root.aspectRatio']} · 실제 ${ratio.spec}',
          );
        }
        final box = tester.getSize(find.byType(PAspectRatio));
        if (box.width != 300) {
          failures.add('$where — root.width: 부모 폭 300 · 실제 ${box.width}');
        }
        if ((box.height - 300 / expected).abs() > 0.01) {
          failures.add(
            '$where — root.height: 폭 ÷ 비율 ${300 / expected} · 실제 ${box.height}',
          );
        }

        // 모서리 0 · 바탕 없음 — 둥근 자름 · 칠한 상자 · 그림자가 없다
        expect(want['root.radius'], 0, reason: where);
        expect(
          find.descendant(
            of: find.byType(PAspectRatio),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is ClipRRect ||
                  w is ClipPath ||
                  w is ClipOval ||
                  w is DecoratedBox ||
                  w is ColoredBox ||
                  w is PhysicalModel ||
                  w is PhysicalShape,
            ),
          ),
          findsNothing,
          reason: where,
        );

        // 넘친 자식을 자른다 — 사각 자름 하나
        expect(want['root.overflow'], 'hidden');
        final clip = tester.widget<ClipRect>(
          find.descendant(
            of: find.byType(PAspectRatio),
            matching: find.byType(ClipRect),
          ),
        );
        if (clip.clipBehavior == Clip.none) {
          failures.add('$where — root.overflow: 자르지 않는다');
        }

        // 자식 — 상자를 채운다(inset 0)
        expect(want['child.inset'], 0);
        final boxRect = tester.getRect(find.byType(PAspectRatio));
        final childRect = tester.getRect(find.byKey(_childKey));
        if (childRect != boxRect) {
          failures.add('$where — child.inset: 상자 $boxRect · 자식 $childRect');
        }
      }
      if (failures.isNotEmpty) fail(failures.join('\n'));
    });
  }

  testWidgets('부모 폭이 바뀌면 높이가 비율대로 다시 정해진다 — 부모 폭 0 이면 상자도 0', (tester) async {
    for (final ratio in PAspectRatioValue.values) {
      for (final width in [0.0, 120.0, 200.0, 360.0]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PAspectRatio(
              key: UniqueKey(),
              ratio: ratio,
              child: const SizedBox(),
            ),
            width: width,
          ),
        );
        final size = tester.getSize(find.byType(PAspectRatio));
        expect(size.width, width, reason: '${ratio.id} 폭 $width');
        expect(
          size.height,
          closeTo(width / ratio.ratio, 0.01),
          reason: '${ratio.id} 폭 $width',
        );
      }
    }
  });

  testWidgets('내용이 오기 전에 자리를 잡는다 — 자식이 비어 있어도 같은 높이, 내용이 와도 그대로', (
    tester,
  ) async {
    Widget box(Widget child) => _host(
      Brightness.light,
      PAspectRatio(ratio: PAspectRatioValue.r16x9, child: child),
    );
    await tester.pumpWidget(box(const SizedBox.shrink()));
    final empty = tester.getSize(find.byType(PAspectRatio));
    expect(empty, Size(300, 300 / (16 / 9)));
    await tester.pumpWidget(
      box(const ColoredBox(color: Color(0xFF123456), child: Text('동영상'))),
    );
    expect(tester.getSize(find.byType(PAspectRatio)), empty);
  });

  testWidgets('넘친 자식은 잘린다 — 상자 밖은 그려지지 않고 눌리지 않는다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Brightness.light,
        Column(
          children: [
            PAspectRatio(
              ratio: PAspectRatioValue.r2x1,
              child: OverflowBox(
                maxWidth: 600,
                maxHeight: 600,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox.square(dimension: 600),
                ),
              ),
            ),
            const SizedBox(height: 300),
          ],
        ),
      ),
    );
    final area = tester.getRect(find.byType(PAspectRatio));
    expect(area.size, const Size(300, 150));
    // 상자 안은 누르고
    await tester.tapAt(area.center);
    expect(taps, 1);
    // 상자 밖(아래)은 자식이 넘쳤어도 누르지 않는다 — 자르기는 그린 것만이 아니라 받는 자리도 막는다
    await tester.tapAt(area.bottomLeft + const Offset(10, 40));
    expect(taps, 1);
    // 자름은 그린 것에 걸린다(사각 자름 하나)
    final clip = tester.widget<ClipRect>(
      find.descendant(
        of: find.byType(PAspectRatio),
        matching: find.byType(ClipRect),
      ),
    );
    expect(clip.clipBehavior, Clip.hardEdge);
  });

  testWidgets('역할 · 이름이 없다 — 자식이 말한다. 누르지 않고 초점이 서지 않는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Brightness.light,
        PAspectRatio(
          ratio: PAspectRatioValue.r1x1,
          child: Semantics(label: '김밥천국 강남점 위치', child: const SizedBox()),
        ),
      ),
    );
    // 상자가 더하는 의미가 없다 — 자식이 단 것뿐이다
    expect(
      find.descendant(
        of: find.byType(PAspectRatio),
        matching: find.byType(Semantics),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(PAspectRatio),
        matching: find.byWidgetPredicate(
          (w) => w is Focus || w is GestureDetector || w is InkResponse,
        ),
      ),
      findsNothing,
    );
    expect(find.bySemanticsLabel('김밥천국 강남점 위치'), findsOneWidget);
    semantics.dispose();
  });

  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 견본이 여덟 비율을 모두 그린다 · 상자는 폭 120', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: AspectRatioDemo(),
            ),
          ),
        ),
      );
      final boxes = tester
          .widgetList<PAspectRatio>(find.byType(PAspectRatio))
          .toList();
      // 여덟 가지 + 자식 견본 둘
      expect(
        boxes.map((b) => b.ratio).toSet(),
        PAspectRatioValue.values.toSet(),
      );
      for (final ratio in PAspectRatioValue.values) {
        final size = tester.getSize(
          find
              .byWidgetPredicate((w) => w is PAspectRatio && w.ratio == ratio)
              .first,
        );
        expect(size.width, 120, reason: ratio.id);
        expect(size.height, closeTo(120 / ratio.ratio, 0.01), reason: ratio.id);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
