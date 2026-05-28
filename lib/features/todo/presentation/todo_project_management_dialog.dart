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
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../application/todo_providers.dart';
import '../domain/todo_project.dart';

/// Todo 프로젝트 관리 다이얼로그 — front `ProjectManagementDialog` 미러.
///
/// 신규: 이름 + 설명(선택) + 색 팔레트 + 추가
/// 기존: 인라인 편집 + 삭제
void showTodoProjectManagementDialog(BuildContext context) {
  showPSheet<void>(
    context,
    title: '프로젝트 관리',
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
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _color = _palette.first;
  bool _adding = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      final repo = await ref.read(todoProjectRepositoryProvider.future);
      await repo.create(
        projectName: name,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        color: _color,
      );
      ref.invalidate(todoProjectListProvider);
      _nameCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _color = _palette.first;
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
    final projectsAsync = ref.watch(todoProjectListProvider);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          Text('새 프로젝트',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          PTextInput(
            controller: _nameCtrl,
            enabled: !_adding,
            placeholder: '프로젝트 이름',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x8),
          PTextInput(
            controller: _descCtrl,
            enabled: !_adding,
            placeholder: '설명 (선택)',
          ),
          const SizedBox(height: PSpace.x8),
          _Palette(
            selected: _color,
            onChanged: (c) => setState(() => _color = c),
            tokens: t,
          ),
          const SizedBox(height: PSpace.x8),
          PButton(
            label: _adding ? '추가 중...' : '프로젝트 추가',
            icon: LucideIcons.plus,
            loading: _adding,
            fullWidth: true,
            onPressed:
                (_nameCtrl.text.trim().isEmpty || _adding) ? null : _create,
          ),
          const SizedBox(height: PSpace.x20),
          PDivider(),
          const SizedBox(height: PSpace.x16),
          Text('등록된 프로젝트',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          projectsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: PSpace.x8),
              child: PListSkeleton(rows: 3),
            ),
            error: (e, _) => Text('프로젝트 로드 실패: $e',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (projects) {
              if (projects.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                  child: Center(
                    child: Text('등록된 프로젝트가 없습니다',
                        style:
                            PTypo.caption.copyWith(color: t.fgTertiary)),
                  ),
                );
              }
              return Column(
                children: [
                  for (final p in projects)
                    _ProjectRow(project: p, tokens: t),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ProjectRow extends ConsumerStatefulWidget {
  const _ProjectRow({required this.project, required this.tokens});
  final TodoProject project;
  final PorestTokens tokens;
  @override
  ConsumerState<_ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends ConsumerState<_ProjectRow> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _color;
  bool _expanded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.project.projectName);
    _descCtrl = TextEditingController(text: widget.project.description ?? '');
    _color = widget.project.color ?? _palette.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(todoProjectRepositoryProvider.future);
      await repo.update(
        id: widget.project.rowId,
        projectName: name,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        color: _color,
      );
      ref.invalidate(todoProjectListProvider);
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
      title: '프로젝트 삭제',
      message:
          '"${widget.project.projectName}" 프로젝트를 삭제하시겠어요? 연결된 할 일은 프로젝트 미지정으로 변경됩니다.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(todoProjectRepositoryProvider.future);
      await repo.delete(widget.project.rowId);
      ref.invalidate(todoProjectListProvider);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PTextInput(
                      controller: _nameCtrl,
                      enabled: _expanded && !_busy,
                      style: PTypo.bodySm
                          .copyWith(fontWeight: PFontWeight.semi),
                    ),
                    if ((_descCtrl.text).isNotEmpty || _expanded) ...[
                      const SizedBox(height: PSpace.x4),
                      PTextInput(
                        controller: _descCtrl,
                        enabled: _expanded && !_busy,
                        placeholder: '설명',
                        style: PTypo.caption,
                      ),
                    ],
                  ],
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
                            _nameCtrl.text = widget.project.projectName;
                            _descCtrl.text = widget.project.description ?? '';
                            _color = widget.project.color ?? _palette.first;
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
