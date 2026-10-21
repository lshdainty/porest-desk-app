// 할 일 밤하늘(01-033 C) — 고정 남색 hex 대신 역할 색: 하늘 bg-neutral-inverted(다크에서는 밝은 하늘), 별 · 글 fg-neutral-inverted 투명도.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/constellation/presentation/sky_colors.dart';

void main() {
  for (final dark in [false, true]) {
    test('밤하늘 색 ${dark ? "다크" : "라이트"}', () {
      final c = dark ? PColors.dark : PColors.light;
      final g = skyGradient(c, three: true);
      expect(g.colors.first, c.bgNeutralInverted);
      expect(g.colors.last, c.bgNeutralInvertedPressed);
      expect(g.colors.length, 3);
      expect(skyInk(c, 0xFF), c.fgNeutralInverted);
      expect(skyInk(c, 0x80).a, closeTo(0.5, 0.01));
    });
  }
  test('다크에서 하늘이 밝다(사용자가 받아들인 대가)', () {
    expect(
      PColors.dark.bgNeutralInverted.computeLuminance(),
      greaterThan(PColors.light.bgNeutralInverted.computeLuminance()),
    );
  });
}
