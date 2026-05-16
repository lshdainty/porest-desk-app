import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_select.dart';
import '../application/memo_providers.dart';
import '../domain/memo_folder.dart';

/// 메모 폴더 트리 관리 — front `MemoFolderTree` 미러 (CRUD).
void showMemoFolderManagementDialog(BuildContext context) {
  showPSheet<void>(
    context,
    title: '폴더 관리',
    contentBuilder: (ctx, scrollCtrl) => _Body(scrollController: scrollCtrl),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.scrollController});
  final ScrollController scrollController;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _newCtrl = TextEditingController();
  int? _newParentId;
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
      final repo = await ref.read(memoFolderRepositoryProvider.future);
      await repo.create(folderName: name, parentId: _newParentId);
      ref.invalidate(memoFolderListProvider);
      _newCtrl.clear();
      setState(() {
        _newParentId = null;
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
    final treeAsync = ref.watch(memoFolderTreeProvider);
    final flatAsync = ref.watch(memoFolderListProvider);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          Text('새 폴더',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          TextField(
            controller: _newCtrl,
            enabled: !_adding,
            decoration: const InputDecoration(hintText: '폴더 이름'),
            onSubmitted: (_) => _create(),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('부모',
                  style: PTypo.caption.copyWith(color: t.fgSecondary)),
              const SizedBox(width: 8),
              Expanded(
                child: flatAsync.when(
                  data: (folders) => PSelect<int?>(
                    value: _newParentId,
                    placeholder: '루트',
                    enabled: !_adding,
                    onChanged: (v) => setState(() => _newParentId = v),
                    items: [
                      const PSelectItem<int?>(value: null, label: '루트'),
                      for (final f in folders)
                        PSelectItem<int?>(
                            value: f.rowId, label: f.folderName),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
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
          const SizedBox(height: PSpace.x16),
          Divider(height: 1, color: t.borderSubtle),
          const SizedBox(height: PSpace.x16),
          Text('폴더 트리',
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          treeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('폴더 로드 실패: $e',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (roots) {
              if (roots.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                  child: Center(
                    child: Text('등록된 폴더가 없습니다',
                        style:
                            PTypo.caption.copyWith(color: t.fgTertiary)),
                  ),
                );
              }
              return Column(
                children: [
                  for (final root in roots) _Node(node: root, depth: 0, tokens: t),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _Node extends ConsumerStatefulWidget {
  const _Node(
      {required this.node, required this.depth, required this.tokens});
  final MemoFolderNode node;
  final int depth;
  final PorestTokens tokens;
  @override
  ConsumerState<_Node> createState() => _NodeState();
}

class _NodeState extends ConsumerState<_Node> {
  bool _editing = false;
  bool _busy = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.node.folder.folderName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(memoFolderRepositoryProvider.future);
      await repo.update(
        id: widget.node.folder.rowId,
        folderName: name,
        parentId: widget.node.folder.parentId,
      );
      ref.invalidate(memoFolderListProvider);
      if (!mounted) return;
      setState(() {
        _editing = false;
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
    final ok = await showPConfirmDialog(
      context,
      title: '폴더 삭제',
      message:
          '"${widget.node.folder.folderName}" 폴더와 하위 폴더를 모두 삭제할까요? 폴더 내 메모는 폴더가 해제됩니다.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(memoFolderRepositoryProvider.future);
      await repo.delete(widget.node.folder.rowId);
      ref.invalidate(memoFolderListProvider);
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
    return Padding(
      padding: EdgeInsets.only(left: widget.depth * 16.0, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: t.bgSurface,
              borderRadius: PRadius.brSm,
              border: Border.all(color: t.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.folder,
                    size: 14, color: t.fgSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    enabled: _editing && !_busy,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: PTypo.bodySm.copyWith(color: t.fgPrimary),
                  ),
                ),
                IconButton(
                  icon: Icon(_editing ? LucideIcons.check : LucideIcons.pencil,
                      size: 14, color: t.fgSecondary),
                  onPressed: _busy
                      ? null
                      : () {
                          if (_editing) {
                            _save();
                          } else {
                            setState(() => _editing = true);
                          }
                        },
                ),
                IconButton(
                  icon: Icon(LucideIcons.trash2,
                      size: 14, color: t.statusDanger),
                  onPressed: _busy ? null : _delete,
                ),
              ],
            ),
          ),
          for (final c in widget.node.children)
            _Node(node: c, depth: widget.depth + 1, tokens: t),
        ],
      ),
    );
  }
}
