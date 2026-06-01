import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/krw.dart';
import '../../../shared/widgets/p_badge.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_collapsible.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../application/card_providers.dart';
import '../domain/card_catalog.dart';

/// 카드 혜택 상세 — front `CardBenefitDialog` 미러 (모바일 바텀시트).
///
/// 구조:
///   - 카드 hero (imgUrl 실제 이미지, errorBuilder fallback)
///   - 연회비 / 전월 실적 2셀
///   - 주요 혜택 태그 (PBadge)
///   - 혜택 상세 (PCollapsible 아코디언 + 모두 펼치기/접기)
void showCardBenefitDetailSheet(BuildContext context, int rowId) {
  showPSheet(
    context,
    title: '카드 상세',
    initialChildSize: 0.9,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    contentBuilder: (ctx, scrollCtrl) =>
        _CardBenefitDetailContent(rowId: rowId, scrollController: scrollCtrl),
    footerBuilder: (ctx) => Row(
      children: [
        const Spacer(),
        PButton(
          label: '닫기',
          variant: PButtonVariant.ghost,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
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
          Text('카드 상세 로드 실패\n$e',
              style: PTypo.bodySm.copyWith(color: t.statusDanger)),
        ],
      ),
      data: (d) {
        final s = d.summary;
        final benefits = d.benefits;
        final allOpen =
            benefits.isNotEmpty && _expanded.length == benefits.length;

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
                    label: '연회비',
                    value: _feeText(s.annualFee),
                    tokens: t,
                  ),
                ),
                const SizedBox(width: PSpace.x8),
                Expanded(
                  child: _InfoCell(
                    label: '전월 실적',
                    value: _performanceText(s.performance),
                    tokens: t,
                  ),
                ),
              ],
            ),
            const SizedBox(height: PSpace.x20),

            // 주요 혜택 태그
            if (d.topBenefits.isNotEmpty) ...[
              Text('주요 혜택 태그',
                  style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary, fontWeight: PFontWeight.bold)),
              const SizedBox(height: PSpace.x8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final g in d.topBenefits)
                    for (final tag in g.tags)
                      PBadge(
                          label: tag, variant: PBadgeVariant.softBrand),
                ],
              ),
              const SizedBox(height: PSpace.x20),
            ],

            // 혜택 상세 — 아코디언
            if (benefits.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text('혜택 상세 · ${benefits.length}건',
                        style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold)),
                  ),
                  PButton(
                    label: allOpen ? '모두 접기' : '모두 펼치기',
                    icon: allOpen
                        ? LucideIcons.chevronsDownUp
                        : LucideIcons.chevronsUpDown,
                    variant: PButtonVariant.ghost,
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
              Text('유의사항',
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
String _feeText(CardAnnualFee? fee) {
  if (fee == null) return '없음';
  if (fee.label != null && fee.label!.isNotEmpty) return fee.label!;
  final amount = fee.amount;
  if (amount == null || amount == 0) return '없음';
  return '국내전용 ${krw(amount)}원';
}

/// 전월 실적 라벨 — front `perf === 0 ? '실적 무관' : 'N원 이상'` 정합.
String _performanceText(CardPerformance? perf) {
  if (perf == null) return '실적 무관';
  if (perf.requiredText != null && perf.requiredText!.isNotEmpty) {
    return perf.requiredText!;
  }
  final amount = perf.requiredAmount;
  if (amount == null || amount == 0) return '실적 무관';
  return '${krw(amount)}원 이상';
}

class _CardHero extends StatelessWidget {
  const _CardHero({required this.summary, required this.tokens});
  final CardCatalogSummary summary;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
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
                  errorBuilder: (_, _, _) => _HeroFallback(tokens: t),
                )
              else
                _HeroFallback(tokens: t),
              if (discontinued)
                Positioned(
                  top: PSpace.x12,
                  right: PSpace.x12,
                  child: PBadge(
                      label: '단종', variant: PBadgeVariant.secondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// imgUrl 없거나 로드 실패 시 — 중립 그라데이션 + 카드 아이콘.
class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.tokens});
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
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
    required this.open,
    required this.onToggle,
    required this.tokens,
  });
  final CardBenefit benefit;
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
                        if ((benefit.title ?? '').isNotEmpty)
                          Text(benefit.title!,
                              style: PTypo.body.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: PFontWeight.bold)),
                        if ((benefit.summary ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(benefit.summary!,
                                    style: PTypo.bodySm.copyWith(
                                        color: t.fgBrand,
                                        fontWeight: PFontWeight.bold)),
                              ),
                              if ((benefit.category ?? '').isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: t.bgSunken,
                                    borderRadius: PRadius.brFull,
                                  ),
                                  child: Text(benefit.category!,
                                      style: PTypo.micro.copyWith(
                                          color: t.fgTertiary,
                                          fontWeight: PFontWeight.semi,
                                          letterSpacing: 0)),
                                ),
                              ],
                            ],
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
                    PSpace.x16, 14, PSpace.x16, PSpace.x16),
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
