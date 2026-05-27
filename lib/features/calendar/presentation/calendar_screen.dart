import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../application/calendar_providers.dart';
import '../domain/calendar_event.dart';
import '../domain/holiday.dart';
import '../domain/user_calendar.dart';
import 'calendar_event_dialog.dart';
import 'user_calendar_management_dialog.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  MonthYM get _key => (year: _focused.year, month: _focused.month);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final eventsAsync = ref.watch(monthEventsProvider(_key));
    final events = eventsAsync.value ?? const <CalendarEvent>[];
    final calendarsAsync = ref.watch(userCalendarListProvider);
    final calendars = calendarsAsync.value ?? const <UserCalendar>[];
    final visibleCount = calendars.where((c) => c.isVisible).length;
    final dotColors = calendars
        .take(3)
        .map((c) => parseColor(c.color, fallback: t.fgBrand))
        .toList();

    final lastDay = DateTime(_key.year, _key.month + 1, 0).day;
    final hStart = '${_key.year.toString().padLeft(4, '0')}-${_key.month.toString().padLeft(2, '0')}-01';
    final hEnd = '${_key.year.toString().padLeft(4, '0')}-${_key.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    final holidaysAsync = ref.watch(holidayListProvider((startDate: hStart, endDate: hEnd)));
    final holidayMap = <String, String>{
      for (final h in (holidaysAsync.value ?? const <Holiday>[])) h.holidayDate: h.holidayName,
    };

    return Column(
      children: [
        _MonthHeader(
          focused: _focused,
          onPrev: () => setState(
              () => _focused = DateTime(_focused.year, _focused.month - 1)),
          onNext: () => setState(
              () => _focused = DateTime(_focused.year, _focused.month + 1)),
          onDateTap: _showMonthYearPicker,
          calendarCount: visibleCount,
          dotColors: dotColors,
          onFilterTap: _showFilterSheet,
          tokens: t,
        ),
        Expanded(
          child: TableCalendar<CalendarEvent>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focused,
            selectedDayPredicate: (d) => isSameDay(_selected, d),
            onDaySelected: (sel, foc) {
              setState(() {
                _selected = sel;
                _focused = foc;
              });
              _openDayEventsSheet(sel);
            },
            onPageChanged: (foc) => setState(() => _focused = foc),
            calendarFormat: CalendarFormat.month,
            eventLoader: (d) => _eventsOnDay(events, d),
            locale: 'ko_KR',
            shouldFillViewport: true,
            headerVisible: false,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekendStyle: PTypo.caption.copyWith(color: t.fgSecondary),
              weekdayStyle: PTypo.caption.copyWith(color: t.fgSecondary),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: true,
              cellMargin: EdgeInsets.zero,
              cellPadding: EdgeInsets.zero,
            ),
            calendarBuilders: CalendarBuilders<CalendarEvent>(
              dowBuilder: (ctx, day) {
                final Color color;
                if (day.weekday == DateTime.sunday) {
                  color = t.statusDanger;
                } else if (day.weekday == DateTime.saturday) {
                  color = t.statusInfo;
                } else {
                  color = t.fgSecondary;
                }
                return Center(
                  child: Text(
                    DateFormat.E('ko_KR').format(day),
                    style: PTypo.caption.copyWith(color: color),
                  ),
                );
              },
              defaultBuilder: (ctx, day, _) => _DayCell(
                  day: day,
                  events: _eventsOnDay(events, day),
                  selected: _selected,
                  isOutside: false,
                  holidayName: holidayMap[_dateKey(day)],
                  tokens: t),
              todayBuilder: (ctx, day, _) => _DayCell(
                  day: day,
                  events: _eventsOnDay(events, day),
                  selected: _selected,
                  isOutside: false,
                  holidayName: holidayMap[_dateKey(day)],
                  tokens: t),
              selectedBuilder: (ctx, day, _) => _DayCell(
                  day: day,
                  events: _eventsOnDay(events, day),
                  selected: _selected,
                  isOutside: false,
                  holidayName: holidayMap[_dateKey(day)],
                  tokens: t),
              outsideBuilder: (ctx, day, _) => _DayCell(
                  day: day,
                  events: _eventsOnDay(events, day),
                  selected: _selected,
                  isOutside: true,
                  holidayName: holidayMap[_dateKey(day)],
                  tokens: t),
              markerBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  void _showMonthYearPicker() {
    showPSheet<void>(
      context,
      title: '날짜 이동',
      shrinkWrap: true,
      contentBuilder: (ctx, scrollCtrl) => _MonthYearPickerSheet(
        initial: _focused,
        scrollController: scrollCtrl,
        onSelect: (date) {
          Navigator.of(context).pop();
          setState(() {
            _focused = date;
            _selected = date;
          });
        },
        onToday: () {
          Navigator.of(context).pop();
          final now = DateTime.now();
          setState(() {
            _focused = now;
            _selected = now;
          });
        },
      ),
    );
  }

  void _showFilterSheet() {
    showPSheet<void>(
      context,
      title: '캘린더',
      contentBuilder: (ctx, scrollCtrl) => _CalendarFilterSheetBody(
        scrollController: scrollCtrl,
        onManage: () {
          Navigator.of(context).pop();
          showUserCalendarManagementDialog(context);
        },
      ),
    );
  }

  void _openDayEventsSheet(DateTime day) {
    final events =
        ref.read(monthEventsProvider(_key)).value ?? const <CalendarEvent>[];
    final dayEvents = _eventsOnDay(events, day);
    final weekday =
        const ['월', '화', '수', '목', '금', '토', '일'][day.weekday - 1];
    final title = '${day.month}월 ${day.day}일 $weekday요일';
    showPSheet<void>(
      context,
      title: title,
      contentBuilder: (ctx, scrollCtrl) => _DayEventsSheetBody(
        day: day,
        events: dayEvents,
        scrollController: scrollCtrl,
        onAdd: () {
          Navigator.of(context).pop();
          showCalendarEventDialog(context, defaultDate: day);
        },
        onTapEvent: (e) {
          Navigator.of(context).pop();
          showCalendarEventDialog(context, edit: e);
        },
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<CalendarEvent> _eventsOnDay(List<CalendarEvent> all, DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
    return all.where((e) {
      final s = e.start;
      final ee = e.end;
      return !(ee.isBefore(dayStart) || s.isAfter(dayEnd));
    }).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }
}

// ─── 커스텀 월 헤더 ────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.focused,
    required this.onPrev,
    required this.onNext,
    required this.onDateTap,
    required this.calendarCount,
    required this.dotColors,
    required this.onFilterTap,
    required this.tokens,
  });

  final DateTime focused;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onDateTap;
  final int calendarCount;
  final List<Color> dotColors;
  final VoidCallback onFilterTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.x4, PSpace.x8, PSpace.x16, PSpace.x4),
      child: Row(
        children: [
          // 이전 달 버튼
          PButton.icon(icon: LucideIcons.chevronLeft, onPressed: onPrev),
          // 년월 텍스트 → 월/년 picker sheet
          GestureDetector(
            onTap: onDateTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${focused.year}년 ${focused.month}월',
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(width: PSpace.x4),
                Icon(LucideIcons.chevronDown, size: 14, color: t.fgTertiary),
              ],
            ),
          ),
          // 다음 달 버튼
          PButton.icon(icon: LucideIcons.chevronRight, onPressed: onNext),
          const Spacer(),
          // 캘린더 필터 칩
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: PSpace.x8, vertical: PSpace.x4),
              decoration: BoxDecoration(
                border: Border.all(color: t.borderSubtle),
                borderRadius: PRadius.brFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 캘린더 색상 도트 (최대 3개)
                  for (int i = 0; i < dotColors.length; i++) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColors[i],
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < dotColors.length - 1)
                      const SizedBox(width: 2),
                  ],
                  if (dotColors.isNotEmpty) const SizedBox(width: PSpace.x4),
                  Text(
                    '$calendarCount',
                    style: PTypo.caption.copyWith(
                      color: t.fgSecondary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(LucideIcons.chevronDown, size: 11, color: t.fgTertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 캘린더 필터 sheet ────────────────────────────────────────────────────────

class _CalendarFilterSheetBody extends ConsumerWidget {
  const _CalendarFilterSheetBody({
    required this.scrollController,
    required this.onManage,
  });
  final ScrollController scrollController;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final async = ref.watch(userCalendarListProvider);
    final calendars = async.value ?? const <UserCalendar>[];

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x20, PSpace.x4, PSpace.x20, PSpace.x24),
      children: [
        // 내 캘린더 섹션
        Padding(
          padding: const EdgeInsets.only(
              top: PSpace.x8, bottom: PSpace.x8),
          child: Text(
            '내 캘린더',
            style: PTypo.caption.copyWith(
              color: t.fgTertiary,
              fontWeight: PFontWeight.semi,
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (calendars.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
            child: Text(
              '캘린더가 없습니다',
              style: PTypo.bodySm.copyWith(color: t.fgTertiary),
            ),
          )
        else
          for (final cal in calendars)
            _CalendarFilterRow(
              calendar: cal,
              onToggle: () async {
                try {
                  final repo =
                      await ref.read(userCalendarRepositoryProvider.future);
                  await repo.toggleVisibility(cal.rowId);
                  ref.invalidate(userCalendarListProvider);
                } catch (_) {
                  if (context.mounted) {
                    showPSnackBar(context, '변경 실패', severity: PSnackSeverity.error);
                  }
                }
              },
              tokens: t,
            ),
        const SizedBox(height: PSpace.x16),
        PDivider(),
        // 관리 버튼
        InkWell(
          onTap: onManage,
          borderRadius: PRadius.brMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
            child: Row(
              children: [
                Icon(LucideIcons.settings2,
                    size: 15, color: t.fgBrand),
                const SizedBox(width: PSpace.x8),
                Text(
                  '캘린더 관리 · 공유 설정',
                  style: PTypo.body.copyWith(
                    color: t.fgBrand,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarFilterRow extends StatelessWidget {
  const _CalendarFilterRow({
    required this.calendar,
    required this.onToggle,
    required this.tokens,
  });
  final UserCalendar calendar;
  final VoidCallback onToggle;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final color = parseColor(calendar.color, fallback: t.fgBrand);
    return InkWell(
      onTap: onToggle,
      borderRadius: PRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
        child: Row(
          children: [
            // 체크박스 (isVisible 상태)
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: calendar.isVisible ? color : Colors.transparent,
                border: Border.all(
                  color: calendar.isVisible ? color : t.borderSubtle,
                  width: 1.5,
                ),
                borderRadius: PRadius.brSm,
              ),
              child: calendar.isVisible
                  ? Icon(LucideIcons.check, size: 13, color: t.fgOnBrand)
                  : null,
            ),
            const SizedBox(width: PSpace.x12),
            // 캘린더 이름
            Expanded(
              child: Text(
                calendar.calendarName,
                style: PTypo.body.copyWith(
                  color: calendar.isVisible ? t.fgPrimary : t.fgTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 날짜 셀 ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.events,
    required this.selected,
    required this.isOutside,
    required this.tokens,
    this.holidayName,
  });
  final DateTime day;
  final List<CalendarEvent> events;
  final DateTime selected;
  final bool isOutside;
  final PorestTokens tokens;
  final String? holidayName;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final today = DateTime.now();
    final isToday = today.year == day.year &&
        today.month == day.month &&
        today.day == day.day;
    final isSelected = selected.year == day.year &&
        selected.month == day.month &&
        selected.day == day.day;
    final isHoliday = holidayName != null && !isOutside;

    final Color dayColor;
    if (isOutside) {
      dayColor = t.fgTertiary.withValues(alpha: 0.4);
    } else if (isSelected) {
      dayColor = t.fgOnBrand;
    } else if (isToday) {
      dayColor = t.fgBrandStrong;
    } else if (isHoliday || day.weekday == DateTime.sunday) {
      dayColor = t.statusDanger;
    } else if (day.weekday == DateTime.saturday) {
      dayColor = t.statusInfo;
    } else {
      dayColor = t.fgPrimary;
    }

    final dayNumber = Container(
      width: PSpace.x24,
      height: PSpace.x24,
      alignment: Alignment.center,
      decoration: isSelected
          ? BoxDecoration(color: t.bgBrand, shape: BoxShape.circle)
          : isToday
              ? BoxDecoration(color: t.bgBrandSubtle, shape: BoxShape.circle)
              : null,
      child: Text(
        '${day.day}',
        style: PTypo.bodySm.copyWith(
          color: dayColor,
          fontWeight: (isSelected || isToday)
              ? PFontWeight.bold
              : PFontWeight.medium,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const dayNumberArea = PSpace.x24 + PSpace.x4 + PSpace.x4 + PSpace.x4;
        const labelRowHeight = 18.0;
        final available = constraints.maxHeight - dayNumberArea;
        final totalSlots = available > 0 ? (available / labelRowHeight).floor() : 0;
        final holidaySlot = isHoliday ? 1 : 0;
        final eventSlots = (totalSlots - holidaySlot).clamp(0, events.length);
        final reserveOverflow = events.length > eventSlots;
        final visibleCount =
            reserveOverflow && eventSlots > 0 ? eventSlots - 1 : eventSlots;
        final visible = events.take(visibleCount).toList();
        final overflow = events.length - visible.length;

        return Padding(
          padding: const EdgeInsets.all(PSpace.x4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: dayNumber),
              const SizedBox(height: PSpace.x4),
              if (isHoliday)
                _CellHolidayLabel(name: holidayName!, dimmed: isOutside, tokens: t),
              for (final ev in visible)
                _CellEventLabel(event: ev, dimmed: isOutside, tokens: t),
              if (overflow > 0)
                Padding(
                  padding: const EdgeInsets.only(left: PSpace.x4),
                  child: Text('+$overflow',
                      style: PTypo.micro.copyWith(color: t.fgTertiary)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CellEventLabel extends StatelessWidget {
  const _CellEventLabel({
    required this.event,
    required this.dimmed,
    required this.tokens,
  });
  final CalendarEvent event;
  final bool dimmed;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color =
        parseColor(event.labelColor ?? event.calendarColor ?? event.color, fallback: tokens.fgBrand);
    final bgAlpha = dimmed ? 0.08 : 0.15;
    final borderAlpha = dimmed ? 0.18 : 0.35;
    final textAlpha = dimmed ? 0.55 : 1.0;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x4, vertical: PSpace.x0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        border: Border.all(color: color.withValues(alpha: borderAlpha)),
        borderRadius: PRadius.brXs,
      ),
      child: Text(
        event.title,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: PTypo.micro.copyWith(
          color: color.withValues(alpha: textAlpha),
          fontWeight: PFontWeight.semi,
        ),
      ),
    );
  }
}

class _CellHolidayLabel extends StatelessWidget {
  const _CellHolidayLabel({
    required this.name,
    required this.dimmed,
    required this.tokens,
  });
  final String name;
  final bool dimmed;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = tokens.statusDanger;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x4, vertical: PSpace.x0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dimmed ? 0.08 : 0.15),
        border: Border.all(color: color.withValues(alpha: dimmed ? 0.18 : 0.35)),
        borderRadius: PRadius.brXs,
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: PTypo.micro.copyWith(
          color: color.withValues(alpha: dimmed ? 0.55 : 1.0),
          fontWeight: PFontWeight.semi,
        ),
      ),
    );
  }
}

// ─── 날짜 클릭 → 일별 이벤트 sheet ───────────────────────────────────────────

class _DayEventsSheetBody extends StatelessWidget {
  const _DayEventsSheetBody({
    required this.day,
    required this.events,
    required this.scrollController,
    required this.onAdd,
    required this.onTapEvent,
  });
  final DateTime day;
  final List<CalendarEvent> events;
  final ScrollController scrollController;
  final VoidCallback onAdd;
  final void Function(CalendarEvent) onTapEvent;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x20, vertical: PSpace.x24),
      children: [
        Row(
          children: [
            Text(
              '${events.length}건',
              style: PTypo.bodySm.copyWith(color: t.fgTertiary),
            ),
            const Spacer(),
            PButton.icon(
              icon: LucideIcons.plus,
              iconColor: t.fgPrimary,
              tooltip: '이벤트 추가',
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: PSpace.x4),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpace.x32),
            child: Center(
              child: Text(
                '이날 이벤트가 없습니다',
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
            ),
          )
        else
          for (int i = 0; i < events.length; i++) ...[
            _DaySheetEventRow(
              event: events[i],
              day: day,
              tokens: t,
              onTap: () => onTapEvent(events[i]),
            ),
            if (i < events.length - 1) PDivider(),
          ],
      ],
    );
  }
}

class _DaySheetEventRow extends StatelessWidget {
  const _DaySheetEventRow({
    required this.event,
    required this.day,
    required this.tokens,
    required this.onTap,
  });
  final CalendarEvent event;
  final DateTime day;
  final PorestTokens tokens;
  final VoidCallback onTap;

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final color =
        parseColor(event.labelColor ?? event.calendarColor ?? event.color, fallback: t.fgBrand);
    final timeLabel = event.isAllDayBool ? '종일' : _hhmm(event.start);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: PSpace.x40,
              child: Text(
                timeLabel,
                style: PTypo.caption.copyWith(color: t.fgSecondary),
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Container(
              width: PSpace.x4,
              height: PSpace.x24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: PRadius.brXs,
              ),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.title,
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.semi),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((event.location ?? '').isNotEmpty ||
                      event.labelName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: PSpace.x4),
                      child: Text(
                        [
                          if ((event.location ?? '').isNotEmpty)
                            event.location!,
                          if (event.labelName != null) event.labelName!,
                        ].join(' · '),
                        style: PTypo.caption.copyWith(color: t.fgTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: PSpace.x16, color: t.fgTertiary),
          ],
        ),
      ),
    );
  }
}

// ─── 연/월 picker sheet ───────────────────────────────────────────────────────

class _MonthYearPickerSheet extends StatefulWidget {
  const _MonthYearPickerSheet({
    required this.initial,
    required this.scrollController,
    required this.onSelect,
    required this.onToday,
  });
  final DateTime initial;
  final ScrollController scrollController;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onToday;

  @override
  State<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<_MonthYearPickerSheet> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final selYear = widget.initial.year;
    final selMonth = widget.initial.month;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 연도 네비 — 화살표 drawer 양 끝
          Row(
            children: [
              PButton.icon(
                icon: LucideIcons.chevronLeft,
                onPressed: () => setState(() => _year--),
              ),
              const Spacer(),
              Text(
                '$_year년',
                style: PTypo.body.copyWith(fontWeight: PFontWeight.bold),
              ),
              const Spacer(),
              PButton.icon(
                icon: LucideIcons.chevronRight,
                onPressed: () => setState(() => _year++),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          // 월 그리드 (4×3)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            mainAxisSpacing: PSpace.x8,
            crossAxisSpacing: PSpace.x4,
            children: List.generate(12, (i) {
              final month = i + 1;
              final isSelected = _year == selYear && month == selMonth;
              return GestureDetector(
                onTap: () => widget.onSelect(DateTime(_year, month)),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? t.bgBrand : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(
                    '$month월',
                    style: PTypo.bodySm.copyWith(
                      color: isSelected ? t.fgOnBrand : t.fgPrimary,
                      fontWeight: isSelected
                          ? PFontWeight.bold
                          : PFontWeight.medium,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: PSpace.x16),
          PDivider(),
          const SizedBox(height: PSpace.x12),
          // 푸터: 오늘로 + 닫기
          Row(
            children: [
              GestureDetector(
                onTap: widget.onToday,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.navigation, size: 14, color: t.fgBrand),
                    const SizedBox(width: PSpace.x4),
                    Text(
                      '오늘로',
                      style: PTypo.bodySm.copyWith(
                        color: t.fgBrand,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PButton(
                label: '닫기',
                variant: PButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
