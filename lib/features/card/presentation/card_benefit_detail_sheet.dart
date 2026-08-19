import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_collapsible.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog.dart';
import 'package:porest_desk_app/features/card/presentation/card_fee_text.dart';
import 'package:porest_desk_app/features/card/presentation/widgets/card_brand.dart';

/// 카드 혜택 상세 — front `CardBenefitDialog` 미러 (모바일 바텀시트).
///
/// 구조:
///   - 카드 hero (imgUrl 실제 이미지, errorBuilder fallback)
///   - 연회비 / 전월 실적 2셀
///   - 주요 혜택 태그 (PBadge)
///   - 혜택 상세 (PCollapsible 아코디언 + 모두 펼치기/접기)
void showCardBenefitDetailSheet(BuildContext context, int rowId) {
  final l = AppLocalizations.of(context);
  showPSheet(
    context,
    title: l.assetCardDetail,
    initialChildSize: 0.9,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    contentBuilder: (ctx, scrollCtrl) =>
        _CardBenefitDetailContent(rowId: rowId, scrollController: scrollCtrl),
    // 읽기전용 뷰 — 단일 닫기. PViewFooter(confirm='닫기' ghost).
    footerBuilder: (ctx) => PViewFooter(
      confirmLabel: l.actionClose,
      confirmVariant: PButtonVariant.ghost,
    ),
  );
}

class _CardBenefitDetailContent extends ConsumerStatefulWidget {
  const _CardBenefitDetailContent({
    required this.rowId,
    required this.scrollController,
  });
  final int rowId;
  final ScrollController scrollController;

  @override
  ConsumerState<_CardBenefitDetailContent> createState() =>
      _CardBenefitDetailContentState();
}

class _CardBenefitDetailContentState
    extends ConsumerState<_CardBenefitDetailContent> {
  /// 펼친 혜택 index 집합.
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final detailAsync = ref.watch(cardCatalogDetailProvider(widget.rowId));

    return detailAsync.when(
      loading: () => _DetailSkeleton(
        tokens: t,
        scrollController: widget.scrollController,
      ),
      error: (e, _) => ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(
            PSpace.x20, PSpace.x4, PSpace.x20, PSpace.x24),
        children: [
          Text('${l.cardDetailLoadError}\n$e',
              style: PTypo.bodySm.copyWith(color: t.statusDanger)),
        ],
      ),
      data: (d) {
        final s = d.summary;
        final benefits = d.benefits;
        final allOpen =
            benefits.isNotEmpty && _expanded.length == benefits.length;
        // front flattenTopTags 정합 — topBenefits[].tags flatten + 중복 제거.
        // (그룹마다 '10%'·'청구할인' 같은 공통 태그가 들어 있어 dedup 안 하면 중복 노출)
        final topTags = <String>[];
        final seenTags = <String>{};
        for (final g in d.topBenefits) {
          for (final tag in g.tags) {
            if (tag.isNotEmpty && seenTags.add(tag)) topTags.add(tag);
          }
        }
        // front 상세 조건 badge — 카드 전월 실적(requiredText ?? '실적 무관'). 모든 혜택 공통.
        final benefitCondition = _benefitCondition(l, s.performance);

        return ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(
              PSpace.x20, PSpace.x4, PSpace.x20, PSpace.x24),
          children: [
            // 카드 hero
            _CardHero(summary: s, tokens: t),
            const SizedBox(height: PSpace.x16),

            // 연회비 / 전월 실적 2셀
            Row(
              children: [
                Expanded(
                  child: _InfoCell(
                    label: l.assetAnnualFee,
                    value: _feeText(l, s.annualFee),
                    tokens: t,
                  ),
                ),
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: _InfoCell(
                    label: l.cardLastMonthPerf,
                    value: _performanceText(l, s.performance),
                    tokens: t,
                  ),
                ),
              ],
            ),
            const SizedBox(height: PSpace.x20),

            // 주요 혜택 태그 (중복 제거)
            if (topTags.isNotEmpty) ...[
              Text(l.cardKeyBenefitTags,
                  style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.bold)),
              const SizedBox(height: PSpace.x8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in topTags)
                    PBadge(label: tag, variant: PBadgeVariant.softBrand),
                ],
              ),
              const SizedBox(height: PSpace.x20),
            ],

            // 혜택 상세 — 아코디언
            if (benefits.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(l.cardBenefitDetailCount(benefits.length),
                        style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold)),
                  ),
                  PButton(
                    label: allOpen ? l.cardCollapseAll : l.cardExpandAll,
                    icon: allOpen
                        ? LucideIcons.chevronsDownUp
                        : LucideIcons.chevronsUpDown,
                    // front: accent(brand 강조) — 텍스트 fgBrand(다크 primary-light)
                    variant: PButtonVariant.accent,
                    size: PButtonSize.sm,
                    onPressed: () => setState(() {
                      if (allOpen) {
                        _expanded.clear();
                      } else {
                        _expanded
                          ..clear()
                          ..addAll(List.generate(benefits.length, (i) => i));
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: PSpace.x8),
              for (int i = 0; i < benefits.length; i++) ...[
                if (i > 0) const SizedBox(height: PSpace.x8),
                _BenefitAccordion(
                  benefit: benefits[i],
                  condition: benefitCondition,
                  open: _expanded.contains(i),
                  onToggle: () => setState(() {
                    _expanded.contains(i)
                        ? _expanded.remove(i)
                        : _expanded.add(i);
                  }),
                  tokens: t,
                ),
              ],
            ],

            // 유의사항
            if (d.cautions.isNotEmpty) ...[
              const SizedBox(height: PSpace.x20),
              Text(l.cardCautions,
                  style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.bold)),
              const SizedBox(height: PSpace.x8),
              PCard(
                variant: PCardVariant.muted,
                color: t.statusWarningSubtle,
                padding: const EdgeInsets.all(PSpace.x12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final c in d.cautions)
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
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 연회비 라벨 — front `card.fee === 0 ? '없음' : '국내전용 N원'` 정합.
String _feeText(AppLocalizations l, CardAnnualFee? fee) =>
    // label 우선 + 금액만 있으면 "국내전용 N원". fee 가 null 이면 "정보 없음",
    // 0원이면 "무료" 로 갈린다.
    cardFeeValue(l, fee, domesticPrefix: true);

/// 전월 실적 라벨 — front `perf === 0 ? '실적 무관' : 'N원 이상'` 정합.
String _performanceText(AppLocalizations l, CardPerformance? perf) {
  if (perf == null) return l.cardPerfNone;
  if (perf.requiredText != null && perf.requiredText!.isNotEmpty) {
    return perf.requiredText!;
  }
  final amount = perf.requiredAmount;
  if (amount == null || amount == 0) return l.cardPerfNone;
  return l.cardPerfMin(krwSigned(amount, false, unit: true));
}

/// 혜택 상세 항목 조건 badge — front CardBenefitDialog 정합.
/// requiredText 있으면 그대로, 없으면 (필수=Y → badge 숨김 / 미필수 → '실적 무관').
String? _benefitCondition(AppLocalizations l, CardPerformance? perf) {
  if (perf == null) return l.cardPerfNone;
  if (perf.requiredText != null && perf.requiredText!.isNotEmpty) {
    return perf.requiredText;
  }
  if (perf.isRequired == 'Y') return null;
  return l.cardPerfNone;
}

class _CardHero extends StatelessWidget {
  const _CardHero({required this.summary, required this.tokens});
  final CardCatalogSummary summary;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    final discontinued = summary.isDiscontinued == 'Y';
    return Opacity(
      opacity: discontinued ? 0.7 : 1,
      child: ClipRRect(
        borderRadius: PRadius.brLg,
        child: AspectRatio(
          aspectRatio: 1.586,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (summary.imgUrl != null && summary.imgUrl!.isNotEmpty)
                Image.network(
                  summary.imgUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _HeroFallback(
                    company: summary.company?.name,
                    cardName: summary.cardName,
                    tokens: t,
                  ),
                )
              else
                _HeroFallback(
                  company: summary.company?.name,
                  cardName: summary.cardName,
                  tokens: t,
                ),
              if (discontinued)
                Positioned(
                  top: PSpace.x12,
                  right: PSpace.x12,
                  child: PBadge(
                      label: l.assetDiscontinued, variant: PBadgeVariant.secondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상세 hero fallback — 3단계 중 2·3단계.
/// 브랜드 매칭 → 카드사 색 그라데이션 + 브랜드명/카드명 오버레이.
/// 미상 → 중립 그라데이션(bgMuted~bgSunken) + 카드 아이콘.
class _HeroFallback extends StatelessWidget {
  const _HeroFallback({
    required this.company,
    required this.cardName,
    required this.tokens,
  });
  final String? company;
  final String? cardName;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final brand = getCardBrand(company);

    if (!brand.known) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.bgMuted, t.bgSunken],
          ),
        ),
        child: Center(
          child: Icon(LucideIcons.creditCard, size: 48, color: t.fgTertiary),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand.bg1, brand.bg2],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 135deg 광택 — 그라데이션 위 부드러운 하이라이트.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x26FFFFFF), Color(0x00FFFFFF)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(PSpace.x20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if ((company ?? '').trim().isNotEmpty)
                  Text(company!.trim(),
                      style: PTypo.bodySm.copyWith(
                          color: brand.fg,
                          fontWeight: PFontWeight.semi),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if ((cardName ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(cardName!.trim(),
                      style: PTypo.body.copyWith(
                          color: brand.fg,
                          fontWeight: PFontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell(
      {required this.label, required this.value, required this.tokens});
  final String label;
  final String value;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return PCard(
      variant: PCardVariant.muted,
      padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x12, vertical: PSpace.x12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: PTypo.caption.copyWith(
                  color: tokens.fgTertiary,
                  fontWeight: PFontWeight.semi)),
          const SizedBox(height: 4),
          Text(value,
              style: PTypo.body.copyWith(
                  color: tokens.fgPrimary,
                  fontWeight: PFontWeight.bold)),
        ],
      ),
    );
  }
}

/// 혜택 상세 1건 — PCollapsible 기반 아코디언 (헤더 항상 보임 + 본문 토글).
class _BenefitAccordion extends StatelessWidget {
  const _BenefitAccordion({
    required this.benefit,
    required this.condition,
    required this.open,
    required this.onToggle,
    required this.tokens,
  });
  final CardBenefit benefit;

  /// 카드 전월 실적 조건 라벨(예: "300,000원 이상" / "실적 무관"). null이면 badge 숨김.
  final String? condition;
  final bool open;
  final VoidCallback onToggle;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return PCard(
      variant: PCardVariant.bordered,
      padding: EdgeInsets.zero,
      child: PCollapsible(
        open: open,
        onOpenChanged: (_) => onToggle(),
        trigger: (ctx, isOpen, toggle) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: toggle,
            borderRadius: PRadius.brLg,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: PSpace.x16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // front: 제목 = 혜택 카테고리(예: "온라인쇼핑")
                        if ((benefit.category ?? '').isNotEmpty)
                          Text(benefit.category!,
                              style: PTypo.body.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: PFontWeight.bold)),
                        if ((benefit.summary ?? benefit.title ?? '')
                            .isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(benefit.summary ?? benefit.title ?? '',
                              style: PTypo.bodySm.copyWith(
                                  color: t.fgBrand,
                                  fontWeight: PFontWeight.bold)),
                        ],
                        // front: badge = 카드 전월 실적 조건 — 요약 아래 별도 줄(좌측 정렬)
                        if (condition != null && condition!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: t.bgSunken,
                                borderRadius: PRadius.brFull,
                              ),
                              child: Text(condition!,
                                  style: PTypo.micro.copyWith(
                                      color: t.fgTertiary,
                                      fontWeight: PFontWeight.semi,
                                      letterSpacing: 0)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: PSpace.x8),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 150),
                    turns: isOpen ? 0.5 : 0,
                    child: Icon(LucideIcons.chevronDown,
                        size: 16, color: t.fgTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),
        content: (benefit.detail ?? '').isEmpty
            ? const SizedBox.shrink()
            : Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: t.borderSubtle)),
                ),
                padding: const EdgeInsets.fromLTRB(
                    PSpace.x20, 14, PSpace.x20, PSpace.x16),
                child: Text(benefit.detail!,
                    style: PTypo.bodySm.copyWith(
                        color: t.fgSecondary,
                        height: PLineHeight.loose)),
              ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton(
      {required this.tokens, required this.scrollController});
  final PorestTokens tokens;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x20, PSpace.x4, PSpace.x20, PSpace.x24),
      children: [
        AspectRatio(
          aspectRatio: 1.586,
          child:
              PSkeleton(width: double.infinity, borderRadius: PRadius.brLg),
        ),
        const SizedBox(height: PSpace.x16),
        Row(
          children: [
            Expanded(
              child: PCard(
                variant: PCardVariant.muted,
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
                variant: PCardVariant.muted,
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
        const PSkeleton.line(width: 88),
        const SizedBox(height: PSpace.x8),
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: PSpace.x8),
          PCard(
            variant: PCardVariant.bordered,
            padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PSkeleton.line(width: i.isEven ? 110 : 90),
                      const SizedBox(height: 6),
                      PSkeleton.line(width: 70, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
