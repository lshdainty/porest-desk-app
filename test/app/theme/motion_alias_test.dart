// 옛 PMotion 은 v104 시간 눈금 · 곡선의 별칭이다(01A-060 · 061) — 값이 따로 놀지 않는다.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/motion.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

void main() {
  test('PMotion → PDuration · PEasing', () {
    expect(PMotion.instant, PDuration.d2);
    expect(PMotion.fast, PDuration.d3);
    expect(PMotion.base, PDuration.d4);
    expect(PMotion.slow, PDuration.d6);
    expect(PMotion.standard, PEasing.easing);
    expect(PMotion.decel, PEasing.enter);
  });
}
