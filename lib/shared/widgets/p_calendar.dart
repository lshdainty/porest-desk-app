import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';

/// specs/components/calendar.md 미러 (Flutter inline picker 적응).
///
/// 한글 locale 기반 single/range mode 캘린더. day cell 40×40 + 원형 fill,
/// 오늘은 outline 2px, 선택일은 brand fill, range middle은 옅은 brand tint.
///
/// react-day-picker spec을 Flutter 직접 그리기로 미러. Popover 안 또는 inline
/// 마운트 둘 다 가능.
enum PCalendarMode { single, range }

class PCalendar extends StatefulWidget {
  const PCalendar.single({
    super.key,
    required DateTime? selected,
    required ValueChanged<DateTime> onChanged,
    this.firstDay,
    this.lastDay,
    this.initialMonth,
  })  : mode = PCalendarMode.single,
        singleSelected = selected,
        rangeStart = null,
        rangeEnd = null,
        onSingleChanged = onChanged,
        onRangeChanged = null;

  const PCalendar.range({
    super.key,
    required DateTime? start,
    required DateTime? end,
    required ValueChanged<({DateTime start, DateTime? end})> onChanged,
    this.firstDay,
    this.lastDay,
    this.initialMonth,
  })  : mode = PCalendarMode.range,
        singleSelected = null,
        rangeStart = start,
        rangeEnd = end,
        onSingleChanged = null,
        onRangeChanged = onChanged;

  final PCalendarMode mode;
  final DateTime? singleSelected;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final ValueChanged<DateTime>? onSingleChanged;
  final ValueChanged<({DateTime start, DateTime? end})>? onRangeChanged;
  final DateTime? firstDay;
  final DateTime? lastDay;
  final DateTime? initialMonth;

  @override
  State<PCalendar> createState() => _PCalendarState();
}

class _PCalendarState extends State<PCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final init = widget.initialMonth ??
        widget.singleSelected ??
        widget.rangeStart ??
        DateTime.now();
    _month = DateTime(init.year, init.month);
  }

  void _prev() => setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _next() => setState(() => _month = DateTime(_month.year, _month.month + 1));

  /// select 로 고를 년도. 범위를 안 주면 보고 있는 월 기준 ±10년 — 화살표로는
  /// 못 갈 거리를 덮되 목록이 수백 줄로 늘어지지 않는 폭이다.
  List<int> get _years {
    final first = widget.firstDay?.year ?? _month.year - 10;
    final last = widget.lastDay?.year ?? _month.year + 10;
    // 보고 있는 월이 범위 밖이어도 select 값이 목록에 있어야 한다.
    final lo = first < _month.year ? first : _month.year;
    final hi = last > _month.year ? last : _month.year;
    return [for (int y = lo; y <= hi; y++) y];
  }

  /// 그 해에 실제로 갈 수 있는 월. 경계 년도면 앞뒤가 잘린다.
  List<int> get _months {
    var lo = 1, hi = 12;
    final f = widget.firstDay, l = widget.lastDay;
    if (f != null && _month.year == f.year) lo = f.month;
    if (l != null && _month.year == l.year) hi = l.month;
    if (_month.month < lo) lo = _month.month;
    if (_month.month > hi) hi = _month.month;
    return [for (int m = lo; m <= hi; m++) m];
  }

  void _jump({int? year, int? month}) {
    final y = year ?? _month.year;
    var m = month ?? _month.month;
    // 년도를 옮기면 그 해엔 없는 달일 수 있다(경계 년도) — 가장 가까운 달로 접는다.
    final f = widget.firstDay, l = widget.lastDay;
    if (f != null && y == f.year && m < f.month) m = f.month;
    if (l != null && y == l.year && m > l.month) m = l.month;
    setState(() => _month = DateTime(y, m));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime d) {
    if (widget.rangeStart == null || widget.rangeEnd == null) return false;
    final start = widget.rangeStart!;
    final end = widget.rangeEnd!;
    return d.isAfter(start.subtract(const Duration(days: 1))) &&
        d.isBefore(end.add(const Duration(days: 1)));
  }

  bool _disabled(DateTime d) {
    if (widget.firstDay != null &&
        d.isBefore(DateTime(widget.firstDay!.year, widget.firstDay!.month,
            widget.firstDay!.day))) {
      return true;
    }
    if (widget.lastDay != null &&
        d.isAfter(DateTime(widget.lastDay!.year, widget.lastDay!.month,
            widget.lastDay!.day))) {
      return true;
    }
    return false;
  }

  void _onTap(DateTime d) {
    if (_disabled(d)) return;
    if (widget.mode == PCalendarMode.single) {
      widget.onSingleChanged?.call(d);
      return;
    }
    // range: 시작/끝 cycle
    if (widget.rangeStart == null ||
        (widget.rangeStart != null && widget.rangeEnd != null)) {
      widget.onRangeChanged?.call((start: d, end: null));
    } else {
      final start = widget.rangeStart!;
      if (d.isBefore(start)) {
        widget.onRangeChanged?.call((start: d, end: null));
      } else {
        widget.onRangeChanged?.call((start: start, end: d));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final now = DateTime.now();
    final weekdays = weekdayLabels();

    // grid 시작: 해당 월 1일이 속한 주의 일요일.
    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final startOffset = firstOfMonth.weekday % 7; // 일=0
    final gridStart = firstOfMonth.subtract(Duration(days: startOffset));

    return Padding(
      padding: const EdgeInsets.all(PSpace.x12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더: prev · [년][월] · next — 큰 단위가 앞이다.
          //
          // 화살표만 두면 몇 년 전으로 가는 데 수십 번을 눌러야 한다. select 로
          // 바로 집게 하고, 화살표는 인접 월 이동용으로 남긴다.
          Row(
            children: [
              _NavBtn(icon: LucideIcons.chevronLeft, onTap: _prev),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 110,
                        child: PSelect<int>(
                          value: _month.year,
                          items: [
                            for (final y in _years)
                              PSelectItem(
                                  value: y, label: yearOnly(DateTime(y))),
                          ],
                          onChanged: (y) => _jump(year: y),
                        ),
                      ),
                      const SizedBox(width: PSpace.x8),
                      SizedBox(
                        width: 96,
                        child: PSelect<int>(
                          value: _month.month,
                          items: [
                            for (final m in _months)
                              PSelectItem(
                                value: m,
                                label: monthOnly(DateTime(_month.year, m)),
                              ),
                          ],
                          onChanged: (m) => _jump(month: m),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _NavBtn(icon: LucideIcons.chevronRight, onTap: _next),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          // 요일 header
          Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: Center(
                      child: Text(
                        w,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.caption,
                          fontWeight: PFontWeight.semi,
                          color: t.fgTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // 6주 × 7일
          for (int week = 0; week < 6; week++)
            Padding(
              padding: const EdgeInsets.only(top: PSpace.x4),
              child: Row(
                children: [
                  for (int dow = 0; dow < 7; dow++)
                    Expanded(
                      child: _DayCell(
                        date: gridStart.add(Duration(days: week * 7 + dow)),
                        month: _month,
                        isToday: _sameDay(
                            gridStart.add(Duration(days: week * 7 + dow)), now),
                        isSelected: _isSelected(
                            gridStart.add(Duration(days: week * 7 + dow))),
                        rangePosition: _rangePosition(
                            gridStart.add(Duration(days: week * 7 + dow))),
                        disabled: _disabled(
                            gridStart.add(Duration(days: week * 7 + dow))),
                        onTap: () => _onTap(
                            gridStart.add(Duration(days: week * 7 + dow))),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _isSelected(DateTime d) {
    if (widget.mode == PCalendarMode.single) {
      return widget.singleSelected != null && _sameDay(widget.singleSelected!, d);
    }
    return (widget.rangeStart != null && _sameDay(widget.rangeStart!, d)) ||
        (widget.rangeEnd != null && _sameDay(widget.rangeEnd!, d));
  }

  _RangePosition _rangePosition(DateTime d) {
    if (widget.mode != PCalendarMode.range) return _RangePosition.none;
    if (widget.rangeStart != null && _sameDay(widget.rangeStart!, d)) {
      return _RangePosition.start;
    }
    if (widget.rangeEnd != null && _sameDay(widget.rangeEnd!, d)) {
      return _RangePosition.end;
    }
    if (_inRange(d)) return _RangePosition.middle;
    return _RangePosition.none;
  }
}

enum _RangePosition { none, start, middle, end }

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.month,
    required this.isToday,
    required this.isSelected,
    required this.rangePosition,
    required this.disabled,
    required this.onTap,
  });
  final DateTime date;
  final DateTime month;
  final bool isToday;
  final bool isSelected;
  final _RangePosition rangePosition;
  final bool disabled;
  final VoidCallback onTap;

  bool get _outside => date.month != month.month;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    // cell-level 시각 (range middle/start/end).
    Color cellBg = Colors.transparent;
    BorderRadius cellRadius = BorderRadius.zero;
    if (rangePosition == _RangePosition.middle) {
      cellBg = t.bgBrandSubtle;
    } else if (rangePosition == _RangePosition.start ||
        rangePosition == _RangePosition.end) {
      cellBg = t.bgBrandSubtle;
      cellRadius = rangePosition == _RangePosition.start
          ? const BorderRadius.only(
              topLeft: Radius.circular(999), bottomLeft: Radius.circular(999))
          : const BorderRadius.only(
              topRight: Radius.circular(999), bottomRight: Radius.circular(999));
    }

    // button-level 시각 (selected = primary 원, today = outline only).
    Color btnBg = Colors.transparent;
    Color textColor = _outside ? t.fgTertiary : t.fgPrimary;
    BoxBorder? btnBorder;
    FontWeight weight = PFontWeight.regular;

    if (isSelected) {
      btnBg = t.bgBrand;
      textColor = t.fgOnBrand;
      weight = PFontWeight.semi;
    } else if (isToday) {
      btnBorder = Border.all(color: t.borderBrand, width: 2);
      weight = PFontWeight.semi;
    }

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: cellBg, borderRadius: cellRadius),
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: disabled ? null : onTap,
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: PMotion.fast,
                  curve: PMotion.standard,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: btnBg,
                    shape: BoxShape.circle,
                    border: btnBorder,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: PFontSize.bodyMd,
                      fontWeight: weight,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: PRadius.brSm,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: PRadius.brSm,
              border: Border.all(color: t.borderDefault),
            ),
            child: Icon(icon, size: 16, color: t.fgSecondary),
          ),
        ),
      ),
    );
  }
}
