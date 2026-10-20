import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/ds/time_picker/time_picker_demo.dart';

// 견본의 오늘 — 2026년 10월 15일(목). 날짜가 고정이라 어느 날 열어도 같은 그림이다.
final _today = DateTime(2026, 10, 15);
final _labels = PDatePickerLabels.ko;

const _presets = [
  PDatePreset.thisWeek,
  PDatePreset.thisMonth,
  PDatePreset.lastMonth,
  PDatePreset.last3Months,
  PDatePreset.thisYear,
];

/// 하루를 고르는 시트 — 고르는 동안 칸 값은 그대로이고 "완료" 로 넣는다(하루를 고르기 전에는 막힌다). 바깥 · 끌어내리기로
/// 닫으면 버린다(null). 열 때는 칸의 값에서 시작한다 — 비었으면 오늘이 든 달을 열고 오늘을 짚기만 한다.
Future<DateTime?> showDatePickerSheet(
  BuildContext context, {
  DateTime? current,
  DateTime? min,
  DateTime? max,
  String title = '날짜 선택',
  DateTime? today,
}) {
  return PBottomSheet.show<DateTime>(
    context,
    builder: (_) {
      DateTime? draft = current;
      return StatefulBuilder(
        builder: (context, setState) => PBottomSheetContent(
          title: title,
          closeLabel: '닫기',
          flushBody: true,
          body: PDatePicker.single(
            labels: _labels,
            semanticLabel: title,
            value: draft,
            min: min,
            max: max,
            today: today ?? _today,
            onChanged: (v) => setState(() => draft = v),
          ),
          footer: [
            PButton(
              label: '완료',
              size: PButtonSize.large,
              onPressed: draft == null
                  ? null
                  : () => PBottomSheet.of(context).close(draft),
            ),
          ],
        ),
      );
    },
  );
}

/// 기간을 고르는 시트 — 달이 위아래로 이어지고(스크롤) 위에 빠른 기간 칩 줄이 있다. 바닥은 "초기화" + "완료"(끝을 고르기 전에는
/// "완료" 가 막힌다).
Future<PDateRange?> showRangePickerSheet(
  BuildContext context, {
  PDateRange? current,
  DateTime? min,
  DateTime? max,
  String title = '기간 선택',
  DateTime? today,
}) {
  return PBottomSheet.show<PDateRange>(
    context,
    builder: (_) {
      PDateRange? draft = current;
      return StatefulBuilder(
        builder: (context, setState) => PBottomSheetContent(
          title: title,
          closeLabel: '닫기',
          flushBody: true,
          body: SizedBox(
            height: PDatePicker.sheetBodyHeight(context),
            child: PDatePicker.range(
              labels: _labels,
              semanticLabel: title,
              visibleRange: PDateVisibleRange.continuous,
              presets: _presets,
              value: draft,
              min: min,
              max: max,
              today: today ?? _today,
              onChanged: (v) => setState(() => draft = v),
            ),
          ),
          footer: [
            PButton(
              label: '초기화',
              size: PButtonSize.large,
              variant: PButtonVariant.neutralWeak,
              onPressed: () => setState(() => draft = null),
            ),
            PButton(
              label: '완료',
              size: PButtonSize.large,
              onPressed: draft?.end == null
                  ? null
                  : () => PBottomSheet.of(context).close(draft),
            ),
          ],
        ),
      );
    },
  );
}

/// 상태 한 줄 — 한 주의 가운데 칸들을 나란히 그린다(기간 사이 날은 이웃이 시작 · 끝이라 띠가 이어진다).
class _Strip extends StatelessWidget {
  const _Strip({required this.label, required this.cells});

  final String label;
  final List<(int day, PDatePickerDayState state)> cells;

  @override
  Widget build(BuildContext context) {
    return DemoRow(
      label: label,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (day, state) in cells)
              PDatePickerDayCell(
                date: DateTime(2026, 10, day),
                state: state,
                label: _labels.day(DateTime(2026, 10, day)),
                width: 48,
                onTap: () {},
              ),
          ],
        ),
      ],
    );
  }
}

/// 카탈로그(/dev/ds) — 날짜 칸 상태 · 겹칠 때, 달력(하루 · 기간 · 여러 날 × 한 달 · 이어지는 달), 가장 나쁜 값(윤년 · 6주 달 · 막힌 날이
/// 걸친 기간 · 연말에 걸친 기간 · 최소 / 최대 범위 · 좁은 폭), 직접 눌러 보는 시트, 날짜 + 시각. 웹 `date-picker.demo.tsx` 와 같은
/// 구성이다 — 두 달 나란히(1280 이상 팝오버)는 앱에 없다.
class DatePickerDemo extends StatelessWidget {
  const DatePickerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const none = PDatePickerDayState();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title:
              '날짜 칸 상태 — 칸 48 · 원 42. 누름은 직접 눌러 본다(원이 눌림 색이 된다 — 오늘 · 기간 사이 날은 한 단계 짙게)',
          children: [
            _Strip(
              label: '보통 · 오늘 · 고름 · 막힘 · 읽기 전용',
              cells: const [
                (13, none),
                (15, PDatePickerDayState(today: true)),
                (16, PDatePickerDayState(selected: true)),
                (17, PDatePickerDayState(disabled: true)),
                (
                  18,
                  PDatePickerDayState(
                    selected: true,
                    rangeStart: true,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            _Strip(
              label: '기간 — 시작 · 사이 · 끝(띠가 이어진다)',
              cells: const [
                (
                  13,
                  PDatePickerDayState(
                    selected: true,
                    rangeStart: true,
                    complete: true,
                  ),
                ),
                (14, PDatePickerDayState(inRange: true, complete: true)),
                (
                  15,
                  PDatePickerDayState(
                    inRange: true,
                    today: true,
                    complete: true,
                  ),
                ),
                (
                  16,
                  PDatePickerDayState(
                    selected: true,
                    rangeEnd: true,
                    complete: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '상태가 겹칠 때 — 고름이 이긴다 · 오늘의 굵기는 남는다 · 막힌 날이 기간 안이면 띠는 그대로 · 미완성 기간의 막힌 시작에는 취소선이 없다',
          children: [
            _Strip(
              label: '오늘을 고름 · 오늘인데 막힘 · 고른 날인데 막힘',
              cells: const [
                (15, PDatePickerDayState(today: true, selected: true)),
                (16, PDatePickerDayState(today: true, disabled: true)),
                (17, PDatePickerDayState(selected: true, disabled: true)),
              ],
            ),
            _Strip(
              label: '기간 사이 막힌 날 · 미완성 기간의 막힌 시작',
              cells: const [
                (
                  13,
                  PDatePickerDayState(
                    selected: true,
                    rangeStart: true,
                    complete: true,
                  ),
                ),
                (
                  14,
                  PDatePickerDayState(
                    inRange: true,
                    disabled: true,
                    complete: true,
                  ),
                ),
                (
                  15,
                  PDatePickerDayState(
                    selected: true,
                    rangeEnd: true,
                    complete: true,
                  ),
                ),
                (
                  18,
                  PDatePickerDayState(
                    selected: true,
                    rangeStart: true,
                    disabled: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '달력 — 하루 · 여러 날 · 기간 × 한 달 · 이어지는 달. 늘 6주(앞뒤 달은 흐리게 · 누르지 못함), 오늘 15일은 옅은 원 + 굵게',
          children: [
            DemoRow(
              label: 'single · month — 10월 20일',
              children: [
                SizedBox(
                  width: 312,
                  child: PDatePicker.single(
                    labels: _labels,
                    semanticLabel: '하루',
                    inset: 0,
                    value: DateTime(2026, 10, 20),
                    today: _today,
                  ),
                ),
              ],
            ),
            DemoRow(
              label: 'range · month — 10월 8일 ~ 10월 22일',
              children: [
                SizedBox(
                  width: 312,
                  child: PDatePicker.range(
                    labels: _labels,
                    semanticLabel: '기간',
                    inset: 0,
                    value: PDateRange(
                      start: DateTime(2026, 10, 8),
                      end: DateTime(2026, 10, 22),
                    ),
                    today: _today,
                  ),
                ),
              ],
            ),
            DemoRow(
              label: 'multiple · month — 10월 7 · 14 · 21일(최대 3개라 나머지는 막힌 날)',
              children: [
                SizedBox(
                  width: 312,
                  child: PDatePicker.multiple(
                    labels: _labels,
                    semanticLabel: '여러 날',
                    inset: 0,
                    value: [
                      DateTime(2026, 10, 7),
                      DateTime(2026, 10, 14),
                      DateTime(2026, 10, 21),
                    ],
                    maxSelectionCount: 3,
                    today: _today,
                  ),
                ),
              ],
            ),
            DemoRow(
              label: 'range · continuous — 빠른 기간 칩 줄 + 이어지는 달(스크롤)',
              children: [
                SizedBox(
                  width: 312,
                  height: 520,
                  child: PDatePicker.range(
                    labels: _labels,
                    semanticLabel: '통계 기간',
                    inset: 0,
                    visibleRange: PDateVisibleRange.continuous,
                    presets: _presets,
                    value: PDateRange(
                      start: DateTime(2026, 10, 1),
                      end: DateTime(2026, 10, 31),
                    ),
                    today: _today,
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '연 · 월 휠이 열린 달력 — 제목을 누르면 열린다',
              children: [
                SizedBox(
                  width: 312,
                  child: PDatePicker.single(
                    labels: _labels,
                    semanticLabel: '연 · 월',
                    inset: 0,
                    defaultWheelOpen: true,
                    value: DateTime(2026, 10, 20),
                    today: _today,
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '가장 나쁜 값 — 윤년 2월 29일 · 6주 달 · 막힌 날이 걸친 기간 · 연말에 걸친 기간 · 최소 / 최대 범위 · 좁은 폭(320 화면)',
          children: [
            DemoRow(
              label: '윤년 2028년 2월 29일',
              children: [
                SizedBox(
                  width: 312,
                  child: PDatePicker.single(
                    labels: _labels,
                    semanticLabel: '윤년',
                    inset: 0,
                    value: DateTime(2028, 2, 29),
                    today: _today,
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '6주 달 — 2026년 8월(토요일에 시작하는 31일)',
              children: [
                SizedBox(
                  width: 312,
                  child: PDatePicker.single(
                    labels: _labels,
                    semanticLabel: '6주 달',
                    inset: 0,
                    value: DateTime(2026, 8, 31),
                    today: _today,
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '연말에 걸친 기간 — 12월 28일 ~ 1월 3일(12월 달력에서는 31일까지 띠)',
              children: [
                SizedBox(
                  width: 312,
                  child: PDatePicker.range(
                    labels: _labels,
                    semanticLabel: '연말 기간',
                    inset: 0,
                    value: PDateRange(
                      start: DateTime(2026, 12, 28),
                      end: DateTime(2027, 1, 3),
                    ),
                    today: _today,
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '최소 / 최대 범위 — 거래일(10월 10일) ~ 오늘(15일)만, 환불일',
              children: [
                SizedBox(
                  width: 312,
                  child: PDatePicker.single(
                    labels: _labels,
                    semanticLabel: '환불일',
                    inset: 0,
                    value: DateTime(2026, 10, 12),
                    min: DateTime(2026, 10, 10),
                    max: _today,
                    today: _today,
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '막힌 날이 걸친 기간 — 주말은 막힌 날, 띠는 그대로',
              children: [
                SizedBox(
                  width: 312,
                  child: PDatePicker.range(
                    labels: _labels,
                    semanticLabel: '평일 기간',
                    inset: 0,
                    isDateDisabled: (d) =>
                        d.weekday == DateTime.saturday ||
                        d.weekday == DateTime.sunday,
                    value: PDateRange(
                      start: DateTime(2026, 10, 5),
                      end: DateTime(2026, 10, 16),
                    ),
                    today: _today,
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '320 화면 — 달력 폭 272, 칸 38.9 라 원을 칸 폭 − 2 로 줄인다',
              children: [
                SizedBox(
                  width: 272,
                  child: PDatePicker.range(
                    labels: _labels,
                    semanticLabel: '좁은 폭',
                    inset: 0,
                    value: PDateRange(
                      start: DateTime(2026, 10, 8),
                      end: DateTime(2026, 10, 22),
                    ),
                    today: _today,
                  ),
                ),
              ],
            ),
          ],
        ),
        const DemoBlock(
          title:
              '직접 눌러 본다 — 시트가 열린다. 고르는 동안 칸은 그대로이고 "완료" 로 넣는다 · 기간은 끝을 고르기 전까지 "완료" 가 막힌다 · 날짜를 치는 칸은 없다',
          children: [_TryDate(), _TryRange()],
        ),
        const DemoBlock(
          title:
              '날짜 + 시각 — 두 칸 나란히. 다른 해 날짜(2027년 1월 3일 (일))는 좁은 폭에서 시각 칸이 다음 줄로 내려간다 · 칸 글은 자르지 않는다',
          children: [_TryDateTime()],
        ),
      ],
    );
  }
}

class _TryDate extends StatefulWidget {
  const _TryDate();

  @override
  State<_TryDate> createState() => _TryDateState();
}

class _TryDateState extends State<_TryDate> {
  DateTime? _date;
  bool _open = false;

  Future<void> _openSheet() async {
    setState(() => _open = true);
    final result = await showDatePickerSheet(context, current: _date);
    if (!mounted) return;
    setState(() {
      _open = false;
      if (result != null) _date = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PField(
      label: '일정 날짜',
      child: PInputButton(
        placeholder: '날짜 선택',
        value: _date == null ? null : formatDateValue(_date, _today),
        suffixIcon: LucideIcons.calendarDays,
        expanded: _open,
        onPressed: _openSheet,
      ),
    );
  }
}

class _TryRange extends StatefulWidget {
  const _TryRange();

  @override
  State<_TryRange> createState() => _TryRangeState();
}

class _TryRangeState extends State<_TryRange> {
  PDateRange? _range;
  bool _open = false;

  Future<void> _openSheet() async {
    setState(() => _open = true);
    final result = await showRangePickerSheet(context, current: _range);
    if (!mounted) return;
    setState(() {
      _open = false;
      if (result != null) _range = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = formatRangeValue(_range, _today);
    return PField(
      label: '통계 기간',
      child: PInputButton(
        placeholder: '기간 선택',
        value: text.isEmpty ? null : text,
        suffixIcon: LucideIcons.calendarDays,
        expanded: _open,
        onPressed: _openSheet,
      ),
    );
  }
}

/// 날짜 칸 + 시각 칸 — 날짜 칸은 글이 다 들어가는 폭 이상, 시각 칸은 144. 한 줄에 둘이 들어가지 않으면 시각 칸이 다음 줄로
/// 내려간다.
class _TryDateTime extends StatefulWidget {
  const _TryDateTime();

  @override
  State<_TryDateTime> createState() => _TryDateTimeState();
}

class _TryDateTimeState extends State<_TryDateTime> {
  DateTime? _date = DateTime(2027, 1, 3);
  PTimeValue? _time = const PTimeValue(15, 30);

  Future<void> _openDate() async {
    final result = await showDatePickerSheet(
      context,
      current: _date,
      title: '거래 날짜',
    );
    if (!mounted) return;
    if (result != null) setState(() => _date = result);
  }

  Future<void> _openTime() async {
    final result = await showTimePickerSheet(
      context,
      current: _time,
      title: '거래 시각',
    );
    if (!mounted) return;
    if (result != null) setState(() => _time = result);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dateText = formatDateValue(_date, _today);
        final painter = TextPainter(
          text: TextSpan(
            text: dateText.isEmpty ? '날짜 선택' : dateText,
            style: PTypography.t5,
          ),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        // 좌우 16 · 아이콘 20 · 사이 10 + 글
        final need = painter.width + PSpacing.x4 * 2 + 20 + PSpacing.x2_5;
        painter.dispose();
        final oneLine = constraints.maxWidth >= math.max(need, 0) + 8 + 144;
        final dateField = PField(
          label: '날짜',
          child: PInputButton(
            value: dateText.isEmpty ? null : dateText,
            placeholder: '날짜 선택',
            suffixIcon: LucideIcons.calendarDays,
            onPressed: _openDate,
          ),
        );
        final timeField = SizedBox(
          width: 144,
          child: PField(
            label: '시각',
            child: PInputButton(
              value: _time == null ? null : formatTimeValue(_time),
              placeholder: '시간 선택',
              suffixIcon: LucideIcons.clock,
              onPressed: _openTime,
            ),
          ),
        );
        if (oneLine) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x2,
            children: [
              Expanded(child: dateField),
              timeField,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: PSpacing.x2,
          children: [dateField, timeField],
        );
      },
    );
  }
}
