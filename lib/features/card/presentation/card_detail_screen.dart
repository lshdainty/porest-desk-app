import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/krw.dart';
import '../application/card_providers.dart';

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.catalogId});
  final int catalogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final detailAsync = ref.watch(cardCatalogDetailProvider(catalogId));

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('카드 상세'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(PSpace.x16),
          child: Text('카드 상세 로드 실패\n$e',
              style: PTypo.bodySm.copyWith(color: t.statusDanger)),
        ),
        data: (d) {
          final s = d.summary;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, PSpace.x16, PSpace.x16, PSpace.x40),
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
                      color: t.fgPrimary, fontWeight: PFontWeight.heavy)),
              const SizedBox(height: 4),
              Text(
                [
                  s.company?.name,
                  s.cardType == 'CREDIT' ? '신용' : '체크',
                ].whereType<String>().join(' · '),
                style: PTypo.bodySm.copyWith(color: t.fgSecondary),
              ),
              const SizedBox(height: PSpace.x16),

              // 연회비/실적 카드
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      label: '연회비',
                      value: s.annualFee?.label ??
                          (s.annualFee?.amount != null
                              ? '${krw(s.annualFee!.amount!)}원'
                              : '없음'),
                      tokens: t,
                    ),
                  ),
                  const SizedBox(width: PSpace.x8),
                  Expanded(
                    child: _InfoCard(
                      label: '전월 실적',
                      value: s.performance?.requiredText ??
                          (s.performance?.requiredAmount != null
                              ? '${krw(s.performance!.requiredAmount!)}원'
                              : '없음'),
                      tokens: t,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PSpace.x20),

              if (d.topBenefits.isNotEmpty) ...[
                Text('주요 혜택 태그',
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                const SizedBox(height: PSpace.x8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final g in d.topBenefits)
                      for (final tag in g.tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.bgBrandSubtle,
                            borderRadius: PRadius.brFull,
                            border: Border.all(color: t.borderBrand),
                          ),
                          child: Text(tag,
                              style: PTypo.caption.copyWith(
                                  color: t.fgBrandStrong,
                                  fontWeight: PFontWeight.semi)),
                        ),
                  ],
                ),
                const SizedBox(height: PSpace.x20),
              ],

              if (d.benefits.isNotEmpty) ...[
                Text('혜택',
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
                const SizedBox(height: PSpace.x8),
                Container(
                  decoration: BoxDecoration(
                    color: t.bgSurface,
                    borderRadius: PRadius.brLg,
                    border: Border.all(color: t.borderSubtle),
                  ),
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
                          Divider(height: 1, color: t.borderSubtle),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: PSpace.x20),
              ],

              if (d.cautions.isNotEmpty) ...[
                Text('유의사항',
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

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.label, required this.value, required this.tokens});
  final String label;
  final String value;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PSpace.x12),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: tokens.borderSubtle),
      ),
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
