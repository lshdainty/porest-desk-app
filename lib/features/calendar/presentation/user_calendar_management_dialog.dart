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
import '../domain/user_calendar.dart';

/// 사용자 다중 캘린더 관리 — front `CalendarManagementDialog` 미러.
void showUserCalendarManagementDialog(BuildContext context) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: const Text('내 캘린더'),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor:
            Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: Navigator.of(modalCtx).pop,
        ),
        child: const _Body(),
      ),
    ],
  );
}

const _palette = <String>[
  '#16a34a', '#2563eb', '#f59e0b', '#ef4444',
  '#a855f7', '#ec4899', '#06b6d4', '#64748b',
];

class _Body extends ConsumerStatefulWidget {
  const _Body();
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _newCtrl = TextEditingController();
  String _newColor = _palette.first;
  bool _adding = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _newCtrl.text.trim();
    if (name.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.create(calendarName: name, color: _newColor);
      ref.invalidate(userCalendarListProvider);
      _newCtrl.clear();
      setState(() {
        _newColor = _palette.first;
        _adding = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _adding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추가 실패: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final async = ref.watch(userCalendarListProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('새 캘린더',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: PSpace.x8),
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: parseColor(_newColor, fallback: t.fgBrand),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _newCtrl,
                  enabled: !_adding,
                  decoration: const InputDecoration(hintText: '캘린더 이름'),
                  onSubmitted: (_) => _create(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed:
                    (_newCtrl.text.trim().isEmpty || _adding) ? null : _create,
                child: _adding
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('추가'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (final c in _palette)
                GestureDetector(
                  onTap: () => setState(() => _newColor = c),
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: parseColor(c, fallback: t.fgBrand),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c == _newColor
                            ? t.fgPrimary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: PSpace.x16),
          Divider(height: 1, color: t.borderSubtle),
          const SizedBox(height: PSpace.x16),
          Text('등록된 캘린더',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: PSpace.x8),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('캘린더 로드 실패: $e',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (cals) {
              if (cals.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                  child: Center(
                    child: Text('등록된 캘린더가 없습니다',
                        style:
                            PTypo.caption.copyWith(color: t.fgTertiary)),
                  ),
                );
              }
              return Column(
                children: [
                  for (final c in cals) _Row(cal: c, tokens: t),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Row extends ConsumerStatefulWidget {
  const _Row({required this.cal, required this.tokens});
  final UserCalendar cal;
  final PorestTokens tokens;
  @override
  ConsumerState<_Row> createState() => _RowState();
}

class _RowState extends ConsumerState<_Row> {
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.toggleVisibility(widget.cal.rowId);
      ref.invalidate(userCalendarListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('변경 실패: ${e.message}')),
      );
    }
  }

  Future<void> _delete() async {
    if (widget.cal.isDefault) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('캘린더 삭제'),
        content: Text('"${widget.cal.calendarName}" 캘린더를 삭제할까요? 이 캘린더의 이벤트는 기본 캘린더로 이동합니다.'),
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
    setState(() => _busy = true);
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.delete(widget.cal.rowId);
      ref.invalidate(userCalendarListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final color = parseColor(widget.cal.color, fallback: t.fgBrand);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brSm,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
              width: 14, height: 14,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(widget.cal.calendarName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: FontWeight.w600)),
                ),
                if (widget.cal.isDefault) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.bgBrandSubtle,
                      borderRadius: PRadius.brXs,
                    ),
                    child: Text('기본',
                        style: PTypo.micro.copyWith(
                            color: t.fgBrand,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              widget.cal.isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
              size: 16,
              color: widget.cal.isVisible
                  ? t.fgSecondary
                  : t.fgTertiary,
            ),
            tooltip: widget.cal.isVisible ? '숨김 처리' : '표시',
            onPressed: _busy ? null : _toggle,
          ),
          if (!widget.cal.isDefault)
            IconButton(
              icon: Icon(LucideIcons.trash2,
                  size: 14, color: t.statusDanger),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
    );
  }
}
