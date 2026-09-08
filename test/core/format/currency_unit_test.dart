// 라벨 괄호 안 통화 단위 — `잔액 (원)` · `잔액 ($)` 의 그 자리 (QA 12차 결정 ③).
//
// USD 를 골라도 라벨은 `잔액 (원)` 이었다. 단위는 **고른 통화**를 따라야 한다.
//
// **웹과 한 글자도 갈리면 안 된다.** 같은 자산을 두 플랫폼이 그리므로, 표기가
// 갈리면 폰에서는 `잔액 (원)` · 브라우저에서는 `잔액 ($)` 이 된다. 규칙의 원문은
// desk-front `shared/lib/porest/currency.ts` 의 `currencyUnit` 이고(#369) 이 파일은
// 그 테스트(`currency.test.ts`)의 미러다.
//
//   KRW  → ko `원` · en `₩`      (원화만 로케일을 탄다)
//   그 외 → 기호                  ($ · € · ¥ · £ …)
//   없음  → 원화로 본다            (kDefaultCurrency)
//   모르는 코드 → 코드 그대로       (빈 괄호보다 낫다)
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:porest_desk_app/core/format/currency.dart';

void main() {
  group('ko — 원화는 `원`', () {
    setUp(() => Intl.defaultLocale = 'ko');

    test('KRW 는 `원` 이다', () {
      expect(currencyUnit('KRW'), '원');
    });

    test('통화를 모르면 원화로 본다', () {
      // 통화가 안 적힌 옛 자산이 있다 — 빈 괄호(`잔액 ()`)로 그리면 안 된다.
      expect(currencyUnit(null), '원');
      expect(currencyUnit(''), '원');
    });

    test('외화는 기호 그대로 — 로케일을 안 탄다', () {
      expect(currencyUnit('USD'), r'$');
      expect(currencyUnit('EUR'), '€');
      expect(currencyUnit('JPY'), '¥');
    });
  });

  group('en — 원화만 `₩` 로 바뀐다', () {
    setUp(() => Intl.defaultLocale = 'en');
    tearDown(() => Intl.defaultLocale = 'ko');

    test('KRW 는 `₩` 이다', () {
      // 한국어 화면은 `원` 을 접미로 붙이고(`krwSigned`) 영어 화면은 `₩` 를 앞에
      // 붙인다. `Balance (원)` 도 `잔액 (₩)` 도 그 화면에서는 남의 글자다.
      expect(currencyUnit('KRW'), '₩');
      expect(currencyUnit(null), '₩');
    });

    test('외화는 ko 와 같은 글자다', () {
      expect(currencyUnit('USD'), r'$');
      expect(currencyUnit('EUR'), '€');
      expect(currencyUnit('JPY'), '¥');
    });
  });

  test('원화 말고는 기호를 새로 세지 않는다 — kCurrencies 한 벌이다', () {
    Intl.defaultLocale = 'ko';
    // 두 벌이 되면 통화를 하나 늘릴 때 한쪽만 늘어나고, 그 어긋남은 화면에서만 보인다.
    for (final c in kCurrencies) {
      if (c.code == kDefaultCurrency) continue;
      expect(currencyUnit(c.code), currencySymbol(c.code), reason: c.code);
    }
  });

  test('모르는 코드는 코드를 그대로 낸다', () {
    Intl.defaultLocale = 'ko';
    expect(currencyUnit('XPT'), 'XPT');
  });
}
