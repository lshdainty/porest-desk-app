import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/todo/domain/todo_tag.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
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
        title: Text(l.ttagTitle), // 웹 헤더 '할일 태그' 정합
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: _Body(scrollController: _scrollCtrl),
    );
  }
}


class _Body extends ConsumerStatefulWidget {
  const _Body({required this.scrollController});
  final ScrollController scrollController;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
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

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x20),
      children: [
        // 안내 카드 — 캘린더 라벨 _IntroCard 정합(제목+설명).
        _TagIntroCard(tokens: t),
        const SizedBox(height: PSpace.x32),
        tagsAsync.when(
          // 추가 버튼은 정적 UI라 로딩에도 진짜를 쓴다 — 개수 텍스트와 행만
          // 데이터 자리. 범용 PListSkeleton(아이콘 없는 2줄)은 실제 태그 행
          // (타일 34 + 이름/사용 수 + 휴지통 + chevron)과 달라 걷어냈다.
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PSkeleton.line(width: 96, height: 14),
                  PButton(
                    label: l.todoNewTag,
                    icon: LucideIcons.plus,
                    variant: PButtonVariant.accent,
                    size: PButtonSize.sm,
                    onPressed: _busy ? null : () => _openEdit(null),
                  ),
                ],
              ),
              for (int i = 0; i < 4; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(top: BorderSide(color: t.borderSubtle)),
                  ),
                  child: const Row(
                    children: [
                      PSkeleton(
                        width: 34,
                        height: 34,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PSkeleton.line(width: 120, height: 15),
                            SizedBox(height: 2),
                            PSkeleton.line(width: 72, height: 12),
                          ],
                        ),
                      ),
                      PSkeleton(
                          width: 32, height: 32, borderRadius: PRadius.brMd),
                      SizedBox(width: PSpace.x4),
                      PSkeleton(width: 15, height: 15),
                    ],
                  ),
                ),
            ],
          ),
          error: (e, _) => Text(
            '${l.todoTagLoadError}: $e',
            style: PTypo.caption.copyWith(color: t.statusDanger),
          ),
          data: (tags) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // label·list 한 묶음 gap 0 — 캘린더 라벨 카운트 라벨 정합.
              // 라벨행 우측 텍스트(accent) 추가 버튼 — 프리셋 정합(filled 안내카드 버튼 폐기)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${l.ttagTitle} · ${tags.length}',
                      style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      )),
                  PButton(
                    label: l.todoNewTag,
                    icon: LucideIcons.plus,
                    variant: PButtonVariant.accent,
                    size: PButtonSize.sm,
                    onPressed: _busy ? null : () => _openEdit(null),
                  ),
                ],
              ),
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
                    // 서버 GROUP BY 집계 — 클라 전체 할일 로드 제거.
                    usage: tags[i].usageCount,
                    first: i == 0,
                    busy: _busy,
                    onTap: () => _openEdit(tags[i]),
                    onDelete: () => _delete(tags[i], tags[i].usageCount),
                    t: t,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 태그 행 — 아이콘 틴트 타일 + 이름/"할 일 N건에 사용 중" + 삭제 + chevron.
/// 안내 카드 — 캘린더 라벨 _IntroCard 미러(제목·설명).
class _TagIntroCard extends StatelessWidget {
  const _TagIntroCard({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    return PCard(
      variant: PCardVariant.brand,
      padding: const EdgeInsets.all(PSpace.x16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              // fill 은 다크에서도 primary 고정(bgBrandSolid) — web --bg-brand 정합.
              color: t.bgBrandSolid,
              borderRadius: PRadius.brMd,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.tag, size: 18, color: t.fgOnBrand),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.ttagTitle,
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    )),
                const SizedBox(height: 2),
                Text(l.ttagDesc,
                    style: PTypo.caption.copyWith(color: t.fgSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              // 캘린더 라벨 행 정합 — 삭제는 빨강(fgExpense, 다크 스왑).
              iconColor: t.fgExpense,
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

/// 태그 편집 시트 — 캘린더 라벨 편집 시트와 동일 구성(미리보기 카드 +
/// 이름 + 스와치 + 취소/저장 푸터). 팔레트만 태그 8 tone.
Future<TodoTagDraft?> showTodoTagEditSheet(
  BuildContext context, {
  TodoTag? tag,
}) {
  final l = AppLocalizations.of(context);
  final nameCtrl = TextEditingController(text: tag?.tagName ?? '');
  final controller = PSheetController();
  controller.setCanSubmit((tag?.tagName ?? '').trim().isNotEmpty);
  String selectedColor = () {
    final c = tag?.color;
    return (c != null && c.isNotEmpty) ? c : kPDefaultPalette.first;
  }();

  controller.onSubmit = () async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    if (!context.mounted) return;
    // 시트는 root navigator 에 떠 있음(p_modal useRootNavigator) — 외부
    // context 로 branch nav 를 pop 하면 화면이 닫히므로 root 명시.
    Navigator.of(context, rootNavigator: true)
        .pop((name: name, color: selectedColor));
  };

  return showPSheet<TodoTagDraft>(
    context,
    title: tag == null ? l.todoNewTag : l.ttagEditTitle,
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _TagEditBody(
      nameController: nameCtrl,
      initialColor: selectedColor,
      controller: controller,
      fallbackName: l.todoNewTag,
      onColorChanged: (c) => selectedColor = c,
    ),
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: l.actionSave),
  );
}

class _TagEditBody extends StatefulWidget {
  const _TagEditBody({
    required this.nameController,
    required this.initialColor,
    required this.controller,
    required this.fallbackName,
    required this.onColorChanged,
  });
  final TextEditingController nameController;
  final String initialColor;
  final PSheetController controller;
  final String fallbackName;
  final ValueChanged<String> onColorChanged;

  @override
  State<_TagEditBody> createState() => _TagEditBodyState();
}

class _TagEditBodyState extends State<_TagEditBody> {
  late String _color = widget.initialColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final swatch = solidSwatchColor(context, _color, fallback: t.fgBrand);
    final preview = widget.nameController.text.trim();
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 미리보기 — 캘린더 라벨 편집 카드와 동일 구성.
          Container(
            padding: const EdgeInsets.all(PSpace.x16),
            decoration: BoxDecoration(
              color: softBg(context, swatch),
              borderRadius: PRadius.brMd,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: swatch, borderRadius: PRadius.brMd),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.tag, size: 18, color: t.fgOnBrand),
                ),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.calPreview,
                          style: PTypo.micro.copyWith(
                              color: t.fgTertiary,
                              fontWeight: PFontWeight.semi,
                              letterSpacing: 0.22)),
                      const SizedBox(height: 2),
                      Text(preview.isEmpty ? widget.fallbackName : preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.bodyLg.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 이름
          Text(l.ttagNameLabel,
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: widget.nameController,
            placeholder: l.todoTagNamePlaceholder,
            onChanged: (v) {
              widget.controller.setCanSubmit(v.trim().isNotEmpty);
              setState(() {});
            },
          ),
          const SizedBox(height: PSpace.x16),

          // 색상
          Text(l.ttagColorLabel,
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x8),
          // 공통 색상 선택기 — 캘린더 라벨과 동일(기본 팔레트).
          PColorPicker(
            selected: _color,
            onChanged: (c) {
              setState(() => _color = c);
              widget.onColorChanged(c);
            },
          ),
        ],
      ),
    );
  }
}
