import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/features/memo/application/memo_providers.dart';
import 'package:porest_desk_app/features/memo/domain/memo.dart';
import 'package:porest_desk_app/features/memo/presentation/memo_actions.dart';
import 'package:porest_desk_app/shared/widgets/p_swipe_actions.dart';
import 'package:porest_desk_app/features/memo/domain/memo_colors.dart';
import 'package:porest_desk_app/features/memo/presentation/memo_edit_dialog.dart';
import 'package:porest_desk_app/features/memo/presentation/memo_detail_dialog.dart';

/// 메모 — 토스 톤 색틴트 카드 그리드 (web `MemoScreen` mobile 미러).
///
/// 검색(클라 필터) + 태그 칩 필터 + 고정/일반 섹션 2열 그리드.
/// 폴더 기능은 새 UI 에서 폐기(백엔드 필드는 유지·미사용).
class MemoScreen extends ConsumerStatefulWidget {
  const MemoScreen({super.key});
  @override
  ConsumerState<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends ConsumerState<MemoScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  /// 선택된 태그 필터. null = 전체.
  String? _tagFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 전체 목록을 한 번 받아 클라이언트에서 검색·태그·정렬 필터 (web 동작 미러).
    final listAsync = ref.watch(memoListProvider);

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.memoTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      // FAB 제거 — 칩 행 우측 + 추가 버튼이 새 메모 진입점 (web 정합).
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async => ref.invalidate(memoListProvider),
        child: listAsync.when(
          // 검색바·칩 행·추가 버튼은 정적 UI 틀 → 항상 실제 렌더(스켈레톤화 금지).
          // 데이터 영역(칩 카운트·카드 그리드)만 스켈레톤.
          loading: () => _buildShell(
            context,
            t,
            // 칩 카운트는 데이터 의존 → 로딩 중 칩 행은 스켈레톤 pill.
            chips: const _ChipRowSkeleton(),
            body: const _MemoGridSkeleton(),
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(PSpace.x16),
            children: [
              Text(
                '${l.memoLoadError}\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger),
              ),
            ],
          ),
          data: (all) => _buildBody(context, t, all),
        ),
      ),
    );
  }

  /// 정적 UI 틀(검색바 + 칩 행 + 추가 버튼) + 본문. 로딩/데이터 공통 셸.
  /// [chips] 는 칩 가로 스크롤 영역(데이터 시 실제 PChip / 로딩 시 스켈레톤),
  /// [body] 는 칩 행 아래 콘텐츠(섹션+그리드 / 그리드 스켈레톤).
  Widget _buildShell(
    BuildContext context,
    PorestTokens t, {
    required Widget chips,
    required Widget body,
  }) {
    final l = AppLocalizations.of(context);
    return ListView(
      // EdgeInsets.zero 미지정 시 safe-area 가 흡수돼 좌우 간격 어긋남 방지.
      padding: const EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        96,
      ),
      children: [
        // 검색 — web mobile 정합: AppBar 고정이 아니라 본문 스크롤 첫 항목.
        PSearchField(
          controller: _searchCtrl,
          hint: l.memoSearchHint,
          trailing: _query.trim().isNotEmpty
              ? PButton.icon(
                  icon: LucideIcons.x,
                  size: PButtonSize.sm,
                  iconColor: t.fgTertiary,
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: PSpace.x12),

        // 태그 칩 가로 스크롤 + 우측 끝 + 추가 (web 칩 행 accent 추가 버튼 정합).
        Row(
          children: [
            Expanded(child: SizedBox(height: 32, child: chips)),
            const SizedBox(width: 8),
            PButton(
              label: l.memoAdd,
              icon: LucideIcons.plus,
              variant: PButtonVariant.accent,
              size: PButtonSize.sm,
              onPressed: () => showMemoEditDialog(context),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x16),

        body,
      ],
    );
  }

  Widget _buildBody(BuildContext context, PorestTokens t, List<Memo> all) {
    final l = AppLocalizations.of(context);
    final hasQuery = _query.trim().isNotEmpty;

    // 태그 정규화 — web `memo.tag || '개인'` 정합. raw tag 만 세면
    // null 태그 메모가 칩 카운트에서 빠져 web(개인 8)과 app(개인 2)이 어긋난다.
    String tagOf(Memo m) => (m.tag ?? '').isNotEmpty ? m.tag! : '개인';

    // 검색 필터 (제목+내용 case-insensitive).
    var visible = all;
    if (hasQuery) {
      final q = _query.trim().toLowerCase();
      visible = visible
          .where(
            (m) =>
                (m.title ?? '').toLowerCase().contains(q) ||
                (m.content ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    // 태그 필터 (정규화 태그 기준 — web 정합).
    if (_tagFilter != null) {
      visible = visible.where((m) => tagOf(m) == _tagFilter).toList();
    }
    // 정렬: 핀 우선 → modifyAt desc.
    visible = [...visible]
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return (b.modifyAt ?? '').compareTo(a.modifyAt ?? '');
      });

    final pinned = visible.where((m) => m.pinned).toList();
    final others = visible.where((m) => !m.pinned).toList();

    // 태그 칩: 데이터에 존재하는 정규화 태그 + 카운트(항상 전체 기준, web 정합).
    final tags = <String>{for (final m in all) tagOf(m)}.toList();

    return _buildShell(
      context,
      t,
      chips: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: PTabs<String?>(
          value: _tagFilter,
          onChanged: (v) => setState(() => _tagFilter = v),
          variant: PTabsVariant.pills,
          size: PTabsSize.sm,
          // count 는 PTabItem trailing 미지원 → 라벨에 병합('전체 N' / '태그 N')
          items: [
            PTabItem(value: null, label: l.memoTagAll(all.length)),
            for (final tag in tags)
              PTabItem(
                value: tag,
                label: '$tag ${all.where((m) => tagOf(m) == tag).length}',
              ),
          ],
        ),
      ),
      body: visible.isEmpty
          ? _EmptyMemo(hasQuery: hasQuery)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pinned.isNotEmpty) ...[
                  _SectionHeader(
                    icon: LucideIcons.pin,
                    label: l.memoSectionPinned(pinned.length),
                    t: t,
                  ),
                  const SizedBox(height: PSpace.x12),
                  _MemoList(memos: pinned, onPin: _togglePin),
                ],
                if (others.isNotEmpty) ...[
                  if (pinned.isNotEmpty) ...[
                    const SizedBox(height: PSpace.x20),
                    _SectionHeader(
                      icon: LucideIcons.stickyNote,
                      label: l.memoSectionAll(others.length),
                      t: t,
                    ),
                    const SizedBox(height: PSpace.x12),
                  ],
                  _MemoList(memos: others, onPin: _togglePin),
                ],
              ],
            ),
    );
  }

  Future<void> _togglePin(Memo memo) async {
    try {
      final repo = await ref.read(memoRepositoryProvider.future);
      await repo.pin(memo.rowId);
      ref.invalidate(memoListProvider);
    } on ApiException {
      if (!mounted) return;
    }
  }
}

/// 빈 상태 2종 — 검색 결과 없음 / 메모 없음.
class _EmptyMemo extends StatelessWidget {
  const _EmptyMemo({required this.hasQuery});
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: PEmptyState(
        icon: hasQuery ? LucideIcons.searchX : LucideIcons.stickyNote,
        message: hasQuery ? l.memoSearchEmpty : l.memoEmpty,
        subMessage: hasQuery ? l.memoSearchEmptyDesc : l.memoEmptyDesc,
        action: hasQuery
            ? null
            : PButton(
                label: l.memoNew,
                icon: LucideIcons.plus,
                size: PButtonSize.sm,
                onPressed: () => showMemoEditDialog(context),
              ),
      ),
    );
  }
}

/// 섹션 라벨 — eyebrow 톤 + leading 아이콘 (web SectionLabel 미러).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.t,
  });
  final IconData icon;
  final String label;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: t.fgTertiary),
        const SizedBox(width: 6),
        Text(
          label,
          style: PTypo.caption.copyWith(
            color: t.fgTertiary,
            fontWeight: PFontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

/// 2열 색틴트 카드 그리드.
/// 메모 목록 — 세로 리스트.
///
/// 예전엔 2열 카드 그리드였다. 보기엔 좋았지만 밀 수 있는 형태가 아니라(폭이 절반이고
/// 옆에 카드가 또 있다) 편집·삭제에 닿으려면 매번 상세를 열어야 했다. 세로 리스트로
/// 바꿔 가계부·할일과 같은 리듬을 쓰고, 밀면 액션이 나오게 한다.
class _MemoList extends ConsumerWidget {
  const _MemoList({required this.memos, required this.onPin});
  final List<Memo> memos;
  final Future<void> Function(Memo) onPin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.tokens;

    return Column(
      children: [
        for (var i = 0; i < memos.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: t.borderSubtle),
          PSwipeActions(
            key: ValueKey('memo-${memos[i].rowId}'),
            groupTag: 'memo-list',
            actions: [
              PSwipeAction(
                label: memos[i].pinned ? l.memoUnpin : l.memoPin,
                icon: LucideIcons.pin,
                onSelect: () => onPin(memos[i]),
              ),
              PSwipeAction(
                label: l.actionEdit,
                icon: LucideIcons.pencil,
                kind: PSwipeKind.primary,
                onSelect: () => memoActions.edit(context, ref, memos[i]),
              ),
              PSwipeAction(
                label: l.actionDelete,
                icon: LucideIcons.trash2,
                kind: PSwipeKind.destructive,
                confirmTitle: memoActions.deleteConfirmTitle(context, memos[i]),
                confirmMessage: memoActions.deleteConfirmMessage(
                  context,
                  memos[i],
                ),
                onSelect: () => memoActions.delete(context, ref, memos[i]),
              ),
            ],
            child: _MemoRow(
              memo: memos[i],
              onTap: () => showMemoDetailDialog(context, memos[i]),
            ),
          ),
        ],
      ],
    );
  }
}

/// 메모 행 — 세로 리스트용.
///
/// 카드(2열 그리드)는 밀 수 있는 형태가 아니다. 폭이 절반이고 옆에 카드가 또 있어서
/// 왼쪽으로 밀어 액션을 여는 동작이 물리적으로 성립하지 않는다. 그래서 세로 리스트로
/// 바꾼다 — 가계부·할일과 같은 리듬이 되고, 스와이프도 붙는다.
///
/// 카드가 보여 주던 것(색 점 · 태그 · 제목 · 본문 · 수정시각 · 고정)은 그대로 옮긴다.
/// 다만 본문은 4줄에서 1줄로 줄인다 — 행 높이가 들쭉날쭉하면 미는 손이 목표를 잃는다.
class _MemoRow extends StatelessWidget {
  const _MemoRow({required this.memo, required this.onTap});

  final Memo memo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final swatch = memoSwatch(context, memo.color);
    final hasTitle = (memo.title ?? '').isNotEmpty;
    final tag = (memo.tag ?? '').isNotEmpty ? memo.tag! : '개인';
    final content = (memo.content ?? '').trim();

    return Material(
      color: t.bgSurface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // 좌우 여백 없음 — 행이 더 얹으면 그만큼 페이지 여백(24)과 어긋난다.
          // 상하만 준다(행 리듬).
          padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 색 점 — 카드의 색 면을 대신한다. 리스트에서 면을 칠하면 행마다
              // 배경이 달라져 목록이 산만해진다.
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasTitle ? memo.title! : l.memoUntitled,
                            style: PTypo.body.copyWith(
                              color: hasTitle ? t.fgPrimary : t.fgTertiary,
                              fontWeight: PFontWeight.semi,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (memo.pinned) ...[
                          const SizedBox(width: 6),
                          Icon(LucideIcons.pin, size: 13, color: swatch),
                        ],
                      ],
                    ),
                    if (content.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        content,
                        style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '$tag · ${monthDayTime(memo.modifyAt)}',
                      style: PTypo.micro.copyWith(color: t.fgTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 태그 칩 행 skeleton — 칩 카운트가 데이터 의존이라 로딩 중 pill placeholder.
/// 실제 PChip(sm) 높이(약 24)·pill radius·가로 간격(6) 정합.
class _ChipRowSkeleton extends StatelessWidget {
  const _ChipRowSkeleton();

  // sm chip 폭 mock — '전체' + 태그 칩 가변 폭 흉내(결정적 시퀀스).
  static const _widths = [54.0, 64.0, 58.0, 72.0, 50.0];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: _widths.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (_, i) => Center(
        child: PSkeleton(
          width: _widths[i],
          height: 24,
          borderRadius: PRadius.brFull,
        ),
      ),
    );
  }
}

/// 메모 목록 skeleton — [_MemoRow] 구조 1:1.
///
/// 스켈레톤이 실제와 다른 모양이면 데이터가 도착하는 순간 화면이 튄다. 그리드
/// 시절엔 2열 카드였는데 목록이 세로 리스트가 됐으니 여기도 같이 바꾼다.
class _MemoGridSkeleton extends StatelessWidget {
  const _MemoGridSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        for (var i = 0; i < 6; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: t.borderSubtle),
          const _MemoCardSkeleton(),
        ],
      ],
    );
  }
}

/// 단일 메모 행 skeleton — [_MemoRow] 내부 구조 미러.
class _MemoCardSkeleton extends StatelessWidget {
  const _MemoCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      // 실렌더와 같은 여백 — 다르면 데이터가 오는 순간 행이 좌우로 튄다.
      padding: EdgeInsets.symmetric(vertical: PSpace.x12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 색 점
          Padding(
            padding: EdgeInsets.only(top: 5),
            child: PSkeleton(width: 8, height: 8, borderRadius: PRadius.brFull),
          ),
          SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                PSkeleton.line(width: 140, height: 15),
                SizedBox(height: 2),
                // 본문 한 줄
                PSkeleton.line(width: 200, height: 13),
                SizedBox(height: 4),
                // 태그 · 수정시각
                PSkeleton.line(width: 96, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
