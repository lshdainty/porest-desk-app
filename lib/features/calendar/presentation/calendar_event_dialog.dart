import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event_form_rules.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_picker_options.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_form_rows.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_pickers.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/forms/form_delete_footer.dart';

/// 폼이 읽는 오늘 — 테스트 · 하네스가 고정한다(`dashboardNow` 와 같은 이음매).
DateTime Function() calendarFormNow = DateTime.now;

/// 일정 추가 · 수정 폼(I-09 21 ~ 30) — ds Bottom Sheet 입력 폼. 제목 입력칸 + List 줄 칸 아홉(캘린더 · 라벨 · 종일 · 시작 · 종료 · 반복 ·
/// 알림 · 장소 · 설명). 고르는 칸은 그 위에 고르기 시트가 뜨고, 장소 · 설명은 같은 시트 안에서 한 단계 들어간다. 바깥 · 끌기로 닫히지
/// 않고, 바뀐 값이 있으면 닫기 전에 "작성한 내용이 사라져요" 를 묻는다. 바닥은 추가 [저장], 수정 [삭제][저장].
void showCalendarEventDialog(
  BuildContext context, {
  CalendarEvent? edit,
  DateTime? defaultDate,
}) {
  final l = AppLocalizations.of(context);
  final probe = CalendarFormProbe();
  PBottomSheet.show<void>(
    context,
    form: true,
    isDirty: () => probe.dirty(),
    interceptClose: () => probe.interceptClose(),
    leaveCopy: PLeaveConfirmCopy(
      title: l.sheetLeaveTitle,
      description: l.sheetLeaveDescription,
      stayLabel: l.sheetLeaveStay,
      leaveLabel: l.sheetLeaveLeave,
    ),
    builder: (_) => CalendarEventFormSheet(
      edit: edit,
      defaultDate: defaultDate,
      probe: probe,
    ),
  );
}

/// 시트가 닫기 청에 답하는 길 — 입력칸의 주인은 시트 State 라 닫을 때 그쪽에 묻는다.
class CalendarFormProbe {
  bool Function() dirty = () => false;

  /// 한 단계가 열려 있으면 그 단계만 닫고 참(시트는 닫지 않는다).
  bool Function() interceptClose = () => false;
}

enum _Step { list, location, description }

class CalendarEventFormSheet extends ConsumerStatefulWidget {
  const CalendarEventFormSheet({
    super.key,
    this.edit,
    this.defaultDate,
    this.probe,
  });

  final CalendarEvent? edit;
  final DateTime? defaultDate;
  final CalendarFormProbe? probe;

  @override
  ConsumerState<CalendarEventFormSheet> createState() =>
      _CalendarEventFormSheetState();
}

class _CalendarEventFormSheetState
    extends ConsumerState<CalendarEventFormSheet> {
  late final TextEditingController _titleCtrl;
  final _titleFocus = FocusNode();
  final _stepCtrl = TextEditingController();

  late String _description;
  late String _location;
  late DateTime _start;
  late DateTime _end;
  late bool _allDay;
  int? _labelRowId;
  int? _calendarRowId;
  String _color = kDefaultEventColor;
  CalendarRecurrence _recurrence = CalendarRecurrence.none;
  List<int> _reminders = <int>[];

  /// 열었을 때 서버에 있던 반복 규칙과 그것이 매핑된 값 — 고르기를 안 바꿨으면 원본(BYDAY 등)을 그대로 되돌려 준다.
  String? _initialRrule;
  CalendarRecurrence _initialRecurrence = CalendarRecurrence.none;

  // 바뀐 값 판정용 처음 값
  late final String _initialTitle;
  late final String _initialDescription;
  late final String _initialLocation;
  late final DateTime _initialStart;
  late final DateTime _initialEnd;
  late final bool _initialAllDay;
  late final int? _initialLabel;
  int? _initialCalendar;
  late final List<int> _initialReminders;

  _Step _step = _Step.list;
  bool _submitting = false;
  bool _showErrors = false;
  String? _titleError;
  String? _saveError;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _initialTitle = e?.title ?? '';
    _titleCtrl = TextEditingController(text: _initialTitle);
    _description = e?.description ?? '';
    _location = e?.location ?? '';
    if (e != null) {
      _start = e.start;
      _end = e.end;
      _allDay = e.isAllDayBool;
      _labelRowId = e.labelRowId;
      // 소속 캘린더 식별자는 calendarRowId (userRowId=이벤트 소유자라 캘린더 매칭 불가).
      _calendarRowId = e.calendarRowId;
      _color = e.color ?? kDefaultEventColor;
      _initialRrule = e.rrule;
      _initialRecurrence = rruleToRecurrence(e.rrule);
      _recurrence = _initialRecurrence;
      // 기존 알림을 먼저 채운다 — 서버는 목록을 통째로 교체하므로 건너뛰면 웹에서 건 알림이 저장 한 번에 사라진다.
      _reminders = ([...e.reminderMinutes]..sort());
    } else {
      final d = widget.defaultDate ?? calendarFormNow();
      _start = DateTime(d.year, d.month, d.day, 9);
      _end = DateTime(d.year, d.month, d.day, 10);
      _allDay = true; // 신규 일정 기본 종일 켬(웹 isAllDay default true 정합).
      // **고를 수 있는 것 중에서** 기본 캘린더를 잡는다 — 숨긴 캘린더가 선택된 채 저장하면 일정이 곧바로 사라진다.
      ref.read(userCalendarListProvider.future).then((cals) {
        if (!mounted || _calendarRowId != null) return;
        final def = defaultCalendarRowId(selectableCalendars(cals));
        if (def == null) return;
        setState(() {
          _calendarRowId = def;
          _initialCalendar = def;
        });
      });
    }
    _initialDescription = _description;
    _initialLocation = _location;
    _initialStart = _start;
    _initialEnd = _end;
    _initialAllDay = _allDay;
    _initialLabel = _labelRowId;
    _initialCalendar = _calendarRowId;
    _initialReminders = [..._reminders];
    final probe = widget.probe;
    if (probe != null) {
      probe.dirty = _dirty;
      probe.interceptClose = _interceptClose;
    }
  }

  @override
  void dispose() {
    final probe = widget.probe;
    if (probe != null) {
      probe.dirty = () => false;
      probe.interceptClose = () => false;
    }
    _titleCtrl.dispose();
    _titleFocus.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  bool _dirty() =>
      _titleCtrl.text != _initialTitle ||
      _description != _initialDescription ||
      _location != _initialLocation ||
      _start != _initialStart ||
      _end != _initialEnd ||
      _allDay != _initialAllDay ||
      _labelRowId != _initialLabel ||
      _calendarRowId != _initialCalendar ||
      _recurrence != _initialRecurrence ||
      !_sameList(_reminders, _initialReminders);

  bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ── 한 단계(장소 · 설명) ────────────────────────────────────
  void _enterStep(_Step step) {
    FocusScope.of(context).unfocus();
    _stepCtrl.text = step == _Step.location ? _location : _description;
    setState(() => _step = step);
  }

  /// "완료" — 친 글을 넣고 줄 칸으로 돌아간다.
  void _confirmStep() {
    if (_step == _Step.list) return;
    final text = _stepCtrl.text;
    setState(() {
      if (_step == _Step.location) {
        _location = text;
      } else {
        _description = text;
      }
      _step = _Step.list;
    });
  }

  /// ← · 뒤로 가기 · Esc — 친 글을 버리고 줄 칸으로(이전 값 그대로).
  void _cancelStep() {
    if (_step == _Step.list) return;
    setState(() => _step = _Step.list);
  }

  bool _interceptClose() {
    if (_step == _Step.list || !mounted) return false;
    _cancelStep();
    return true;
  }

  // ── 고르기 ──────────────────────────────────────────────
  List<CalendarChoiceSource> _calendarSources() => [
    for (final c in selectableCalendars(
      ref.read(userCalendarListProvider).value ?? const [],
      keepRowId: widget.edit?.calendarRowId,
    ))
      CalendarChoiceSource.of(context, c.rowId, c.calendarName, c.color),
  ];

  List<CalendarChoiceSource> _labelSources() => [
    for (final x in ref.read(eventLabelsProvider).value ?? const [])
      CalendarChoiceSource.of(context, x.rowId, x.labelName, x.color),
  ];

  Future<void> _pickCalendar() async {
    final l = AppLocalizations.of(context);
    final options = _calendarSources();
    FocusScope.of(context).unfocus();
    final v = await showCalendarChoiceSheet(
      context,
      title: l.calFieldCalendar,
      selected: _calendarRowId,
      items: [
        for (final o in options)
          CalendarChoice(value: o.rowId, label: o.name, dot: o.dot),
      ],
    );
    if (v == null || !mounted) return;
    final o = options.firstWhere((o) => o.rowId == v);
    setState(() {
      _calendarRowId = v;
      _color = o.colorHex ?? _color;
    });
  }

  Future<void> _pickLabel() async {
    final l = AppLocalizations.of(context);
    final labels = _labelSources();
    FocusScope.of(context).unfocus();
    final v = await showCalendarChoiceSheet(
      context,
      title: l.calFieldLabel,
      selected: _labelRowId ?? 0,
      items: [
        CalendarChoice(value: 0, label: l.calNoLabel),
        for (final o in labels)
          CalendarChoice(value: o.rowId, label: o.name, dot: o.dot),
      ],
      footnote: labels.isEmpty ? l.calFormLabelHint : null,
    );
    if (v == null || !mounted) return;
    setState(() => _labelRowId = v == 0 ? null : v);
  }

  Future<void> _pickRecurrence() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final v = await showCalendarChoiceSheet(
      context,
      title: l.calRepeat,
      selected: _recurrence.index,
      items: [
        for (final r in CalendarRecurrence.values)
          CalendarChoice(value: r.index, label: recurrenceLabel(l, r)),
      ],
    );
    if (v == null || !mounted) return;
    setState(() => _recurrence = CalendarRecurrence.values[v]);
  }

  Future<void> _pickReminders() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final v = await showCalendarMultiChoiceSheet(
      context,
      title: l.calFieldReminder,
      selected: _reminders,
      items: [
        for (final m in kCalendarReminderOptions)
          CalendarChoice(value: m, label: reminderLabel(l, m)),
      ],
    );
    if (v == null || !mounted) return;
    setState(() => _reminders = [...v]..sort());
  }

  Future<void> _pickDay(bool isStart) async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final cur = isStart ? _start : _end;
    final picked = await showCalendarDaySheet(
      context,
      title: isStart ? l.calFormStartDay : l.calFormEndDay,
      value: cur,
      today: calendarFormNow(),
    );
    if (picked == null || !mounted) return;
    final next = DateTime(
      picked.year,
      picked.month,
      picked.day,
      cur.hour,
      cur.minute,
    );
    setState(() {
      if (isStart) {
        _start = next;
        _end = ensureEndAfterStart(_start, _end, allDay: _allDay);
      } else {
        _end = next;
      }
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final cur = isStart ? _start : _end;
    final picked = await showCalendarTimeSheet(
      context,
      title: isStart ? l.calFormStartTime : l.calFormEndTime,
      value: roundTimeToStep(PTimeValue.fromDateTime(cur), 5),
    );
    if (picked == null || !mounted) return;
    final next = DateTime(
      cur.year,
      cur.month,
      cur.day,
      picked.hour,
      picked.minute,
    );
    setState(() {
      if (isStart) {
        _start = next;
        _end = ensureEndAfterStart(_start, _end, allDay: false);
      } else {
        _end = next;
      }
    });
  }

  // ── 저장 · 삭제 ──────────────────────────────────────────
  /// 저장 본문에 실을 반복 규칙 — 고르기를 안 바꿨으면 원본을 그대로 되돌린다.
  String? get _rruleForSave => _recurrence == _initialRecurrence
      ? _initialRrule
      : recurrenceToRrule(_recurrence);

  bool get _rangeInvalid => calendarRangeInvalid(_start, _end, allDay: _allDay);

  /// 반복 일정을 저장 · 삭제한 뒤에는 이미 받아 둔 다른 달에 옛 회차가 남지 않게 달 전체를 비운다(I-09 30).
  void _invalidateAfterWrite({required bool recurring, DateTime? origStart}) {
    if (recurring) {
      ref.invalidate(monthEventsProvider);
    } else {
      ref.invalidate(
        monthEventsProvider((year: _start.year, month: _start.month)),
      );
      if (origStart != null &&
          (origStart.year != _start.year || origStart.month != _start.month)) {
        ref.invalidate(
          monthEventsProvider((year: origStart.year, month: origStart.month)),
        );
      }
    }
    // 홈 위젯(오늘 일정·다가오는 일정)의 원본 — 셸 상주라 스스로 안 받는다.
    ref.invalidate(dashboardSummaryProvider);
  }

  /// [저장] 은 켜 두고 누를 때 비거나 틀린 칸마다 오류를 보이며 첫 오류 칸으로 초점을 옮긴다.
  Future<void> _save() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() {
        _showErrors = true;
        _titleError = l.calFormTitleRequired;
      });
      _titleFocus.requestFocus();
      return;
    }
    if (_rangeInvalid) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _submitting = true;
      _saveError = null;
    });
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      final description = _description.trim();
      final location = _location.trim();
      if (_isEdit) {
        await repo.updateEvent(
          id: widget.edit!.rowId,
          title: title,
          // 설명·장소·라벨은 이 화면이 가진 칸이다 — 비운 상태를 명시적 null 로 실어야 지워진다(키를 빼면 서버가 지금 값을 지킨다).
          description: Patch.set(description.isEmpty ? null : description),
          // 서버는 수정 요청에 실린 종류로 무조건 덮어쓴다 — 종류를 고르는 자리가 없으니 원래 값을 되돌려 준다.
          eventType: widget.edit!.eventType,
          color: _color,
          calendarRowId: _calendarRowId,
          startDate: calendarIso(_start),
          endDate: calendarIso(_end),
          isAllDay: _allDay,
          labelRowId: Patch.set(_labelRowId),
          location: Patch.set(location.isEmpty ? null : location),
          rrule: Patch.set(_rruleForSave),
          reminderMinutes: _reminders,
          // 반복 일정은 연 회차를 함께 알린다 — 안 알리면 서버가 이 회차 날짜를 반복의 새 시작으로 써서 앞 회차들이 사라졌다.
          occurrenceStartDate: widget.edit!.rrule != null
              ? widget.edit!.startDate
              : null,
        );
      } else {
        await repo.createEvent(
          title: title,
          description: description.isEmpty ? null : description,
          color: _color,
          calendarRowId: _calendarRowId,
          startDate: calendarIso(_start),
          endDate: calendarIso(_end),
          isAllDay: _allDay,
          labelRowId: _labelRowId,
          location: location.isEmpty ? null : location,
          rrule: _rruleForSave,
          reminderMinutes: _reminders,
        );
      }
      _invalidateAfterWrite(
        recurring: _rruleForSave != null || widget.edit?.rrule != null,
        origStart: widget.edit?.start,
      );
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException {
      // 시트는 닫히지 않고 쓴 값이 남는다 — 폼 맨 위 Callout(snackbar.md "저장 · 제출이 실패함")
      if (!mounted) return;
      setState(() => _saveError = l.calFormSaveFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    final e = widget.edit!;
    final ok = await PAlertDialog.show(
      context,
      title: l.calEventDelete,
      description: l.calEventDeleteConfirm(e.title),
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      _submitting = true;
      _saveError = null;
    });
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      await repo.deleteEvent(e.rowId);
      _invalidateAfterWrite(recurring: e.rrule != null, origStart: e.start);
      if (!mounted) return;
      PBottomSheet.of(context).close();
    } on ApiException {
      if (!mounted) return;
      setState(() => _saveError = l.calFormDeleteFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── 그리기 ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final inStep = _step != _Step.list;
    final heading = _isEdit ? l.calEventEdit : l.calEventAdd;
    if (inStep) {
      return PBottomSheetContent(
        title: _step == _Step.location ? l.calLocation : l.calFieldDescription,
        closeLabel: l.actionClose,
        showCloseButton: false,
        onBack: _cancelStep,
        backLabel: l.actionBack,
        headerAction: CalendarStepDone(
          label: l.actionDone,
          onPressed: _confirmStep,
        ),
        flushBody: true,
        scrollFog: true,
        body: _buildStep(l),
      );
    }

    final labels = ref.watch(eventLabelsProvider).value ?? const [];
    final calendarsAsync = ref.watch(userCalendarListProvider);
    // 숨긴 캘린더는 고를 수 없다 — 다만 편집 중인 일정이 이미 든 캘린더는 남긴다(기준은 연 순간의 소속).
    final options = selectableCalendars(
      calendarsAsync.value ?? const [],
      keepRowId: widget.edit?.calendarRowId,
    );
    // 고를 수 있는 목록 밖의 값이 선택돼 있으면 기본 선택으로 되돌린다.
    final selected = options.any((c) => c.rowId == _calendarRowId)
        ? _calendarRowId
        : defaultCalendarRowId(options);

    final save = PButton(
      label: l.actionSave,
      size: PButtonSize.large,
      loading: _submitting,
      onPressed: _submitting ? null : _save,
    );
    return PBottomSheetContent(
      title: heading,
      closeLabel: l.actionClose,
      flushBody: true,
      scrollFog: true,
      body: CalendarEventFormRows(
        titleController: _titleCtrl,
        titleFocus: _titleFocus,
        autofocusTitle: !_isEdit,
        titleError: _titleError,
        onTitleChanged: (_) {
          if (_titleError != null) setState(() => _titleError = null);
        },
        saveError: _saveError,
        calendars: [
          for (final c in options)
            CalendarChoiceSource.of(context, c.rowId, c.calendarName, c.color),
        ],
        calendarsLoading: calendarsAsync.isLoading,
        selectedCalendar: selected,
        onPickCalendar: _pickCalendar,
        onRetryCalendars: () => ref.invalidate(userCalendarListProvider),
        labels: [
          for (final x in labels)
            CalendarChoiceSource.of(context, x.rowId, x.labelName, x.color),
        ],
        selectedLabel: _labelRowId,
        onPickLabel: _pickLabel,
        allDay: _allDay,
        onAllDay: (v) => setState(() => _allDay = v),
        start: _start,
        end: _end,
        today: calendarFormNow(),
        rangeError: _showErrors && _rangeInvalid,
        onPickStartDay: () => _pickDay(true),
        onPickStartTime: () => _pickTime(true),
        onPickEndDay: () => _pickDay(false),
        onPickEndTime: () => _pickTime(false),
        recurrence: _recurrence,
        onPickRecurrence: _pickRecurrence,
        reminders: _reminders,
        onPickReminders: _pickReminders,
        location: _location,
        description: _description,
        onStep: (s) => _enterStep(
          s == CalendarFormStep.location ? _Step.location : _Step.description,
        ),
      ),
      footer: _isEdit ? const [] : [save],
      footerRow: _isEdit
          ? PFormDeleteFooter(
              deleteLabel: l.actionDelete,
              onDelete: _submitting ? null : _delete,
              save: save,
            )
          : null,
    );
  }

  Widget _buildStep(AppLocalizations l) {
    const gutter = EdgeInsets.fromLTRB(
      PSpacing.globalGutter,
      PSpacing.x3,
      PSpacing.globalGutter,
      PSpacing.x2,
    );
    if (_step == _Step.location) {
      return Padding(
        padding: gutter,
        child: PInput(
          controller: _stepCtrl,
          autofocus: true,
          semanticLabel: l.calLocation,
          placeholder: l.calLocationPlaceholder,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            LengthLimitingTextInputFormatter(kCalendarLocationMax),
          ],
          onSubmitted: (_) => _confirmStep(),
        ),
      );
    }
    return Padding(
      padding: gutter,
      child: PField(
        maxGraphemeCount: kCalendarContentMax,
        child: PTextarea(
          controller: _stepCtrl,
          autofocus: true,
          semanticLabel: l.calFieldDescription,
          placeholder: l.calDescriptionPlaceholder,
          maxHeight: 200,
        ),
      ),
    );
  }
}
