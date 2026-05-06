import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../application/asset_providers.dart';
import '../domain/asset.dart';
import '../domain/asset_type_meta.dart';
import 'asset_edit_dialog.dart';
import 'asset_transfer_dialog.dart';

/// 자산 관리 화면 (More → 자산 push 라우트).
///
/// - 타입별 그룹 (계좌 / 카드 / 투자 / 부채)
/// - 각 자산: 아이콘 + 이름·기관 + 잔액
/// - 탭 → AssetEditDialog (수정·삭제)
/// - + FAB → AssetEditDialog (신규)
/// - 우상단 ⇄ 버튼 → AssetTransferDialog
class AssetScreen extends ConsumerWidget {
  const AssetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final assetsAsync = ref.watch(assetsProvider);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('자산'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '자산 간 이체',
            icon: const Icon(LucideIcons.arrowRightLeft),
            onPressed: () => showAssetTransferDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: t.bgBrand,
        foregroundColor: t.fgOnBrand,
        onPressed: () => showAssetEditDialog(context),
        child: const Icon(LucideIcons.plus),
      ),
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(assetsProvider);
          await ref.read(assetsProvider.future);
        },
        child: assetsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorBox(
            message: '자산을 불러오지 못했습니다\n$e',
            onRetry: () => ref.invalidate(assetsProvider),
          ),
          data: (assets) => _AssetList(
              assets: assets, masked: settings.hideAmounts, tokens: t),
        ),
      ),
    );
  }
}

class _AssetList extends StatelessWidget {
  const _AssetList(
      {required this.assets, required this.masked, required this.tokens});
  final List<Asset> assets;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(PSpace.x24),
        children: [
          const SizedBox(height: PSpace.x32),
          Icon(LucideIcons.wallet, size: 48, color: tokens.fgDisabled),
          const SizedBox(height: PSpace.x12),
          Text('등록된 자산이 없습니다',
              textAlign: TextAlign.center,
              style: PTypo.body.copyWith(color: tokens.fgTertiary)),
          const SizedBox(height: PSpace.x4),
          Text('우하단 + 버튼으로 첫 자산을 추가해보세요',
              textAlign: TextAlign.center,
              style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
        ],
      );
    }

    // 그룹 구성
    final byGroup = <String, List<Asset>>{};
    for (final a in assets) {
      final g = AssetTypeMeta.of(a.assetType).group;
      byGroup.putIfAbsent(g, () => []).add(a);
    }

    final orderedGroups = [
      for (final g in assetGroupOrder)
        if (byGroup.containsKey(g)) g,
      for (final g in byGroup.keys)
        if (!assetGroupOrder.contains(g)) g,
    ];

    final totalAssets = assets
        .where((a) => a.isIncludedInTotal != 'N')
        .fold<int>(0, (s, a) => s + (a.balance ?? 0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x80),
      children: [
        // 합계 카드
        Container(
          padding: const EdgeInsets.all(PSpace.x16),
          decoration: BoxDecoration(
            color: tokens.surfaceHero,
            borderRadius: PRadius.brXl,
            border: Border.all(
                color: tokens.borderBrand.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('전체 합계',
                  style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
              const SizedBox(height: 4),
              Text(krwMasked(totalAssets, masked),
                  style: PTypo.displayMd.copyWith(
                      color: tokens.fgPrimary, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        for (final group in orderedGroups) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x4, vertical: PSpace.x8),
            child: Row(
              children: [
                Text(group,
                    style: PTypo.caption.copyWith(
                        color: tokens.fgSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(width: PSpace.x8),
                Text('${byGroup[group]!.length}',
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: tokens.bgSurface,
              borderRadius: PRadius.brLg,
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Column(
              children: [
                for (int i = 0; i < byGroup[group]!.length; i++) ...[
                  _AssetRow(
                      asset: byGroup[group]![i],
                      masked: masked,
                      tokens: tokens),
                  if (i < byGroup[group]!.length - 1)
                    Divider(height: 1, color: tokens.borderSubtle, indent: 52),
                ],
              ],
            ),
          ),
          const SizedBox(height: PSpace.x12),
        ],
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.asset,
    required this.masked,
    required this.tokens,
  });
  final Asset asset;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final meta = AssetTypeMeta.of(asset.assetType);
    final excluded = asset.isIncludedInTotal == 'N';
    return InkWell(
      onTap: () => showAssetEditDialog(context, edit: asset),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Icon(meta.icon, size: 20, color: tokens.fgSecondary),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(asset.assetName,
                            style: PTypo.body.copyWith(
                                color: tokens.fgPrimary,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (excluded)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: tokens.bgMuted,
                              borderRadius: PRadius.brSm,
                            ),
                            child: Text('합계 제외',
                                style: PTypo.micro
                                    .copyWith(color: tokens.fgTertiary)),
                          ),
                        ),
                    ],
                  ),
                  if (asset.institution != null && asset.institution!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('${meta.label} · ${asset.institution}',
                          style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                          overflow: TextOverflow.ellipsis),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(meta.label,
                          style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
                    ),
                ],
              ),
            ),
            Text(
              asset.balance == null ? '—' : krwMasked(asset.balance!, masked),
              style: PTypo.money.copyWith(color: tokens.fgPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView(
      padding: const EdgeInsets.all(PSpace.x16),
      children: [
        Container(
          padding: const EdgeInsets.all(PSpace.x16),
          decoration: BoxDecoration(
            color: t.statusDangerSubtle,
            borderRadius: PRadius.brLg,
          ),
          child: Column(
            children: [
              Text(message, style: PTypo.bodySm.copyWith(color: t.statusDangerFg)),
              const SizedBox(height: PSpace.x8),
              OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ),
        ),
      ],
    );
  }
}
