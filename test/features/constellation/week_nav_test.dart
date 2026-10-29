// 관측 리포트 주 넘기기(I-11 10-29 결정 4) — 월요일 시작 · 넘기면 같은 요일 · 미래면 오늘. 웹과 같은 표본 JSON.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/constellation/presentation/forest_report_screen.dart';

void main() {
  final rows =
      (jsonDecode(File('test/fixtures/i11_1_week_nav.json').readAsStringSync())
              as Map<String, dynamic>)['rows']
          as List<dynamic>;

  test('표본 ${rows.length} 줄 전부', () {
    for (final r in rows.cast<Map<String, dynamic>>()) {
      final today = DateTime.parse(r['today'] as String);
      final got = weekNavSelect(
        sel: r['sel'] as String,
        week: r['dir'] == 'prev' ? 0 : 1,
        now: today.add(const Duration(hours: 13)),
      );
      expect(got, r['expect'], reason: '$r');
    }
  });

  test('이전 주 → 보던 요일의 지난주 같은 요일(월요일 시작)', () {
    // 2026-10-29 목 → 지난주 목 10-22
    expect(
      weekNavSelect(sel: '2026-10-29', week: 0, now: DateTime(2026, 10, 29, 9)),
      '2026-10-22',
    );
  });

  test('다음 주 → 같은 요일, 미래면 오늘', () {
    final now = DateTime(2026, 10, 29, 9); // 목
    expect(weekNavSelect(sel: '2026-10-22', week: 1, now: now), '2026-10-29');
    // 지난주 토(10-24)에서 다음 주 → 이번 주 토(10-31)는 미래 → 오늘
    expect(weekNavSelect(sel: '2026-10-24', week: 1, now: now), '2026-10-29');
  });
}
