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
import '../../../shared/widgets/p_progress.dart';
import '../../../shared/widgets/p_toggle.dart';
import '../application/asset_providers.dart';
import '../domain/asset.dart';
import 'asset_edit_dialog.dart';
import 'widgets/asset_logo.dart';

/// 계좌·카드 관리 — web AccountManager 미러. 설정 단일 진입점에서 자산 추가/편집.
/// 탭(계좌·예금/카드/투자) + 총액 + 리스트(항목 → 편집) + 그룹별 추가.
enum _Group { account, card, invest }

const Map<_Group, List<String>> _groupTypes = {
  _Group.account: ['BANK_ACCOUNT', 'SAVINGS', 'CASH'],
  _Group.card: ['CREDIT_CARD', 'CHECK_CARD', 'LOAN'],
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
        loading: () => const Center(child: PCircularProgressIndicator()),
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

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x20,
              vertical: PSpace.x20,
            ),
            children: [
              // 탭 (계좌·예금 / 카드 / 투자)
              PToggleGroupSingle<_Group>(
                value: _tab,
                expanded: true,
                visual: PToggleGroupVisual.solid,
                onChanged: (v) => setState(() => _tab = v),
                items: [
                  PToggleGroupItem(
                    value: _Group.account,
                    label: '계좌·예금 ${countOf(_Group.account)}',
                  ),
                  PToggleGroupItem(
                    value: _Group.card,
                    label: '카드 ${countOf(_Group.card)}',
                  ),
                  PToggleGroupItem(
                    value: _Group.invest,
                    label: '투자 ${countOf(_Group.invest)}',
                  ),
                ],
              ),
              const SizedBox(height: PSpace.x12),
              // 총액
              Text(
                masked ? '총 •••' : '총 ${krw(total)}원',
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
              const SizedBox(height: PSpace.x8),
              // 리스트
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x32),
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
                  padding: const EdgeInsets.symmetric(horizontal: PSpace.x16),
                  child: Column(
                    children: [
                      for (var i = 0; i < filtered.length; i++)
                        _ManageRow(
                          asset: filtered[i],
                          masked: masked,
                          negative: isCard,
                          tokens: t,
                          showTopBorder: i > 0,
                          onTap: () => showAssetEditForm(context, filtered[i]),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: PSpace.x20),
              // 그룹별 추가
              Center(
                child: PButton(
                  label: '${_groupLabel(_tab)} 추가',
                  icon: LucideIcons.plus,
                  onPressed: _onAdd,
                ),
              ),
            ],
          );
        },
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
          padding: const EdgeInsets.symmetric(vertical: 14),
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
                    if (asset.institution != null &&
                        asset.institution!.isNotEmpty)
                      Text(
                        asset.institution!,
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
