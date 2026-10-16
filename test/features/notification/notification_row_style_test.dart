// 날짜 · 시각 표기 — 7일 넘은 알림은 날짜 규칙(올해는 줄임), 시각은 오전 · 오후 12시간(International v106).
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/format/date.dart';

void main() {
  test('7일 넘은 알림은 날짜 규칙(올해 줄임)으로 쓴다', () {
    final d = DateTime(DateTime.now().year, 3, 9);
    expect(formatDay(d).md, '3월 9일');
  });

  test('시각은 오전 · 오후 12시간', () {
    expect(timeOfDay12(DateTime(2026, 10, 16, 15, 7)), '오후 3:07');
    expect(timeOfDay12(DateTime(2026, 10, 16, 0, 5)), '오전 12:05');
    expect(timeOfDay12(DateTime(2026, 10, 16, 12, 0)), '오후 12:00');
  });
}
