import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../expense/presentation/export_dialog.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_search_field.dart';

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.desc,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final String desc;
  final void Function(BuildContext ctx) onTap;
}

class _NavGroup {
  const _NavGroup({required this.label, required this.items});
  final String label;
  final List<_NavItem> items;
}

List<_NavGroup> _buildGroups(BuildContext ctx) => [
  _NavGroup(label: '돈 관리', items: [
    _NavItem(label: '가계부', icon: LucideIcons.receiptText, desc: '지출 · 수입 · 이체', onTap: (c) => c.go('/expense')),
    _NavItem(label: '자산', icon: LucideIcons.wallet, desc: '계좌 · 카드 · 투자 · 부채', onTap: (c) => c.go('/assets')),
    _NavItem(label: '예산', icon: LucideIcons.sheet, desc: '월간 · 카테고리별', onTap: (c) => c.go('/budget')),
    _NavItem(label: '통계·분석', icon: LucideIcons.pieChart, desc: '카테고리 · 트렌드 · 비교', onTap: (c) => c.go('/stats')),
    _NavItem(label: '반복 거래', icon: LucideIcons.repeat, desc: '구독 · 고정비', onTap: (c) => c.push('/recurring')),
    _NavItem(label: '카드·계좌 관리', icon: LucideIcons.creditCard, desc: '계좌·카드 추가·편집', onTap: (c) => c.push('/account-card-manage')),
  ]),
  _NavGroup(label: '일상', items: [
    _NavItem(label: '캘린더', icon: LucideIcons.calendar1, desc: '일정 · 반복 · 알림', onTap: (c) => c.go('/calendar')),
    _NavItem(label: '할 일', icon: LucideIcons.checkSquare, desc: '마감 · 우선순위 · 태그', onTap: (c) => c.push('/todos')),
    _NavItem(label: '메모', icon: LucideIcons.fileText, desc: '분류 · 고정 · 검색', onTap: (c) => c.push('/memos')),
    _NavItem(label: '더치페이', icon: LucideIcons.users, desc: '정산 · 친구 · 송금 요청', onTap: (c) => c.push('/dutch-pay')),
    _NavItem(label: '카드 혜택', icon: LucideIcons.creditCard, desc: '신용·체크 카드 검색', onTap: (c) => c.push('/card-benefits')),
  ]),
  _NavGroup(label: '개인화', items: [
    _NavItem(label: '카테고리', icon: LucideIcons.tag, desc: '지출 · 수입', onTap: (c) => c.push('/categories')),
    _NavItem(label: '프리셋', icon: LucideIcons.bookmark, desc: '자주 쓰는 내역', onTap: (c) => c.push('/presets')),
    _NavItem(label: '표시 설정', icon: LucideIcons.palette, desc: '테마 · 밀도 · 통화', onTap: (c) => c.push('/settings')),
  ]),
  _NavGroup(label: '계정·시스템', items: [
    _NavItem(label: '설정', icon: LucideIcons.settings, desc: '전체 설정 메뉴', onTap: (c) => c.push('/settings')),
    _NavItem(label: '알림', icon: LucideIcons.bell, desc: '푸시 · 방해 금지', onTap: (c) => c.push('/settings/notifications')),
    _NavItem(label: '데이터 내보내기', icon: LucideIcons.download, desc: 'CSV · 자동 백업', onTap: (c) => showExportDialog(c)),
    _NavItem(label: '계정', icon: LucideIcons.user, desc: '프로필 · 보안 · 구독', onTap: (c) => c.push('/account')),
  ]),
];

/// 모바일 전용 "전체" 탭 — 검색바 + 바로가기 + 그룹별 메뉴 카드.
class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  final _ctrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<_NavItem> get _allItems =>
      _buildGroups(context).expand((g) => g.items).toList();

  List<_NavItem>? get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return null;
    return _allItems
        .where((i) =>
            i.label.toLowerCase().contains(q) ||
            i.desc.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final groups = _buildGroups(context);
    final filtered = _filtered;
    final isSearching = _query.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x20, vertical: PSpace.x20),
      children: [
        // 검색바
        PSearchField(
          hint: '메뉴 검색',
          controller: _ctrl,
          focusNode: _searchFocus,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: PSpace.x20),

        // 검색 결과
        if (isSearching) ...[
          if (filtered == null || filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('검색 결과가 없습니다',
                    style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.body,
                        color: t.fgTertiary)),
              ),
            )
          else
            _GroupCard(
              label: null,
              items: filtered,
              tokens: t,
            ),
        ],

        // 그룹 리스트 (검색 비활성일 때만)
        if (!isSearching)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int gi = 0; gi < groups.length; gi++) ...[
                if (gi > 0) const SizedBox(height: PSpace.x20),
                _GroupCard(
                  label: groups[gi].label,
                  items: groups[gi].items,
                  tokens: t,
                ),
              ],
            ],
          ),

        const SizedBox(height: PSpace.x32),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.label,
    required this.items,
    required this.tokens,
  });
  final String? label;
  final List<_NavItem> items;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(label!,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: PFontSize.caption,
                  fontWeight: PFontWeight.bold,
                  color: tokens.fgPrimary,
                )),
          ),
        ],
        PCard(
          variant: PCardVariant.shadow,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _NavRow(item: items[i], tokens: tokens),
                if (i < items.length - 1)
                  const PDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.item, required this.tokens});
  final _NavItem item;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => item.onTap(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, size: 18, color: tokens.fgSecondary),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: PFontSize.body,
                    fontWeight: PFontWeight.semi,
                    color: tokens.fgPrimary,
                    letterSpacing: -0.01,
                  )),
            ),
            if (item.desc.isNotEmpty) ...[
              Text(item.desc,
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: PFontSize.caption,
                    color: tokens.fgTertiary,
                  )),
              const SizedBox(width: PSpace.x4),
            ],
            Icon(LucideIcons.chevronRight, size: 14, color: tokens.fgTertiary),
          ],
        ),
      ),
    );
  }
}
