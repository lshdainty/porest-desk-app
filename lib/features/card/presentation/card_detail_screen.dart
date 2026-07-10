import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.catalogId});
  final int catalogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final detailAsync = ref.watch(cardCatalogDetailProvider(catalogId));

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(l.assetCardDetail),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: detailAsync.when(
        loading: () => _CardDetailSkeleton(tokens: t),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(PSpace.x16),
          child: Text('${l.cardDetailLoadError}\n$e',
              style: PTypo.bodySm.copyWith(color: t.statusDanger)),
        ),
        data: (d) {
          final s = d.summary;
          return ListView(
            padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x20, vertical: PSpace.x24),
            children: [
              // 카드 이미지
              if (s.imgUrl != null)
                ClipRRect(
                  borderRadius: PRadius.brLg,
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: Image.network(s.imgUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                            color: t.bgMuted,
                            alignment: Alignment.center,
                            child: Icon(LucideIcons.creditCard,
                                size: 48, color: t.fgTertiary))),
                  ),
                ),
              const SizedBox(height: PSpace.x16),

              Text(s.cardName,
                  style: PTypo.h3.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                [
                  s.company?.name,
                  s.cardType == 'CREDIT' ? l.assetCardShortCredit : l.assetCardShortCheck,
                ].whereType<String>().join(' · '),
                style: PTypo.bodySm.copyWith(color: t.fgSecondary),
              ),
              const SizedBox(height: PSpace.x16),

              // 연회비/실적 카드
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      label: l.assetAnnualFee,
                      value: s.annualFee?.label ??
                          (s.annualFee?.amount != null
                              ? krwSigned(s.annualFee!.amount!, false, unit: true)
                              : l.cardNone),
                      tokens: t,
                    ),
                  ),
                  const SizedBox(width: PSpace.x8),
                  Expanded(
                    child: _InfoCard(
                      label: l.cardLastMonthPerf,
                      value: s.performance?.requiredText ??
                          (s.performance?.requiredAmount != null
                              ? krwSigned(s.performance!.requiredAmount!, false, unit: true)
                              : l.cardNone),
                      tokens: t,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PSpace.x20),

              if (d.topBenefits.isNotEmpty) ...[
                Text(l.cardKeyBenefitTags,
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                const SizedBox(height: PSpace.x8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final g in d.topBenefits)
                      for (final tag in g.tags)
                        PBadge(label: tag, variant: PBadgeVariant.softBrand),
                  ],
                ),
                const SizedBox(height: PSpace.x20),
              ],

              if (d.benefits.isNotEmpty) ...[
                Text(l.cardBenefits,
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                const SizedBox(height: PSpace.x8),
                PCard(
                  variant: PCardVariant.bordered,
                  child: Column(
                    children: [
                      for (int i = 0; i < d.benefits.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.all(PSpace.x12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((d.benefits[i].title ?? '').isNotEmpty)
                                Text(d.benefits[i].title!,
                                    style: PTypo.bodySm.copyWith(
                                        color: t.fgPrimary,
                                        fontWeight: PFontWeight.bold)),
                              if ((d.benefits[i].summary ?? '').isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(d.benefits[i].summary!,
                                    style: PTypo.caption
                                        .copyWith(color: t.fgSecondary)),
                              ],
                              if ((d.benefits[i].detail ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(d.benefits[i].detail!,
                                    style: PTypo.caption
                                        .copyWith(color: t.fgTertiary)),
                              ],
                            ],
                          ),
                        ),
                        if (i < d.benefits.length - 1)
                          PDivider(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: PSpace.x20),
              ],

              if (d.cautions.isNotEmpty) ...[
                Text(l.cardCautions,
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                const SizedBox(height: PSpace.x8),
                Container(
                  padding: const EdgeInsets.all(PSpace.x12),
                  decoration: BoxDecoration(
                    color: t.statusWarningSubtle,
                    borderRadius: PRadius.brLg,
                    border: Border.all(
                        color: t.statusWarning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final c in d.cautions) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(LucideIcons.alertTriangle,
                                  size: 12, color: t.statusWarningFg),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(c.summary ?? c.title ?? '',
                                    style: PTypo.caption.copyWith(
                                        color: t.statusWarningFg)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 카드 상세 skeleton — 이미지 + 이름/서브텍스트 + 연회비/실적 카드 + 혜택 리스트.
class _CardDetailSkeleton extends StatelessWidget {
  const _CardDetailSkeleton({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x20,
        vertical: PSpace.x24,
      ),
      children: [
        AspectRatio(
          aspectRatio: 1.6,
          child: PSkeleton(width: double.infinity, borderRadius: PRadius.brLg),
        ),
        const SizedBox(height: PSpace.x16),
        const PSkeleton.line(width: 200),
        const SizedBox(height: 4),
        PSkeleton.line(width: 120, height: 12),
        const SizedBox(height: PSpace.x16),
        Row(
          children: [
            Expanded(
              child: PCard(
                variant: PCardVariant.bordered,
                padding: const EdgeInsets.all(PSpace.x12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PSkeleton.line(width: 40, height: 12),
                    const SizedBox(height: 4),
                    const PSkeleton.line(width: 60),
                  ],
                ),
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: PCard(
                variant: PCardVariant.bordered,
                padding: const EdgeInsets.all(PSpace.x12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PSkeleton.line(width: 48, height: 12),
                    const SizedBox(height: 4),
                    const PSkeleton.line(width: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x20),
        const PSkeleton.line(width: 56),
        const SizedBox(height: PSpace.x8),
        PCard(
          variant: PCardVariant.bordered,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < 4; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i < 3
                        ? Border(bottom: BorderSide(color: t.borderSubtle))
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: PSpace.x16,
                    vertical: PSpace.x12,
                  ),
                  child: Row(
                    children: [
                      PSkeleton.line(width: i.isEven ? 120 : 100),
                      const Spacer(),
                      PSkeleton.line(width: 56, height: 12),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.label, required this.value, required this.tokens});
  final String label;
  final String value;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return PCard(
      padding: const EdgeInsets.all(PSpace.x12),
      variant: PCardVariant.bordered,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
          const SizedBox(height: 2),
          Text(value,
              style: PTypo.body.copyWith(
                  color: tokens.fgPrimary, fontWeight: PFontWeight.bold)),
        ],
      ),
    );
  }
}
