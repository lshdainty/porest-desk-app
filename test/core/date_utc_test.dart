import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/core/format/date.dart';

/// 서버 `[UTC]` 시각을 로컬로 옮기는 규칙.
///
/// 이게 틀리면 "마지막 사용 3분 전" 이 "9시간 전" 으로 보인다 — 화면이 멀쩡해 보여서
/// 눈으로는 못 잡는 종류의 오차라 테스트로 못 박는다.
void main() {
  test('시간대 표시가 없는 값은 UTC 로 읽는다', () {
    final dt = parseServerUtc('2026-08-24T10:30:00');
    // toLocal() 결과는 기기 시간대에 따라 다르므로, UTC 로 되돌려 비교한다.
    expect(dt!.toUtc(), DateTime.utc(2026, 8, 24, 10, 30));
  });

  test('Z 가 붙어 오면 그대로 존중한다 — 두 번 보정하지 않는다', () {
    expect(parseServerUtc('2026-08-24T10:30:00Z')!.toUtc(),
        DateTime.utc(2026, 8, 24, 10, 30));
  });

  test('오프셋이 붙어 오면 그대로 존중한다', () {
    expect(parseServerUtc('2026-08-24T19:30:00+09:00')!.toUtc(),
        DateTime.utc(2026, 8, 24, 10, 30));
  });

  test('밀리초가 붙어도 읽는다', () {
    expect(parseServerUtc('2026-08-24T10:30:00.123')!.toUtc(),
        DateTime.utc(2026, 8, 24, 10, 30, 0, 123));
  });

  test('없거나 못 읽는 값은 null — 화면이 시각을 빼고 그린다', () {
    expect(parseServerUtc(null), isNull);
    expect(parseServerUtc(''), isNull);
    expect(parseServerUtc('알 수 없음'), isNull);
  });
}
