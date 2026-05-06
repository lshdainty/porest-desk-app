import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/network/api_exception.dart';
import '../application/calendar_providers.dart';
import '../domain/calendar_event.dart';

void showCalendarEventDialog(
  BuildContext context, {
  CalendarEvent? edit,
  DateTime? defaultDate,
}) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: Text(edit == null ? '이벤트 추가' : '이벤트 수정'),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor:
            Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: Navigator.of(modalCtx).pop,
        ),
        child: _Body(edit: edit, defaultDate: defaultDate),
      ),
    ],
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({this.edit, this.defaultDate});
  final CalendarEvent? edit;
  final DateTime? defaultDate;
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
    } else {
      final d = widget.defaultDate ?? DateTime.now();
      _start = DateTime(d.year, d.month, d.day, 9, 0);
      _end = DateTime(d.year, d.month, d.day, 10, 0);
      _allDay = false;
    }
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

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      final monthKey = (year: _start.year, month: _start.month);
      if (_isEdit) {
        await repo.updateEvent(
          id: widget.edit!.rowId,
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
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
      // 이전 month 도 invalidate (수정 시 날짜 변경 가능성)
      if (_isEdit) {
        final orig = widget.edit!.start;
        if (orig.year != _start.year || orig.month != _start.month) {
          ref.invalidate(monthEventsProvider(
              (year: orig.year, month: orig.month)));
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '이벤트가 수정되었습니다' : '이벤트가 추가되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이벤트 삭제'),
        content: Text('"${widget.edit!.title}" 이벤트를 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: context.tokens.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      await repo.deleteEvent(widget.edit!.rowId);
      final monthKey = (year: _start.year, month: _start.month);
      ref.invalidate(monthEventsProvider(monthKey));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
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
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(cur));
    if (t == null || !mounted) return;
    setState(() {
      final next = DateTime(cur.year, cur.month, cur.day, t.hour, t.minute);
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
    final labelsAsync = ref.watch(eventLabelsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('제목', style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: '예: 가족 식사'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x12),

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('종일',
                style: PTypo.body.copyWith(color: t.fgPrimary)),
            value: _allDay,
            onChanged: (v) => setState(() => _allDay = v),
          ),
          const SizedBox(height: PSpace.x4),

          // 시작
          Text('시작', style: PTypo.caption.copyWith(color: t.fgSecondary)),
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
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
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

          Text('종료', style: PTypo.caption.copyWith(color: t.fgSecondary)),
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
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
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

          Text('라벨 (선택)',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          labelsAsync.when(
            loading: () => const SizedBox(
                height: 32,
                child: Center(child: CircularProgressIndicator())),
            error: (_, _) => Text('라벨 로드 실패',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (labels) => labels.isEmpty
                ? Text('등록된 라벨이 없습니다',
                    style:
                        PTypo.caption.copyWith(color: t.fgTertiary))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _LabelChip(
                        label: '없음',
                        color: t.fgTertiary,
                        selected: _labelRowId == null,
                        onTap: () => setState(() => _labelRowId = null),
                        tokens: t,
                      ),
                      for (final l in labels)
                        _LabelChip(
                          label: l.labelName,
                          color: parseColor(l.color, fallback: t.fgBrand),
                          selected: _labelRowId == l.rowId,
                          onTap: () =>
                              setState(() => _labelRowId = l.rowId),
                          tokens: t,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: PSpace.x12),

          Text('장소 (선택)',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(hintText: '예: 강남역 1번 출구'),
          ),
          const SizedBox(height: PSpace.x12),

          Text('메모 (선택)',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: '추가 메모'),
          ),
          const SizedBox(height: PSpace.x24),

          Row(
            children: [
              if (_isEdit) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.statusDanger,
                      side: BorderSide(
                          color: t.statusDanger.withValues(alpha: 0.5)),
                    ),
                    onPressed: _submitting ? null : _delete,
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('삭제'),
                  ),
                ),
                const SizedBox(width: PSpace.x8),
              ],
              Expanded(
                flex: _isEdit ? 1 : 2,
                child: FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? '수정' : '추가'),
                ),
              ),
            ],
          ),
        ],
      ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.bgMuted,
          borderRadius: PRadius.brMd,
          border: Border.all(color: tokens.borderDefault),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: tokens.fgSecondary),
            const SizedBox(width: 6),
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

class _LabelChip extends StatelessWidget {
  const _LabelChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : tokens.bgSurface,
          border: Border.all(
              color: selected ? color : tokens.borderDefault,
              width: selected ? 1.5 : 1),
          borderRadius: PRadius.brPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: PTypo.caption.copyWith(
                    color: tokens.fgPrimary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
