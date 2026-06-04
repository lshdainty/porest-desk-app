import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_chip.dart';
import '../../../shared/widgets/p_empty_state.dart';
import '../../../shared/widgets/p_floating_action_button.dart';
import '../../../shared/widgets/p_search_field.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../application/memo_providers.dart';
import '../domain/memo.dart';
import '../domain/memo_colors.dart';
import 'memo_edit_dialog.dart';

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
    // 전체 목록을 한 번 받아 클라이언트에서 검색·태그·정렬 필터 (web 동작 미러).
    final listAsync = ref.watch(memoListProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: const Text('메모'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      floatingActionButton: PFloatingActionButton(
        icon: LucideIcons.plus,
        tooltip: '메모 추가',
        onPressed: () => showMemoEditDialog(context),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async => ref.invalidate(memoListProvider),
        child: listAsync.when(
          loading: () => _MemoSkeleton(tokens: t),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(PSpace.x16),
            children: [
              Text(
                '메모 로드 실패\n$e',
                style: PTypo.bodySm.copyWith(color: t.statusDanger),
              ),
            ],
          ),
          data: (all) => _buildBody(context, t, all),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PorestTokens t, List<Memo> all) {
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

    return ListView(
      // EdgeInsets.zero 미지정 시 safe-area 가 흡수돼 좌우 간격 어긋남 방지.
      padding: const EdgeInsets.fromLTRB(
        PSpace.x16,
        PSpace.x16,
        PSpace.x16,
        96,
      ),
      children: [
        // 검색 — web mobile 정합: AppBar 고정이 아니라 본문 스크롤 첫 항목.
        PSearchField(
          controller: _searchCtrl,
          hint: '메모 검색',
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
            Expanded(
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: tags.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return PChip(
                        label: '전체',
                        size: PChipSize.sm,
                        selected: _tagFilter == null,
                        trailing: _CountBadge(
                          count: all.length,
                          selected: _tagFilter == null,
                          t: t,
                        ),
                        onTap: () => setState(() => _tagFilter = null),
                      );
                    }
                    final tag = tags[i - 1];
                    final n = all.where((m) => tagOf(m) == tag).length;
                    return PChip(
                      label: tag,
                      size: PChipSize.sm,
                      selected: _tagFilter == tag,
                      trailing: _CountBadge(
                        count: n,
                        selected: _tagFilter == tag,
                        t: t,
                      ),
                      onTap: () => setState(() => _tagFilter = tag),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            PButton(
              label: '추가',
              icon: LucideIcons.plus,
              variant: PButtonVariant.accent,
              size: PButtonSize.sm,
              onPressed: () => showMemoEditDialog(context),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x16),

        if (visible.isEmpty)
          _EmptyMemo(hasQuery: hasQuery)
        else ...[
          if (pinned.isNotEmpty) ...[
            _SectionHeader(
              icon: LucideIcons.pin,
              label: '고정 · ${pinned.length}',
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
                label: '모든 메모 · ${others.length}',
                t: t,
              ),
              const SizedBox(height: PSpace.x12),
            ],
            _CardGrid(memos: others, onPin: _togglePin),
          ],
        ],
      ],
    );
  }

  Future<void> _togglePin(Memo memo) async {
    try {
      final repo = await ref.read(memoRepositoryProvider.future);
      await repo.pin(memo.rowId);
      ref.invalidate(memoListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '실패: ${e.message}',
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: PEmptyState(
        icon: hasQuery ? LucideIcons.searchX : LucideIcons.stickyNote,
        message: hasQuery ? '결과가 없어요' : '메모가 없어요',
        subMessage: hasQuery ? '다른 검색어를 입력해보세요.' : '생각이 떠오를 때, 새 메모를 만들어보세요.',
        action: hasQuery
            ? null
            : PButton(
                label: '새 메모',
                icon: LucideIcons.plus,
                size: PButtonSize.sm,
                onPressed: () => showMemoEditDialog(context),
              ),
      ),
    );
  }
}

/// 칩 우측 카운트 — active 시 onBrand 톤.
class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.selected,
    required this.t,
  });
  final int count;
  final bool selected;
  final PorestTokens t;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count',
      style: PTypo.caption.copyWith(
        color: (selected ? t.fgOnBrand : t.fgSecondary).withValues(alpha: 0.6),
        fontWeight: PFontWeight.medium,
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
        onTap: () => showMemoEditDialog(context, edit: memos[i]),
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
                  hasTitle ? memo.title! : '(제목 없음)',
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

/// 메모 목록 skeleton — 2열 그리드 placeholder.
class _MemoSkeleton extends StatelessWidget {
  const _MemoSkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x16,
        PSpace.x16,
        PSpace.x16,
        96,
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 검색바(36) + 태그 칩 placeholder — 실화면 구조 동일.
        const PSkeleton.line(height: 36),
        const SizedBox(height: PSpace.x12),
        const PSkeleton.line(width: 200, height: 28),
        const SizedBox(height: PSpace.x16),
        GridView.builder(
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
          itemBuilder: (_, _) => Container(
            decoration: BoxDecoration(
              color: t.bgSurface,
              borderRadius: PRadius.brLg,
              border: Border.all(color: t.borderSubtle),
            ),
          ),
        ),
      ],
    );
  }
}
