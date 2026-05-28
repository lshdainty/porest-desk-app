import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../../shared/widgets/p_tabs.dart';
import '../application/asset_providers.dart';
import '../domain/asset.dart';
import 'asset_detail_dialog.dart';
import 'asset_edit_dialog.dart';
import 'widgets/asset_logo.dart';

/// 계좌·카드 관리 — web AccountManager 미러. 설정 단일 진입점에서 자산 추가/편집.
/// 탭(계좌·예금/카드/투자) + 총액 + 리스트(항목 → 편집) + 그룹별 추가.
enum _Group { account, card, invest }

const Map<_Group, List<String>> _groupTypes = {
  _Group.account: ['BANK_ACCOUNT', 'SAVINGS', 'CASH', 'LOAN'],
  _Group.card: ['CREDIT_CARD', 'CHECK_CARD'],
  _Group.invest: ['INVESTMENT'],
};

String _groupLabel(_Group g) => switch (g) {
      _Group.account => '계좌',
      _Group.card => '카드',
      _Group.invest => '투자',
    };

class AccountCardManageScreen extends ConsumerStatefulWidget {
  const AccountCardManageScreen({super.key});

  @override
  ConsumerState<AccountCardManageScreen> createState() =>
      _AccountCardManageScreenState();
}

class _AccountCardManageScreenState
    extends ConsumerState<AccountCardManageScreen> {
  _Group _tab = _Group.account;

  void _onAdd() {
    switch (_tab) {
      case _Group.account:
        showAssetAddDialog(context);
      case _Group.card:
        showCardAddDialog(context);
      case _Group.invest:
        showInvestmentAddDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final masked = ref.watch(settingsProvider).value?.hideAmounts ?? false;
    final assetsAsync = ref.watch(assetsProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: const Text('계좌·카드 관리'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: assetsAsync.when(
        loading: () => _AccountCardManageSkeleton(tokens: t),
        error: (e, _) => Center(
          child: Text(
            '자산을 불러오지 못했습니다\n$e',
            textAlign: TextAlign.center,
            style: PTypo.bodySm.copyWith(color: t.fgSecondary),
          ),
        ),
        data: (assets) {
          int countOf(_Group g) =>
              assets.where((a) => _groupTypes[g]!.contains(a.assetType)).length;
          final filtered = assets
              .where((a) => _groupTypes[_tab]!.contains(a.assetType))
              .toList();
          final total = filtered.fold<int>(0, (s, a) => s + (a.balance ?? 0));
          final isCard = _tab == _Group.card;

          return Column(
            children: [
              // 탭 — AppBar 바로 아래 흰띠, full width underline (stats_screen 미러)
              Container(
                color: t.bgSurface,
                child: PTabs<_Group>(
                  value: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                  variant: PTabsVariant.underline,
                  expand: true,
                  items: [
                    PTabItem(
                      value: _Group.account,
                      label: '계좌·예금 ${countOf(_Group.account)}',
                    ),
                    PTabItem(
                      value: _Group.card,
                      label: '카드 ${countOf(_Group.card)}',
                    ),
                    PTabItem(
                      value: _Group.invest,
                      label: '투자 ${countOf(_Group.invest)}',
                    ),
                  ],
                ),
              ),
              // 콘텐츠 (총액 + 리스트, page-edge padding)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PSpace.x20,
                    vertical: PSpace.x20,
                  ),
                  children: [
                    // 총액 (좌) + 추가 (우, ghost+accent)
                    Row(
                      children: [
                        Text(
                          masked ? '총 •••' : '총 ${krw(total)}원',
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
                        ),
                        const Spacer(),
                        PButton(
                          label: '${_groupLabel(_tab)} 추가',
                          icon: LucideIcons.plus,
                          variant: PButtonVariant.accent,
                          size: PButtonSize.sm,
                          onPressed: _onAdd,
                        ),
                      ],
                    ),
                    const SizedBox(height: PSpace.x4),
                    // 리스트
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: PSpace.x32,
                        ),
                        child: Center(
                          child: Text(
                            '등록된 ${_groupLabel(_tab)}이 없어요',
                            style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                          ),
                        ),
                      )
                    else
                      PCard(
                        variant: PCardVariant.shadow,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < filtered.length; i++)
                              _ManageRow(
                                asset: filtered[i],
                                masked: masked,
                                negative: isCard,
                                tokens: t,
                                showTopBorder: i > 0,
                                onTap: () => showAssetDetailRich(
                                  context,
                                  filtered[i],
                                  onEdit: () =>
                                      showAssetEditForm(context, filtered[i]),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 계좌·카드 관리 skeleton — 탭 + 총액행 + PCard 리스트 5행.
class _AccountCardManageSkeleton extends StatelessWidget {
  const _AccountCardManageSkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Column(
      children: [
        // 탭 영역 (underline, full-width — AppBar 바로 아래 bgSurface 띠)
        Container(
          color: t.bgSurface,
          child: Row(
            children: [
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    child: PSkeleton.line(width: 60),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x20,
              vertical: PSpace.x20,
            ),
            children: [
              // 총액 + 추가 버튼 행
              Row(
                children: [
                  const PSkeleton.line(width: 80),
                  const Spacer(),
                  const PSkeleton(width: 72, height: 32),
                ],
              ),
              const SizedBox(height: PSpace.x4),
              PCard(
                variant: PCardVariant.shadow,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (int i = 0; i < 5; i++)
                      _ManageRowSkel(isLast: i == 4, tokens: t),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManageRowSkel extends StatelessWidget {
  const _ManageRowSkel({required this.isLast, required this.tokens});
  final bool isLast;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: t.borderSubtle)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x16,
        vertical: PSpace.x16,
      ),
      child: Row(
        children: [
          const PSkeleton(width: 36, height: 36),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PSkeleton.line(width: 80),
                const SizedBox(height: 4),
                PSkeleton.line(width: 56, height: 12),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          const PSkeleton.line(width: 72),
          const SizedBox(width: PSpace.x8),
          const PSkeleton(width: 18, height: 18),
        ],
      ),
    );
  }
}

class _ManageRow extends StatelessWidget {
  const _ManageRow({
    required this.asset,
    required this.masked,
    required this.negative,
    required this.tokens,
    required this.showTopBorder,
    required this.onTap,
  });

  final Asset asset;
  final bool masked;
  final bool negative;
  final PorestTokens tokens;
  final bool showTopBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final balance = asset.balance ?? 0;
    final sub = [asset.institution, asset.memo]
        .where((s) => s != null && s.isNotEmpty)
        .join(' · ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: showTopBorder
                ? Border(top: BorderSide(color: t.borderSubtle))
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: PSpace.x16),
          child: Row(
            children: [
              AssetLogo(asset: asset),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.assetName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.fgPrimary,
                        fontSize: PFontSize.body,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.fgTertiary,
                          fontSize: PFontSize.caption,
                          fontWeight: PFontWeight.medium,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: PSpace.x8),
              Text(
                masked
                    ? '•••'
                    : negative
                        ? '−${krw(balance.abs())}원'
                        : '${krw(balance)}원',
                style: TextStyle(
                  color: t.fgPrimary,
                  fontSize: PFontSize.bodyLg,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.32,
                ),
              ),
              const SizedBox(width: PSpace.x8),
              Icon(LucideIcons.chevronRight, size: 18, color: t.fgTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
