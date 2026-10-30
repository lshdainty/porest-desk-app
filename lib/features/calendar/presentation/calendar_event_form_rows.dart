import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event_form_rules.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';

/// 고르기 시트에 줄로 오르는 캘린더 · 라벨 — 이름과 앞 색 점.
class CalendarChoiceSource {
  const CalendarChoiceSource({
    required this.rowId,
    required this.name,
    required this.dot,
    this.colorHex,
  });

  factory CalendarChoiceSource.of(
    BuildContext context,
    int rowId,
    String name,
    String? hex,
  ) => CalendarChoiceSource(
    rowId: rowId,
    name: name,
    colorHex: hex,
    dot: chartToneOf(context, hex).solid,
  );

  final int rowId;
  final String name;
  final String? colorHex;
  final Color dot;
}

enum CalendarFormStep { location, description }

const double _rowIcon = 22;

/// 일정 폼 시트의 본문 — 제목 입력칸 + List 줄 칸 아홉(I-09 22 ~ 28). 상태는 부모가 든다.
class CalendarEventFormRows extends StatelessWidget {
  const CalendarEventFormRows({
    super.key,
    required this.titleController,
    required this.titleFocus,
    required this.autofocusTitle,
    required this.titleError,
    required this.onTitleChanged,
    required this.saveError,
    required this.calendars,
    required this.calendarsLoading,
    required this.selectedCalendar,
    required this.onPickCalendar,
    required this.onRetryCalendars,
    required this.labels,
    required this.selectedLabel,
    required this.onPickLabel,
    required this.allDay,
    required this.onAllDay,
    required this.start,
    required this.end,
    required this.today,
    required this.rangeError,
    required this.onPickStartDay,
    required this.onPickStartTime,
    required this.onPickEndDay,
    required this.onPickEndTime,
    required this.recurrence,
    required this.onPickRecurrence,
    required this.reminders,
    required this.onPickReminders,
    required this.location,
    required this.description,
    required this.onStep,
  });

  final TextEditingController titleController;
  final FocusNode titleFocus;
  final bool autofocusTitle;
  final String? titleError;
  final ValueChanged<String> onTitleChanged;
  final String? saveError;
  final List<CalendarChoiceSource> calendars;
  final bool calendarsLoading;
  final int? selectedCalendar;
  final VoidCallback onPickCalendar;
  final VoidCallback onRetryCalendars;
  final List<CalendarChoiceSource> labels;
  final int? selectedLabel;
  final VoidCallback onPickLabel;
  final bool allDay;
  final ValueChanged<bool> onAllDay;
  final DateTime start;
  final DateTime end;
  final DateTime today;
  final bool rangeError;
  final VoidCallback onPickStartDay;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndDay;
  final VoidCallback onPickEndTime;
  final CalendarRecurrence recurrence;
  final VoidCallback onPickRecurrence;
  final List<int> reminders;
  final VoidCallback onPickReminders;
  final String location;
  final String description;
  final ValueChanged<CalendarFormStep> onStep;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;

    CalendarChoiceSource? find(List<CalendarChoiceSource> from, int? id) {
      for (final s in from) {
        if (s.rowId == id) return s;
      }
      return null;
    }

    final cal = find(calendars, selectedCalendar);
    final label = find(labels, selectedLabel);
    final none = l.calFormNone;

    Widget calendarRow() {
      if (calendars.isNotEmpty) {
        return PickerRow(
          title: l.calFieldCalendar,
          prefix: const Icon(LucideIcons.calendar, size: _rowIcon),
          value: cal?.name,
          leading: cal == null ? null : PickerDot(color: cal.dot),
          onTap: onPickCalendar,
        );
      }
      // 고를 캘린더가 0 개 — 불러오는 중이면 값 없이, 실패면 "불러오지 못했어요" + 누르면 다시 받는다
      return PickerRow(
        title: l.calFieldCalendar,
        prefix: const Icon(LucideIcons.calendar, size: _rowIcon),
        value: calendarsLoading ? null : l.calFormCalendarLoadFailed,
        onTap: calendarsLoading ? null : onRetryCalendars,
      );
    }

    String chevronValue(String v) => v.isEmpty ? none : v;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (saveError != null) CalendarSaveErrorCallout(message: saveError!),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            PSpacing.x3,
            PSpacing.globalGutter,
            PSpacing.x2,
          ),
          child: PField(
            required: true,
            invalid: titleError != null,
            errorMessage: titleError,
            child: PInput(
              controller: titleController,
              focusNode: titleFocus,
              autofocus: autofocusTitle,
              semanticLabel: l.calFieldTitle,
              placeholder: l.calTitlePlaceholder,
              inputFormatters: [
                LengthLimitingTextInputFormatter(kCalendarTitleMax),
              ],
              onChanged: onTitleChanged,
            ),
          ),
        ),
        PList(
          semanticLabel: l.calFormRows,
          children: [
            calendarRow(),
            PickerRow(
              title: l.calFieldLabel,
              prefix: const Icon(LucideIcons.tag, size: _rowIcon),
              value: label?.name ?? l.calNoLabel,
              leading: label == null ? null : PickerDot(color: label.dot),
              onTap: onPickLabel,
            ),
            PListSwitchItem(
              title: l.calAllDay,
              prefix: const Icon(LucideIcons.sun, size: _rowIcon),
              checked: allDay,
              onChanged: onAllDay,
            ),
            _DateRow(
              title: l.calStartDate,
              dayName: l.calFormStartDay,
              timeName: l.calFormStartTime,
              value: start,
              today: today,
              allDay: allDay,
              onDay: onPickStartDay,
              onTime: onPickStartTime,
            ),
            _DateRow(
              title: l.calEndDate,
              dayName: l.calFormEndDay,
              timeName: l.calFormEndTime,
              value: end,
              today: today,
              allDay: allDay,
              onDay: onPickEndDay,
              onTime: onPickEndTime,
            ),
          ],
        ),
        if (rangeError)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: Semantics(
              liveRegion: true,
              child: Text(
                l.calFormEndBeforeStart,
                style: PTypography.t3.copyWith(color: c.fgCritical),
              ),
            ),
          ),
        PList(
          semanticLabel: l.calFormRowsMore,
          children: [
            PickerRow(
              title: l.calRepeat,
              prefix: const Icon(LucideIcons.repeat, size: _rowIcon),
              value: recurrenceLabel(l, recurrence),
              onTap: onPickRecurrence,
            ),
            PickerRow(
              title: l.calFieldReminder,
              prefix: const Icon(LucideIcons.bell, size: _rowIcon),
              value: reminderValueText(l, reminders),
              onTap: onPickReminders,
            ),
            PListButtonItem(
              title: l.calLocation,
              prefix: const Icon(LucideIcons.mapPin, size: _rowIcon),
              suffix: PListSuffix(
                children: [
                  Text(chevronValue(location)),
                  const ExcludeSemantics(child: Icon(LucideIcons.chevronRight)),
                ],
              ),
              onTap: () => onStep(CalendarFormStep.location),
            ),
            PListButtonItem(
              title: l.calFieldDescription,
              prefix: const Icon(LucideIcons.text, size: _rowIcon),
              suffix: PListSuffix(
                children: [
                  // 설명은 값 미리보기라 두 줄까지(list.md:158)
                  Text(
                    chevronValue(description),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const ExcludeSemantics(child: Icon(LucideIcons.chevronRight)),
                ],
              ),
              onTap: () => onStep(CalendarFormStep.description),
            ),
          ],
        ),
      ],
    );
  }
}

/// 시작 · 종료 줄 — 날짜 조각 + 시각 조각 둘(time-picker.md:71). 조각마다 누르는 자리 44 이상 · 이름을 따로 두고, 종일이면 시각 조각이
/// 없다. 두 조각이 한 줄에 안 들어가면 시각 조각이 다음 줄로 간다(글은 자르지 않는다).
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.title,
    required this.dayName,
    required this.timeName,
    required this.value,
    required this.today,
    required this.allDay,
    required this.onDay,
    required this.onTime,
  });

  final String title;
  final String dayName;
  final String timeName;
  final DateTime value;
  final DateTime today;
  final bool allDay;
  final VoidCallback onDay;
  final VoidCallback onTime;

  @override
  Widget build(BuildContext context) {
    final dayText = formatDateValue(value, today);
    final timeText = formatTimeValue(
      PTimeValue.fromDateTime(value),
      labels: PTimePickerLabels.of(context),
    );
    final width = MediaQuery.sizeOf(context).width;
    return PListItem(
      title: title,
      prefix: const Icon(LucideIcons.clock, size: _rowIcon),
      suffix: ConstrainedBox(
        // 제목을 짓누르지 않게 값 자리의 폭을 정한다 — 모자라면 시각 조각이 다음 줄로
        constraints: BoxConstraints(maxWidth: math.max(160.0, width * 0.62)),
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: PSpacing.x2,
          children: [
            _Piece(label: '$dayName, $dayText', text: dayText, onTap: onDay),
            if (!allDay)
              _Piece(
                label: '$timeName, $timeText',
                text: timeText,
                onTap: onTime,
              ),
          ],
        ),
      ),
    );
  }
}

class _Piece extends StatelessWidget {
  const _Piece({required this.label, required this.text, required this.onTap});

  final String label;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PListAction(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: PTouch.min),
            child: Align(
              widthFactor: 1,
              alignment: Alignment.center,
              child: Text(text),
            ),
          ),
        ),
      ),
    );
  }
}

/// 한 단계 머리의 오른쪽 "완료" — 닫기 원 자리의 글 버튼(t4 14 · 700 · `fg-neutral` · 보이는 36). 시트 머리의 동작 자리는 44 폭이라
/// 글 버튼이 왼쪽으로 넘쳐 나오게 하고, 바깥 끝은 화면 끝에서 16(웹 `SheetStepDone` 과 같다)에 맞춘다.
class CalendarStepDone extends StatelessWidget {
  const CalendarStepDone({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxWidth: 160,
      alignment: Alignment.centerRight,
      child: Transform.translate(
        offset: const Offset(4, 0),
        child: PButton(
          label: label,
          variant: PButtonVariant.ghost,
          ghostColor: PButtonGhostColor.neutral,
          size: PButtonSize.small,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// 폼 맨 위 저장 실패 알림 — 서버가 낸 글이 아니라 우리 글.
class CalendarSaveErrorCallout extends StatelessWidget {
  const CalendarSaveErrorCallout({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PSpacing.globalGutter,
      PSpacing.x3,
      PSpacing.globalGutter,
      0,
    ),
    child: PCallout(
      tone: PCalloutTone.critical,
      description: message,
      alert: true,
    ),
  );
}
