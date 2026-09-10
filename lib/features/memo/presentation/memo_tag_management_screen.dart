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
import 'package:porest_desk_app/features/memo/application/memo_providers.dart';
import 'package:porest_desk_app/features/memo/domain/memo_tag.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_swipe_actions.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// 메모 태그 관리 — 할 일 태그 화면(`todo_tag_management_screen.dart`)을
/// **그대로 미러링한다**(사용자 지시 2026-09-08 — 새로 설계하지 않는다).
///
/// 설정에서 두 화면이 나란히 놓이므로 다르게 생기면 그 자체가 결함으로 읽힌다.
/// 서버도 같은 모양이다 — `/memo-tag` 는 경로·본문·응답이 `/todo-tag` 와 같다
/// (`MemoTagApiController`). 웹은 `widgets/memo-manage/MemoTagManager` 가 같은 자리다.
///
/// 종전엔 앱에 이 화면이 없어, **앱만 쓰는 사람은 메모 태그를 만들 수 없었다** —
/// 편집기 선택지는 서버 마스터가 SoT 인데 그 마스터를 늘릴 길이 웹에만 있었다.
class MemoTagManagementScreen extends StatefulWidget {
  const MemoTagManagementScreen({super.key});

  @override
  State<MemoTagManagementScreen> createState() =>
      _MemoTagManagementScreenState();
}

class _MemoTagManagementScreenState extends State<MemoTagManagementScreen> {
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
        title: Text(l.mtagTitle), // 웹 설정 '메모 태그' 정합
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

  /// 저장·삭제가 끝나기 전에 화면이 닫혀도 목록을 비울 수 있게 미리 잡아 둔다.
  ///
  /// `ref` 는 unmount 뒤에 쓰면 던지고(`_assertNotDisposed`), 그렇다고 `if (mounted)`
  /// 로 막으면 **무효화 자체가 안 일어난다** — [memoTagListProvider] 는 keepAlive,
  /// [memoListProvider] 는 autoDispose 가 아니라 둘 다 화면보다 오래 산다. 서버엔
  /// 들어간 이름이 목록에는 옛 값으로 남아, 포그라운드 복귀 전까지 안 걷힌다.
  /// 컨테이너는 `ProviderScope` 의 것이라 화면 수명과 무관하다(#348 와 같은 방식).
  late ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    // 진입 시 갱신 — keepAlive provider 라 다른 클라이언트 변경 반영 위해 무효화.
    //
    // 여기만 `mounted` 로 막는다. 이건 **화면에 그리기 전에 새로 읽는 것**이지
    // 내가 방금 쓴 값을 걷어 내는 게 아니다 — 화면이 이미 사라졌으면 걷어 낼
    // 헌 값도, 보여 줄 사람도 없다. 그래도 비우면 아무도 안 보는 GET 만 나간다.
    Future.microtask(() {
      if (mounted) ref.invalidate(memoTagListProvider);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  Future<void> _save(MemoTag? origin, String name, String color) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = await _container.read(memoTagRepositoryProvider.future);
      if (origin == null) {
        await repo.create(tagName: name, color: color);
      } else {
        await repo.update(id: origin.rowId, tagName: name, color: color);
      }
      // 저장 도중에 화면을 닫아도 여기까지 온다 — 서버엔 이미 들어갔으므로
      // 목록은 반드시 걷어 낸다. 그래서 `ref` 가 아니라 컨테이너다.
      _container.invalidate(memoTagListProvider);
      // 개명이면 서버가 그 태그를 쓰던 메모의 `tag` 문자열도 함께 옮긴다
      // (`MemoTagServiceImpl.updateTag`) — 목록을 안 걷어 내면 돌아갔을 때
      // 칩과 카드가 옛 이름을 계속 그린다.
      _container.invalidate(memoListProvider);
      if (mounted) setState(() => _busy = false);
    } on ApiException {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _delete(MemoTag tag, int usage) async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.memoDeleteTagTitle,
      message: l.memoDeleteTagConfirm(tag.tagName, usage),
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final repo = await _container.read(memoTagRepositoryProvider.future);
      await repo.delete(tag.rowId);
      _container.invalidate(memoTagListProvider);
      // 삭제는 그 태그를 쓰던 메모의 `tag` 를 비운다 — 목록도 다시 읽어야
      // 그 메모들이 '태그 없음' 으로 보인다.
      _container.invalidate(memoListProvider);
      if (mounted) setState(() => _busy = false);
    } on ApiException {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _openEdit(MemoTag? tag) async {
    final result = await showMemoTagEditSheet(context, tag: tag);
    if (result != null) {
      await _save(tag, result.name, result.color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final tagsAsync = ref.watch(memoTagListProvider);

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
                    label: l.memoNewTag,
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
                        width: 32,
                        height: 32,
                        borderRadius: PRadius.brMd,
                      ),
                      SizedBox(width: PSpace.x4),
                      PSkeleton(width: 15, height: 15),
                    ],
                  ),
                ),
            ],
          ),
          error: (e, _) => Text(
            '${l.memoTagLoadError}: $e',
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
                  Text(
                    '${l.mtagTitle} · ${tags.length}',
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                  PButton(
                    label: l.memoNewTag,
                    icon: LucideIcons.plus,
                    variant: PButtonVariant.accent,
                    size: PButtonSize.sm,
                    onPressed: _busy ? null : () => _openEdit(null),
                  ),
                ],
              ),
              if (tags.isEmpty)
                // 캘린더 라벨 화면과 같은 PEmptyState — 자체로 그리면 부모가 start 정렬이라
                // 아이콘·문구가 왼쪽에 붙는다(사용자 제보).
                PEmptyState(icon: LucideIcons.tags, message: l.mtagEmpty)
              else
                for (var i = 0; i < tags.length; i++)
                  // 밀면 수정·삭제. 행의 🗑·> 를 걷었으므로 탭(편집)이 비제스처 경로다
                  // (spec swipe-actions.md · WCAG 2.1.1).
                  PSwipeActions(
                    key: ValueKey('memo-tag-${tags[i].rowId}'),
                    groupTag: 'memo-tag-list',
                    enabled: !_busy,
                    actions: [
                      PSwipeAction(
                        label: AppLocalizations.of(context).actionEdit,
                        icon: LucideIcons.pencil,
                        kind: PSwipeKind.primary,
                        onSelect: () => _openEdit(tags[i]),
                      ),
                      PSwipeAction(
                        label: AppLocalizations.of(context).actionDelete,
                        icon: LucideIcons.trash2,
                        kind: PSwipeKind.destructive,
                        // _delete 가 자체 확인을 띄운다 — 여기서 또 주면 두 번 뜬다.
                        onSelect: () => _delete(tags[i], tags[i].usageCount),
                      ),
                    ],
                    child: _TagRow(
                      tag: tags[i],
                      // 서버 GROUP BY 집계 — 클라 전체 할일 로드 제거.
                      usage: tags[i].usageCount,
                      first: i == 0,
                      busy: _busy,
                      onTap: () => _openEdit(tags[i]),
                      t: t,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 태그 행 — 아이콘 틴트 타일 + 이름/"메모 N건에 사용 중" + 삭제 + chevron.
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
                Text(
                  l.mtagTitle,
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.mtagDesc,
                  style: PTypo.caption.copyWith(color: t.fgSecondary),
                ),
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
    required this.t,
  });
  final MemoTag tag;
  final int usage;
  final bool first;
  final bool busy;
  final VoidCallback onTap;
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
          border: first ? null : Border(top: BorderSide(color: t.borderSubtle)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  color.withValues(alpha: 0.14),
                  t.bgSurface,
                ),
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
                    l.mtagUsage(usage),
                    style: PTypo.caption.copyWith(
                      color: t.fgTertiary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            // 🗑·> 를 두지 않는다 — 밀면 수정·삭제, 탭하면 편집(사용자 결정).
          ],
        ),
      ),
    );
  }
}

/// 편집 시트 결과 — 이름 + hex 색.
typedef MemoTagDraft = ({String name, String color});

/// 태그 편집 시트 — 캘린더 라벨 편집 시트와 동일 구성(미리보기 카드 +
/// 이름 + 스와치 + 취소/저장 푸터). 팔레트만 태그 8 tone.
Future<MemoTagDraft?> showMemoTagEditSheet(
  BuildContext context, {
  MemoTag? tag,
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
    Navigator.of(
      context,
      rootNavigator: true,
    ).pop((name: name, color: selectedColor));
  };

  return showPSheet<MemoTagDraft>(
    context,
    title: tag == null ? l.memoNewTag : l.mtagEditTitle,
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _TagEditBody(
      nameController: nameCtrl,
      initialColor: selectedColor,
      controller: controller,
      fallbackName: l.memoNewTag,
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
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
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
                    color: swatch,
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
                      Text(
                        l.calPreview,
                        style: PTypo.micro.copyWith(
                          color: t.fgTertiary,
                          fontWeight: PFontWeight.semi,
                          letterSpacing: 0.22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preview.isEmpty ? widget.fallbackName : preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PTypo.bodyLg.copyWith(
                          color: t.fgPrimary,
                          fontWeight: PFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 이름
          Text(
            l.mtagNameLabel,
            style: PTypo.caption.copyWith(color: t.fgSecondary),
          ),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: widget.nameController,
            placeholder: l.memoTagNamePlaceholder,
            onChanged: (v) {
              widget.controller.setCanSubmit(v.trim().isNotEmpty);
              setState(() {});
            },
          ),
          const SizedBox(height: PSpace.x16),

          // 색상
          Text(
            l.mtagColorLabel,
            style: PTypo.caption.copyWith(color: t.fgSecondary),
          ),
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
