import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_search_field.dart';

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

List<_NavGroup> _buildGroups(BuildContext ctx, {required bool hasSecurities}) {
  final l = AppLocalizations.of(ctx);
  return [
    _NavGroup(label: l.moreGroupMoney, items: [
      _NavItem(label: l.navExpense, icon: LucideIcons.receiptText, desc: l.moreDescExpense, onTap: (c) => c.go('/expense')),
      _NavItem(label: l.navAsset, icon: LucideIcons.wallet, desc: l.moreDescAsset, onTap: (c) => c.go('/assets')),
      // 증권 메뉴는 구독(SECURITIES) 보유 시에만 노출
      if (hasSecurities)
        _NavItem(label: l.moreItemStocks, icon: LucideIcons.trendingUp, desc: l.moreDescStocks, onTap: (c) => c.push('/stocks')),
      _NavItem(label: l.navBudget, icon: LucideIcons.filePen, desc: l.moreDescBudget, onTap: (c) => c.go('/budget')),
      _NavItem(label: l.moreItemStats, icon: LucideIcons.pieChart, desc: l.moreDescStats, onTap: (c) => c.go('/stats')),
      _NavItem(label: l.navRecurring, icon: LucideIcons.repeat, desc: l.moreDescRecurring, onTap: (c) => c.push('/recurring')),
      _NavItem(label: l.moreItemAccountCard, icon: LucideIcons.creditCard, desc: l.moreDescAccountCard, onTap: (c) => c.push('/account-card-manage')),
    ]),
    _NavGroup(label: l.moreGroupDaily, items: [
      _NavItem(label: l.navCalendar, icon: LucideIcons.calendar1, desc: l.moreDescCalendar, onTap: (c) => c.go('/calendar')),
      _NavItem(label: l.navTodo, icon: LucideIcons.squareCheckBig, desc: l.moreDescTodo, onTap: (c) => c.push('/todos')),
      _NavItem(label: l.navMemo, icon: LucideIcons.fileText, desc: l.moreDescMemo, onTap: (c) => c.push('/memos')),
      _NavItem(label: l.navDutchPay, icon: LucideIcons.users, desc: l.moreDescDutchPay, onTap: (c) => c.push('/dutch-pay')),
      _NavItem(label: l.moreItemCardBenefits, icon: LucideIcons.creditCard, desc: l.moreDescCardBenefits, onTap: (c) => c.push('/card-benefits')),
    ]),
    _NavGroup(label: l.moreGroupPersonal, items: [
      _NavItem(label: l.navCategories, icon: LucideIcons.tag, desc: l.moreDescCategories, onTap: (c) => c.push('/categories')),
      _NavItem(label: l.navPresets, icon: LucideIcons.bookmark, desc: l.moreDescPresets, onTap: (c) => c.push('/presets')),
      _NavItem(label: l.moreItemDisplay, icon: LucideIcons.palette, desc: l.moreDescDisplay, onTap: (c) => c.push('/settings')),
    ]),
    _NavGroup(label: l.moreGroupSystem, items: [
      _NavItem(label: l.navSettings, icon: LucideIcons.settings, desc: l.moreDescSettings, onTap: (c) => c.push('/settings')),
      _NavItem(label: l.navNotifications, icon: LucideIcons.bell, desc: l.moreDescNotifications, onTap: (c) => c.push('/settings/notifications')),
      _NavItem(label: l.exportTitle, icon: LucideIcons.download, desc: l.moreDescExport, onTap: (c) => c.push('/settings/export-data')),
      _NavItem(label: l.moreItemAccount, icon: LucideIcons.user, desc: l.moreDescAccount, onTap: (c) => c.push('/account')),
    ]),
  ];
}

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

  List<_NavItem> _allItems(bool hasSecurities) =>
      _buildGroups(context, hasSecurities: hasSecurities).expand((g) => g.items).toList();

  List<_NavItem>? _filtered(bool hasSecurities) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return null;
    return _allItems(hasSecurities)
        .where((i) =>
            i.label.toLowerCase().contains(q) ||
            i.desc.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final hasSecurities = ref.watch(hasSecuritiesProvider);
    final groups = _buildGroups(context, hasSecurities: hasSecurities);
    final filtered = _filtered(hasSecurities);
    final isSearching = _query.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x20, vertical: PSpace.x20),
      children: [
        // 검색바
        PSearchField(
          hint: l.moreSearchHint,
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
                child: Text(l.moreSearchEmpty,
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
