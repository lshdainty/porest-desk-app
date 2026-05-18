import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_chip.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_progress.dart';
import '../../../shared/widgets/p_section_label.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_switch.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/calendar_providers.dart';
import '../domain/calendar_event.dart';
import '../domain/user_calendar.dart';

void showCalendarEventDialog(
  BuildContext context, {
  CalendarEvent? edit,
  DateTime? defaultDate,
}) {
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? '일정 추가' : '일정 수정',
    contentBuilder: (ctx, scrollCtrl) => _Body(
      edit: edit,
      defaultDate: defaultDate,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit != null ? '수정' : '저장',
    ),
  ).whenComplete(controller.dispose);
}

const _colorOptions = <String>[
  '#3b82f6',
  '#ef4444',
  '#22c55e',
  '#f59e0b',
  '#8b5cf6',
  '#ec4899',
  '#06b6d4',
  '#f97316',
];

enum _RecurrenceOption { none, daily, weekly, monthly, yearly }

const _recurrenceLabels = <_RecurrenceOption, String>{
  _RecurrenceOption.none: '반복 없음',
  _RecurrenceOption.daily: '매일',
  _RecurrenceOption.weekly: '매주',
  _RecurrenceOption.monthly: '매월',
  _RecurrenceOption.yearly: '매년',
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

String _reminderLabel(int min) {
  if (min < 60) return '$min분 전';
  if (min == 60) return '1시간 전';
  if (min == 1440) return '1일 전';
  return '$min분 전';
}

Future<void> _confirmDelete(BuildContext ctx, CalendarEvent edit) async {
  final container = ProviderScope.containerOf(ctx, listen: false);
  final ok = await showPConfirmDialog(
    ctx,
    title: '일정 삭제',
    message: '"${edit.title}" 일정을 삭제할까요?',
    confirmLabel: '삭제',
    destructive: true,
  );
  if (!ok) return;
  try {
    final repo = await container.read(calendarRepositoryProvider.future);
    await repo.deleteEvent(edit.rowId);
    container.invalidate(monthEventsProvider(
        (year: edit.start.year, month: edit.start.month)));
  } on ApiException catch (e) {
    if (!ctx.mounted) return;
    showPSnackBar(ctx, '삭제 실패: ${e.message}', severity: PSnackSeverity.error);
    return;
  }
  if (!ctx.mounted) return;
  Navigator.of(ctx).pop();
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
  String _color = _colorOptions[4]; // violet 기본
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
      _userCalendarRowId = e.userRowId;
      _color = e.color ?? _colorOptions[4];
      _recurrence = _rruleToRecurrence(e.rrule);
    } else {
      final d = widget.defaultDate ?? DateTime.now();
      _start = DateTime(d.year, d.month, d.day, 9, 0);
      _end = DateTime(d.year, d.month, d.day, 10, 0);
      _allDay = false;
    }
    widget.controller.onSubmit = _submit;
    if (widget.edit != null) {
      widget.controller.onDelete = () => _confirmDelete(context, widget.edit!);
    }
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
      showPSnackBar(context, _isEdit ? '일정이 수정되었습니다' : '일정이 추가되었습니다', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _syncController();
      }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final cur = isStart ? _start : _end;
    final d = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d == null || !mounted) return;
    setState(() {
      final next = DateTime(d.year, d.month, d.day, cur.hour, cur.minute);
      if (isStart) {
        _start = next;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = next;
      }
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final cur = isStart ? _start : _end;
    final picked = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(cur));
    if (picked == null || !mounted) return;
    setState(() {
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

  Future<void> _pickCalendar(List<UserCalendar> cals) async {
    final res = await showPSheet<int>(
      context,
      title: '캘린더 선택',
      contentBuilder: (sheetCtx, scrollCtrl) {
        final t = sheetCtx.tokens;
        return ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(
              PSpace.x8, 0, PSpace.x8, PSpace.x16),
          children: [
            for (final c in cals)
              ListTile(
                leading: Container(
                  width: PSpace.x12,
                  height: PSpace.x12,
                  decoration: BoxDecoration(
                    color: parseColor(c.color, fallback: t.fgBrand),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(c.calendarName),
                trailing: c.rowId == _userCalendarRowId
                    ? Icon(LucideIcons.check, color: t.fgBrand)
                    : null,
                onTap: () => Navigator.pop(sheetCtx, c.rowId),
              ),
          ],
        );
      },
      initialChildSize: 0.5,
      minChildSize: 0.3,
    );
    if (res != null) setState(() => _userCalendarRowId = res);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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
          PSectionLabel('제목', variant: PSectionLabelVariant.header),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _titleCtrl,
            placeholder: '예: 가족 식사',
            onChanged: (_) {
              setState(() {});
              _syncController();
            },
          ),
          const SizedBox(height: PSpace.x16),

          PSectionLabel('설명', variant: PSectionLabelVariant.header),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _descCtrl,
            maxLines: 3,
            placeholder: '추가 설명 (선택)',
          ),
          const SizedBox(height: PSpace.x16),

          // 캘린더
          PSectionLabel('캘린더', variant: PSectionLabelVariant.header),
          const SizedBox(height: PSpace.x4),
          calendarsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: PSpace.x8),
              child:
                  Center(child: SizedBox(height: PSpace.x16, width: PSpace.x16, child: PCircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (_, _) => Text('캘린더 로드 실패',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (cals) => InkWell(
              onTap: cals.isEmpty ? null : () => _pickCalendar(cals),
              borderRadius: PRadius.brMd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: PSpace.x12, vertical: PSpace.x12),
                decoration: BoxDecoration(
                  color: t.bgMuted,
                  borderRadius: PRadius.brMd,
                  border: Border.all(color: t.borderDefault),
                ),
                child: Row(
                  children: [
                    if (selectedCalendar != null) ...[
                      Container(
                        width: PSpace.x12,
                        height: PSpace.x12,
                        decoration: BoxDecoration(
                          color: parseColor(selectedCalendar.color,
                              fallback: t.fgBrand),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: PSpace.x8),
                      Text(selectedCalendar.calendarName,
                          style: PTypo.bodySm
                              .copyWith(color: t.fgPrimary)),
                    ] else
                      Text('캘린더 없음',
                          style:
                              PTypo.bodySm.copyWith(color: t.fgTertiary)),
                    const Spacer(),
                    Icon(LucideIcons.chevronDown,
                        size: PSpace.x16, color: t.fgTertiary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 라벨
          PSectionLabel('라벨', variant: PSectionLabelVariant.header, icon: LucideIcons.tag),
          const SizedBox(height: PSpace.x8),
          labelsAsync.when(
            loading: () => const SizedBox(
                height: PSpace.x32,
                child: Center(child: PCircularProgressIndicator())),
            error: (_, _) => Text('라벨 로드 실패',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (labels) => labels.isEmpty
                ? Text('라벨이 없습니다',
                    style: PTypo.caption.copyWith(color: t.fgTertiary))
                : Wrap(
                    spacing: PSpace.x8,
                    runSpacing: PSpace.x8,
                    children: [
                      PChip(
                        label: '없음',
                        color: t.fgTertiary,
                        dotColor: t.fgTertiary,
                        variant: PChipVariant.subtle,
                        selected: _labelRowId == null,
                        onTap: () => setState(() => _labelRowId = null),
                      ),
                      for (final l in labels)
                        PChip(
                          label: l.labelName,
                          color: parseColor(l.color, fallback: t.fgBrand),
                          dotColor: parseColor(l.color, fallback: t.fgBrand),
                          variant: PChipVariant.subtle,
                          selected: _labelRowId == l.rowId,
                          onTap: () =>
                              setState(() => _labelRowId = l.rowId),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: PSpace.x16),

          // 색상
          PSectionLabel('색상', variant: PSectionLabelVariant.header),
          const SizedBox(height: PSpace.x8),
          Wrap(
            spacing: PSpace.x12,
            runSpacing: PSpace.x8,
            children: [
              for (final c in _colorOptions)
                _ColorSphere(
                  color: parseColor(c, fallback: t.fgBrand),
                  selected: _color.toLowerCase() == c.toLowerCase(),
                  onTap: () => setState(() => _color = c),
                  tokens: t,
                ),
            ],
          ),
          const SizedBox(height: PSpace.x16),

          // 종일
          PSwitchTile(
            title: '종일',
            value: _allDay,
            onChanged: (v) => setState(() => _allDay = v),
          ),
          const SizedBox(height: PSpace.x4),

          // 시작
          PSectionLabel('시작일', variant: PSectionLabelVariant.header),
          const SizedBox(height: PSpace.x4),
          Row(
            children: [
              Expanded(
                child: _DateTimeBox(
                  icon: LucideIcons.calendar,
                  label:
                      '${_start.year}-${_start.month.toString().padLeft(2, '0')}-${_start.day.toString().padLeft(2, '0')}',
                  onTap: () => _pickDate(true),
                  tokens: t,
                ),
              ),
              if (!_allDay) ...[
                const SizedBox(width: PSpace.x8),
                SizedBox(
                  width: PSpace.x80 + PSpace.x20,
                  child: _DateTimeBox(
                    icon: LucideIcons.clock,
                    label:
                        '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
                    onTap: () => _pickTime(true),
                    tokens: t,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: PSpace.x12),

          PSectionLabel('종료일', variant: PSectionLabelVariant.header),
          const SizedBox(height: PSpace.x4),
          Row(
            children: [
              Expanded(
                child: _DateTimeBox(
                  icon: LucideIcons.calendar,
                  label:
                      '${_end.year}-${_end.month.toString().padLeft(2, '0')}-${_end.day.toString().padLeft(2, '0')}',
                  onTap: () => _pickDate(false),
                  tokens: t,
                ),
              ),
              if (!_allDay) ...[
                const SizedBox(width: PSpace.x8),
                SizedBox(
                  width: PSpace.x80 + PSpace.x20,
                  child: _DateTimeBox(
                    icon: LucideIcons.clock,
                    label:
                        '${_end.hour.toString().padLeft(2, '0')}:${_end.minute.toString().padLeft(2, '0')}',
                    onTap: () => _pickTime(false),
                    tokens: t,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: PSpace.x16),

          // 장소
          PSectionLabel('장소', variant: PSectionLabelVariant.header, icon: LucideIcons.mapPin),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _locationCtrl,
            placeholder: '장소를 입력하세요',
          ),
          const SizedBox(height: PSpace.x16),

          // 반복
          PSectionLabel('반복', variant: PSectionLabelVariant.header, icon: LucideIcons.repeat),
          const SizedBox(height: PSpace.x8),
          Wrap(
            spacing: PSpace.x8,
            runSpacing: PSpace.x8,
            children: [
              for (final r in _RecurrenceOption.values)
                PChip(
                  label: _recurrenceLabels[r]!,
                  variant: PChipVariant.subtle,
                  selected: _recurrence == r,
                  onTap: () => setState(() => _recurrence = r),
                ),
            ],
          ),
          const SizedBox(height: PSpace.x16),

          // 알림
          PSectionLabel('알림', variant: PSectionLabelVariant.header, icon: LucideIcons.bell),
          const SizedBox(height: PSpace.x8),
          Wrap(
            spacing: PSpace.x8,
            runSpacing: PSpace.x8,
            children: [
              for (final m in _reminderOptions)
                PChip(
                  label: _reminderLabel(m),
                  variant: PChipVariant.subtle,
                  selected: _reminders.contains(m),
                  onTap: () => setState(() {
                    if (!_reminders.add(m)) _reminders.remove(m);
                  }),
                ),
            ],
          ),
      ],
    );
  }
}

class _DateTimeBox extends StatelessWidget {
  const _DateTimeBox({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tokens,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x12, vertical: PSpace.x12),
        decoration: BoxDecoration(
          color: tokens.bgMuted,
          borderRadius: PRadius.brMd,
          border: Border.all(color: tokens.borderDefault),
        ),
        child: Row(
          children: [
            Icon(icon, size: PSpace.x16, color: tokens.fgSecondary),
            const SizedBox(width: PSpace.x4),
            Expanded(
              child: Text(label,
                  style: PTypo.bodySm.copyWith(color: tokens.fgPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}


class _ColorSphere extends StatelessWidget {
  const _ColorSphere({
    required this.color,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: PSpace.x32,
        height: PSpace.x32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: tokens.fgBrand, width: 2.5)
              : null,
        ),
      ),
    );
  }
}
