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
import 'package:groo_damda_app/shared/ds/list/list_row.dart'
    show kPListStackBelowEm;
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
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

/// 줄의 값 자리 — 줄 끝에서 줄바꿈하고(말줄임 없음) 제목은 한 줄로 지킨다. ds List 는 긴 값이 오면 본문을 1em 까지 줄이므로("장 / 소")
/// 제목 글 폭을 재어 값의 최대 폭을 정한다(웹은 제목에 whitespace-nowrap 을 둔 것과 같다 — I-09 K 7).
class _RowValue {
  const _RowValue({
    required this.title,
    required this.rowWidth,
    required this.text,
    this.leading,
    this.maxLines,
    this.reserve = 0,
  });

  /// ds List 의 좁은 줄 판정(list.md "큰 글자에서 값을 본문 아래로") — 줄 안 폭이 제목 글자 16개(16em)보다 좁은가.
  /// 좁으면 값은 ds 가 본문 아래로 내린다(이때는 폭을 제한하지 않는다).
  static bool isNarrow(BuildContext context, double rowWidth) =>
      rowWidth - PSpacing.globalGutter * 2 <
      kPListStackBelowEm *
          MediaQuery.textScalerOf(context).scale(PTypography.t5.fontSize!);

  final String title;
  final double rowWidth;
  final String text;
  final Widget? leading;
  final int? maxLines;

  /// 값 뒤에 따로 서는 것의 폭(꺾쇠 + 사이).
  final double reserve;

  /// 줄 앞 아이콘 22 + 사이 12, 제목 ↔ 값 사이 10, 줄 좌우 24.
  static const double _fixed = PSpacing.globalGutter * 2 + 22 + 12 + 10;

  /// 제목을 한 줄로 두고 남는 값 자리의 폭.
  static double maxWidthFor(
    BuildContext context,
    String title,
    double rowWidth, {
    double reserve = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: keepAll(title), style: PTypography.t5),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final titleWidth = painter.width;
    painter.dispose();
    return math.max(48.0, rowWidth - _fixed - titleWidth - reserve);
  }

  /// 줄 뒤 붙이개에 넣을 값 — 좁은 줄이면 ds 가 값으로 읽는 [Text] 그대로(본문 아래로 내려간다), 넓으면 폭을 제한한 상자.
  /// 위젯 클래스째 넣으면 ds 가 "컨트롤" 로 읽어 내려가지 않으므로 여기서 [Text] 를 바로 만들어 준다.
  Widget build(BuildContext context) {
    final narrow = isNarrow(context, rowWidth);
    final max = maxWidthFor(context, title, rowWidth, reserve: reserve);
    final value = Text.rich(
      TextSpan(
        children: [
          if (leading != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: PSpacing.x1_5),
                child: leading,
              ),
            ),
          TextSpan(text: text),
        ],
      ),
      textAlign: narrow ? null : TextAlign.end,
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
      semanticsLabel: text,
    );
    // 좁은 줄은 ds 의 값(Text)으로 둔다 — 본문 아래로 내려가고 제목이 줄 안 폭을 다 쓴다
    if (narrow) return value;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max),
      child: value,
    );
  }
}

/// 일정 폼 시트의 본문 — 제목 입력칸 + List 줄 칸 아홉(I-09 22 ~ 28). 상태는 부모가 든다.
class CalendarEventFormRows extends StatelessWidget {
  const CalendarEventFormRows({
    super.key,
    required this.titleController,
    required this.titleFocus,
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

    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;

        /// 값이 있는 줄 — 값은 줄 끝에서 줄바꿈하고 제목은 한 줄이다.
        Widget row({
          required String title,
          required IconData icon,
          required String? value,
          required VoidCallback? onTap,
          Widget? leading,
          bool chevron = false,
          int? maxLines,
        }) => PListButtonItem(
          title: title,
          prefix: Icon(icon, size: _rowIcon),
          onTap: onTap,
          suffix: value == null && !chevron
              ? null
              : PListSuffix(
                  children: [
                    if (value != null)
                      _RowValue(
                        title: title,
                        rowWidth: width,
                        text: value,
                        leading: leading,
                        maxLines: maxLines,
                        reserve: chevron ? 22 : 0,
                      ).build(context),
                    if (chevron)
                      const ExcludeSemantics(
                        child: Icon(LucideIcons.chevronRight),
                      ),
                  ],
                ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (saveError != null)
              CalendarSaveErrorCallout(message: saveError!),
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
                // 고를 캘린더가 0 개 — 불러오는 중이면 값 없이, 실패면 "불러오지 못했어요" + 누르면 다시 받는다
                calendars.isNotEmpty
                    ? row(
                        title: l.calFieldCalendar,
                        icon: LucideIcons.calendar,
                        value: cal?.name,
                        leading: cal == null ? null : PickerDot(color: cal.dot),
                        onTap: onPickCalendar,
                      )
                    : row(
                        title: l.calFieldCalendar,
                        icon: LucideIcons.calendar,
                        value: calendarsLoading
                            ? null
                            : l.calFormCalendarLoadFailed,
                        onTap: calendarsLoading ? null : onRetryCalendars,
                      ),
                row(
                  title: l.calFieldLabel,
                  icon: LucideIcons.tag,
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
                  rowWidth: width,
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
                  rowWidth: width,
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
                row(
                  title: l.calRepeat,
                  icon: LucideIcons.repeat,
                  value: recurrenceLabel(l, recurrence),
                  onTap: onPickRecurrence,
                ),
                row(
                  title: l.calFieldReminder,
                  icon: LucideIcons.bell,
                  value: reminderValueText(l, reminders),
                  onTap: onPickReminders,
                ),
                row(
                  title: l.calLocation,
                  icon: LucideIcons.mapPin,
                  value: location.isEmpty ? none : location,
                  chevron: true,
                  onTap: () => onStep(CalendarFormStep.location),
                ),
                row(
                  title: l.calFieldDescription,
                  icon: LucideIcons.text,
                  // 설명은 값 미리보기라 두 줄까지(list.md:158)
                  value: description.isEmpty ? none : description,
                  maxLines: 2,
                  chevron: true,
                  onTap: () => onStep(CalendarFormStep.description),
                ),
              ],
            ),
          ],
        );
      },
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
    required this.rowWidth,
    required this.onDay,
    required this.onTime,
  });

  final String title;
  final String dayName;
  final String timeName;
  final DateTime value;
  final DateTime today;
  final bool allDay;
  final double rowWidth;
  final VoidCallback onDay;
  final VoidCallback onTime;

  @override
  Widget build(BuildContext context) {
    final dayText = formatDateValue(value, today);
    final timeText = formatTimeValue(
      PTimeValue.fromDateTime(value),
      labels: PTimePickerLabels.of(context),
    );
    return PListItem(
      title: title,
      prefix: const Icon(LucideIcons.clock, size: _rowIcon),
      suffix: ConstrainedBox(
        // 제목을 짓누르지 않게 값 자리의 폭을 정한다 — 모자라면 시각 조각이 다음 줄로
        constraints: BoxConstraints(
          maxWidth: math.max(
            120.0,
            _RowValue.maxWidthFor(context, title, rowWidth),
          ),
        ),
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
