import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_tone.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 폰 달력 격자 — 칸 높이 103 고정 · 칸마다 위 1px 선 · 칸 안 글자 칩(I-09 9 10).
/// 격자가 화면보다 길면 화면이 스크롤하고, 마지막 주 아래에 탭 바 보상을 둔다.

/// 칸 높이.
const double kCalendarCellHeight = 103;

/// 요일 줄 · 격자의 좌우 안쪽 2.
const double kCalendarGridInset = PSpacing.x0_5;

/// 요일 줄 높이.
const double kCalendarWeekdayRowHeight = 32;

/// 칸 안 칩 높이(100% 글자) · 칩 사이.
const double kCalendarChipHeight = 18;
const double kCalendarChipGap = PSpacing.x0_5;

/// 칸 좌우 안쪽 1 · 칩 안쪽 좌우 3 — 간격 토큰에 없는 화면 값(그림 `.pc.tall` · `.ec`).
const double kCalendarCellInset = 1;
const double _chipPadX = 3;

/// 칸 위 선 1px 아래 여백 1 — 위 2(선 포함)에서 날 숫자가 시작한다.
const double kCalendarCellTopPad = 1;

/// 칸 안 날 숫자 원 — 글자가 커지면 따라 커진다.
const double kCalendarDayCircle = 26;

/// 그날(`day`)에 걸친 일정 — 시작 시각 차례.
List<CalendarEvent> eventsOnDay(List<CalendarEvent> all, DateTime day) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
  return all.where((e) {
    return !(e.end.isBefore(dayStart) || e.start.isAfter(dayEnd));
  }).toList()..sort((a, b) => a.start.compareTo(b.start));
}

/// 'YYYY-MM-DD'.
String calendarDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 달 격자에 그릴 날 — 일요일 시작, 앞뒤 이웃 달 칸 포함, 5주 달은 5줄.
List<DateTime> calendarGridDays(DateTime month) {
  final first = DateTime(month.year, month.month);
  final lead = first.weekday % 7;
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final weeks = ((lead + daysInMonth) / 7).ceil();
  return [
    for (var i = 0; i < weeks * 7; i++)
      DateTime(first.year, first.month, 1 - lead + i),
  ];
}

/// 요일 줄 — 높이 32 · t3 · 평일 fg-neutral-subtle · 일 fg-critical · 토 지금 색 그대로(fg-brand).
class CalendarWeekdayRow extends StatelessWidget {
  const CalendarWeekdayRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labels = weekdayLabels();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kCalendarGridInset),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kCalendarWeekdayRowHeight),
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    labels[i],
                    style: PTypography.t3.copyWith(
                      color: switch (i) {
                        0 => c.fgCritical,
                        6 => c.fgBrand,
                        _ => c.fgNeutralSubtle,
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 달 격자 — 주마다 칸 7개. 칸 전체가 그날 시트를 여는 누르는 자리 하나다.
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    super.key,
    required this.month,
    required this.events,
    required this.holidays,
    required this.onDayTap,
  });

  final DateTime month;
  final List<CalendarEvent> events;

  /// 'YYYY-MM-DD' → 공휴일 이름. 공휴일을 끄면 빈 맵.
  final Map<String, String> holidays;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final days = calendarGridDays(month);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kCalendarGridInset),
      child: Column(
        children: [
          for (var w = 0; w < days.length ~/ 7; w++)
            SizedBox(
              height: kCalendarCellHeight,
              child: Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: CalendarDayCell(
                        day: days[w * 7 + d],
                        isOutside: days[w * 7 + d].month != month.month,
                        events: eventsOnDay(events, days[w * 7 + d]),
                        holidayName: holidays[calendarDateKey(days[w * 7 + d])],
                        onTap: () => onDayTap(days[w * 7 + d]),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 이벤트가 한 날짜 칸에서 차지하는 멀티데이 바 위치 — 단일/시작/중간/종료.
enum _SegPos { none, first, middle, last }

bool _isMulti(CalendarEvent e) {
  final sd = DateTime(e.start.year, e.start.month, e.start.day);
  final ed = DateTime(e.end.year, e.end.month, e.end.day);
  return ed.isAfter(sd);
}

_SegPos _segPos(CalendarEvent e, DateTime day) {
  final sd = DateTime(e.start.year, e.start.month, e.start.day);
  final ed = DateTime(e.end.year, e.end.month, e.end.day);
  if (!ed.isAfter(sd)) return _SegPos.none;
  final d = DateTime(day.year, day.month, day.day);
  if (d == sd) return _SegPos.first;
  if (d == ed) return _SegPos.last;
  return _SegPos.middle;
}

/// 칸 하나 — 위 1px 선 · 날 숫자 원 · 글자 칩 · "+N개".
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.isOutside,
    required this.events,
    required this.onTap,
    this.holidayName,
  });

  final DateTime day;
  final bool isOutside;
  final List<CalendarEvent> events;
  final String? holidayName;
  final VoidCallback onTap;

  /// 칸 안에 칩이 들어갈 수 있는 줄 수 — (칸 높이 − 위 2 − 날 숫자 − 사이 2) ÷ (칩 + 사이). 글자 크기를 곱해 실제 크기로 잰다.
  static int slotsFor(TextScaler scaler) {
    final number = _numberBox(scaler);
    final chip = _chipHeight(scaler);
    final avail =
        kCalendarCellHeight - PSpacing.x0_5 - number - kCalendarChipGap;
    if (avail <= 0) return 0;
    return ((avail + kCalendarChipGap) / (chip + kCalendarChipGap)).floor();
  }

  static double _numberBox(TextScaler s) => s
      .scale(PTypography.t4.fontSize! * PTypography.t4.height!)
      .clamp(kCalendarDayCircle, double.infinity);

  static double _chipHeight(TextScaler s) =>
      s.scale(kCalendarChipHeight).clamp(kCalendarChipHeight, double.infinity);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final now = DateTime.now();
    final isToday =
        now.year == day.year && now.month == day.month && now.day == day.day;
    final isHoliday = holidayName != null && !isOutside;

    final Color dayColor;
    if (isOutside) {
      // 이웃 달은 날짜 숫자만 fg-disabled — 그 칸의 일정 · 휴일 이름은 이번 달과 같다(불투명도를 쓰지 않는다, 03-C 5A)
      dayColor = c.fgDisabled;
    } else if (isHoliday || day.weekday == DateTime.sunday) {
      dayColor = c.fgCritical;
    } else if (day.weekday == DateTime.saturday) {
      dayColor = c.fgBrand;
    } else {
      dayColor = c.fgNeutral;
    }

    // 멀티데이 우선 · 시작 · 기간 차례로 안정 정렬해 상단 줄을 고정 — 이웃 칸에서 같은 줄에 선다.
    final ordered = [...events]
      ..sort((a, b) {
        final am = _isMulti(a), bm = _isMulti(b);
        if (am != bm) return am ? -1 : 1;
        final cmp = a.start.compareTo(b.start);
        if (cmp != 0) return cmp;
        return b.end.difference(b.start).compareTo(a.end.difference(a.start));
      });

    final slots = slotsFor(scaler);
    final total = ordered.length + (isHoliday ? 1 : 0);
    final overflow = total > slots;
    // 넘치면 마지막 줄을 "+N개" 가 차지한다
    final shown = overflow ? (slots - 1).clamp(0, slots) : total;
    final holidayShown = isHoliday && shown > 0;
    final eventShown = (shown - (holidayShown ? 1 : 0)).clamp(
      0,
      ordered.length,
    );
    final visible = ordered.take(eventShown).toList();
    final hidden = total - (holidayShown ? 1 : 0) - visible.length;

    final numberBox = _numberBox(scaler);
    final dayNumber = Container(
      width: numberBox,
      height: numberBox,
      alignment: Alignment.center,
      // 오늘 = 옅은 원 bg-neutral-weak + 700 (date-picker.md — 브랜드 색으로 채우지 않는다)
      decoration: (isToday && !isOutside)
          ? BoxDecoration(color: c.bgNeutralWeak, shape: BoxShape.circle)
          : null,
      child: Text(
        '${day.day}',
        style: PTypography.t4.copyWith(
          color: dayColor,
          fontWeight: isToday && !isOutside ? FontWeight.w700 : FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: '${monthDayDow(day)}, ${l.calEventTotalCount(total)}',
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.strokeNeutralSubtle)),
            ),
            // 위 2 = 선 1 + 1
            child: Padding(
              padding: const EdgeInsets.only(top: kCalendarCellTopPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: dayNumber),
                  const SizedBox(height: kCalendarChipGap),
                  if (holidayShown)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: kCalendarCellInset,
                        right: kCalendarCellInset,
                        bottom: kCalendarChipGap,
                      ),
                      child: _ChipBar(
                        text: holidayName!,
                        tone: holidayTone(context),
                        radius: _chipRadius,
                      ),
                    ),
                  for (final ev in visible)
                    _EventChip(event: ev, day: day, position: _segPos(ev, day)),
                  if (overflow && hidden > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _chipPadX,
                      ),
                      // 개수라 말줄임 대신 칸 폭에 맞춰 줄여 보인다(글자 200% 에서도 "+3개" 가 읽힌다)
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l.calMoreEvents(hidden),
                          maxLines: 1,
                          softWrap: false,
                          style: PTypography.t2.copyWith(
                            color: c.fgNeutralMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const BorderRadius _chipRadius = BorderRadius.all(Radius.circular(PRounded.r1));

/// 칩 한 줄 — 높이 18(글자 크기를 곱한다) · 모서리 4 · 좌우 3 · t2 500 · 한 줄 끝 말줄임.
class _ChipBar extends StatelessWidget {
  const _ChipBar({
    required this.text,
    required this.tone,
    required this.radius,
  });

  final String text;
  final ChartTone tone;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: CalendarDayCell._chipHeight(
          MediaQuery.textScalerOf(context),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _chipPadX),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(color: tone.weak, borderRadius: radius),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: _chipStyle(tone),
      ),
    );
  }
}

/// 칩 글 — t2 12 · 500, 줄 높이 18.
TextStyle _chipStyle(ChartTone tone) => PTypography.t2.copyWith(
  height: kCalendarChipHeight / 12,
  fontWeight: FontWeight.w500,
  color: tone.contrast,
);

class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.event,
    required this.day,
    required this.position,
  });

  final CalendarEvent event;
  final DateTime day;
  final _SegPos position;

  @override
  Widget build(BuildContext context) {
    final tone = eventTone(context, event);
    // 멀티데이 연속 바: 시작=좌측만 round, 종료=우측만 round, 중간=square + 칸 끝까지
    // (인접 칸과 이어지도록 연결 변은 가로 inset 0). 이어지는 일정의 띠 모양은 지금 그대로(사용자 결정).
    const r = Radius.circular(PRounded.r1);
    final radius = switch (position) {
      _SegPos.none => _chipRadius,
      _SegPos.first => const BorderRadius.horizontal(left: r),
      _SegPos.last => const BorderRadius.horizontal(right: r),
      _SegPos.middle => BorderRadius.zero,
    };
    final showText = position == _SegPos.none;
    final leftInset = position == _SegPos.none || position == _SegPos.first;
    final rightInset = position == _SegPos.none || position == _SegPos.last;

    // 이 칸이 "이 주(행)에서 바가 끝나는 칸" 인가 — 이벤트 마지막 날이거나 주의 끝(토).
    // 라벨은 행마다 한 번, 이 칸에서 왼쪽으로 넘치게 그린다. Flutter 는 z-index 가 없어 나중에 그려지는(오른쪽)
    // 칸이 위에 오므로, 끝 칸에서 왼쪽으로 뻗어야 이웃 조각의 배경에 글자가 가려지지 않는다.
    final d = DateTime(day.year, day.month, day.day);
    final isRowSegEnd =
        position != _SegPos.none &&
        (position == _SegPos.last || d.weekday == DateTime.saturday);
    final int rowSegDays;
    if (isRowSegEnd) {
      final weekStart = d.subtract(Duration(days: d.weekday % 7));
      final sd = DateTime(event.start.year, event.start.month, event.start.day);
      final segStart = sd.isAfter(weekStart) ? sd : weekStart;
      rowSegDays = d.difference(segStart).inDays + 1;
    } else {
      rowSegDays = 0;
    }
    final style = _chipStyle(tone);
    final h = CalendarDayCell._chipHeight(MediaQuery.textScalerOf(context));
    return Padding(
      padding: EdgeInsets.only(
        left: leftInset ? kCalendarCellInset : 0,
        right: rightInset ? kCalendarCellInset : 0,
        bottom: kCalendarChipGap,
      ),
      child: Container(
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: _chipPadX),
        decoration: BoxDecoration(color: tone.weak, borderRadius: radius),
        alignment: Alignment.centerLeft,
        child: isRowSegEnd
            ? LayoutBuilder(
                builder: (context, c) {
                  // 칸 폭 균등 + 조각 사이 여백 0 — 칸 수 × 현재 폭으로 스팬을 근사한다
                  final spanW = c.maxWidth * rowSegDays;
                  return OverflowBox(
                    alignment: Alignment.centerRight,
                    minWidth: spanW,
                    maxWidth: spanW,
                    child: Text(
                      event.title,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: style,
                    ),
                  );
                },
              )
            : Text(
                showText ? event.title : '',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
      ),
    );
  }
}
