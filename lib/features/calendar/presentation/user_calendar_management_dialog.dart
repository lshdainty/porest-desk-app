import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_badge.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_progress.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/calendar_providers.dart';
import '../domain/user_calendar.dart';

/// 사용자 다중 캘린더 관리 — front `CalendarManagementDialog` 미러.
void showUserCalendarManagementDialog(BuildContext context) {
  showPSheet<void>(
    context,
    title: '내 캘린더',
    contentBuilder: (ctx, scrollCtrl) => _Body(scrollController: scrollCtrl),
  );
}

const _palette = kChartBaseHexes;

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.scrollController});
  final ScrollController scrollController;
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
      showPSnackBar(context, '추가 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final async = ref.watch(userCalendarListProvider);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          Text('새 캘린더',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: solidSwatchColor(context, _newColor, fallback: t.fgBrand),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PTextInput(
                  controller: _newCtrl,
                  enabled: !_adding,
                  placeholder: '캘린더 이름',
                  onSubmitted: (_) => _create(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              PButton(
                label: '추가',
                loading: _adding,
                onPressed:
                    (_newCtrl.text.trim().isEmpty || _adding) ? null : _create,
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
                      color: solidSwatchColor(context, c, fallback: t.fgBrand),
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
          PDivider(),
          const SizedBox(height: PSpace.x16),
          Text('등록된 캘린더',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          async.when(
            loading: () => const Center(child: PCircularProgressIndicator()),
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
      showPSnackBar(context, '변경 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _delete() async {
    if (widget.cal.isDefault) return;
    final ok = await showPConfirmDialog(
      context,
      title: '캘린더 삭제',
      message:
          '"${widget.cal.calendarName}" 캘린더를 삭제할까요? 이 캘린더의 이벤트는 기본 캘린더로 이동합니다.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(userCalendarRepositoryProvider.future);
      await repo.delete(widget.cal.rowId);
      ref.invalidate(userCalendarListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showPSnackBar(context, '삭제 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final color = solidSwatchColor(context, widget.cal.color, fallback: t.fgBrand);
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
                          fontWeight: PFontWeight.semi)),
                ),
                if (widget.cal.isDefault) ...[
                  const SizedBox(width: 6),
                  const PBadge(
                      label: '기본', variant: PBadgeVariant.softBrand),
                ],
              ],
            ),
          ),
          PButton.icon(
            icon: widget.cal.isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
            size: PButtonSize.sm,
            iconColor:
                widget.cal.isVisible ? t.fgSecondary : t.fgTertiary,
            tooltip: widget.cal.isVisible ? '숨김 처리' : '표시',
            onPressed: _busy ? null : _toggle,
          ),
          if (!widget.cal.isDefault)
            PButton.icon(
              icon: LucideIcons.trash2,
              size: PButtonSize.sm,
              iconColor: t.statusDanger,
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
    );
  }
}
