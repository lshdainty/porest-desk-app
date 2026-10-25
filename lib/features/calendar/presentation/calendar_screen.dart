import 'package:groo_damda_app/shared/ds/bottom_navigation/p_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_divider.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_visibility.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_dialog.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_detail_dialog.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_filter_sheet.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_month_row.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_tone.dart';

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
    final calendarsAsync = ref.watch(userCalendarListProvider);
    final calendars = calendarsAsync.value ?? const <UserCalendar>[];
    final eventsAsync = ref.watch(monthEventsProvider(_key));
    // 표시를 끈 캘린더의 일정은 화면에서 뺀다 (웹 CalendarContainer 정합).
    // 그리드 라벨·"+N" 넘침 표시·날짜 시트가 모두 이 목록 하나를 보므로,
    // 여기서 한 번 거르면 "점은 있는데 눌러도 없는" 상태가 생기지 않는다.
    final events = visibleCalendarEvents(
      eventsAsync.value ?? const <CalendarEvent>[],
      calendars,
    );
    final holidayVisible = ref.watch(holidayVisibleProvider);
    // 표시 개수 = 활성 사용자 캘린더 + 활성 내장 소스(공휴일). 웹 CalendarSourceToggle
    // totalCount(visible 캘린더 + enabled builtin) 정합 — 공휴일 누락으로 웹보다 1 적던 버그 fix.
    final visibleCount =
        calendars.where((c) => c.isVisible).length + (holidayVisible ? 1 : 0);
    // 점도 표시 중인 캘린더만 — 웹 CalendarSourceToggle dotColors 정합
    // (`userCalendars.filter(c => c.isVisible).slice(0, 3)`). 개수는 visible 로
    // 세면서 점은 전부에서 뽑던 탓에 "1개" 옆에 점이 둘 찍히곤 했다.
    final dotColors = calendars
        .where((c) => c.isVisible)
        .take(3)
        .map((c) => chartToneOf(context, c.color).solid)
        .toList();

    final lastDay = DateTime(_key.year, _key.month + 1, 0).day;
    final hStart =
        '${_key.year.toString().padLeft(4, '0')}-${_key.month.toString().padLeft(2, '0')}-01';
    final hEnd =
        '${_key.year.toString().padLeft(4, '0')}-${_key.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    final holidaysAsync = ref.watch(
      holidayListProvider((startDate: hStart, endDate: hEnd)),
    );
    // 기타 소스 > 공휴일 토글 off 면 빈 맵 → 달력에 공휴일 라벨/색 미표시.
    final holidayMap = holidayVisible
        ? <String, String>{
            for (final h in (holidaysAsync.value ?? const <Holiday>[]))
              h.holidayDate: h.holidayName,
          }
        : const <String, String>{};

    // 첫 로딩(이벤트/캘린더 아직 없음) — 웹 CalendarMonthViewSkeleton 정합.
    final firstLoading =
        (eventsAsync.isLoading && !eventsAsync.hasValue) ||
        (calendarsAsync.isLoading && !calendarsAsync.hasValue);

    // 띠 화면 — 달력 한 장이 머리 바로 아래부터 화면 폭 흰 띠다(02-005 / Q-019-3, I-05 74)
    return ColoredBox(
      key: const ValueKey('calendar-band'),
      color: context.colors.bgLayerDefault,
      child: Column(
        children: [
          CalendarMonthRow(
            month: _focused,
            onPrev: () => setState(
              () => _focused = DateTime(_focused.year, _focused.month - 1),
            ),
            onNext: () => setState(
              () => _focused = DateTime(_focused.year, _focused.month + 1),
            ),
            onPick: _showMonthYearPicker,
            calendarCount: visibleCount,
            dotColors: dotColors,
            onFilterTap: _showFilterSheet,
          ),
          if (firstLoading)
            Expanded(
              child: Padding(
                // 플로팅 탭바 보상 — 그리드가 바 뒤까지 확장되지 않게(셸 화면 공통).
                padding: EdgeInsets.only(
                  bottom: bottomNavigationInset(context),
                ),
                child: _CalendarGridSkeleton(tokens: t),
              ),
            )
          else
            Expanded(
              child: Padding(
                // 플로팅 탭바 보상 — 그리드가 바 뒤까지 확장되지 않게(셸 화면 공통).
                padding: EdgeInsets.only(
                  bottom: bottomNavigationInset(context),
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
                    _openDayEventsSheet(sel);
                  },
                  onPageChanged: (foc) => setState(() => _focused = foc),
                  calendarFormat: CalendarFormat.month,
                  eventLoader: (d) => _eventsOnDay(events, d),
                  locale: 'ko_KR',
                  shouldFillViewport: true,
                  headerVisible: false,
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekendStyle: PTypography.t2.copyWith(
                      color: context.colors.fgNeutralMuted,
                    ),
                    weekdayStyle: PTypography.t2.copyWith(
                      color: context.colors.fgNeutralMuted,
                    ),
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
                        color = t.statusDangerFg;
                      } else if (day.weekday == DateTime.saturday) {
                        color = t.fgBrand;
                      } else {
                        // 평일 = 일반 텍스트색(가계부 요일 헤더 정합, 사용자 결정)
                        color = t.fgPrimary;
                      }
                      return Center(
                        child: Text(
                          formatDay(day).dow,
                          style: PTypo.caption.copyWith(color: color),
                        ),
                      );
                    },
                    defaultBuilder: (ctx, day, _) => _DayCell(
                      day: day,
                      events: _eventsOnDay(events, day),
                      isOutside: false,
                      holidayName: holidayMap[_dateKey(day)],
                      tokens: t,
                    ),
                    todayBuilder: (ctx, day, _) => _DayCell(
                      day: day,
                      events: _eventsOnDay(events, day),
                      isOutside: false,
                      holidayName: holidayMap[_dateKey(day)],
                      tokens: t,
                    ),
                    selectedBuilder: (ctx, day, _) => _DayCell(
                      day: day,
                      events: _eventsOnDay(events, day),
                      isOutside: false,
                      holidayName: holidayMap[_dateKey(day)],
                      tokens: t,
                    ),
                    outsideBuilder: (ctx, day, _) => _DayCell(
                      day: day,
                      events: _eventsOnDay(events, day),
                      isOutside: true,
                      holidayName: holidayMap[_dateKey(day)],
                      tokens: t,
                    ),
                    markerBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMonthYearPicker() {
    showPSheet<void>(
      context,
      title: AppLocalizations.of(context).calDatePicker,
      shrinkWrap: true,
      contentBuilder: (ctx, scrollCtrl) => _MonthYearPickerSheet(
        initial: _focused,
        scrollController: scrollCtrl,
        // showPSheet 는 root navigator 에 뜸 — State context 로 pop 하면 탭 안
        // 페이지가 pop 되므로(스택 소진 크래시) rootNavigator 지정 필수.
        onSelect: (date) {
          Navigator.of(context, rootNavigator: true).pop();
          setState(() {
            _focused = date;
            _selected = date;
          });
        },
        onToday: () {
          Navigator.of(context, rootNavigator: true).pop();
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
    showCalendarFilterSheet(
      context,
      onManage: () => context.push('/settings/calendar-share'),
    );
  }

  void _openDayEventsSheet(DateTime day) {
    // 그리드와 같은 규칙 — 표시를 끈 캘린더의 일정은 시트에도 올리지 않는다.
    final events = visibleCalendarEvents(
      ref.read(monthEventsProvider(_key)).value ?? const <CalendarEvent>[],
      ref.read(userCalendarListProvider).value ?? const <UserCalendar>[],
    );
    final dayEvents = _eventsOnDay(events, day);
    // 공휴일 — 그리드와 동일하게 holidayVisible 게이트 + 월 범위에서 해당일 필터.
    // 웹 상세처럼 종일 항목으로 함께 노출.
    final holidayVisible = ref.read(holidayVisibleProvider);
    final lastDay = DateTime(_key.year, _key.month + 1, 0).day;
    final hStart =
        '${_key.year.toString().padLeft(4, '0')}-${_key.month.toString().padLeft(2, '0')}-01';
    final hEnd =
        '${_key.year.toString().padLeft(4, '0')}-${_key.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    final dayKey = _dateKey(day);
    final dayHolidays = holidayVisible
        ? (ref
                      .read(
                        holidayListProvider((startDate: hStart, endDate: hEnd)),
                      )
                      .value ??
                  const <Holiday>[])
              .where((h) => h.holidayDate == dayKey)
              .toList()
        : const <Holiday>[];
    final title = localeIsEn()
        ? '${formatDay(day).md}, ${formatDay(day).dow}'
        : '${formatDay(day).md} ${formatDay(day).dow}요일';
    showPSheet<void>(
      context,
      title: title,
      contentBuilder: (ctx, scrollCtrl) => _DayEventsSheetBody(
        day: day,
        events: dayEvents,
        holidays: dayHolidays,
        scrollController: scrollCtrl,
        onAdd: () {
          Navigator.of(context, rootNavigator: true).pop();
          showCalendarEventDialog(context, defaultDate: day);
        },
        onTapEvent: (e) {
          Navigator.of(context, rootNavigator: true).pop();
          showCalendarEventDetailDialog(context, e);
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
    }).toList()..sort((a, b) => a.start.compareTo(b.start));
  }
}

// ─── 날짜 셀 ──────────────────────────────────────────────────────────────────

/// 캘린더 첫 로딩 skeleton — 정적 요일 헤더(실제 라벨) + 6주 × 7일 데이터 그리드.
///
/// 요일 헤더는 서버 무관 정적 틀이라 스켈레톤화하지 않고 실제 텍스트 렌더(TableCalendar
/// dowBuilder 정합). 셀 내부 날짜 숫자(24px 박스 좌측 정렬)와 이벤트 바(full-bleed,
/// micro 높이, brSm)만 데이터 placeholder 로 그려 로딩-후 _DayCell 과 1:1 정합.
class _CalendarGridSkeleton extends StatelessWidget {
  const _CalendarGridSkeleton({required this.tokens});
  final GrooTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    // 월~일 — TableCalendar daysOfWeekStyle/dowBuilder 정합(주말 색 포함, 실제 텍스트).
    final dow = weekdayLabels(mondayFirst: true);
    Color dowColor(int i) {
      if (i == 6) return t.statusDangerFg; // 일
      if (i == 5) return t.fgBrand; // 토
      return t.fgSecondary;
    }

    return Column(
      children: [
        // 정적 요일 헤더 (월~일) — 실제 라벨 렌더, 스켈레톤화 안 함.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
          child: Row(
            children: [
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      dow[i],
                      style: PTypo.caption.copyWith(color: dowColor(i)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 6주 데이터 그리드 — _DayCell 레이아웃(상단 24px 날짜 + full-bleed 이벤트 바) 정합.
        Expanded(
          child: Column(
            children: [
              for (int w = 0; w < 6; w++)
                Expanded(
                  child: Row(
                    children: [
                      for (int d = 0; d < 7; d++)
                        Expanded(
                          child: Padding(
                            // _DayCell 바깥 vertical: x4 정합.
                            padding: const EdgeInsets.symmetric(
                              vertical: PSpace.x4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 날짜 숫자 자리 — 24×24 박스, 셀 중앙(_DayCell dayNumber).
                                const Center(
                                  child: PSkeleton(
                                    width: PSpace.x24,
                                    height: PSpace.x24,
                                    borderRadius: PRadius.brSm,
                                  ),
                                ),
                                const SizedBox(height: PSpace.x4),
                                // 일부 셀에만 이벤트 바 placeholder — _CellEventLabel 정합
                                // (full-bleed, 좌우 x4 inset, micro 높이 16, brSm).
                                if ((w + d) % 3 == 0)
                                  const Padding(
                                    padding: EdgeInsets.only(
                                      left: PSpace.x4,
                                      right: PSpace.x4,
                                      bottom: PSpace.x4,
                                    ),
                                    child: PSkeleton(
                                      height: 16,
                                      borderRadius: PRadius.brSm,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.events,
    required this.isOutside,
    required this.tokens,
    this.holidayName,
  });
  final DateTime day;
  final List<CalendarEvent> events;
  final bool isOutside;
  final GrooTokens tokens;
  final String? holidayName;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final today = DateTime.now();
    final isToday =
        today.year == day.year &&
        today.month == day.month &&
        today.day == day.day;
    final isHoliday = holidayName != null && !isOutside;

    final Color dayColor;
    if (isOutside) {
      // 이웃 달은 날짜 숫자만 fg-disabled — 그 칸의 일정 · 금액 · 휴일 이름은 이번 달과 같다(불투명도를 쓰지 않는다, 03-C 5A)
      dayColor = t.fgDisabled;
    } else if (isToday) {
      // 오늘 — web 정합: 항상 오늘에만 solid 원 (선택 날짜 표시는 하지 않음)
      dayColor = t.fgOnBrand;
    } else if (isHoliday || day.weekday == DateTime.sunday) {
      dayColor = t.statusDangerFg;
    } else if (day.weekday == DateTime.saturday) {
      dayColor = t.fgBrand;
    } else {
      dayColor = t.fgPrimary;
    }

    final dayNumber = Container(
      width: PSpace.x24,
      height: PSpace.x24,
      alignment: Alignment.center,
      // 오늘 원 — 가계부 월그리드 선택 원 정합(bgBrandSolid, 다크 primary 고정. 사용자 결정)
      decoration: (isToday && !isOutside)
          ? BoxDecoration(color: t.bgBrandSolid, shape: BoxShape.circle)
          : null,
      child: Text(
        '${day.day}',
        style: PTypo.bodySm.copyWith(
          color: dayColor,
          fontWeight: isToday ? PFontWeight.bold : PFontWeight.medium,
        ),
      ),
    );

    // 멀티데이 바 연속성: 멀티데이 이벤트를 (멀티 우선·시작·기간) 안정 정렬해 상단 lane 고정
    // → 인접 셀에서 같은 행에 위치(웹 eventPositions 정합의 경량 버전).
    final ordered = [...events]
      ..sort((a, b) {
        final am = _isMulti(a), bm = _isMulti(b);
        if (am != bm) return am ? -1 : 1;
        final c = a.start.compareTo(b.start);
        if (c != 0) return c;
        return b.end.difference(b.start).compareTo(a.end.difference(a.start));
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        const dayNumberArea = PSpace.x24 + PSpace.x4 + PSpace.x4 + PSpace.x4;
        const labelRowHeight = 18.0;
        final available = constraints.maxHeight - dayNumberArea;
        final totalSlots = available > 0
            ? (available / labelRowHeight).floor()
            : 0;
        final holidaySlot = isHoliday ? 1 : 0;
        final eventSlots = (totalSlots - holidaySlot).clamp(0, ordered.length);
        final reserveOverflow = ordered.length > eventSlots;
        final visibleCount = reserveOverflow && eventSlots > 0
            ? eventSlots - 1
            : eventSlots;
        final visible = ordered.take(visibleCount).toList();
        final overflow = ordered.length - visible.length;

        return Padding(
          // 멀티데이 바가 셀 가로 끝까지 이어지도록 세로 padding 만; 가로는 요소별 적용.
          padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 날짜 숫자는 요일 헤더(dowBuilder Center)와 같이 셀 정중앙에 선다.
              // 가계부 _TxmCalendar · 할일 _LedgerCalendar 도 셀 중앙이라, 이걸로
              // 세 캘린더가 같은 규칙을 쓴다.
              Center(child: dayNumber),
              const SizedBox(height: PSpace.x4),
              if (isHoliday)
                Padding(
                  padding: const EdgeInsets.only(
                    left: PSpace.x4,
                    right: PSpace.x4,
                    bottom: PSpace.x4,
                  ),
                  child: _CellHolidayLabel(name: holidayName!, tokens: t),
                ),
              for (final ev in visible)
                _CellEventLabel(
                  event: ev,
                  day: day,
                  position: _segPos(ev, day),
                  tokens: t,
                ),
              if (overflow > 0)
                Padding(
                  padding: const EdgeInsets.only(left: PSpace.x4),
                  child: Text(
                    '+$overflow',
                    style: PTypo.micro.copyWith(color: t.fgTertiary),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 이벤트가 한 날짜 셀에서 차지하는 멀티데이 바 위치 — 단일/시작/중간/종료.
enum _SegPos { none, first, middle, last }

/// 날짜만 비교해 멀티데이(2일 이상) 여부.
bool _isMulti(CalendarEvent e) {
  final sd = DateTime(e.start.year, e.start.month, e.start.day);
  final ed = DateTime(e.end.year, e.end.month, e.end.day);
  return ed.isAfter(sd);
}

/// [day] 에서 이벤트 [e] 의 세그먼트 위치.
_SegPos _segPos(CalendarEvent e, DateTime day) {
  final sd = DateTime(e.start.year, e.start.month, e.start.day);
  final ed = DateTime(e.end.year, e.end.month, e.end.day);
  if (!ed.isAfter(sd)) return _SegPos.none;
  final d = DateTime(day.year, day.month, day.day);
  if (d == sd) return _SegPos.first;
  if (d == ed) return _SegPos.last;
  return _SegPos.middle;
}

class _CellEventLabel extends StatelessWidget {
  const _CellEventLabel({
    required this.event,
    required this.day,
    required this.position,
    required this.tokens,
  });
  final CalendarEvent event;
  final DateTime day;
  final _SegPos position;
  final GrooTokens tokens;

  @override
  Widget build(BuildContext context) {
    final tone = eventTone(context, event);
    // 멀티데이 연속 바: 시작=좌측만 round, 종료=우측만 round, 중간=square + full-bleed
    // (인접 셀과 이어지도록 연결 변은 가로 inset 0). 제목은 시작(first)/단일(none) 만(웹 정합).
    // 색은 역할 색 chart-*-weak(바탕) · chart-*-contrast(글) — 섞어 만든 색이 아니다(I-09 5).
    // 이웃 달 셀의 일정도 이번 달과 같은 색이다(흐리게 하지 않는다).
    const r = Radius.circular(PRadius.sm);
    final radius = switch (position) {
      _SegPos.none => PRadius.brSm,
      _SegPos.first => const BorderRadius.horizontal(left: r),
      _SegPos.last => const BorderRadius.horizontal(right: r),
      _SegPos.middle => BorderRadius.zero,
    };
    // 단일 이벤트만 좌측 제목. 멀티데이는 아래 가운데 라벨이 맡는다 — 시작 조각에만
    // 두면 바의 나머지가 빈 띠로 남고, 주가 넘어가면 다음 주 바에는 제목이 아예
    // 없었다(사용자 결정: 연속 바는 제목을 가운데에, 웹 정합).
    final showText = position == _SegPos.none;
    final leftInset = position == _SegPos.none || position == _SegPos.first;
    final rightInset = position == _SegPos.none || position == _SegPos.last;

    // 이 셀이 "이 주(행)에서 바가 끝나는 칸" 인가 — 이벤트 마지막 날이거나 주의 끝(토).
    // 라벨은 행마다 한 번, 이 칸에서 왼쪽으로 넘치게 그린다. Flutter 는 z-index 가
    // 없어 나중에 그려지는(오른쪽) 칸이 위에 오므로, 시작 칸에서 오른쪽으로 뻗으면
    // 이웃 조각의 배경에 글자가 가려진다 — 끝 칸에서 왼쪽으로 뻗으면 안 가려진다.
    final d = DateTime(day.year, day.month, day.day);
    final isRowSegEnd =
        position != _SegPos.none &&
        (position == _SegPos.last || d.weekday == DateTime.saturday);
    // 이 행에서 바가 차지하는 칸 수 — 행 시작(일요일)과 이벤트 첫날 중 늦은 쪽부터.
    final int rowSegDays;
    if (isRowSegEnd) {
      final weekStart = d.subtract(Duration(days: d.weekday % 7));
      final sd = DateTime(event.start.year, event.start.month, event.start.day);
      final segStart = sd.isAfter(weekStart) ? sd : weekStart;
      rowSegDays = d.difference(segStart).inDays + 1;
    } else {
      rowSegDays = 0;
    }
    return Padding(
      padding: EdgeInsets.only(
        left: leftInset ? PSpace.x4 : 0.0,
        right: rightInset ? PSpace.x4 : 0.0,
        bottom: PSpace.x4, // 세로로 쌓인 이벤트 바 사이 간격(웹 gap-1 정합)
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x4,
          vertical: PSpace.x0,
        ),
        decoration: BoxDecoration(color: tone.weak, borderRadius: radius),
        child: isRowSegEnd
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  // 빈 텍스트가 바 높이를 잡는다 — 라벨은 그 위에 겹쳐 스팬으로 뻗는다.
                  Text(
                    '',
                    maxLines: 1,
                    style: PTypo.micro.copyWith(fontWeight: PFontWeight.semi),
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        // 칸 폭 균등 + 조각 사이 여백 0 — 칸 수 × 현재 폭으로 스팬을
                        // 근사한다(첫·끝 조각의 바깥 4px 만 오차, 가운데 정렬이라 안 보인다).
                        final spanW = c.maxWidth * rowSegDays;
                        return Align(
                          alignment: Alignment.centerRight,
                          child: OverflowBox(
                            alignment: Alignment.centerRight,
                            maxWidth: spanW,
                            child: SizedBox(
                              width: spanW,
                              child: Text(
                                event.title,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: PTypo.micro.copyWith(
                                  color: tone.contrast,
                                  fontWeight: PFontWeight.semi,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            : Text(
                showText ? event.title : '',
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: PTypo.micro.copyWith(
                  color: tone.contrast,
                  fontWeight: PFontWeight.semi,
                ),
              ),
      ),
    );
  }
}

class _CellHolidayLabel extends StatelessWidget {
  const _CellHolidayLabel({required this.name, required this.tokens});
  final String name;
  final GrooTokens tokens;

  @override
  Widget build(BuildContext context) {
    final tone = holidayTone(context);
    // 이벤트 칩과 같은 모양 · 색은 chart-red-weak / chart-red-contrast.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x4,
        vertical: PSpace.x0,
      ),
      decoration: BoxDecoration(color: tone.weak, borderRadius: PRadius.brSm),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: PTypo.micro.copyWith(
          color: tone.contrast,
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
    required this.holidays,
    required this.scrollController,
    required this.onAdd,
    required this.onTapEvent,
  });
  final DateTime day;
  final List<CalendarEvent> events;
  final List<Holiday> holidays;
  final ScrollController scrollController;
  final VoidCallback onAdd;
  final void Function(CalendarEvent) onTapEvent;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final total = holidays.length + events.length;
    return ListView(
      controller: scrollController,
      // 하단 — 플로팅 탭바 보상.
      padding: EdgeInsets.fromLTRB(
        PSpace.xl,
        PSpace.x24,
        PSpace.xl,
        bottomNavigationInset(context),
      ),
      children: [
        Row(
          children: [
            Text(
              l.calEventTotalCount(total),
              style: PTypo.bodySm.copyWith(color: t.fgTertiary),
            ),
            const Spacer(),
            PButton.icon(
              icon: LucideIcons.plus,
              iconColor: t.fgPrimary,
              tooltip: l.calEventAdd,
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: PSpace.x4),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpace.x32),
            child: Center(
              child: Text(
                l.calNoEventsThisDay,
                style: PTypo.bodySm.copyWith(color: t.fgTertiary),
              ),
            ),
          )
        else ...[
          // 공휴일(종일) 먼저 — 웹 상세 정합.
          for (int i = 0; i < holidays.length; i++) ...[
            _DaySheetHolidayRow(holiday: holidays[i], tokens: t),
            if (i < holidays.length - 1 || events.isNotEmpty) PDivider(),
          ],
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
      ],
    );
  }
}

// 공휴일 행 — 종일 + 빨강(fgExpense) 바 + 이름 (_DaySheetEventRow 스타일 정합).
class _DaySheetHolidayRow extends StatelessWidget {
  const _DaySheetHolidayRow({required this.holiday, required this.tokens});
  final Holiday holiday;
  final GrooTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: PSpace.x40,
            child: Text(
              l.calAllDay,
              style: PTypo.caption.copyWith(color: t.fgSecondary),
            ),
          ),
          const SizedBox(width: PSpace.x8),
          Container(
            width: PSpace.x4,
            height: PSpace.x24,
            decoration: BoxDecoration(
              color: t.statusDangerFg,
              borderRadius: PRadius.brXs,
            ),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Text(
              holiday.holidayName,
              style: PTypo.body.copyWith(
                color: t.fgPrimary,
                fontWeight: PFontWeight.semi,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
  final GrooTokens tokens;
  final VoidCallback onTap;

  String _hhmm(DateTime d) => timeOfDay12(d);

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    final color = eventTone(context, event).solid;
    final timeLabel = event.isAllDayBool ? l.calAllDay : _hhmm(event.start);
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
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
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
            Icon(
              LucideIcons.chevronRight,
              size: PSpace.x16,
              color: t.fgTertiary,
            ),
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
    final l = AppLocalizations.of(context);
    final selYear = widget.initial.year;
    final selMonth = widget.initial.month;

    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 연도 네비 — 화살표 drawer 양 끝
          Row(
            children: [
              PButton.icon(
                tooltip: AppLocalizations.of(context).actionPrev,
                icon: LucideIcons.chevronLeft,
                onPressed: () => setState(() => _year--),
              ),
              const Spacer(),
              Text(
                yearOnly(DateTime(_year)),
                style: PTypo.body.copyWith(fontWeight: PFontWeight.bold),
              ),
              const Spacer(),
              PButton.icon(
                tooltip: AppLocalizations.of(context).actionNext,
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
                    // 선택 월 박스 = 채움(흰 글씨) 버튼이므로 primary 고정 토큰.
                    // bgBrand 는 다크에서 primary-light 로 밝아져 웹(bg-primary)과 어긋남.
                    color: isSelected ? t.bgBrandSolid : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(
                    monthOnly(DateTime(_year, month)),
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
          // 푸터: 오늘로 + 닫기 — 화면 폭을 반씩 나눠 갖는다
          // (spec drawer.md "flex:1 평등 분배"). 가계부 월 선택(budget_screen)과 같은 배치.
          Row(
            children: [
              Expanded(
                child: PButton(
                  label: l.calGoToToday,
                  icon: LucideIcons.navigation,
                  variant: PButtonVariant.ghost,
                  fullWidth: true,
                  onPressed: widget.onToday,
                ),
              ),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: PButton(
                  label: l.actionClose,
                  variant: PButtonVariant.ghost,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
