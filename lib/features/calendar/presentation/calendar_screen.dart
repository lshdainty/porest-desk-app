import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../application/calendar_providers.dart';
import '../domain/calendar_event.dart';
import '../domain/holiday.dart';
import '../domain/user_calendar.dart';
import 'calendar_event_dialog.dart';

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
        .map((c) => solidSwatchColor(context, c.color, fallback: t.fgBrand))
        .toList();

    final lastDay = DateTime(_key.year, _key.month + 1, 0).day;
    final hStart = '${_key.year.toString().padLeft(4, '0')}-${_key.month.toString().padLeft(2, '0')}-01';
    final hEnd = '${_key.year.toString().padLeft(4, '0')}-${_key.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
    final holidaysAsync = ref.watch(holidayListProvider((startDate: hStart, endDate: hEnd)));
    final holidayVisible = ref.watch(holidayVisibleProvider);
    // 기타 소스 > 공휴일 토글 off 면 빈 맵 → 달력에 공휴일 라벨/색 미표시.
    final holidayMap = holidayVisible
        ? <String, String>{
            for (final h in (holidaysAsync.value ?? const <Holiday>[]))
              h.holidayDate: h.holidayName,
          }
        : const <String, String>{};

    // 첫 로딩(이벤트/캘린더 아직 없음) — 웹 CalendarMonthViewSkeleton 정합.
    final firstLoading = (eventsAsync.isLoading && !eventsAsync.hasValue) ||
        (calendarsAsync.isLoading && !calendarsAsync.hasValue);

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
        if (firstLoading)
          Expanded(child: _CalendarGridSkeleton(tokens: t))
        else
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
                  color = t.fgExpense;
                } else if (day.weekday == DateTime.saturday) {
                  color = t.fgBrand;
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
                  isOutside: false,
                  holidayName: holidayMap[_dateKey(day)],
                  tokens: t),
              todayBuilder: (ctx, day, _) => _DayCell(
                  day: day,
                  events: _eventsOnDay(events, day),
                  isOutside: false,
                  holidayName: holidayMap[_dateKey(day)],
                  tokens: t),
              selectedBuilder: (ctx, day, _) => _DayCell(
                  day: day,
                  events: _eventsOnDay(events, day),
                  isOutside: false,
                  holidayName: holidayMap[_dateKey(day)],
                  tokens: t),
              outsideBuilder: (ctx, day, _) => _DayCell(
                  day: day,
                  events: _eventsOnDay(events, day),
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
      shrinkWrap: true, // 컨텐츠 높이에 맞춤(아래 빈 공간 제거)
      contentBuilder: (ctx, _) => _CalendarFilterSheetBody(
        onManage: () {
          Navigator.of(context).pop();
          context.push('/settings/calendar-share');
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
                    '$calendarCount개',
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
    required this.onManage,
  });
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final async = ref.watch(userCalendarListProvider);
    final calendars = async.value ?? const <UserCalendar>[];
    final holidayVisible = ref.watch(holidayVisibleProvider);

    Widget sectionLabel(String text) => Padding(
          padding: const EdgeInsets.only(top: PSpace.x8, bottom: PSpace.x8),
          child: Text(
            text,
            style: PTypo.caption.copyWith(
              color: t.fgTertiary,
              fontWeight: PFontWeight.semi,
              letterSpacing: 0.3,
            ),
          ),
        );

    // 컨텐츠 높이에 맞춰 wrap (showPSheet shrinkWrap 모드) → Column 사용.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x20, PSpace.x4, PSpace.x20, PSpace.x24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 내 캘린더 섹션
          sectionLabel('내 캘린더'),
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
              _FilterRow(
                colorHex: cal.color,
                name: cal.calendarName,
                checked: cal.isVisible,
                onToggle: () async {
                  try {
                    final repo =
                        await ref.read(userCalendarRepositoryProvider.future);
                    await repo.toggleVisibility(cal.rowId);
                    ref.invalidate(userCalendarListProvider);
                  } catch (_) {
                    if (context.mounted) {
                      showPSnackBar(context, '변경 실패',
                          severity: PSnackSeverity.error);
                    }
                  }
                },
                tokens: t,
              ),
          const SizedBox(height: PSpace.x8),
          PDivider(),
          // 기타 소스 섹션 — 공휴일 on/off (웹 정합)
          sectionLabel('기타 소스'),
          _FilterRow(
            colorHex: '#c73838',
            name: '공휴일',
            checked: holidayVisible,
            onToggle: () =>
                ref.read(holidayVisibleProvider.notifier).toggle(),
            tokens: t,
          ),
          const SizedBox(height: PSpace.x8),
          PDivider(),
          // 관리 버튼
          InkWell(
            onTap: onManage,
            borderRadius: PRadius.brMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
              child: Row(
                children: [
                  Icon(LucideIcons.settings2, size: 15, color: t.fgBrand),
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
      ),
    );
  }
}

/// 캘린더/기타소스 공용 필터 행 — 체크박스(색 채움) + 색 점 + 이름. 웹 정합.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.colorHex,
    required this.name,
    required this.checked,
    required this.onToggle,
    required this.tokens,
  });
  final String? colorHex;
  final String name;
  final bool checked;
  final VoidCallback onToggle;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final color = solidSwatchColor(context, colorHex, fallback: t.fgBrand);
    // light fill(다크모드 light variant) 위에서도 체크가 보이도록 fill 명도 기준 대비 색.
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : const Color(0xFF1A1F2E);
    return InkWell(
      onTap: onToggle,
      borderRadius: PRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
        child: Row(
          children: [
            // 체크박스 (checked 상태)
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? color : Colors.transparent,
                border: Border.all(
                  color: checked ? color : t.borderSubtle,
                  width: 1.5,
                ),
                borderRadius: PRadius.brSm,
              ),
              child: checked
                  ? Icon(LucideIcons.check, size: 13, color: checkColor)
                  : null,
            ),
            const SizedBox(width: PSpace.x12),
            // 색 점 (웹 정합)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: PSpace.x8),
            // 이름
            Expanded(
              child: Text(
                name,
                style: PTypo.body.copyWith(
                  color: checked ? t.fgPrimary : t.fgTertiary,
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

/// 캘린더 첫 로딩 skeleton — 정적 요일 헤더(실제 라벨) + 6주 × 7일 데이터 그리드.
///
/// 요일 헤더는 서버 무관 정적 틀이라 스켈레톤화하지 않고 실제 텍스트 렌더(TableCalendar
/// dowBuilder 정합). 셀 내부 날짜 숫자(24px 박스 좌측 정렬)와 이벤트 바(full-bleed,
/// micro 높이, brSm)만 데이터 placeholder 로 그려 로딩-후 _DayCell 과 1:1 정합.
class _CalendarGridSkeleton extends StatelessWidget {
  const _CalendarGridSkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    // 월~일 — TableCalendar daysOfWeekStyle/dowBuilder 정합(주말 색 포함, 실제 텍스트).
    const dow = ['월', '화', '수', '목', '금', '토', '일'];
    Color dowColor(int i) {
      if (i == 6) return t.fgExpense; // 일
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
                                vertical: PSpace.x4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 날짜 숫자 자리 — 24×24 박스, 좌측 x4 정렬(_DayCell dayNumber).
                                const Padding(
                                  padding: EdgeInsets.only(left: PSpace.x4),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: PSkeleton(
                                      width: PSpace.x24,
                                      height: PSpace.x24,
                                      borderRadius: PRadius.brSm,
                                    ),
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
                                        bottom: PSpace.x4),
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
  final PorestTokens tokens;
  final String? holidayName;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final today = DateTime.now();
    final isToday = today.year == day.year &&
        today.month == day.month &&
        today.day == day.day;
    final isHoliday = holidayName != null && !isOutside;

    final Color dayColor;
    if (isOutside) {
      dayColor = t.fgTertiary.withValues(alpha: 0.4);
    } else if (isToday) {
      // 오늘 — web 정합: 항상 오늘에만 solid 원 (선택 날짜 표시는 하지 않음)
      dayColor = t.fgOnBrand;
    } else if (isHoliday || day.weekday == DateTime.sunday) {
      dayColor = t.fgExpense;
    } else if (day.weekday == DateTime.saturday) {
      dayColor = t.fgBrand;
    } else {
      dayColor = t.fgPrimary;
    }

    final dayNumber = Container(
      width: PSpace.x24,
      height: PSpace.x24,
      alignment: Alignment.center,
      // web 오늘 셀 정합 — bg-[var(--fg-brand)] solid 원 (다크 primary-light 자동)
      decoration: (isToday && !isOutside)
          ? BoxDecoration(color: t.fgBrand, shape: BoxShape.circle)
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
        final totalSlots = available > 0 ? (available / labelRowHeight).floor() : 0;
        final holidaySlot = isHoliday ? 1 : 0;
        final eventSlots = (totalSlots - holidaySlot).clamp(0, ordered.length);
        final reserveOverflow = ordered.length > eventSlots;
        final visibleCount =
            reserveOverflow && eventSlots > 0 ? eventSlots - 1 : eventSlots;
        final visible = ordered.take(visibleCount).toList();
        final overflow = ordered.length - visible.length;

        return Padding(
          // 멀티데이 바가 셀 가로 끝까지 이어지도록 세로 padding 만; 가로는 요소별 적용.
          padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: PSpace.x4),
                child: Align(alignment: Alignment.centerLeft, child: dayNumber),
              ),
              const SizedBox(height: PSpace.x4),
              if (isHoliday)
                Padding(
                  padding: const EdgeInsets.only(
                      left: PSpace.x4, right: PSpace.x4, bottom: PSpace.x4),
                  child: _CellHolidayLabel(
                      name: holidayName!, dimmed: isOutside, tokens: t),
                ),
              for (final ev in visible)
                _CellEventLabel(
                  event: ev,
                  position: _segPos(ev, day),
                  dimmed: isOutside,
                  tokens: t,
                ),
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
    required this.position,
    required this.dimmed,
    required this.tokens,
  });
  final CalendarEvent event;
  final _SegPos position;
  final bool dimmed;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final base = solidSwatchColor(
        context, event.labelColor ?? event.calendarColor ?? event.color,
        fallback: tokens.fgBrand);
    // 멀티데이 연속 바: 시작=좌측만 round, 종료=우측만 round, 중간=square + full-bleed
    // (인접 셀과 이어지도록 연결 변은 가로 inset 0). 제목은 시작(first)/단일(none) 만(웹 정합).
    // 색은 dark-aware(solidSwatchColor: 체크박스와 동일 base) + 불투명(chipFill/chipText).
    // 이월 셀은 Opacity. 웹은 동일하게 getPaletteByColor 한 함수로 통일.
    const r = Radius.circular(PRadius.sm);
    final radius = switch (position) {
      _SegPos.none => PRadius.brSm,
      _SegPos.first => const BorderRadius.horizontal(left: r),
      _SegPos.last => const BorderRadius.horizontal(right: r),
      _SegPos.middle => BorderRadius.zero,
    };
    final showText = position == _SegPos.none || position == _SegPos.first;
    final leftInset = position == _SegPos.none || position == _SegPos.first;
    final rightInset = position == _SegPos.none || position == _SegPos.last;
    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: Padding(
        padding: EdgeInsets.only(
          left: leftInset ? PSpace.x4 : 0.0,
          right: rightInset ? PSpace.x4 : 0.0,
          bottom: PSpace.x4, // 세로로 쌓인 이벤트 바 사이 간격(웹 gap-1 정합)
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x4, vertical: PSpace.x0),
          decoration: BoxDecoration(
            color: chipFill(context, base),
            borderRadius: radius,
          ),
          child: Text(
            showText ? event.title : '',
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
            style: PTypo.micro.copyWith(
              color: chipText(context, base),
              fontWeight: PFontWeight.semi,
            ),
          ),
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
    final base = tokens.statusDanger;
    // 이벤트 칩과 동일 톤: 불투명 bg + 적응형 텍스트 · border 없음 · radius-sm.
    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x4, vertical: PSpace.x0),
        decoration: BoxDecoration(
          color: chipFill(context, base),
          borderRadius: PRadius.brSm,
        ),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.clip,
          softWrap: false,
          style: PTypo.micro.copyWith(
            color: chipText(context, base),
            fontWeight: PFontWeight.semi,
          ),
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
        solidSwatchColor(context, event.labelColor ?? event.calendarColor ?? event.color, fallback: t.fgBrand);
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
