import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';
import 'package:porest_desk_app/shared/widgets/p_tab_bar.dart';

class _NavItem {
  const _NavItem({
    required this.label,
    required this.desc,
    required this.onTap,
  });
  final String label;

  /// 검색 필터 전용 — 화면엔 표시하지 않음 (design: 텍스트 링크만).
  final String desc;
  final void Function(BuildContext ctx) onTap;
}

class _NavGroup {
  const _NavGroup({required this.label, required this.items});
  final String label;
  final List<_NavItem> items;
}

List<_NavGroup> _buildGroups(BuildContext ctx, {required bool hasSecurities}) {
  final l = AppLocalizations.of(ctx);
  return [
    _NavGroup(label: l.moreGroupMoney, items: [
      _NavItem(label: l.navExpense, desc: l.moreDescExpense, onTap: (c) => c.go('/expense')),
      _NavItem(label: l.navAsset, desc: l.moreDescAsset, onTap: (c) => c.go('/assets')),
      // 증권 메뉴는 구독(SECURITIES) 보유 시에만 노출
      if (hasSecurities)
        _NavItem(label: l.moreItemStocks, desc: l.moreDescStocks, onTap: (c) => c.push('/stocks')),
      _NavItem(label: l.navBudget, desc: l.moreDescBudget, onTap: (c) => c.go('/budget')),
      _NavItem(label: l.navSavingGoals, desc: l.moreDescSavingGoal, onTap: (c) => c.push('/saving-goals')),
      _NavItem(label: l.moreItemStats, desc: l.moreDescStats, onTap: (c) => c.go('/stats')),
      _NavItem(label: l.navRecurring, desc: l.moreDescRecurring, onTap: (c) => c.push('/recurring')),
      _NavItem(label: l.moreItemSmsPaste, desc: l.moreDescSmsPaste, onTap: (c) => c.push('/sms-paste')),
      _NavItem(label: l.moreItemAccountCard, desc: l.moreDescAccountCard, onTap: (c) => c.push('/account-card-manage')),
    ]),
    _NavGroup(label: l.moreGroupDaily, items: [
      _NavItem(label: l.navCalendar, desc: l.moreDescCalendar, onTap: (c) => c.go('/calendar')),
      _NavItem(label: l.navTodo, desc: l.moreDescTodo, onTap: (c) => c.push('/todos')),
      _NavItem(label: l.navMemo, desc: l.moreDescMemo, onTap: (c) => c.push('/memos')),
      _NavItem(label: l.navDutchPay, desc: l.moreDescDutchPay, onTap: (c) => c.push('/dutch-pay')),
      _NavItem(label: l.moreItemCardBenefits, desc: l.moreDescCardBenefits, onTap: (c) => c.push('/card-benefits')),
    ]),
    _NavGroup(label: l.moreGroupPersonal, items: [
      _NavItem(label: l.navCategories, desc: l.moreDescCategories, onTap: (c) => c.push('/categories')),
      _NavItem(label: l.navPresets, desc: l.moreDescPresets, onTap: (c) => c.push('/presets')),
      _NavItem(label: l.moreItemDisplay, desc: l.moreDescDisplay, onTap: (c) => c.push('/settings')),
    ]),
    _NavGroup(label: l.moreGroupSystem, items: [
      _NavItem(label: l.navSettings, desc: l.moreDescSettings, onTap: (c) => c.push('/settings')),
      _NavItem(label: l.navNotifications, desc: l.moreDescNotifications, onTap: (c) => c.push('/settings/notifications')),
      _NavItem(label: l.exportTitle, desc: l.moreDescExport, onTap: (c) => c.push('/settings/export-data')),
      _NavItem(label: l.moreItemAccount, desc: l.moreDescAccount, onTap: (c) => c.push('/account')),
    ]),
  ];
}

/// 모바일 전용 "전체" 탭 — design chrome.jsx MoreScreen (K뱅크 톤) 미러.
///
/// 검색 인풋 + 그룹 라벨(16/700) + **카드 없이 2열 텍스트 링크 그리드**(15/500),
/// 그룹 사이 1px 헤어라인. 아이콘·설명·chevron 행 폐기 — 텍스트만으로 시원하게.
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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final hasSecurities = ref.watch(hasSecuritiesProvider);
    final groups = _buildGroups(context, hasSecurities: hasSecurities);
    final q = _query.trim().toLowerCase();
    final isSearching = q.isNotEmpty;
    // design: 검색은 그룹 구조를 유지한 채 라벨/설명 매칭 항목만 남긴다.
    final visible = isSearching
        ? [
            for (final g in groups)
              if (g.items.any((i) =>
                  i.label.toLowerCase().contains(q) ||
                  i.desc.toLowerCase().contains(q)))
                _NavGroup(
                  label: g.label,
                  items: [
                    for (final i in g.items)
                      if (i.label.toLowerCase().contains(q) ||
                          i.desc.toLowerCase().contains(q))
                        i,
                  ],
                ),
          ]
        : groups;

    return Column(
      children: [
        // 검색 인풋 — 리스트 스크롤과 무관하게 상단 고정.
        Padding(
          padding: const EdgeInsets.fromLTRB(
              PSpace.x24, PSpace.x4, PSpace.x24, PSpace.x8),
          child: PSearchField(
            hint: l.moreSearchHint,
            controller: _ctrl,
            focusNode: _searchFocus,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView(
            // 하단 — 플로팅 탭바 보상.
            padding: EdgeInsets.fromLTRB(
                PSpace.x24, 0, PSpace.x24, pTabBarBottomInset(context)),
            children: [

        if (isSearching && visible.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Text(l.moreSearchEmpty,
                  style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: PFontSize.body,
                      color: t.fgTertiary)),
            ),
          )
        else
          for (int gi = 0; gi < visible.length; gi++) ...[
            // 그룹 사이 헤어라인 — design .flat-div (margin 14px 20px)
            if (gi > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(
                    vertical: 14),
                color: t.borderSubtle,
              ),
            // 그룹 라벨 — design 16/700, padding '14px 20px 2px'
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 2),
              child: Text(
                visible[gi].label,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 16,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.16,
                  color: t.fgPrimary,
                ),
              ),
            ),
            // 2열 텍스트 링크 그리드 — design padding '6px 20px 4px', columnGap 16
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Column(
                children: [
                  for (int r = 0; r < visible[gi].items.length; r += 2)
                    Row(
                      children: [
                        Expanded(child: _TextLink(item: visible[gi].items[r])),
                        const SizedBox(width: PSpace.x16),
                        Expanded(
                          child: r + 1 < visible[gi].items.length
                              ? _TextLink(item: visible[gi].items[r + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
            ],
          ),
        ),
      ],
    );
  }
}

/// K뱅크 톤 텍스트 링크 — 15/500, 세로 13 padding, 탭 중 opacity 피드백 (design 정합).
class _TextLink extends StatefulWidget {
  const _TextLink({required this.item});
  final _NavItem item;

  @override
  State<_TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<_TextLink> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () => widget.item.onTap(context),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.55 : 1,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(
            widget.item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: 15,
              fontWeight: PFontWeight.medium,
              letterSpacing: -0.15,
              color: t.fgPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
