import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/holding_format.dart';

/// I-31 — 음수 금액·수량·축의 빼기 기호는 U+2212 하나다(chart.md "빼기는 U+2212").
/// 출력에 ASCII 하이픈이 한 글자도 없어야 하고, 부호 뒤는 절댓값이다.
void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  for (final loc in ['ko', 'en']) {
    group('$loc', () {
      setUp(() => Intl.defaultLocale = loc);
      tearDown(() => Intl.defaultLocale = null);

      test('krw(-n) 은 U+2212 + 절댓값', () {
        expect(krw(-1000), '−1,000');
        expect(krw(-30400000), '−30,400,000');
        expect(krw(-1), '−1');
        expect(krw(-1000).contains('-'), isFalse);
      });

      test('krw: 양수 · 0 · sign · abs 계약은 그대로', () {
        expect(krw(1000), '1,000');
        expect(krw(0), '0');
        expect(krw(0, sign: true), '0');
        expect(krw(1000, sign: true), '+1,000');
        expect(krw(-2000, abs: true), '2,000');
        expect(krw(-2000, sign: true), '−2,000');
      });

      test('krwSigned · krwMasked 도 따라 바뀐다', () {
        expect(krwSigned(-1250000, false).contains('-'), isFalse);
        expect(krwSigned(-1250000, false), startsWith(kMinus));
        expect(krwMasked(-1250000, false), '−1,250,000');
        expect(krwMasked(-1250000, true), kHideMask);
      });

      test('formatChartAxis 음수는 U+2212', () {
        final s = formatChartAxis(-52000);
        expect(s.contains('-'), isFalse);
        expect(s, startsWith(kMinus));
        expect(formatChartAxis(52000).contains(kMinus), isFalse);
      });
    });
  }

  test('ko: krwSigned 단위 · 축 값', () {
    Intl.defaultLocale = 'ko';
    expect(krwSigned(-100000, false, unit: true), '−100,000원');
    expect(formatChartAxis(-25000000), '−2,500만');
    Intl.defaultLocale = null;
  });

  test('en: 단위 ₩ 는 부호 뒤 — −₩1,000 · 축 −52K · −5.2M', () {
    Intl.defaultLocale = 'en';
    expect(krwSigned(-1000, false, unit: true), '−₩1,000');
    expect(krwSigned(1000, false, unit: true), '₩1,000');
    expect(formatChartAxis(-52000), '−52K');
    expect(formatChartAxis(-5200000), '−5.2M');
    Intl.defaultLocale = null;
  });

  test('formatHoldingQty 음수 출력은 U+2212, 양수는 그대로', () {
    expect(formatHoldingQty('-1234.5'), '−1,234.5');
    expect(formatHoldingQty('-0.5', AssetHoldingType.crypto), '−0.5');
    expect(formatHoldingQty('1234.5'), '1,234.5');
    expect(formatHoldingQty('-3').contains('-'), isFalse);
  });

  test('formatOriginalAmount 음수는 기호 앞에 U+2212', () {
    expect(formatOriginalAmount(-5.5, 'USD', 'en'), '−\$5.50');
    expect(formatOriginalAmount(5.5, 'USD', 'en'), '\$5.50');
    expect(formatOriginalAmount(-1280, 'JPY', 'en'), '−¥1,280');
    expect(formatOriginalAmount(-5.5, 'USD', 'en').contains('-'), isFalse);
  });
}
