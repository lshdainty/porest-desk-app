// 일정 폼의 순수 규칙 — 웹 `use-event-form.ts` 와 같은 결과인지 표로 잠근다(I-09 26 · 27 · 28 · 30).
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/calendar/domain/calendar_event_form_rules.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  group('ensureEndAfterStart — 웹 ensureEndAfterStart 와 같은 결과', () {
    DateTime t(int d, int h, [int m = 0]) => DateTime(2026, 10, d, h, m);

    // 웹 표(시각 있는 일정): 시작 < 끝 이면 끝 그대로, 아니면 시작 + 1시간
    test('시각 있는 일정 — 끝이 늦으면 그대로', () {
      expect(
        ensureEndAfterStart(t(22, 9), t(22, 10), allDay: false),
        t(22, 10),
      );
    });

    test('시각 있는 일정 — 끝이 앞서면 시작 + 1시간', () {
      expect(
        ensureEndAfterStart(t(23, 9), t(22, 10), allDay: false),
        t(23, 10),
      );
      expect(
        ensureEndAfterStart(t(22, 11), t(22, 10), allDay: false),
        t(22, 12),
      );
    });

    test('시각 있는 일정 — 끝과 같아도 시작 + 1시간(웹과 같다)', () {
      expect(
        ensureEndAfterStart(t(22, 10), t(22, 10), allDay: false),
        t(22, 11),
      );
    });

    test('시작 + 1시간이 자정을 넘으면 다음 날로', () {
      expect(
        ensureEndAfterStart(t(22, 23, 30), t(22, 23, 0), allDay: false),
        DateTime(2026, 10, 23, 0, 30),
      );
    });

    // 웹 표(종일): 날짜만 본다 — 시작 날이 끝 날보다 뒤일 때만 끝을 민다
    test('종일 — 같은 날이면 시각이 앞서도 끝을 건드리지 않는다', () {
      expect(ensureEndAfterStart(t(22, 9), t(22, 8), allDay: true), t(22, 8));
    });

    test('종일 — 시작 날이 끝 날보다 뒤면 시작 날로 끌려간다', () {
      final out = ensureEndAfterStart(t(25, 9), t(22, 10), allDay: true);
      expect(DateTime(out.year, out.month, out.day), DateTime(2026, 10, 25));
    });

    test('종일 — 끝 날이 뒤면 그대로(여러 날 일정)', () {
      expect(ensureEndAfterStart(t(22, 9), t(25, 10), allDay: true), t(25, 10));
    });
  });

  group('calendarRangeInvalid — 저장 때 종료 줄 아래 오류', () {
    final s = DateTime(2026, 10, 22, 10);
    test('시각 있는 일정은 끝이 앞서야 틀린 것(같으면 맞다)', () {
      expect(
        calendarRangeInvalid(s, DateTime(2026, 10, 22, 9), allDay: false),
        isTrue,
      );
      expect(calendarRangeInvalid(s, s, allDay: false), isFalse);
    });

    test('종일은 날짜만 본다', () {
      expect(
        calendarRangeInvalid(s, DateTime(2026, 10, 22, 8), allDay: true),
        isFalse,
      );
      expect(
        calendarRangeInvalid(s, DateTime(2026, 10, 21, 23), allDay: true),
        isTrue,
      );
    });
  });

  group('반복 · 알림', () {
    test('rrule 은 다섯 FREQ 만 읽고 나머지(격주 등)는 반복 안 함으로 보인다', () {
      expect(rruleToRecurrence(null), CalendarRecurrence.none);
      expect(rruleToRecurrence(''), CalendarRecurrence.none);
      expect(
        rruleToRecurrence('FREQ=WEEKLY;BYDAY=MO,WE'),
        CalendarRecurrence.weekly,
      );
      expect(rruleToRecurrence('FREQ=HOURLY'), CalendarRecurrence.none);
    });

    test('고른 반복을 RRULE 로 — 웹 recurrenceToRrule 과 같은 값', () {
      expect(
        {for (final r in CalendarRecurrence.values) r: recurrenceToRrule(r)},
        {
          CalendarRecurrence.none: null,
          CalendarRecurrence.daily: 'FREQ=DAILY',
          CalendarRecurrence.weekly: 'FREQ=WEEKLY',
          CalendarRecurrence.monthly: 'FREQ=MONTHLY',
          CalendarRecurrence.yearly: 'FREQ=YEARLY',
        },
      );
    });

    test('알림 줄 값은 짧은 차례, 없으면 "알림 없음"', () {
      expect(reminderValueText(l, const []), '알림 없음');
      expect(reminderValueText(l, const [1440, 60]), '1시간 전, 1일 전');
      expect(reminderValueText(l, const [30, 5]), '5분 전, 30분 전');
    });

    test('저장 시각 글', () {
      expect(calendarIso(DateTime(2026, 10, 22, 9, 5)), '2026-10-22T09:05:00');
    });
  });
}
