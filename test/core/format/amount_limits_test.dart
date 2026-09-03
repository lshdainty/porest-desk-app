// 금액 상한 포매터 — 타이핑 자체를 막는다(QA #12).
//
// 자릿수로 세면 안 된다는 게 이 테스트의 요지다. 100억은 11자리라
// `LengthLimitingTextInputFormatter(11)` 로는 999억이 그대로 통과한다.
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/core/format/amount_limits.dart';

/// 사용자가 [next] 를 친 결과 입력칸에 남는 문자열.
String _type(AmountLimitFormatter f, String prev, String next) => f
    .formatEditUpdate(
      TextEditingValue(text: prev),
      TextEditingValue(text: next),
    )
    .text;

void main() {
  group('AmountLimitFormatter — 거래 100억', () {
    const f = AmountLimitFormatter(kAmountMax);

    test('상한 이하는 그대로 들어간다', () {
      expect(_type(f, '999999999', '9999999999'), '9999999999'); // 99.9억
      expect(_type(f, '1000000000', '10000000000'), '10000000000'); // 100억 정각
    });

    test('상한을 넘는 순간 타이핑이 안 먹는다', () {
      // QA 가 웹에서 친 999억. 자릿수(11)만 세는 방식은 이걸 통과시킨다.
      expect(_type(f, '9999999999', '99999999999'), '9999999999');
      expect(_type(f, '10000000000', '100000000001'), '10000000000');
    });

    test('64비트를 넘겨 파싱이 깨지는 자릿수도 막힌다', () {
      expect(_type(f, '10000000000', '9' * 25), '10000000000');
    });

    test('비우는 건 언제나 된다', () {
      expect(_type(f, '99999999999999', ''), '');
      expect(_type(f, '500', '0'), '0');
    });

    test('상한이 생기기 전 저장된 값은 한 글자씩 줄일 수 있다', () {
      // 상한 도입 전 데이터(99조)를 편집 진입하면 컨트롤러 직접 대입이라 포매터를
      // 안 탄다. 줄이는 편집까지 막으면 통째로 비우는 수밖에 없다.
      expect(_type(f, '99999999999999', '9999999999999'), '9999999999999');
      expect(_type(f, '9999999999999', '999999999999'), '999999999999');
      // 늘리는 방향은 여전히 막힌다.
      expect(_type(f, '99999999999999', '999999999999999'), '99999999999999');
      // 선행 0 이 붙어도 자릿수만 보고 늘었다고 오판하지 않는다.
      expect(_type(f, '99999999999999', '099999999999999'), '99999999999999');
    });
  });

  test('잔액 상한은 거래와 별개다 — 1,000억(QA #17)', () {
    const f = AmountLimitFormatter(kBalanceMax);
    expect(kBalanceMax, 10 * kAmountMax);
    expect(_type(f, '10000000000', '100000000000'), '100000000000'); // 1,000억
    expect(_type(f, '100000000000', '1000000000000'), '100000000000');
    // QA 가 만든 99조 계좌는 못 만든다.
    expect(_type(f, '0', '99999999999999'), '0');
  });
}
