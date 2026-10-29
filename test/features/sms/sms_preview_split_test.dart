// SmsPreview 가 줄을 가른다 — Dart RegExp 에는 `\R` 이 없다(글자 R 로 읽혀 줄이 안 갈렸다).
// 줄이 안 갈리면 가맹점 · 발신 기관을 못 읽고 문자 전체가 제목이 된다.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/sms/domain/sms_preview.dart';

void main() {
  test('줄바꿈(\\n · \\r\\n · \\r)으로 줄을 갈라 가맹점 · 기관 · 금액을 읽는다', () {
    for (final nl in ['\n', '\r\n', '\r']) {
      final text = [
        '[Web발신]',
        '숲빛카드',
        '12,000원 일시불',
        '10/29 12:10',
        '골목 찌개집',
      ].join(nl);
      final p = SmsPreview.of(text);
      expect(p.merchant, '골목 찌개집', reason: 'nl=${nl.codeUnits}');
      expect(p.issuer, '숲빛카드');
      expect(p.amount, 12000);
    }
  });
}
