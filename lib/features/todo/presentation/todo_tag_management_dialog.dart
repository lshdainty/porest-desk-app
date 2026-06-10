import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/todo/domain/todo_tag.dart';

/// Todo 태그 관리 다이얼로그 — front `TagManagementDialog` 미러.
void showTodoTagManagementDialog(BuildContext context) {
  showPSheet<void>(
    context,
    title: '태그 관리',
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
      showPSnackBar(context, '추가 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tagsAsync = ref.watch(todoTagListProvider);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          Text('새 태그',
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
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: PTextInput(
                  controller: _newCtrl,
                  enabled: !_adding,
                  placeholder: '태그 이름',
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
          PColorPicker(
            selected: _newColor,
            onChanged: (c) => setState(() => _newColor = c),
          ),
          const SizedBox(height: PSpace.x20),
          PDivider(),
          const SizedBox(height: PSpace.x16),
          Text('등록된 태그',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          tagsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: PSpace.x8),
              child: PListSkeleton(rows: 3),
            ),
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
      showPSnackBar(context, '수정 실패: ${e.message}', severity: PSnackSeverity.error);
    }
  }

  Future<void> _delete() async {
    final ok = await showPConfirmDialog(
      context,
      title: '태그 삭제',
      message: '"${widget.tag.tagName}" 태그를 삭제하시겠어요?',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(todoTagRepositoryProvider.future);
      await repo.delete(widget.tag.rowId);
      ref.invalidate(todoTagListProvider);
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
                            _ctrl.text = widget.tag.tagName;
                            _color = widget.tag.color ?? _palette.first;
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
            PColorPicker(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
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

