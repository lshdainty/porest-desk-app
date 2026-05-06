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
import '../application/todo_providers.dart';
import '../domain/todo_tag.dart';

/// Todo 태그 관리 다이얼로그 — front `TagManagementDialog` 미러.
void showTodoTagManagementDialog(BuildContext context) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: const Text('태그 관리'),
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
      final repo = await ref.read(todoTagRepositoryProvider.future);
      await repo.create(tagName: name, color: _newColor);
      ref.invalidate(todoTagListProvider);
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
    final tagsAsync = ref.watch(todoTagListProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('새 태그',
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
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: TextField(
                  controller: _newCtrl,
                  enabled: !_adding,
                  decoration: const InputDecoration(hintText: '태그 이름'),
                  onSubmitted: (_) => _create(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: PSpace.x8),
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
          const SizedBox(height: PSpace.x8),
          _Palette(
            selected: _newColor,
            onChanged: (c) => setState(() => _newColor = c),
            tokens: t,
          ),
          const SizedBox(height: PSpace.x20),
          Divider(height: 1, color: t.borderSubtle),
          const SizedBox(height: PSpace.x16),
          Text('등록된 태그',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: PSpace.x8),
          tagsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('태그 로드 실패: $e',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (tags) {
              if (tags.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                  child: Center(
                    child: Text('등록된 태그가 없습니다',
                        style:
                            PTypo.caption.copyWith(color: t.fgTertiary)),
                  ),
                );
              }
              return Column(
                children: [for (final tag in tags) _TagRow(tag: tag, tokens: t)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TagRow extends ConsumerStatefulWidget {
  const _TagRow({required this.tag, required this.tokens});
  final TodoTag tag;
  final PorestTokens tokens;
  @override
  ConsumerState<_TagRow> createState() => _TagRowState();
}

class _TagRowState extends ConsumerState<_TagRow> {
  late final TextEditingController _ctrl;
  late String _color;
  bool _expanded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.tag.tagName);
    _color = widget.tag.color ?? _palette.first;
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
      final repo = await ref.read(todoTagRepositoryProvider.future);
      await repo.update(id: widget.tag.rowId, tagName: name, color: _color);
      ref.invalidate(todoTagListProvider);
      if (!mounted) return;
      setState(() {
        _expanded = false;
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 실패: ${e.message}')),
      );
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('태그 삭제'),
        content: Text('"${widget.tag.tagName}" 태그를 삭제하시겠어요?'),
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
      final repo = await ref.read(todoTagRepositoryProvider.future);
      await repo.delete(widget.tag.rowId);
      ref.invalidate(todoTagListProvider);
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
                child: TextField(
                  controller: _ctrl,
                  enabled: _expanded && !_busy,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: PTypo.bodySm.copyWith(color: t.fgPrimary),
                ),
              ),
              IconButton(
                icon: Icon(_expanded ? LucideIcons.x : LucideIcons.pencil,
                    size: 16, color: t.fgSecondary),
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _expanded = !_expanded;
                          if (!_expanded) {
                            _ctrl.text = widget.tag.tagName;
                            _color = widget.tag.color ?? _palette.first;
                          }
                        }),
              ),
              IconButton(
                icon: Icon(LucideIcons.trash2,
                    size: 16, color: t.statusDanger),
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
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('저장'),
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
