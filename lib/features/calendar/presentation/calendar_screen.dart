import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
          IconButton(
            icon: Icon(LucideIcons.refreshCw,
                size: 18, color: t.fgSecondary),
            onPressed: () => ref.invalidate(monthEventsProvider(_key)),
          ),
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
      body: SafeArea(
        top: false,
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
          shouldFillViewport: true,
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
              Color color;
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
                tokens: t),
            todayBuilder: (ctx, day, _) => _DayCell(
                day: day,
                events: _eventsOnDay(events, day),
                selected: _selected,
                isOutside: false,
                tokens: t),
            selectedBuilder: (ctx, day, _) => _DayCell(
                day: day,
                events: _eventsOnDay(events, day),
                selected: _selected,
                isOutside: false,
                tokens: t),
            outsideBuilder: (ctx, day, _) => _DayCell(
                day: day,
                events: _eventsOnDay(events, day),
                selected: _selected,
                isOutside: true,
                tokens: t),
            markerBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // 셀 가용 높이에서 날짜 숫자 영역(24) + 상하 패딩(8) + 간격(4) 빼고
        // 라벨 1개 높이(약 18) 로 나눠 표시 가능 개수 계산.
        const dayNumberArea = PSpace.x24 + PSpace.x4 + PSpace.x4 + PSpace.x4;
        const labelRowHeight = 18.0;
        final available = constraints.maxHeight - dayNumberArea;
        final fit = available > 0 ? (available / labelRowHeight).floor() : 0;
        final maxLabels = fit.clamp(0, events.length);
        final reserveOverflow = events.length > maxLabels;
        final visibleCount = reserveOverflow && maxLabels > 0
            ? maxLabels - 1
            : maxLabels;
        final visible = events.take(visibleCount).toList();
        final overflow = events.length - visible.length;

        return Padding(
          padding: const EdgeInsets.all(PSpace.x4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: dayNumber),
              const SizedBox(height: PSpace.x4),
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

