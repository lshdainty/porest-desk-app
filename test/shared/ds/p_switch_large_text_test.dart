// Switch 가 큰 글자(200%)에서 깨지지 않는다 — 웹 ds Switch 는 몸통이 px 인데 손잡이 이동이 rem 이라 글자를 키우면 손잡이가 몸통 밖으로
// 밀렸다(I-09 09-2 웹 613609ff). 앱은 몸통 · 손잡이 · 이동이 모두 논리 px 라 글자 배율과 무관하다 — 그 사실을 잠근다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/switch/p_switch.dart';

Widget _app(double scale, bool checked, PSwitchSize size) => MaterialApp(
  theme: GrooTheme.light(),
  builder: (c, child) => MediaQuery(
    data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: PSwitchmark(checked: checked, size: size, enabled: true),
    ),
  ),
);

void main() {
  const spec = {
    PSwitchSize.s16: (26.0, 16.0),
    PSwitchSize.s24: (38.0, 24.0),
    PSwitchSize.s32: (52.0, 32.0),
  };
  for (final size in PSwitchSize.values) {
    for (final checked in [false, true]) {
      for (final scale in [1.0, 2.0, 3.0]) {
        testWidgets('${size.name} ${checked ? '켬' : '끔'} 글자 ×$scale', (
          tester,
        ) async {
          await tester.pumpWidget(_app(scale, checked, size));
          await tester.pumpAndSettle();
          final track = tester.getRect(
            find.byKey(const ValueKey('switchmark-track')),
          );
          final thumb = tester.getRect(
            find.byKey(const ValueKey('switchmark-thumb')),
          );
          final (w, h) = spec[size]!;
          expect(track.width, w, reason: '몸통 폭은 배율을 따르지 않는다');
          expect(track.height, h);
          // 손잡이가 몸통 안에 있다(켬은 오른쪽 끝 · 끔은 왼쪽 끝)
          expect(thumb.left, greaterThanOrEqualTo(track.left - 0.01));
          expect(thumb.right, lessThanOrEqualTo(track.right + 0.01));
          expect(thumb.top, greaterThanOrEqualTo(track.top - 0.01));
          expect(thumb.bottom, lessThanOrEqualTo(track.bottom + 0.01));
          // 이동 거리 = 몸통 폭 − 몸통 높이(스펙 switch.yaml translateX), 배율과 무관
          final travel = w - h;
          if (checked) {
            expect(
              thumb.center.dx - track.center.dx,
              closeTo(travel / 2, 0.6),
              reason: '켠 손잡이는 오른쪽으로 travel 만큼',
            );
          } else {
            expect(
              track.center.dx - thumb.center.dx,
              closeTo(travel / 2, 0.6),
              reason: '끈 손잡이는 왼쪽에 있다',
            );
          }
        });
      }
    }
  }
}
