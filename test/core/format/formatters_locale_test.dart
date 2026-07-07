import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';

/// intl 로케일 포맷팅 회귀 게이트.
///
/// ko 그룹은 **기존 출력 문자열을 그대로** assert 한다 — 회귀 0 검증의 핵심.
/// en 그룹은 새 포맷(₩ 접두 · compact · DateFormat 스켈레톤)을 검증한다.
///
/// 포맷터는 `Intl.defaultLocale` 로 로케일을 판정하므로 그룹별로 세팅한다.
void main() {
  // 요일 배열은 date.dart 의 private `_dows` 와 동일 — ko dow 기대값 산출용.
  const dows = ['일', '월', '화', '수', '목', '금', '토'];

  // en DateFormat 이 로케일 심볼을 요구 → 앱 main() 과 동일하게 초기화.
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('ko locale — 회귀 0 (기존 출력 그대로)', () {
    setUp(() => Intl.defaultLocale = 'ko');

    test('krw: 천단위 콤마 · 부호 · 절댓값', () {
      expect(krw(10000), '10,000');
      expect(krw(1234567), '1,234,567');
      expect(krw(0), '0');
      expect(krw(1000, sign: true), '+1,000');
      expect(krw(-2000, abs: true), '2,000');
    });

    test('krwSigned: 원 접미 · 부호 · 마스킹', () {
      expect(krwSigned(10000, false, unit: true), '10,000원');
      expect(krwSigned(10000, false, sign: '−', unit: true), '−10,000원');
      expect(krwSigned(10000, false), '10,000');
      expect(krwSigned(10000, true, unit: true), kHideMask);
    });

    test('formatChartAxis: 억/만 축약', () {
      expect(formatChartAxis(1200000000), '12.0억');
      expect(formatChartAxis(-51750000), '−5,200만');
      expect(formatChartAxis(5000), '5000');
    });

    test('formatDay · yearMonth: 수동 포맷', () {
      final d = DateTime(2026, 1, 1); // 목요일
      expect(formatDay(d).md, '1월 1일');
      expect(formatDay(d).dow, dows[d.weekday % 7]);
      expect(yearMonth(DateTime(2026, 7, 1)), '2026년 7월');
    });

    test('weekdayLabels · yearOnly · monthOnly: 수동 포맷', () {
      // 기존 인라인 배열과 정확히 동일 (일~토 / 월~일).
      expect(weekdayLabels(), const ['일', '월', '화', '수', '목', '금', '토']);
      expect(weekdayLabels(mondayFirst: true),
          const ['월', '화', '수', '목', '금', '토', '일']);
      expect(yearOnly(DateTime(2026, 7, 1)), '2026년');
      expect(monthOnly(DateTime(2026, 7, 1)), '7월');
    });

    // Intl.defaultLocale='ko' 배선 후 bare DateFormat(toIsoLocal) 이 ko 심볼을
    // 요구 → 초기화 안 됐으면 throw. 회귀 가드.
    test('toIsoLocal: ISO 그대로 (locale 무관)', () {
      expect(toIsoLocal(DateTime(2026, 7, 15, 9, 5, 3)), '2026-07-15T09:05:03');
    });
  });

  group('en locale — 신규 포맷', () {
    setUp(() => Intl.defaultLocale = 'en');
    tearDown(() => Intl.defaultLocale = 'ko'); // 다른 테스트 오염 방지

    test('krw: 콤마 그룹핑 ko 와 동일', () {
      expect(krw(10000), '10,000');
      expect(krw(1234567), '1,234,567');
    });

    test('krwSigned: ₩ 접두 (부호는 최선두)', () {
      expect(krwSigned(10000, false, unit: true), '₩10,000');
      expect(krwSigned(10000, false, sign: '−', unit: true), '−₩10,000');
      expect(krwSigned(10000, false), '10,000'); // unit=false → 숫자만
    });

    test('formatChartAxis: compact (M/K)', () {
      expect(formatChartAxis(120000000), '120M');
      expect(formatChartAxis(52000), '52K');
    });

    test('formatDay · yearMonth: DateFormat(en) 스켈레톤', () {
      final d = DateTime(2026, 1, 1); // Thursday
      expect(formatDay(d).md, 'Jan 1');
      expect(formatDay(d).dow, 'Thu');
      expect(yearMonth(DateTime(2026, 7, 1)), 'Jul 2026');
    });

    test('weekdayLabels · yearOnly · monthOnly: DateFormat(en)', () {
      expect(weekdayLabels(),
          const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']);
      expect(weekdayLabels(mondayFirst: true),
          const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
      expect(yearOnly(DateTime(2026, 7, 1)), '2026');
      expect(monthOnly(DateTime(2026, 7, 1)), 'Jul');
    });
  });
}
