import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/tag_group/p_tag_group.dart';

/// 카탈로그(/dev/ds) — 크기 셋, 앞세울 항목 하나(neutral · bold), 아이콘 앞 · 뒤, 줄바꿈 · 한 줄 말줄임.
class TagGroupDemo extends StatelessWidget {
  const TagGroupDemo({super.key});

  static const _meta = [
    PTag('식비', icon: LucideIcons.utensils),
    PTag('신한카드'),
    PTag('오후 2:10'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '크기 — t2 12/16(기본) · t3 13/18(목록 줄) · t4 14/19',
          children: [
            for (final size in PTagGroupSize.values)
              DemoRow(
                label: size.name,
                children: [PTagGroup(size: size, items: _meta)],
              ),
          ],
        ),
        const DemoBlock(
          title: '앞세울 항목 하나 — neutral · bold, 뜻이 있는 아이콘은 읽을 글(srLabel)',
          children: [
            PTagGroup(
              items: [
                PTag('신용카드'),
                PTag(
                  '전월 30만원 이상',
                  tone: PTagTone.neutral,
                  weight: PTagWeight.bold,
                ),
                PTag(
                  '12',
                  icon: LucideIcons.eye,
                  iconAfter: true,
                  srLabel: '조회 12',
                ),
              ],
            ),
            PTagGroup(
              items: [
                PTag('Pro', tone: PTagTone.brand),
                PTag('김민수'),
                PTag('3분 전'),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '넘칠 때 — wrap(낱말 단위 줄바꿈, 구분은 앞 줄 끝) · truncate(한 줄, 항목마다 말줄임)',
          children: [
            const SizedBox(
              width: 180,
              child: PTagGroup(
                items: [
                  PTag('생활용품'),
                  PTag('현대카드 ZERO Edition2'),
                  PTag('어제 오후 9:42'),
                ],
              ),
            ),
            SizedBox(
              width: 220,
              child: Row(
                children: [
                  Flexible(
                    child: PTagGroup(
                      size: PTagGroupSize.t3,
                      overflow: PTagGroupOverflow.truncate,
                      items: const [
                        PTag('생활용품'),
                        PTag('현대카드 ZERO Edition2'),
                        // 금액처럼 꼭 보일 항목은 줄지 않는다
                        PTag(
                          '12,800원',
                          tone: PTagTone.neutral,
                          weight: PTagWeight.bold,
                          shrink: 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '위 둘은 폭 180 · 220',
              style: PTypography.t2.copyWith(color: c.fgNeutralSubtle),
            ),
          ],
        ),
      ],
    );
  }
}
