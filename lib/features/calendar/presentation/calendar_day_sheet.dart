import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_text.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_tone.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 날을 누르면 뜨는 그날 시트(I-09 11) — ds Bottom Sheet 조회(바깥 · 끌기로 닫힘). 제목 "10월 22일 (목)", 본문은 일정 줄
/// 목록(공휴일 먼저, 그다음 시작 시각 차례), 바닥 "일정 추가" 폭 전체. 높이는 내용만큼 · 90% 상한.
Future<void> showCalendarDaySheet(
  BuildContext context, {
  required DateTime day,
  required List<CalendarEvent> events,
  required List<Holiday> holidays,
  required List<UserCalendar> calendars,
  required VoidCallback onAdd,
  required ValueChanged<CalendarEvent> onTapEvent,
}) {
  final l = AppLocalizations.of(context);
  return PBottomSheet.show<void>(
    context,
    builder: (sheetContext) => PBottomSheetContent(
      title: monthDayDow(day),
      closeLabel: l.actionClose,
      flushBody: true,
      scrollFog: true,
      body: CalendarDaySheetBody(
        title: monthDayDow(day),
        events: events,
        holidays: holidays,
        calendars: calendars,
        onTapEvent: (e) {
          PBottomSheet.of(sheetContext).close();
          onTapEvent(e);
        },
      ),
      footer: [
        PButton(
          label: l.calEventAdd,
          size: PButtonSize.large,
          onPressed: () {
            PBottomSheet.of(sheetContext).close();
            onAdd();
          },
        ),
      ],
    ),
  );
}

/// 그날 시트 본문 — 일정 줄 목록. 줄 사이 선 없음 · 꺾쇠 없음(상세를 여는 줄).
class CalendarDaySheetBody extends StatelessWidget {
  const CalendarDaySheetBody({
    super.key,
    required this.title,
    required this.events,
    required this.holidays,
    required this.calendars,
    required this.onTapEvent,
  });

  /// 목록의 이름 — 시트 제목과 같은 글.
  final String title;
  final List<CalendarEvent> events;
  final List<Holiday> holidays;
  final List<UserCalendar> calendars;
  final ValueChanged<CalendarEvent> onTapEvent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (events.isEmpty && holidays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpacing.x6,
          vertical: PSpacing.x8,
        ),
        child: Text(
          keepAll(l.calNoEventsThisDay),
          textAlign: TextAlign.center,
          style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
        ),
      );
    }
    final red = holidayTone(context);
    return PList(
      semanticLabel: title,
      children: [
        // 공휴일(종일) 먼저 — 보기만 하는 줄
        for (final h in holidays)
          PListItem(
            title: h.holidayName,
            detail: l.calHolidays,
            prefix: ExcludeSemantics(
              child: PListTile(
                background: red.weak,
                color: red.solid,
                child: const Icon(LucideIcons.flag),
              ),
            ),
          ),
        for (final e in events)
          _EventRow(event: e, calendars: calendars, onTap: () => onTapEvent(e)),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.calendars,
    required this.onTap,
  });

  final CalendarEvent event;
  final List<UserCalendar> calendars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tone = eventTone(context, event);
    final calName = event.calendarRowId == null
        ? null
        : calendars
              .where((c) => c.rowId == event.calendarRowId)
              .firstOrNull
              ?.calendarName;
    // "{시각} · {캘린더} · {라벨} · {반복}" — 없는 조각은 뺀다
    final detail = [
      eventTimeText(l, event),
      ?calName,
      ?event.labelName,
      ?eventRepeatLabel(l, event.rrule),
    ].where((s) => s.isNotEmpty).join(' · ');
    return PListButtonItem(
      title: event.title,
      detail: detail,
      prefix: ExcludeSemantics(
        child: PListTile(
          background: tone.weak,
          color: tone.solid,
          child: Icon(event.isAllDayBool ? LucideIcons.sun : LucideIcons.clock),
        ),
      ),
      onTap: onTap,
    );
  }
}
