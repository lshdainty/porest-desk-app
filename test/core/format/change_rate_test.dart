// 등락률 표기 한 함수(사용자 결정 2026-10-25) + 외화 금액 소수 규칙.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/format/change_rate.dart';
import 'package:groo_damda_app/core/format/currency.dart';

void main() {
  group('formatChangeRate — 어디서나 소수 둘째 자리', () {
    test('0.43% · 5.00% · −12.30%(U+2212)', () {
      expect(formatChangeRate(0.43), '0.43%');
      expect(formatChangeRate(5), '5.00%');
      expect(formatChangeRate(-12.3), '−12.30%');
      expect(
        formatChangeRate(-12.3).contains('-'),
        isFalse,
        reason: '하이픈이 아니다',
      );
    });

    test('signed — 양수에만 + , 0 과 반올림해 0 이 되는 값은 부호 없음', () {
      expect(formatChangeRate(5, signed: true), '+5.00%');
      expect(formatChangeRate(-5, signed: true), '−5.00%');
      expect(formatChangeRate(0, signed: true), '0.00%');
      expect(formatChangeRate(0.004, signed: true), '0.00%');
      expect(
        formatChangeRate(-0.004, signed: true),
        '0.00%',
        reason: '"-0.00%" 가 나오지 않는다',
      );
    });

    test('천 퍼센트 이상은 정수부에 쉼표 — 1,234.50% · 부호 U+2212 · signed', () {
      expect(formatChangeRate(1234.5), '1,234.50%');
      expect(formatChangeRate(-1234.5), '−1,234.50%');
      expect(formatChangeRate(1234.5, signed: true), '+1,234.50%');
      expect(formatChangeRate(-1234.5, signed: true), '−1,234.50%');
      expect(formatChangeRate(-1234.5).contains('-'), isFalse);
      expect(formatChangeRate(1234567.891), '1,234,567.89%');
      expect(formatChangeRate(999.99), '999.99%', reason: '세 자리는 쉼표 없음');
      expect(formatChangeRate(1000), '1,000.00%');
    });

    test('Abs — 크기만(방향은 화살표가 말한다)', () {
      expect(formatChangeRateAbs(-2.9), '2.90%');
      expect(formatChangeRateAbs(0.4), '0.40%');
      expect(formatChangeRateAbs(5), '5.00%');
      expect(formatChangeRateAbs(-1234.5), '1,234.50%');
    });
  });

  group('formatOriginalAmount — 소수 둘째 자리를 늘 보인다(소수 없는 통화는 0자리)', () {
    test(r'$1,000.00 · $1,000.50', () {
      expect(formatOriginalAmount(1000, 'USD', 'ko'), r'$1,000.00');
      expect(formatOriginalAmount(1000.5, 'USD', 'ko'), r'$1,000.50');
    });

    test('엔 · 원 · 동은 0자리', () {
      expect(formatOriginalAmount(1280, 'JPY', 'ko'), '¥1,280');
      expect(formatOriginalAmount(1280, 'KRW', 'ko'), '₩1,280');
      expect(formatOriginalAmount(1280, 'VND', 'ko'), '₫1,280');
    });
  });
}
