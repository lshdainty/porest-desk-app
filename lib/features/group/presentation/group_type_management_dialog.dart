import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_progress.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/group_providers.dart';
import '../domain/group_type.dart';

/// 그룹 타입 관리 다이얼로그 — front `GroupTypeManagementDialog` 미러.
void showGroupTypeManagementDialog(BuildContext context) {
  showPSheet<void>(
    context,
    title: '그룹 타입 관리',
    contentBuilder: (ctx, scrollCtrl) => _Body(scrollController: scrollCtrl),
  );
}

const _palette = <String>[
  '#16a34a', '#2563eb', '#f59e0b', '#ef4444',
  '#a855f7', '#ec4899', '#06b6d4', '#64748b',
];

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
      final repo = await ref.read(groupTypeRepositoryProvider.future);
      await repo.create(typeName: name, color: _newColor);
      ref.invalidate(groupTypeListProvider);
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
    final typesAsync = ref.watch(groupTypeListProvider);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          Text('새 그룹 타입',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
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
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: PTextInput(
                  controller: _newCtrl,
                  enabled: !_adding,
                  placeholder: '예: 가족, 회사',
                  onSubmitted: (_) => _create(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: PSpace.x8),
              PButton(
                label: '추가',
                loading: _adding,
                onPressed:
                    (_newCtrl.text.trim().isEmpty || _adding) ? null : _create,
              ),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          _Palette(
            selected: _newColor,
            onChanged: (c) => setState(() => _newColor = c),
            tokens: t,
          ),
          const SizedBox(height: PSpace.x20),
          PDivider(),
          const SizedBox(height: PSpace.x16),
          Text('등록된 그룹 타입',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          typesAsync.when(
            loading: () => const Center(child: PCircularProgressIndicator()),
            error: (e, _) => Text('타입 로드 실패: $e',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (types) {
              if (types.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                  child: Center(
                    child: Text('등록된 타입이 없습니다',
                        style:
                            PTypo.caption.copyWith(color: t.fgTertiary)),
                  ),
                );
              }
              return Column(
                children: [for (final tp in types) _Row(type: tp, tokens: t)],
              );
            },
          ),
      ],
    );
  }
}

class _Row extends ConsumerStatefulWidget {
  const _Row({required this.type, required this.tokens});
  final GroupType type;
  final PorestTokens tokens;
  @override
  ConsumerState<_Row> createState() => _RowState();
}

class _RowState extends ConsumerState<_Row> {
  late final TextEditingController _ctrl;
  late String _color;
  bool _expanded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.type.typeName);
    _color = widget.type.color ?? _palette.first;
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
      final repo = await ref.read(groupTypeRepositoryProvider.future);
      await repo.update(
        id: widget.type.rowId,
        typeName: name,
        color: _color,
      );
      ref.invalidate(groupTypeListProvider);
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
      title: '타입 삭제',
      message:
          '"${widget.type.typeName}" 타입을 삭제하시겠어요? 이 타입을 사용하던 그룹은 타입 미지정 상태가 됩니다.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(groupTypeRepositoryProvider.future);
      await repo.delete(widget.type.rowId);
      ref.invalidate(groupTypeListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showPSnackBar(context, '삭제 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final color = parseColor(_color, fallback: t.fgBrand);
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
              Container(
                  width: 20, height: 20,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
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
                    : () => setState(() {
                          _expanded = !_expanded;
                          if (!_expanded) {
                            _ctrl.text = widget.type.typeName;
                            _color = widget.type.color ?? _palette.first;
                          }
                        }),
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
            _Palette(
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

class _Palette extends StatelessWidget {
  const _Palette({
    required this.selected,
    required this.onChanged,
    required this.tokens,
  });
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
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: parseColor(c, fallback: tokens.fgBrand),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      c == selected ? tokens.fgPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: c == selected
                  ? const Icon(LucideIcons.check,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ),
      ],
    );
  }
}
