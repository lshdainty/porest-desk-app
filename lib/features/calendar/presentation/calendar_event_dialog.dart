import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/patch.dart';
import 'package:porest_desk_app/features/dashboard/application/dashboard_providers.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/shared/widgets/p_toggle.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_picker_options.dart';

void showCalendarEventDialog(
  BuildContext context, {
  CalendarEvent? edit,
  DateTime? defaultDate,
}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.calEventAdd : l.calEventEdit,
    contentBuilder: (ctx, scrollCtrl) => _Body(
      edit: edit,
      defaultDate: defaultDate,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit != null ? l.actionEdit : l.actionSave,
    ),
  ).whenComplete(controller.dispose);
}

/// 신규 일정 기본 색 = blue(primary) — 웹 DEFAULT_EVENT_COLOR(#2c70bf) 정합.
const _kDefaultEventColor = '#2c70bf';

enum _RecurrenceOption { none, daily, weekly, monthly, yearly }

String _recurrenceLabel(AppLocalizations l, _RecurrenceOption r) => switch (r) {
  _RecurrenceOption.none => l.calRecurrenceNone,
  _RecurrenceOption.daily => l.calRepeatDaily,
  _RecurrenceOption.weekly => l.calRepeatWeekly,
  _RecurrenceOption.monthly => l.calRepeatMonthly,
  _RecurrenceOption.yearly => l.calRepeatYearly,
};

_RecurrenceOption _rruleToRecurrence(String? rrule) {
  if (rrule == null || rrule.isEmpty) return _RecurrenceOption.none;
  if (rrule.contains('FREQ=DAILY')) return _RecurrenceOption.daily;
  if (rrule.contains('FREQ=WEEKLY')) return _RecurrenceOption.weekly;
  if (rrule.contains('FREQ=MONTHLY')) return _RecurrenceOption.monthly;
  if (rrule.contains('FREQ=YEARLY')) return _RecurrenceOption.yearly;
  return _RecurrenceOption.none;
}

/// 칩이 고른 반복을 저장 본문에 실을 RRULE 로 바꾼다 — 웹 `recurrenceToRrule` 과 같은 값.
/// `none` 은 null 이고, 수정에서는 그 null 이 "반복을 지워라" 로 나간다.
String? _recurrenceToRrule(_RecurrenceOption r) => switch (r) {
  _RecurrenceOption.none => null,
  _RecurrenceOption.daily => 'FREQ=DAILY',
  _RecurrenceOption.weekly => 'FREQ=WEEKLY',
  _RecurrenceOption.monthly => 'FREQ=MONTHLY',
  _RecurrenceOption.yearly => 'FREQ=YEARLY',
};

const _reminderOptions = <int>[5, 15, 30, 60, 1440];

String _reminderLabel(AppLocalizations l, int min) {
  if (min == 60) return l.calReminderHourBefore;
  if (min == 1440) return l.calReminderDayBefore;
  return l.calReminderMinutesBefore(min);
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    this.edit,
    this.defaultDate,
    required this.scrollController,
    required this.controller,
  });
  final CalendarEvent? edit;
  final DateTime? defaultDate;
  final ScrollController scrollController;
  final PSheetController controller;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;
  late DateTime _start;
  late DateTime _end;
  late bool _allDay;
  int? _labelRowId;
  int? _userCalendarRowId;
  String _color = _kDefaultEventColor; // violet 기본
  _RecurrenceOption _recurrence = _RecurrenceOption.none;

  /// 열었을 때 서버에 있던 반복 규칙과, 그것이 매핑된 칩.
  ///
  /// 칩 다섯 개는 `FREQ=` 하나만 표현한다 — 웹이 만든 `FREQ=WEEKLY;BYDAY=MO,WE` 나
  /// 서버가 늘린 규칙을 칩으로 되그릴 수 없다. 그래서 **사용자가 칩을 안 바꿨으면
  /// 원본을 그대로 되돌려 준다.** 안 그러면 여는 것만으로 세부 규칙이 뭉개진다.
  String? _initialRrule;
  _RecurrenceOption _initialRecurrence = _RecurrenceOption.none;
  final Set<int> _reminders = <int>{};
  bool _submitting = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    if (e != null) {
      _start = e.start;
      _end = e.end;
      _allDay = e.isAllDayBool;
      _labelRowId = e.labelRowId;
      // 소속 캘린더 식별자는 calendarRowId (userRowId=이벤트 소유자라 캘린더 매칭 불가).
      _userCalendarRowId = e.calendarRowId;
      _color = e.color ?? _kDefaultEventColor;
      _initialRrule = e.rrule;
      _initialRecurrence = _rruleToRecurrence(e.rrule);
      _recurrence = _initialRecurrence;
      // 기존 알림을 칩에 먼저 채운다. 이걸 건너뛰고 저장만 실으면 서버가 목록을
      // 통째로 교체하므로, 웹에서 건 알림이 앱 저장 한 번에 전부 사라진다.
      _reminders.addAll(e.reminderMinutes);
    } else {
      final d = widget.defaultDate ?? DateTime.now();
      _start = DateTime(d.year, d.month, d.day, 9, 0);
      _end = DateTime(d.year, d.month, d.day, 10, 0);
      _allDay = true; // 신규 일정 기본 종일 ON (웹 isAllDay default true 정합).
      // 생성 모드: 캘린더 로드 후 기본 캘린더 선택(저장 반영). 웹 EventForm useEffect 패턴.
      // **고를 수 있는 것 중에서** 잡는다 — 기본 캘린더가 숨겨져 있는데 그대로 고르면
      // 목록에 없는 값이 선택된 채로 남고, 저장하면 그 일정이 곧바로 사라진다.
      ref.read(userCalendarListProvider.future).then((cals) {
        if (!mounted || _userCalendarRowId != null) return;
        final def = defaultCalendarRowId(selectableCalendars(cals));
        if (def == null) return;
        setState(() => _userCalendarRowId = def);
      });
    }
    widget.controller.onSubmit = _submit;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_submitting && _titleCtrl.text.trim().isNotEmpty;

  void _syncController() {
    widget.controller.setCanSubmit(_canSubmit);
    widget.controller.setSubmitting(_submitting);
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00';

  /// 저장 본문에 실을 반복 규칙. 칩을 안 바꿨으면 원본을 그대로 되돌린다.
  String? get _rruleForSave => _recurrence == _initialRecurrence
      ? _initialRrule
      : _recurrenceToRrule(_recurrence);

  /// 저장 본문에 실을 알림 사전분 — 서버가 이 목록으로 전체를 교체한다.
  /// 오름차순으로 고정해 같은 선택이면 같은 본문이 나가게 한다.
  List<int> get _reminderMinutesForSave => _reminders.toList()..sort();

  Future<void> _submit() async {
    setState(() => _submitting = true);
    _syncController();
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      final monthKey = (year: _start.year, month: _start.month);
      if (_isEdit) {
        await repo.updateEvent(
          id: widget.edit!.rowId,
          title: _titleCtrl.text.trim(),
          // 설명·장소·라벨은 이 화면이 가진 칸이다 — 비운 상태를 명시적 null 로 실어야
          // 지워진다. 키를 빼면 서버가 지금 값을 지키므로(desk-back #325), 지우고
          // 저장해도 다시 열면 옛 값이 그대로 있다.
          description: Patch.set(
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          ),
          // 서버는 수정 요청에 실린 종류로 무조건 덮어쓴다. 이 화면에는 종류를 고르는
          // 자리가 없으므로 원래 값을 그대로 되돌려 준다 — 안 그러면 다른 데서 정한
          // 종류가 여기서 저장 한 번에 기본값으로 바뀐다.
          eventType: widget.edit!.eventType,
          color: _color,
          calendarRowId: _userCalendarRowId,
          startDate: _iso(_start),
          endDate: _iso(_end),
          isAllDay: _allDay,
          labelRowId: Patch.set(_labelRowId),
          location: Patch.set(
            _locationCtrl.text.trim().isEmpty
                ? null
                : _locationCtrl.text.trim(),
          ),
          // 반복·알림은 이 화면이 소유한 칸이다 — 늘 실어야 칩이 실제로 동작한다.
          // 반복은 명시적 null 까지 실어야 '반복 없음' 이 반영된다(키를 빼면 유지).
          rrule: Patch.set(_rruleForSave),
          reminderMinutes: _reminderMinutesForSave,
        );
      } else {
        await repo.createEvent(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          color: _color,
          calendarRowId: _userCalendarRowId,
          startDate: _iso(_start),
          endDate: _iso(_end),
          isAllDay: _allDay,
          labelRowId: _labelRowId,
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          rrule: _rruleForSave,
          reminderMinutes: _reminderMinutesForSave,
        );
      }
      ref.invalidate(monthEventsProvider(monthKey));
      // 홈 위젯(오늘 일정·다가오는 일정)의 원본 — 셸 상주라 스스로 안 받는다.
      ref.invalidate(dashboardSummaryProvider);
      if (_isEdit) {
        final orig = widget.edit!.start;
        if (orig.year != _start.year || orig.month != _start.month) {
          ref.invalidate(
            monthEventsProvider((year: orig.year, month: orig.month)),
          );
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _syncController();
      }
    }
  }

  void _onPickDate(bool isStart, DateTime? d) {
    if (d == null) return;
    setState(() {
      final cur = isStart ? _start : _end;
      final next = DateTime(d.year, d.month, d.day, cur.hour, cur.minute);
      if (isStart) {
        _start = next;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = next;
      }
    });
  }

  void _onPickTime(bool isStart, TimeOfDay? picked) {
    if (picked == null) return;
    setState(() {
      final cur = isStart ? _start : _end;
      final next = DateTime(
        cur.year,
        cur.month,
        cur.day,
        picked.hour,
        picked.minute,
      );
      if (isStart) {
        _start = next;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final labelsAsync = ref.watch(eventLabelsProvider);
    final calendarsAsync = ref.watch(userCalendarListProvider);

    // 숨긴 캘린더는 고를 수 없다 — 다만 편집 중인 일정이 이미 든 캘린더는 남긴다.
    // 기준은 연 순간의 소속(`widget.edit`)이다. 사용자가 다른 캘린더를 골랐다고
    // 원래 자리가 목록에서 사라지면 되돌아갈 데가 없어진다.
    final calendarOptions = selectableCalendars(
      calendarsAsync.value ?? const [],
      keepRowId: widget.edit?.calendarRowId,
    );
    // 고를 수 있는 목록 밖의 값이 선택돼 있으면 셀렉트가 이름 없는 칸을 그린다 —
    // 그때는 기본 선택으로 되돌린다(목록과 기본 선택은 늘 같은 규칙을 지난다).
    final selectedCalendarRowId =
        calendarOptions.any((c) => c.rowId == _userCalendarRowId)
        ? _userCalendarRowId
        : defaultCalendarRowId(calendarOptions);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        PSpace.xl,
        PSpace.x8,
        PSpace.xl,
        PSpace.x16,
      ),
      children: [
        PSectionLabel(l.calFieldTitle, variant: PSectionLabelVariant.header),
        const SizedBox(height: PSpace.x8),
        PTextInput(
          controller: _titleCtrl,
          placeholder: l.calTitlePlaceholder,
          onChanged: (_) {
            setState(() {});
            _syncController();
          },
        ),
        const SizedBox(height: PSpace.x16),

        PSectionLabel(
          l.calFieldDescription,
          variant: PSectionLabelVariant.header,
        ),
        const SizedBox(height: PSpace.x8),
        PTextInput(
          controller: _descCtrl,
          maxLines: 3,
          placeholder: l.calDescriptionPlaceholder,
        ),
        const SizedBox(height: PSpace.x16),

        // 캘린더
        PSectionLabel(l.calFieldCalendar, variant: PSectionLabelVariant.header),
        const SizedBox(height: PSpace.x8),
        calendarsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: PSpace.x8),
            child: Center(
              child: SizedBox(
                height: PSpace.x16,
                width: PSpace.x16,
                child: PCircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => Text(
            l.calCalendarLoadError,
            style: PTypo.caption.copyWith(color: t.statusDanger),
          ),
          data: (_) => PSelect<int>(
            value: selectedCalendarRowId,
            placeholder: l.calSelectCalendar,
            onChanged: (v) {
              if (v != null) setState(() => _userCalendarRowId = v);
            },
            items: [
              for (final c in calendarOptions)
                PSelectItem<int>(
                  value: c.rowId,
                  label: c.calendarName,
                  leading: _labelDot(
                    solidSwatchColor(context, c.color, fallback: t.fgBrand),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        // 라벨
        PSectionLabel(
          l.calFieldLabel,
          variant: PSectionLabelVariant.header,
          icon: LucideIcons.tag,
        ),
        const SizedBox(height: PSpace.x8),
        // web EventForm 정합 — chip 나열 대신 Select ('라벨이 없습니다' + 색 점)
        labelsAsync.when(
          loading: () => const SizedBox(
            height: PSpace.x32,
            child: Center(child: PCircularProgressIndicator()),
          ),
          error: (_, _) => Text(
            l.calLabelLoadError,
            style: PTypo.caption.copyWith(color: t.statusDanger),
          ),
          data: (labels) => PSelect<int>(
            value: _labelRowId ?? 0,
            onChanged: (v) => setState(() => _labelRowId = v == 0 ? null : v),
            items: [
              PSelectItem(
                value: 0,
                label: l.calNoLabel,
                leading: _labelDot(t.fgTertiary.withValues(alpha: 0.3)),
              ),
              for (final l in labels)
                PSelectItem(
                  value: l.rowId,
                  label: l.labelName,
                  leading: _labelDot(
                    solidSwatchColor(context, l.color, fallback: t.fgBrand),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        // 색상
        PSectionLabel(l.calFieldColor, variant: PSectionLabelVariant.header),
        const SizedBox(height: PSpace.x8),
        PColorPicker(
          selected: _color,
          onChanged: (hex) => setState(() => _color = hex),
        ),
        const SizedBox(height: PSpace.x16),

        // 종일 — web 정합: [토글][라벨] 좌측 정렬
        Row(
          children: [
            PSwitch(
              value: _allDay,
              onChanged: (v) => setState(() => _allDay = v),
              semanticLabel: l.calAllDay,
            ),
            const SizedBox(width: PSpace.x8),
            Text(l.calAllDay, style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
          ],
        ),
        const SizedBox(height: PSpace.x12),

        // 시작/종료 — 종일 ON: 시작·종료 가로 2칸(웹 grid-cols-2 정합),
        // 종일 OFF: 세로 stack + 각 행 [날짜][시간].
        if (_allDay) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PSectionLabel(
                      l.calFieldStartDate,
                      variant: PSectionLabelVariant.header,
                    ),
                    const SizedBox(height: PSpace.x8),
                    PDateInput(
                      value: _start,
                      onChanged: (d) => _onPickDate(true, d),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PSectionLabel(
                      l.calFieldEndDate,
                      variant: PSectionLabelVariant.header,
                    ),
                    const SizedBox(height: PSpace.x8),
                    PDateInput(
                      value: _end,
                      onChanged: (d) => _onPickDate(false, d),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x16),
        ] else ...[
          PSectionLabel(
            l.calFieldStartDate,
            variant: PSectionLabelVariant.header,
          ),
          const SizedBox(height: PSpace.x8),
          Row(
            children: [
              Expanded(
                child: PDateInput(
                  value: _start,
                  onChanged: (d) => _onPickDate(true, d),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                ),
              ),
              const SizedBox(width: PSpace.x8),
              SizedBox(
                width: PSpace.x80 + PSpace.x20,
                child: PTimeInput(
                  value: TimeOfDay.fromDateTime(_start),
                  onChanged: (tm) => _onPickTime(true, tm),
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          PSectionLabel(
            l.calFieldEndDate,
            variant: PSectionLabelVariant.header,
          ),
          const SizedBox(height: PSpace.x8),
          Row(
            children: [
              Expanded(
                child: PDateInput(
                  value: _end,
                  onChanged: (d) => _onPickDate(false, d),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                ),
              ),
              const SizedBox(width: PSpace.x8),
              SizedBox(
                width: PSpace.x80 + PSpace.x20,
                child: PTimeInput(
                  value: TimeOfDay.fromDateTime(_end),
                  onChanged: (tm) => _onPickTime(false, tm),
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x16),
        ],

        // 장소
        PSectionLabel(
          l.calLocation,
          variant: PSectionLabelVariant.header,
          icon: LucideIcons.mapPin,
        ),
        const SizedBox(height: PSpace.x8),
        PTextInput(
          controller: _locationCtrl,
          placeholder: l.calLocationPlaceholder,
        ),
        const SizedBox(height: PSpace.x16),

        // 반복
        PSectionLabel(
          l.calRepeat,
          variant: PSectionLabelVariant.header,
          icon: LucideIcons.repeat,
        ),
        const SizedBox(height: PSpace.x8),
        Wrap(
          spacing: PSpace.x4,
          runSpacing: PSpace.x4,
          children: [
            for (final r in _RecurrenceOption.values)
              PToggle(
                label: _recurrenceLabel(l, r),
                pressed: _recurrence == r,
                size: PToggleSize.sm,
                onChanged: (_) => setState(() => _recurrence = r),
              ),
          ],
        ),
        const SizedBox(height: PSpace.x16),

        // 알림
        PSectionLabel(
          l.calFieldReminder,
          variant: PSectionLabelVariant.header,
          icon: LucideIcons.bell,
        ),
        const SizedBox(height: PSpace.x8),
        Wrap(
          spacing: PSpace.x4,
          runSpacing: PSpace.x4,
          children: [
            for (final m in _reminderOptions)
              PToggle(
                label: _reminderLabel(l, m),
                pressed: _reminders.contains(m),
                size: PToggleSize.sm,
                onChanged: (_) => setState(() {
                  if (!_reminders.add(m)) _reminders.remove(m);
                }),
              ),
          ],
        ),
      ],
    );
  }
}

/// 라벨 select 항목 좌측 색 점 — web `h-3 w-3 rounded-full` 정합.
Widget _labelDot(Color color) => Container(
  width: 12,
  height: 12,
  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
);
