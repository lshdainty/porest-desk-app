import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_progress.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/calendar_providers.dart';
import '../domain/event_label.dart';

/// 캘린더 라벨 관리 다이얼로그 — front `LabelManagementDialog` 미러.
///
/// 라벨 CRUD: 색상 선택, 이름 수정/삭제. 신규 라벨 추가 폼이 상단에 있고,
/// 그 아래 기존 라벨 리스트(인라인 편집).
void showEventLabelManagementDialog(BuildContext context) {
  showPSheet<void>(
    context,
    title: '라벨 관리',
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
  final _newNameCtrl = TextEditingController();
  String _newColor = _palette.first;
  bool _adding = false;

  @override
  void dispose() {
    _newNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _newNameCtrl.text.trim();
    if (name.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      await repo.createLabel(labelName: name, color: _newColor);
      ref.invalidate(eventLabelsProvider);
      _newNameCtrl.clear();
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
    final labelsAsync = ref.watch(eventLabelsProvider);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          // 새 라벨 추가
          Text('새 라벨',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          Row(
            children: [
              _ColorDot(
                color: solidSwatchColor(context, _newColor, fallback: t.fgBrand),
                size: 28,
              ),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: PTextInput(
                  controller: _newNameCtrl,
                  enabled: !_adding,
                  placeholder: '라벨 이름',
                  onSubmitted: (_) => _create(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: PSpace.x8),
              PButton(
                label: '추가',
                loading: _adding,
                onPressed: (_newNameCtrl.text.trim().isEmpty || _adding)
                    ? null
                    : _create,
              ),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          _PaletteRow(
            selected: _newColor,
            onChanged: (c) => setState(() => _newColor = c),
            tokens: t,
          ),
          const SizedBox(height: PSpace.x20),
          PDivider(),
          const SizedBox(height: PSpace.x16),

          // 기존 라벨 리스트
          Text('등록된 라벨',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          labelsAsync.when(
            loading: () => const Center(child: PCircularProgressIndicator()),
            error: (e, _) => Text('라벨 로드 실패: $e',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (labels) {
              if (labels.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                  child: Center(
                    child: Text('등록된 라벨이 없습니다',
                        style:
                            PTypo.caption.copyWith(color: t.fgTertiary)),
                  ),
                );
              }
              return Column(
                children: [
                  for (final l in labels) _LabelRow(label: l, tokens: t),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _LabelRow extends ConsumerStatefulWidget {
  const _LabelRow({required this.label, required this.tokens});
  final EventLabel label;
  final PorestTokens tokens;
  @override
  ConsumerState<_LabelRow> createState() => _LabelRowState();
}

class _LabelRowState extends ConsumerState<_LabelRow> {
  late final TextEditingController _ctrl;
  late String _color;
  bool _expanded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.label.labelName);
    _color = widget.label.color ?? _palette.first;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      await repo.updateLabel(id: widget.label.rowId, labelName: name, color: _color);
      ref.invalidate(eventLabelsProvider);
      if (!mounted) return;
      setState(() {
        _expanded = false;
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showPSnackBar(context, '수정 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _delete() async {
    final ok = await showPConfirmDialog(
      context,
      title: '라벨 삭제',
      message:
          '"${widget.label.labelName}" 라벨을 삭제하시겠어요? 이 라벨이 적용된 이벤트는 라벨이 해제됩니다.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      await repo.deleteLabel(widget.label.rowId);
      ref.invalidate(eventLabelsProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showPSnackBar(context, '삭제 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final color = solidSwatchColor(context, _color, fallback: t.fgBrand);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ColorDot(color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: PTextInput(
                  controller: _ctrl,
                  enabled: _expanded && !_busy,
                  style: PTypo.bodySm,
                ),
              ),
              PButton.icon(
                icon: _expanded ? LucideIcons.x : LucideIcons.pencil,
                size: PButtonSize.sm,
                onPressed: _busy
                    ? null
                    : () {
                        setState(() {
                          _expanded = !_expanded;
                          if (!_expanded) {
                            _ctrl.text = widget.label.labelName;
                            _color = widget.label.color ?? _palette.first;
                          }
                        });
                      },
              ),
              PButton.icon(
                icon: LucideIcons.trash2,
                size: PButtonSize.sm,
                iconColor: t.statusDanger,
                onPressed: _busy ? null : _delete,
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            _PaletteRow(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
              tokens: t,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: PButton(
                label: '저장',
                loading: _busy,
                onPressed: _busy ? null : _save,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow(
      {required this.selected,
      required this.onChanged,
      required this.tokens});
  final String selected;
  final ValueChanged<String> onChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in _palette)
          GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: solidSwatchColor(context, c, fallback: tokens.fgBrand),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      c == selected ? tokens.fgPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: c == selected
                  ? Icon(LucideIcons.check,
                      size: 14,
                      // light fill(다크모드) 위에서도 보이도록 명도 기준 대비 색.
                      color: ThemeData.estimateBrightnessForColor(solidSwatchColor(
                                  context, c, fallback: tokens.fgBrand)) ==
                              Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1A1F2E))
                  : null,
            ),
          ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, this.size = 20});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
