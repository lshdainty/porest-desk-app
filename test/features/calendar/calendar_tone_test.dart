// 일정 칩 · 줄 타일 색 한 규칙 (I-09 5) — 라벨 → 캘린더 → 저장 색 차례, 섞은 색이 아니라 역할 색.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_tone.dart';

CalendarEvent _e({String? label, String? cal, String? own}) => CalendarEvent(
  rowId: 1,
  title: '일정',
  startDate: '2026-10-22T09:00:00',
  endDate: '2026-10-22T10:00:00',
  labelColor: label,
  calendarColor: cal,
  color: own,
);

Future<ChartTone> _tone(
  WidgetTester tester,
  CalendarEvent e, {
  bool dark = false,
}) async {
  late ChartTone out;
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? GrooTheme.dark() : GrooTheme.light(),
      home: Builder(
        builder: (context) {
          out = eventTone(context, e);
          return const SizedBox();
        },
      ),
    ),
  );
  return out;
}

void main() {
  const blue = '#2c70bf';
  const red = '#c73838';
  const green = '#2d8060';

  test('색을 고르는 차례 — 라벨 → 캘린더 → 저장 색', () {
    expect(eventColorHex(_e(label: blue, cal: red, own: green)), blue);
    expect(eventColorHex(_e(cal: red, own: green)), red);
    expect(eventColorHex(_e(own: green)), green);
    expect(eventColorHex(_e()), isNull);
  });

  testWidgets('라이트 — 바탕 weak · 글 contrast · 점 solid 가 역할 색이다', (tester) async {
    final t = await _tone(tester, _e(label: blue, cal: red));
    expect(t.weak, PColors.light.chartBlueWeak);
    expect(t.contrast, PColors.light.chartBlueContrast);
    expect(t.solid, PColors.light.chartBlue);
  });

  testWidgets('다크 — 같은 일정이 다크 역할 색으로 바뀐다', (tester) async {
    final t = await _tone(tester, _e(cal: green), dark: true);
    expect(t.weak, PColors.dark.chartGreenWeak);
    expect(t.contrast, PColors.dark.chartGreenContrast);
    expect(t.solid, PColors.dark.chartGreen);
  });

  testWidgets('색이 없으면 blue, 공휴일은 늘 red', (tester) async {
    final t = await _tone(tester, _e());
    expect(t.weak, PColors.light.chartBlueWeak);
    late ChartTone h;
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: Builder(
          builder: (context) {
            h = holidayTone(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(h.weak, PColors.light.chartRedWeak);
    expect(h.contrast, PColors.light.chartRedContrast);
  });
}
