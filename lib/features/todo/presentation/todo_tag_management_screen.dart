import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/todo/domain/todo_tag.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// 할일 태그 관리 — design settings-todo-tags.jsx TodoTagManager 미러.
///
/// 설정 하위 풀스크린 화면(캘린더 라벨 화면 셸 정합). 태그 리스트(아이콘
/// 틴트 타일 + "할 일 N건에 사용 중" + 삭제) + 행 탭 → 이름+8 tone 스와치
/// 편집 시트, 하단 고스트 '새 태그' 행. 사용 건수는 category=태그명 클라 집계.
class TodoTagManagementScreen extends StatefulWidget {
  const TodoTagManagementScreen({super.key});

  @override
  State<TodoTagManagementScreen> createState() =>
      _TodoTagManagementScreenState();
}

class _TodoTagManagementScreenState extends State<TodoTagManagementScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.todoTagMgmt),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: _Body(scrollController: _scrollCtrl),
    );
  }
}

/// 8 tone — design TTAG_TONES(blue/green/violet/orange/pink/red/yellow/brown).
/// 저장은 hex(chart base) — 기존 백엔드 color 필드·solidSwatchColor 해석 그대로.
const _tagPalette = <String>[
  '#2c70bf', // blue
  '#2d8060', // green
  '#8b4dba', // violet
  '#b36418', // orange
  '#b83b7a', // pink
  '#c73838', // red
  '#8c7400', // yellow
  '#9a6536', // brown
];

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.scrollController});
  final ScrollController scrollController;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  static const TodoFilter _allFilter = (status: null, priority: null);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // 진입 시 갱신 — keepAlive provider 라 다른 클라이언트 변경 반영 위해 무효화.
    Future.microtask(() {
      if (mounted) ref.invalidate(todoTagListProvider);
    });
  }

  Future<void> _save(TodoTag? origin, String name, String color) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    try {
      final repo = await ref.read(todoTagRepositoryProvider.future);
      if (origin == null) {
        await repo.create(tagName: name, color: color);
      } else {
        await repo.update(id: origin.rowId, tagName: name, color: color);
      }
      ref.invalidate(todoTagListProvider);
      if (mounted) setState(() => _busy = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showPSnackBar(
        context,
        '${origin == null ? l.todoAddFailed : l.todoUpdateFailed}: ${e.message}',
        severity: PSnackSeverity.error,
      );
    }
  }

  Future<void> _delete(TodoTag tag, int usage) async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.todoDeleteTagTitle,
      message:
          '${l.todoDeleteTagConfirm(tag.tagName)}\n${l.ttagDeleteDesc(usage)}',
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(todoTagRepositoryProvider.future);
      await repo.delete(tag.rowId);
      ref.invalidate(todoTagListProvider);
      if (mounted) setState(() => _busy = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showPSnackBar(
        context,
        '${AppLocalizations.of(context).todoDeleteFailed}: ${e.message}',
        severity: PSnackSeverity.error,
      );
    }
  }

  Future<void> _openEdit(TodoTag? tag) async {
    final result = await showTodoTagEditSheet(context, tag: tag);
    if (result != null) {
      await _save(tag, result.name, result.color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final tagsAsync = ref.watch(todoTagListProvider);
    // 사용 건수 — 할일 category(태그명) 클라 집계 (design t.count).
    final todos = ref.watch(todoListProvider(_allFilter)).value;
    final usageByName = <String, int>{};
    if (todos != null) {
      for (final x in todos) {
        final v = x.category?.trim();
        if (v == null || v.isEmpty) continue;
        usageByName[v] = (usageByName[v] ?? 0) + 1;
      }
    }

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x20, 0, PSpace.x20, PSpace.x20),
      children: [
        // 헤더 설명 (design 상단 desc).
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
          child: Text(
            l.ttagDesc,
            style: PTypo.bodySm.copyWith(color: t.fgTertiary, height: 1.5),
          ),
        ),
        tagsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: PSpace.x8),
            child: PListSkeleton(rows: 4),
          ),
          error: (e, _) => Text(
            '${l.todoTagLoadError}: $e',
            style: PTypo.caption.copyWith(color: t.statusDanger),
          ),
          data: (tags) => Column(
            children: [
              if (tags.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(LucideIcons.tags, size: 26, color: t.fgTertiary),
                      const SizedBox(height: 8),
                      Text(
                        l.ttagEmpty,
                        style: PTypo.bodySm.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (var i = 0; i < tags.length; i++)
                  _TagRow(
                    tag: tags[i],
                    usage: usageByName[tags[i].tagName] ?? 0,
                    first: i == 0,
                    busy: _busy,
                    onTap: () => _openEdit(tags[i]),
                    onDelete: () =>
                        _delete(tags[i], usageByName[tags[i].tagName] ?? 0),
                    t: t,
                  ),
              // 하단 고스트 '새 태그' 행 (design mobile 추가 행).
              InkWell(
                onTap: _busy ? null : () => _openEdit(null),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: tags.isEmpty
                        ? null
                        : Border(top: BorderSide(color: t.borderSubtle)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.plus, size: 15, color: t.fgBrand),
                      const SizedBox(width: 6),
                      Text(
                        l.todoNewTag,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: 14.5,
                          fontWeight: PFontWeight.bold,
                          color: t.fgBrand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 태그 행 — 아이콘 틴트 타일 + 이름/"할 일 N건에 사용 중" + 삭제 + chevron.
class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.usage,
    required this.first,
    required this.busy,
    required this.onTap,
    required this.onDelete,
    required this.t,
  });
  final TodoTag tag;
  final int usage;
  final bool first;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = solidSwatchColor(context, tag.color, fallback: t.fgBrand);
    return InkWell(
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border:
              first ? null : Border(top: BorderSide(color: t.borderSubtle)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                    color.withValues(alpha: 0.14), t.bgSurface),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.tag, size: 15, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag.tagName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: 15,
                      fontWeight: PFontWeight.semi,
                      letterSpacing: -0.15,
                      color: t.fgPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.ttagUsage(usage),
                    style: PTypo.caption.copyWith(
                        color: t.fgTertiary, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            PButton.icon(
              icon: LucideIcons.trash2,
              size: PButtonSize.sm,
              onPressed: busy ? null : onDelete,
            ),
            Icon(LucideIcons.chevronRight, size: 15, color: t.fgTertiary),
          ],
        ),
      ),
    );
  }
}

/// 편집 시트 결과 — 이름 + hex 색.
typedef TodoTagDraft = ({String name, String color});

/// 태그 편집 시트 — 이름 + 8 tone 스와치 + 저장/태그 추가 (design TodoTagEditSheet).
Future<TodoTagDraft?> showTodoTagEditSheet(
  BuildContext context, {
  TodoTag? tag,
}) {
  final l = AppLocalizations.of(context);
  return showPSheet<TodoTagDraft>(
    context,
    title: tag == null ? l.todoNewTag : l.ttagEditTitle,
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _TagEditBody(tag: tag),
  );
}

class _TagEditBody extends StatefulWidget {
  const _TagEditBody({required this.tag});
  final TodoTag? tag;
  @override
  State<_TagEditBody> createState() => _TagEditBodyState();
}

class _TagEditBodyState extends State<_TagEditBody> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.tag?.tagName ?? '');
  late String _color = () {
    final c = widget.tag?.color;
    return (c != null && c.isNotEmpty) ? c : _tagPalette.first;
  }();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final ok = _ctrl.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.x20, 0, PSpace.x20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.ttagNameLabel,
            style: PTypo.bodySm.copyWith(
              color: t.fgPrimary,
              fontWeight: PFontWeight.semi,
            ),
          ),
          const SizedBox(height: PSpace.x8),
          PTextInput(
            controller: _ctrl,
            autofocus: true,
            placeholder: l.todoTagNamePlaceholder,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x16),
          Text(
            l.ttagColorLabel,
            style: PTypo.bodySm.copyWith(
              color: t.fgPrimary,
              fontWeight: PFontWeight.semi,
            ),
          ),
          const SizedBox(height: PSpace.x8),
          PColorPicker(
            selected: _color,
            palette: _tagPalette,
            columns: 4,
            onChanged: (c) => setState(() => _color = c),
          ),
          const SizedBox(height: PSpace.x20),
          SizedBox(
            width: double.infinity,
            child: PButton(
              label: widget.tag == null ? l.ttagAddCta : l.actionSave,
              onPressed: !ok
                  ? null
                  : () => Navigator.of(context)
                      .pop((name: _ctrl.text.trim(), color: _color)),
            ),
          ),
        ],
      ),
    );
  }
}
