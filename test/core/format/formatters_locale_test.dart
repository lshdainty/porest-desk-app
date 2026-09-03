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

    // QA #73·#70 확정 표 — 웹 `shared/lib/porest/format.ts` 의 `formatChartAxis`
    // 테스트에 **글자 그대로 같은 표**가 들어 있다. 같은 화면을 두 플랫폼이 그리므로
    // 여기서 한 줄이라도 갈리면 사용자 눈에 바로 보인다.
    //
    // 규칙은 구간과 상관없이 하나다.
    //   · 값은 소수 첫째 자리까지, `.0` 은 뗀다 (`5.0만` ✗ → `5만` ✓)
    //   · 정수부는 늘 천단위 콤마 (1만 미만도 — 앱만 `5000` 이었다, QA #70)
    //   · 반올림이 다음 단위에 닿으면 올린다 (99,999,999 → `1억`)
    //   · 음수 부호는 U+2212(−), ASCII 하이픈이 아니다
    const chartAxis = <int, String>{
      0: '0',
      5000: '5,000',
      9999: '9,999',
      10000: '1만',
      11881: '1.2만',
      13879: '1.4만',
      50000: '5만',
      99999: '10만',
      100000: '10만',
      250000: '25만',
      999999: '100만',
      1000000: '100만',
      1500000: '150만',
      5040000: '504만',
      12300000: '1,230만',
      12305000: '1,230.5만',
      51750000: '5,175만',
      99999999: '1억',
      100000000: '1억',
      120000000: '1.2억',
      500000000: '5억',
      1200000000: '12억',
      1250000000: '12.5억',
      999900000000: '9,999억',
      999999999999: '1조',
      1000000000000: '1조',
      1200000000000: '1.2조',
      -51750000: '−5,175만',
      -11881: '−1.2만',
    };

    test('formatChartAxis: 조/억/만 축약 — 웹과 같은 문자열', () {
      for (final e in chartAxis.entries) {
        expect(
          formatChartAxis(e.key.toDouble()),
          e.value,
          reason: '${e.key} 의 축약',
        );
      }
    });

    test('formatChartAxis: `.0` 을 남기지 않는다', () {
      // QA #73 이 잡은 자리 — 합계 50,000 인 달의 도넛 중앙이 `5.0만` 이었다.
      // 어느 구간에서도 소수부가 0 이면 뗀다.
      for (final n in [10000, 50000, 100000, 1000000, 100000000, 500000000]) {
        expect(formatChartAxis(n.toDouble()), isNot(contains('.0')));
      }
    });

    test('minusOf: 0 은 부호를 붙이지 않는다 (QA #1 · #69)', () {
      expect(minusOf(1), kMinus); // U+2212
      expect(minusOf(1), isNot('-')); // ASCII 하이픈이 아니다
      expect(minusOf(0), '');
      // 총 부채는 선결제 카드 때문에 음수가 될 수 있다 — 부호를 겹치지 않고 뒤집는다.
      expect(minusOf(-1), '+');
      // 화면이 실제로 조립하는 모양. 값이 0 이면 `-0원` 이 아니라 `0원`.
      expect(krwSigned(0, false, sign: minusOf(0), unit: true), '0원');
      expect(krwSigned(51750, false, sign: minusOf(51750)), '−51,750');
    });

    test('formatChartAxis: 축 눈금이 서로 겹치지 않는다', () {
      // 축은 0에서 5등분한다. 어느 스케일에서든 라벨이 중복되면 축을 읽을 수 없다.
      for (final top in [
        50000.0,
        1000000.0,
        3000000.0,
        50000000.0,
        3.0e8,
        3.0e9,
      ]) {
        final labels = [
          for (var i = 0; i <= 4; i++) formatChartAxis(top * i / 4),
        ];
        expect(
          labels.toSet().length,
          labels.length,
          reason: '스케일 $top 에서 라벨 중복: $labels',
        );
        // 축 폭(reservedSize 52) 안에 들어가야 한다.
        for (final s in labels) {
          expect(s.length, lessThanOrEqualTo(8), reason: '라벨이 길다: $s');
        }
      }
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
      expect(weekdayLabels(mondayFirst: true), const [
        '월',
        '화',
        '수',
        '목',
        '금',
        '토',
        '일',
      ]);
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
      expect(weekdayLabels(), const [
        'Sun',
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
      ]);
      expect(weekdayLabels(mondayFirst: true), const [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ]);
      expect(yearOnly(DateTime(2026, 7, 1)), '2026');
      expect(monthOnly(DateTime(2026, 7, 1)), 'Jul');
    });
  });
}
