// Scroll Fog 가 스펙 값(test/fixtures/design_spec/scroll-fog.json)대로인지 — 자리마다 흐림 깊이 · 방향 · 안쪽 여백과
// 마스크(gradient-fade-mask). 웹은 같은 JSON 을 크로미움에서 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/shared/ds/scroll_fog/p_scroll_fog.dart';

import '../../support/design_spec.dart';

final _spec = DesignSpec.load('scroll-fog');

/// "위 20px · 아래 80px" · 20 → (시작, 끝)
(double, double) _pair(Object? v) {
  if (v is num) return (v.toDouble(), v.toDouble());
  final m = RegExp(r'위 (\d+)px · 아래 (\d+)px').firstMatch('$v');
  if (m == null) throw ArgumentError('$v');
  return (double.parse(m.group(1)!), double.parse(m.group(2)!));
}

void main() {
  for (final combo in _spec.combos(['use'])) {
    testWidgets('${combo['use']} — 흐림 깊이 · 안쪽 여백이 스펙 값이다', (tester) async {
      final use = PScrollFogUse.values.byName(combo['use']!);
      final want = _spec.resolve(combo, 'enabled');
      final m = scrollFogMetrics(use);

      final (fogStart, fogEnd) = _pair(want['fog.size']);
      expect((m.fogStart, m.fogEnd), (fogStart, fogEnd));

      final padStart =
          want['content.paddingTop'] ??
          want['content.paddingX'] ??
          want['content.padding'];
      final padEnd =
          want['content.paddingBottom'] ??
          want['content.paddingX'] ??
          want['content.padding'];
      expect((m.padStart, m.padEnd), (padStart, padEnd));

      await tester.pumpWidget(
        MaterialApp(
          theme: PorestTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: PScrollFog(
                use: use,
                child: const SizedBox(width: 600, height: 600),
              ),
            ),
          ),
        ),
      );
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      // 가로 줄만 가로, 나머지는 세로
      expect(
        scroll.scrollDirection,
        use == PScrollFogUse.row ? Axis.horizontal : Axis.vertical,
      );
      final padding = scroll.padding! as EdgeInsets;
      if (use == PScrollFogUse.row) {
        expect((padding.left, padding.right), (padStart, padEnd));
      } else {
        expect((padding.top, padding.bottom), (padStart, padEnd));
      }
    });
  }

  test('마스크는 gradient-fade-mask 를 깊이만큼으로 줄여 양 끝에 놓는다', () {
    final want = specGradient(_spec.resolve({}, 'enabled')['fog.mask']);
    final fade = PGradients.light.fadeMask;
    // 토큰(16단계)이 스펙과 같다
    expect(fade.colors.length, want.colors.length);
    for (var i = 0; i < want.colors.length; i++) {
      expect(sameColor(want.colors[i], fade.colors[i]), isTrue);
      expect(fade.stops![i], closeTo(want.stops[i], 1e-9));
    }
    // 높이 200 · 위 20 · 아래 80 — 시작 쪽은 0 ~ 0.1, 끝 쪽은 0.6 ~ 1
    final g = fogGradient(fade, Axis.vertical, const Size(100, 200), 20, 80);
    expect(g.begin, Alignment.topCenter);
    expect(g.colors.first.a, 0); // 가장자리는 투명
    expect(g.colors.last.a, 0);
    expect(g.stops![15], closeTo(0.1, 1e-9)); // 위 흐림 끝 — 불투명
    expect(g.colors[15].a, 1);
    expect(g.stops![16], closeTo(0.6, 1e-9)); // 아래 흐림 시작 — 불투명
    expect(g.colors[16].a, 1);
    expect(g.stops!.last, 1);
    // 가로 — 왼쪽에서 오른쪽
    final h = fogGradient(fade, Axis.horizontal, const Size(400, 40), 20, 20);
    expect(h.begin, Alignment.centerLeft);
    expect(h.stops![15], closeTo(20 / 400, 1e-9));
    // 상자가 깊이 합보다 작으면 반씩 나눈다 — 겹치지 않는다
    final tiny = fogGradient(fade, Axis.vertical, const Size(10, 50), 20, 80);
    expect(tiny.stops![15], lessThanOrEqualTo(tiny.stops![16]));
  });

  testWidgets('흐림은 색을 덮지 않는 마스크다(dstIn) — 흐린 자리도 눌린다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PorestTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 200,
            child: PScrollFog(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(width: 300, height: 400),
              ),
            ),
          ),
        ),
      ),
    );
    final mask = tester.widget<ShaderMask>(find.byType(ShaderMask));
    expect(mask.blendMode, BlendMode.dstIn);
    // 위 흐림 자리(위에서 5px)를 눌러도 받는다 — 여백 20 위라 내용 첫 줄 위는 여백이다
    await tester.tapAt(
      tester.getTopLeft(find.byType(PScrollFog)) + const Offset(150, 25),
    );
    expect(taps, 1);
  });
}
