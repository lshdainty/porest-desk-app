import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_empty_state.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/features/memo/application/memo_providers.dart';
import 'package:porest_desk_app/features/memo/domain/memo.dart';
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
                  _CardGrid(memos: pinned, onPin: _togglePin),
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
                  _CardGrid(memos: others, onPin: _togglePin),
                ],
              ],
            ),
    );
  }

  Future<void> _togglePin(Memo memo) async {
    final l = AppLocalizations.of(context);
    try {
      final repo = await ref.read(memoRepositoryProvider.future);
      await repo.pin(memo.rowId);
      ref.invalidate(memoListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        l.memoActionFailed(e.message),
        severity: PSnackSeverity.error,
      );
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
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.memos, required this.onPin});
  final List<Memo> memos;
  final Future<void> Function(Memo) onPin;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // safe-area 흡수 방지.
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: PSpace.x12,
        mainAxisSpacing: PSpace.x12,
        mainAxisExtent: 168,
      ),
      itemCount: memos.length,
      itemBuilder: (_, i) => _MemoCard(
        memo: memos[i],
        onTap: () => showMemoDetailDialog(context, memos[i]),
        onPin: () => onPin(memos[i]),
      ),
    );
  }
}

class _MemoCard extends StatelessWidget {
  const _MemoCard({
    required this.memo,
    required this.onTap,
    required this.onPin,
  });
  final Memo memo;
  final VoidCallback onTap;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final bg = memoCardBg(context, memo.color);
    final tagFg = memoTagFg(context, memo.color);
    final swatch = memoSwatch(context, memo.color);
    final hasTitle = (memo.title ?? '').isNotEmpty;
    final tag = (memo.tag ?? '').isNotEmpty ? memo.tag! : '개인';

    // 주의: BoxDecoration 의 boxShadow 는 박스 본체를 그림자색으로 채워 블러하는
    // 방식이라 decoration 에 color 가 없으면 그림자 내부(라이트 5%/다크 30% 검정)가
    // 카드 전체에 베일로 남는다 — bg 가 web 보다 어둡고 칙칙해 보이던 버그 fix.
    // color 를 같은 decoration 에 두면 그림자 본체를 덮어 외곽선만 남는다.
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PRadius.brLg,
        boxShadow: t.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: PRadius.brLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: PRadius.brLg,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 행: dot + 태그 + 핀.
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tag,
                        style: PTypo.micro.copyWith(
                          color: tagFg,
                          fontWeight: PFontWeight.semi,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 핀 마크는 고정 메모에만 — 비고정 카드 노이즈 제거 (고정 설정은 편집 다이얼로그).
                    if (memo.pinned)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onPin,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(LucideIcons.pin, size: 13, color: swatch),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hasTitle ? memo.title! : l.memoUntitled,
                  style: PTypo.body.copyWith(
                    fontSize: PFontSize.bodyMd, // 15px title (web 15/700)
                    color: hasTitle ? t.fgPrimary : t.fgTertiary,
                    fontWeight: PFontWeight.bold,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    memo.content ?? '',
                    style: PTypo.bodySm.copyWith(
                      color: t.fgSecondary,
                      height: 1.45,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _fmtUpdated(memo.modifyAt),
                  style: PTypo.micro.copyWith(color: t.fgTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 'YYYY-MM-DD(T| )HH:MM(:SS)' → 'MM/DD · HH:MM' (web 정합).
  /// 서버 modifyAt 은 ISO('T' 구분)라 'T'도 처리 — 'T' 잔존 버그 fix.
  static String _fmtUpdated(String? raw) {
    if (raw == null || raw.length < 16) return '';
    // 5..16 → 'MM-DD(T| )HH:MM'
    final seg = raw.substring(5, 16);
    return seg.replaceFirst('-', '/').replaceFirst(RegExp(r'[T ]'), ' · ');
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

/// 메모 그리드 skeleton — 2열 카드 placeholder.
/// 실제 [_MemoCard] 구조 1:1: shadow 카드(border 없음, color-tinted 대신 surface),
/// padding 18, 상단 dot+태그 행 / 제목 줄 / 본문 4줄 / 날짜 줄.
class _MemoGridSkeleton extends StatelessWidget {
  const _MemoGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: PSpace.x12,
        mainAxisSpacing: PSpace.x12,
        mainAxisExtent: 168,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => const _MemoCardSkeleton(),
    );
  }
}

/// 단일 메모 카드 skeleton — 실제 [_MemoCard] 내부 구조 미러.
class _MemoCardSkeleton extends StatelessWidget {
  const _MemoCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // 실제 카드는 shadow(boxShadow: shadowSm) + radius-lg, border 없음.
    return Container(
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        boxShadow: t.shadowSm,
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 행: 8×8 dot + 태그 라인.
            Row(
              children: [
                PSkeleton(width: 8, height: 8, borderRadius: PRadius.brFull),
                SizedBox(width: 6),
                PSkeleton.line(width: 56, height: 10),
              ],
            ),
            SizedBox(height: 8),
            // 제목(15/700 → 19px line) — 1줄.
            PSkeleton.line(width: 96, height: 15),
            SizedBox(height: 8),
            // 본문 4줄.
            Expanded(
              child: PSkeletonLines(lines: 3, lineHeight: 11),
            ),
            SizedBox(height: 8),
            // 날짜(micro) 줄.
            PSkeleton.line(width: 64, height: 10),
          ],
        ),
      ),
    );
  }
}
