import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/motion.dart';
import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/widgets/p_back_button.dart';
import 'package:groo_damda_app/shared/widgets/p_badge.dart';
import 'package:groo_damda_app/shared/widgets/p_collapsible.dart';
import 'package:groo_damda_app/shared/widgets/p_divider.dart';
import 'package:groo_damda_app/shared/widgets/p_flat_section.dart';
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/presentation/card_fee_text.dart';

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.catalogId});
  final int catalogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final detailAsync = ref.watch(cardCatalogDetailProvider(catalogId));

    // 폰 구역 화면 — 회색 바닥 위 구역마다 화면 폭 흰 띠(I-01 결정 3). 띠 안에 카드를 두지 않는다.
    return Scaffold(
      backgroundColor: context.colors.bgLayerBasement,
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
          padding: const EdgeInsets.only(top: kScreenBandGap),
          child: PScreenSection(
            child: Text(
              '${l.cardDetailLoadError}\n$e',
              style: PTypo.bodySm.copyWith(color: t.statusDangerFg),
            ),
          ),
        ),
        data: (d) {
          final s = d.summary;
          return ListView(
            padding: const EdgeInsets.only(
              top: kScreenBandGap,
              bottom: PSpacing.x6,
            ),
            children: [
              PScreenSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 카드 이미지
                    if (s.imgUrl != null) ...[
                      ClipRRect(
                        borderRadius: PRadius.brLg,
                        child: AspectRatio(
                          aspectRatio: 1.6,
                          child: Image.network(
                            s.imgUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: t.bgMuted,
                              alignment: Alignment.center,
                              child: Icon(
                                LucideIcons.creditCard,
                                size: 48,
                                color: t.fgTertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: PSpace.x16),
                    ],
                    Text(
                      s.cardName,
                      style: PTypo.h3.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        s.company?.name,
                        s.cardType == 'CREDIT'
                            ? l.assetCardShortCredit
                            : l.assetCardShortCheck,
                      ].whereType<String>().join(' · '),
                      style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                    ),
                    const SizedBox(height: PSpace.x16),
                    // 연회비 · 실적 — 띠 안이라 상자 없이 위 선 하나로 가른다
                    _InfoRow(
                      tokens: t,
                      children: [
                        _InfoCell(
                          label: l.assetAnnualFee,
                          value: cardFeeValue(l, s.annualFee),
                          tokens: t,
                        ),
                        _InfoCell(
                          label: l.cardLastMonthPerf,
                          value:
                              s.performance?.requiredText ??
                              (s.performance?.requiredAmount != null
                                  ? krwSigned(
                                      s.performance!.requiredAmount!,
                                      false,
                                      unit: true,
                                    )
                                  : l.cardNone),
                          tokens: t,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (d.topBenefits.isNotEmpty) ...[
                const SizedBox(height: kScreenBandGap),
                PScreenSection(
                  child: PFlatSection(
                    title: l.cardKeyBenefitTags,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final g in d.topBenefits)
                          for (final tag in g.tags)
                            PBadge(
                              label: tag,
                              variant: PBadgeVariant.softBrand,
                            ),
                      ],
                    ),
                  ),
                ),
              ],

              if (d.benefits.isNotEmpty) ...[
                const SizedBox(height: kScreenBandGap),
                PScreenSection(
                  child: PFlatSection(
                    title: l.cardBenefits,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < d.benefits.length; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: PSpace.x12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((d.benefits[i].title ?? '').isNotEmpty)
                                  Text(
                                    d.benefits[i].title!,
                                    style: PTypo.bodySm.copyWith(
                                      color: t.fgPrimary,
                                      fontWeight: PFontWeight.bold,
                                    ),
                                  ),
                                if ((d.benefits[i].summary ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    d.benefits[i].summary!,
                                    style: PTypo.caption.copyWith(
                                      color: t.fgSecondary,
                                    ),
                                  ),
                                ],
                                if ((d.benefits[i].detail ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    d.benefits[i].detail!,
                                    style: PTypo.caption.copyWith(
                                      color: t.fgTertiary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (i < d.benefits.length - 1) PDivider(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              if (d.cautions.isNotEmpty) ...[
                const SizedBox(height: kScreenBandGap),
                PScreenSection(
                  child: PFlatSection(
                    title: l.cardCautions,
                    child: Container(
                      padding: const EdgeInsets.all(PSpace.x12),
                      decoration: BoxDecoration(
                        color: t.statusWarningSubtle,
                        borderRadius: PRadius.brLg,
                        border: Border.all(
                          color: t.statusWarning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final c in d.cautions)
                            _CautionItem(
                              caution: c,
                              fallbackLabel: l.cardCautionDetailsFallback,
                            ),
                        ],
                      ),
                    ),
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

/// 카드 상세 skeleton — 실렌더와 같은 띠 두 장(이미지 + 이름 + 연회비/실적 · 혜택 목록).
class _CardDetailSkeleton extends StatelessWidget {
  const _CardDetailSkeleton({required this.tokens});
  final GrooTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return ListView(
      padding: const EdgeInsets.only(top: kScreenBandGap, bottom: PSpacing.x6),
      children: [
        PScreenSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.6,
                child: PSkeleton(
                  width: double.infinity,
                  borderRadius: PRadius.brLg,
                ),
              ),
              const SizedBox(height: PSpace.x16),
              const Align(
                alignment: Alignment.centerLeft,
                child: PSkeleton.line(width: 200),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: PSkeleton.line(width: 120, height: 12),
              ),
              const SizedBox(height: PSpace.x16),
              _InfoRow(
                tokens: t,
                children: [
                  for (final w in const [40.0, 48.0])
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PSkeleton.line(width: w, height: 12),
                        const SizedBox(height: 4),
                        const PSkeleton.line(width: 60),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: kScreenBandGap),
        PScreenSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PSkeleton.line(width: 56),
              const SizedBox(height: PSpace.x8),
              for (int i = 0; i < 4; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
                  child: Row(
                    children: [
                      PSkeleton.line(width: i.isEven ? 120 : 100),
                      const Spacer(),
                      PSkeleton.line(width: 56, height: 12),
                    ],
                  ),
                ),
                if (i < 3) PDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 연회비 · 실적 줄 — 띠 안이라 상자 없이 위 선 하나로 가르고 두 칸을 나란히 둔다.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.tokens, required this.children});
  final GrooTokens tokens;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: PSpace.x16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: PSpace.x12),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.label,
    required this.value,
    required this.tokens,
  });
  final String label;
  final String value;
  final GrooTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: PTypo.body.copyWith(
            color: tokens.fgPrimary,
            fontWeight: PFontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 유의사항 한 줄. `detail` 이 있으면 펼쳐 볼 수 있다.
///
/// 웹(CardCautionList.tsx)과 같은 구조다 — `summary` 를 제목으로 걸고 `detail` 은
/// 접어 둔다. 예전에는 `summary ?? title` 만 그려서 **`detail` 이 화면 어디에도
/// 나오지 않았다**. 카드사 PDF 수집분은 본문이 detail 에만 들어 있는 게 많아,
/// 유의사항이 제목만 있고 속은 빈 것처럼 보였다.
///
/// `detail` 이 없으면 펼칠 게 없으므로 chevron 도 달지 않는다(웹은 트리거를
/// disabled 로 둔다). `summary` 와 `title` 이 모두 비면 fallback 문구를 쓴다.
class _CautionItem extends StatelessWidget {
  const _CautionItem({required this.caution, required this.fallbackLabel});

  final CardBenefit caution;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final head = (caution.summary ?? caution.title ?? '').trim();
    final body = (caution.detail ?? '').trim();
    final label = head.isNotEmpty ? head : fallbackLabel;

    if (body.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _row(t, label, null),
      );
    }

    return PCollapsible(
      trigger: (context, isOpen, toggle) => InkWell(
        onTap: toggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _row(t, label, isOpen),
        ),
      ),
      content: Padding(
        // 아이콘(12) + 간격(6) 만큼 들여써 제목과 본문의 좌측을 맞춘다.
        padding: const EdgeInsets.only(left: 18, bottom: 6),
        child: Text(
          body,
          style: PTypo.caption.copyWith(color: t.statusWarningFg),
        ),
      ),
    );
  }

  Widget _row(GrooTokens t, String label, bool? isOpen) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(LucideIcons.alertTriangle, size: 12, color: t.statusWarningFg),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          label,
          style: PTypo.caption.copyWith(color: t.statusWarningFg),
        ),
      ),
      if (isOpen != null) ...[
        const SizedBox(width: 6),
        AnimatedRotation(
          turns: isOpen ? 0.5 : 0,
          duration: PMotion.fast,
          child: Icon(
            LucideIcons.chevronDown,
            size: 12,
            color: t.statusWarningFg,
          ),
        ),
      ],
    ],
  );
}
