import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/shared/widgets/p_toggle.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';

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

String _recurrenceLabel(AppLocalizations l, _RecurrenceOption r) =>
    switch (r) {
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
      _recurrence = _rruleToRecurrence(e.rrule);
    } else {
      final d = widget.defaultDate ?? DateTime.now();
      _start = DateTime(d.year, d.month, d.day, 9, 0);
      _end = DateTime(d.year, d.month, d.day, 10, 0);
      _allDay = true; // 신규 일정 기본 종일 ON (웹 isAllDay default true 정합).
      // 생성 모드: 캘린더 로드 후 기본 캘린더 선택(저장 반영). 웹 EventForm useEffect 패턴.
      ref.read(userCalendarListProvider.future).then((cals) {
        if (!mounted || _userCalendarRowId != null || cals.isEmpty) return;
        final def =
            cals.firstWhere((c) => c.isDefault, orElse: () => cals.first);
        setState(() => _userCalendarRowId = def.rowId);
      });
    }
    widget.controller.onSubmit = _submit;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _syncController());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting && _titleCtrl.text.trim().isNotEmpty;

  void _syncController() {
    widget.controller.setCanSubmit(_canSubmit);
    widget.controller.setSubmitting(_submitting);
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() => _submitting = true);
    _syncController();
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      final monthKey = (year: _start.year, month: _start.month);
      if (_isEdit) {
        await repo.updateEvent(
          id: widget.edit!.rowId,
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          color: _color,
          calendarRowId: _userCalendarRowId,
          startDate: _iso(_start),
          endDate: _iso(_end),
          isAllDay: _allDay,
          labelRowId: _labelRowId,
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
        );
      } else {
        await repo.createEvent(
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          color: _color,
          calendarRowId: _userCalendarRowId,
          startDate: _iso(_start),
          endDate: _iso(_end),
          isAllDay: _allDay,
          labelRowId: _labelRowId,
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
        );
      }
      ref.invalidate(monthEventsProvider(monthKey));
      if (_isEdit) {
        final orig = widget.edit!.start;
        if (orig.year != _start.year || orig.month != _start.month) {
          ref.invalidate(monthEventsProvider(
              (year: orig.year, month: orig.month)));
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, _isEdit ? l.calEventUpdated : l.calEventAdded,
          severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '${l.calActionFailed}: ${e.message}',
          severity: PSnackSeverity.error);
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
      final next =
          DateTime(cur.year, cur.month, cur.day, picked.hour, picked.minute);
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

    final selectedCalendar = calendarsAsync.value?.firstWhere(
      (c) => c.rowId == _userCalendarRowId,
      orElse: () => calendarsAsync.value!.firstWhere(
        (c) => c.isDefault,
        orElse: () => calendarsAsync.value!.first,
      ),
    );

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
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

          PSectionLabel(l.calFieldDescription,
              variant: PSectionLabelVariant.header),
          const SizedBox(height: PSpace.x8),
          PTextInput(
            controller: _descCtrl,
            maxLines: 3,
            placeholder: l.calDescriptionPlaceholder,
          ),
          const SizedBox(height: PSpace.x16),

          // 캘린더
          PSectionLabel(l.calFieldCalendar,
              variant: PSectionLabelVariant.header),
          const SizedBox(height: PSpace.x8),
          calendarsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: PSpace.x8),
              child:
                  Center(child: SizedBox(height: PSpace.x16, width: PSpace.x16, child: PCircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (_, _) => Text(l.calCalendarLoadError,
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (cals) => PSelect<int>(
              value: selectedCalendar?.rowId,
              placeholder: l.calSelectCalendar,
              onChanged: (v) {
                if (v != null) setState(() => _userCalendarRowId = v);
              },
              items: [
                for (final c in cals)
                  PSelectItem<int>(
                    value: c.rowId,
                    label: c.calendarName,
                    leading: _labelDot(
                        solidSwatchColor(context, c.color, fallback: t.fgBrand)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 라벨
          PSectionLabel(l.calFieldLabel,
              variant: PSectionLabelVariant.header, icon: LucideIcons.tag),
          const SizedBox(height: PSpace.x8),
          // web EventForm 정합 — chip 나열 대신 Select ('라벨이 없습니다' + 색 점)
          labelsAsync.when(
            loading: () => const SizedBox(
                height: PSpace.x32,
                child: Center(child: PCircularProgressIndicator())),
            error: (_, _) => Text(l.calLabelLoadError,
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (labels) => PSelect<int>(
              value: _labelRowId ?? 0,
              onChanged: (v) =>
                  setState(() => _labelRowId = v == 0 ? null : v),
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
                    leading: _labelDot(solidSwatchColor(context, l.color,
                        fallback: t.fgBrand)),
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
              Text(l.calAllDay,
                  style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
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
                      PSectionLabel(l.calFieldStartDate,
                          variant: PSectionLabelVariant.header),
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
                      PSectionLabel(l.calFieldEndDate,
                          variant: PSectionLabelVariant.header),
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
            PSectionLabel(l.calFieldStartDate,
                variant: PSectionLabelVariant.header),
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
            PSectionLabel(l.calFieldEndDate,
                variant: PSectionLabelVariant.header),
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
          PSectionLabel(l.calLocation,
              variant: PSectionLabelVariant.header, icon: LucideIcons.mapPin),
          const SizedBox(height: PSpace.x8),
          PTextInput(
            controller: _locationCtrl,
            placeholder: l.calLocationPlaceholder,
          ),
          const SizedBox(height: PSpace.x16),

          // 반복
          PSectionLabel(l.calRepeat,
              variant: PSectionLabelVariant.header, icon: LucideIcons.repeat),
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
          PSectionLabel(l.calFieldReminder,
              variant: PSectionLabelVariant.header, icon: LucideIcons.bell),
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
