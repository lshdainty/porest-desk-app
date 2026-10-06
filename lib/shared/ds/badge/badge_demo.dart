import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/badge/p_badge.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';

/// 카탈로그(/dev/ds) — 변형 셋 × 톤 여섯 × 크기 둘, 앞 아이콘, 줄 옆에 붙는 자리, 둘 묶음(좁으면 각자 말줄임).
class BadgeDemo extends StatelessWidget {
  const BadgeDemo({super.key});

  // 톤마다 스펙의 porest 예(badge.md — Tone)
  static const _labels = {
    PBadgeTone.neutral: '예정',
    PBadgeTone.brand: '나',
    PBadgeTone.informative: '읽기 전용',
    PBadgeTone.positive: '달성',
    PBadgeTone.warning: '만료 임박',
    PBadgeTone.critical: '연체',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final variant in PBadgeVariant.values)
          DemoBlock(
            title: switch (variant) {
              PBadgeVariant.weak => 'weak — 옅은 바탕(기본, 되풀이되는 목록)',
              PBadgeVariant.solid => 'solid — 채움(한 화면에 꼭 눈에 띌 것 하나)',
              PBadgeVariant.outline => 'outline — 옅은 선(상세 · 본문의 중간 강조)',
            },
            children: [
              for (final size in PBadgeSize.values)
                DemoRow(
                  label: size == PBadgeSize.medium
                      ? 'medium 20(기본)'
                      : 'large 24',
                  children: [
                    for (final tone in PBadgeTone.values)
                      PBadge(
                        label: _labels[tone]!,
                        variant: variant,
                        tone: tone,
                        size: size,
                      ),
                  ],
                ),
            ],
          ),
        const DemoBlock(
          title: '앞 아이콘 — 글자색을 따르고 읽지 않는다',
          children: [
            DemoRow(
              label: 'prefixIcon',
              children: [
                PBadge(
                  label: '편집 가능',
                  prefixIcon: LucideIcons.pencil,
                  variant: PBadgeVariant.outline,
                  tone: PBadgeTone.positive,
                ),
                PBadge(
                  label: '읽기 전용',
                  prefixIcon: LucideIcons.eye,
                  variant: PBadgeVariant.outline,
                  tone: PBadgeTone.informative,
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '줄 옆 — 이름은 말줄임, 배지는 줄지 않는다',
          children: [
            SizedBox(
              width: 200,
              child: Row(
                spacing: PSpacing.x1_5,
                children: [
                  Flexible(
                    child: Text(
                      '넷플릭스 프리미엄 정기 결제',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypography.t5.copyWith(color: c.fgNeutral),
                    ),
                  ),
                  const PBadge(label: '예정'),
                ],
              ),
            ),
          ],
        ),
        const DemoBlock(
          title: '둘 묶음 — 사이 4, 좁으면 줄바꿈하지 않고 각자 말줄임',
          children: [
            SizedBox(
              width: 150,
              child: PBadgeGroup(
                children: [
                  PBadge(label: '신용', size: PBadgeSize.large),
                  PBadge(
                    label: '단종된 카드',
                    variant: PBadgeVariant.solid,
                    size: PBadgeSize.large,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
