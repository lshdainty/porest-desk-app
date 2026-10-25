import 'package:flutter/material.dart';

import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';

/// 일정이 칩 · 줄 타일에서 쓰는 저장 색 — **라벨 → 캘린더 → 일정 저장 색** 차례(I-09 5).
/// 격자 칩 · 그날 시트 줄 · 상세가 모두 이 한 식을 쓴다.
String? eventColorHex(CalendarEvent e) =>
    e.labelColor ?? e.calendarColor ?? e.color;

/// 일정의 칩 색 한 벌 — 옅은 바탕 `chart-*-weak` · 아이콘 `chart-*` · 칩 글 `chart-*-contrast`.
ChartTone eventTone(BuildContext context, CalendarEvent e) =>
    chartToneOf(context, eventColorHex(e));

/// 공휴일 칩 · 줄 타일 — 늘 `chart-red`.
ChartTone holidayTone(BuildContext context) => chartToneOfKey(context, 'red');
