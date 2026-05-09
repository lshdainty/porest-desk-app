import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../application/calendar_providers.dart';
import '../domain/calendar_event.dart';
import 'calendar_event_dialog.dart';
import 'event_label_management_dialog.dart';
import 'holiday_management_dialog.dart';
import 'user_calendar_management_dialog.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  CalendarFormat _fmt = CalendarFormat.month;

  MonthYM get _key => (year: _focused.year, month: _focused.month);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final eventsAsync = ref.watch(monthEventsProvider(_key));
    final events = eventsAsync.value ?? const <CalendarEvent>[];
    final dayEvents = _eventsOnDay(events, _selected);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('캘린더'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.moreVertical, color: t.fgSecondary),
            onSelected: (v) {
              switch (v) {
                case 'calendars':
                  showUserCalendarManagementDialog(context);
                  break;
                case 'labels':
                  showEventLabelManagementDialog(context);
                  break;
                case 'holidays':
                  showHolidayManagementDialog(context);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'calendars', child: Text('내 캘린더')),
              PopupMenuItem(value: 'labels', child: Text('라벨 관리')),
              PopupMenuItem(value: 'holidays', child: Text('공휴일 관리')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: t.bgBrand,
        foregroundColor: t.fgOnBrand,
        onPressed: () =>
            showCalendarEventDialog(context, defaultDate: _selected),
        child: const Icon(LucideIcons.plus),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(monthEventsProvider(_key));
          await ref.read(monthEventsProvider(_key).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              PSpace.x16, PSpace.x12, PSpace.x16, PSpace.x80),
          children: [
            Container(
              decoration: BoxDecoration(
                color: t.bgSurface,
                borderRadius: PRadius.brLg,
                border: Border.all(color: t.borderSubtle),
              ),
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
                },
                onPageChanged: (foc) => setState(() => _focused = foc),
                calendarFormat: _fmt,
                onFormatChanged: (f) => setState(() => _fmt = f),
                eventLoader: (d) => _eventsOnDay(events, d),
                locale: 'ko_KR',
                rowHeight: PSpace.x80,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: PTypo.body.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.bold),
                  leftChevronIcon: Icon(LucideIcons.chevronLeft,
                      size: 18, color: t.fgSecondary),
                  rightChevronIcon: Icon(LucideIcons.chevronRight,
                      size: 18, color: t.fgSecondary),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekendStyle: PTypo.caption
                      .copyWith(color: t.statusDanger),
                  weekdayStyle: PTypo.caption
                      .copyWith(color: t.fgSecondary),
                ),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: true,
                  cellMargin: EdgeInsets.zero,
                  cellPadding: EdgeInsets.zero,
                ),
                calendarBuilders: CalendarBuilders<CalendarEvent>(
                  defaultBuilder: (ctx, day, _) =>
                      _DayCell(day: day, events: _eventsOnDay(events, day),
                          selected: _selected, isOutside: false, tokens: t),
                  todayBuilder: (ctx, day, _) =>
                      _DayCell(day: day, events: _eventsOnDay(events, day),
                          selected: _selected, isOutside: false, tokens: t),
                  selectedBuilder: (ctx, day, _) =>
                      _DayCell(day: day, events: _eventsOnDay(events, day),
                          selected: _selected, isOutside: false, tokens: t),
                  outsideBuilder: (ctx, day, _) =>
                      _DayCell(day: day, events: _eventsOnDay(events, day),
                          selected: _selected, isOutside: true, tokens: t),
                  markerBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: PSpace.x12),
            Row(
              children: [
                Text(
                    '${_selected.year}.${_selected.month}.${_selected.day}',
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                const SizedBox(width: 6),
                Text('${dayEvents.length}건',
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
              ],
            ),
            const SizedBox(height: PSpace.x8),
            if (eventsAsync.isLoading && events.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(PSpace.x24),
                      child: CircularProgressIndicator()))
            else if (eventsAsync.hasError && events.isEmpty)
              Padding(
                padding: const EdgeInsets.all(PSpace.x16),
                child: Text('이벤트 로드 실패\n${eventsAsync.error}',
                    style:
                        PTypo.bodySm.copyWith(color: t.statusDanger)),
              )
            else if (dayEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: PSpace.x32),
                child: Center(
                    child: Text('이날 이벤트가 없습니다',
                        style: PTypo.bodySm
                            .copyWith(color: t.fgTertiary))),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: t.bgSurface,
                  borderRadius: PRadius.brLg,
                  border: Border.all(color: t.borderSubtle),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < dayEvents.length; i++) ...[
                      _EventRow(event: dayEvents[i], tokens: t),
                      if (i < dayEvents.length - 1)
                        Divider(
                            height: 1, color: t.borderSubtle, indent: 16),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

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

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.events,
    required this.selected,
    required this.isOutside,
    required this.tokens,
  });
  final DateTime day;
  final List<CalendarEvent> events;
  final DateTime selected;
  final bool isOutside;
  final PorestTokens tokens;

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

    Color dayColor;
    if (isOutside) {
      dayColor = t.fgTertiary.withValues(alpha: 0.4);
    } else if (isSelected) {
      dayColor = t.fgOnBrand;
    } else if (isToday) {
      dayColor = t.fgBrandStrong;
    } else if (day.weekday == DateTime.sunday) {
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

    const maxLabels = 2;
    final visible = events.take(maxLabels).toList();
    final overflow = events.length - visible.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x4, PSpace.x4, PSpace.x4, PSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: dayNumber),
          const SizedBox(height: PSpace.x4),
          for (final ev in visible) ...[
            _CellEventLabel(event: ev, dimmed: isOutside, tokens: t),
            const SizedBox(height: PSpace.x4),
          ],
          if (overflow > 0)
            Padding(
              padding: const EdgeInsets.only(left: PSpace.x4),
              child: Text('+$overflow',
                  style: PTypo.micro.copyWith(color: t.fgTertiary)),
            ),
        ],
      ),
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
    final color = parseColor(event.labelColor ?? event.color,
        fallback: tokens.fgBrand);
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
        overflow: TextOverflow.ellipsis,
        style: PTypo.micro.copyWith(
          color: color.withValues(alpha: textAlpha),
          fontWeight: PFontWeight.semi,
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.tokens});
  final CalendarEvent event;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    final color = parseColor(event.labelColor ?? event.color,
        fallback: tokens.fgBrand);
    final s = event.start;
    final e = event.end;
    final timeLabel = event.isAllDayBool
        ? '종일'
        : '${_hhmm(s)}–${_hhmm(e)}';
    return InkWell(
      onTap: () => showCalendarEventDialog(context, edit: event),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: PRadius.brXs2,
              ),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: PTypo.body.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: PFontWeight.semi)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      timeLabel,
                      if ((event.location ?? '').isNotEmpty)
                        event.location!,
                      if (event.labelName != null) event.labelName!,
                    ].whereType<String>().join(' · '),
                    style: PTypo.caption
                        .copyWith(color: tokens.fgTertiary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: tokens.fgTertiary),
          ],
        ),
      ),
    );
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
