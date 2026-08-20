import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_edit_dialog.dart';
import 'package:porest_desk_app/features/asset/presentation/widgets/asset_logo.dart';

/// 계좌·카드 관리 — web AccountManager 미러. 설정 단일 진입점에서 자산 추가/편집.
/// 탭(계좌·예금/카드/투자) + 총액 + 리스트(항목 → 편집) + 그룹별 추가.
enum _Group { account, card, invest }

const Map<_Group, List<String>> _groupTypes = {
  _Group.account: ['BANK_ACCOUNT', 'SAVINGS', 'CASH', 'LOAN'],
  _Group.card: ['CREDIT_CARD', 'CHECK_CARD'],
  _Group.invest: ['INVESTMENT'],
};

String _groupLabel(AppLocalizations l, _Group g) => switch (g) {
      _Group.account => l.assetCatAccount,
      _Group.card => l.assetGroupCard,
      _Group.invest => l.assetGroupInvestment,
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
    final l = AppLocalizations.of(context);
    final masked = ref.watch(hideCardProvider('asset.manage'));
    final assetsAsync = ref.watch(assetsProvider);

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.assetManageTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: assetsAsync.when(
        loading: () => _AccountCardManageSkeleton(tokens: t),
        error: (e, _) => Center(
          child: Text(
            '${l.assetLoadError}\n$e',
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
          // '총액 제외'(isIncludedInTotal == 'N') 자산은 탭 합계에서 제외 (web 정합).
          final total = filtered
              .where((a) => a.isIncludedInTotal != 'N')
              .fold<int>(0, (s, a) => s + (a.balance ?? 0));
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
                      label: l.assetTabAccountsSavings(countOf(_Group.account)),
                    ),
                    PTabItem(
                      value: _Group.card,
                      label: l.assetTabCards(countOf(_Group.card)),
                    ),
                    PTabItem(
                      value: _Group.invest,
                      label: l.assetTabInvest(countOf(_Group.invest)),
                    ),
                  ],
                ),
              ),
              // 콘텐츠 (총액 + 리스트, page-edge padding)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PSpace.x24,
                    vertical: PSpace.x20,
                  ),
                  children: [
                    // 총액 (좌) + 추가 (우, ghost+accent)
                    Row(
                      children: [
                        Text(
                          masked
                              ? '${l.assetTotalPrefix} ••••••'
                              : '${l.assetTotalPrefix} ${krwSigned(total, false, unit: true)}',
                          style: PTypo.caption.copyWith(color: t.fgTertiary),
                        ),
                        const Spacer(),
                        PButton(
                          label: l.assetAddCategory(_groupLabel(l, _tab)),
                          icon: LucideIcons.plus,
                          variant: PButtonVariant.accent,
                          size: PButtonSize.sm,
                          onPressed: _onAdd,
                        ),
                      ],
                    ),
                    // 리스트 — 총액 label 과 gap 0(사용자 결정, label·list 는 한 묶음).
                    // margin-top -8(web 정합) — Flutter 음수 margin 없어 Transform.translate
                    // (paint-only, label↔list 시각 간격 -8 당김).
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: PSpace.x32,
                              ),
                              child: Center(
                                child: Text(
                                  l.assetCategoryEmpty(_groupLabel(l, _tab)),
                                  style: PTypo.bodySm.copyWith(
                                    color: t.fgTertiary,
                                  ),
                                ),
                              ),
                            )
                          // 카드 다이어트 — 카드 없이 플랫 행 리스트.
                          : Column(
                              children: [
                                for (var i = 0; i < filtered.length; i++)
                                  _ManageRow(
                                    asset: filtered[i],
                                    masked: masked,
                                    negative: isCard,
                                    tokens: t,
                                    onTap: () => showAssetDetailRich(
                                      context,
                                      filtered[i],
                                      onEdit: () => showAssetEditForm(
                                          context, filtered[i]),
                                      // 관리 화면이라 상세에서 지울 수 있다.
                                      allowDelete: true,
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
              horizontal: PSpace.x24,
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
              // 스켈레톤 플랫 — 총액 label 과 gap 0 + Transform -8(실제 리스트 정합).
              Transform.translate(
                offset: const Offset(0, -8),
                child: Column(
                  children: [
                    for (int i = 0; i < 5; i++)
                      const _ManageRowSkel(),
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
  const _ManageRowSkel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 0, // 실제 행과 같은 값
        vertical: PSpace.x16,
      ),
      child: Row(
        children: [
          PSkeleton(width: 36, height: 36),
          SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PSkeleton.line(width: 80),
                SizedBox(height: 4),
                PSkeleton.line(width: 56, height: 12),
              ],
            ),
          ),
          SizedBox(width: PSpace.x8),
          PSkeleton.line(width: 72),
          SizedBox(width: PSpace.x8),
          PSkeleton(width: 18, height: 18),
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
    required this.onTap,
  });

  final Asset asset;
  final bool masked;
  final bool negative;
  final PorestTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    final balance = asset.balance ?? 0;
    // 카드 사용액은 음수 표기 컨벤션, 계좌는 실제 부호(대출 등 음수 잔액).
    // 음수만 fg-expense 강조, 0 은 부호·강조 없이 '0원' (−0원 방지) — web 정합.
    // 저장된 부호를 그대로 믿는다 — 예전엔 카드 그룹에서 부호를 강제로 뒤집었는데,
    // 그러면 데이터가 양수로 어긋나도 행은 멀쩡해 보이고 합계만 틀린 값이 나온다.
    // 지금은 저장할 때 음수로 정규화하므로 표시에서 손볼 게 없다.
    final isNeg = balance < 0;
    final sub = [asset.institution, asset.memo]
        .where((s) => s != null && s.isNotEmpty)
        .join(' · ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          // web MANAGE_ROW(계좌·카테고리 공용) 정합 — py 12 / 아이콘 36 / 금액 bodySm
          // 좌우 0 — 페이지가 24 를 쥔다. 행이 더 얹으면 위 라벨과 어긋난다(설정 리스트 공통 규칙).
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: PSpace.x12),
          child: Row(
            children: [
              AssetLogo(asset: asset, size: 36),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    masked
                        ? '••••'
                        : isNeg
                            ? krwSigned(balance.abs(), false, sign: '−', unit: true)
                            : krwSigned(balance.abs(), false, unit: true),
                    style: TextStyle(
                      color: t.fgPrimary,
                      fontSize: PFontSize.bodySm,
                      fontWeight: PFontWeight.bold,
                      letterSpacing: -0.32,
                    ),
                  ),
                  // web 정합 — 총액 미포함 자산은 금액 아래 작은 '총액 제외' 표기
                  if (asset.isIncludedInTotal == 'N') ...[
                    const SizedBox(height: 2),
                    Text(
                      l.assetExcludedFromTotal,
                      style: TextStyle(
                        color: t.fgTertiary,
                        fontSize: PFontSize.micro,
                      ),
                    ),
                  ],
                ],
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
