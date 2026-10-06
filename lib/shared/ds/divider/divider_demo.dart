import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/divider/p_divider.dart';

/// 카탈로그(/dev/ds) — 가로(끝까지 · 들임 16) · 세로(줄 높이를 따른다, 들임은 위아래 16).
class DividerDemo extends StatelessWidget {
  const DividerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpacing.x3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: PTypography.t4.copyWith(color: c.fgNeutralMuted)),
          Text(value, style: PTypography.t4.copyWith(color: c.fgNeutral)),
        ],
      ),
    );
    Widget cell(String label, String value) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpacing.x4),
        child: Column(
          spacing: PSpacing.x1,
          children: [
            Text(
              label,
              style: PTypography.t2.copyWith(color: c.fgNeutralSubtle),
            ),
            Text(value, style: PTypography.t4.copyWith(color: c.fgNeutral)),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '가로 — 같은 묶음 안은 들인 선(inset 16), 묶음 사이는 끝까지',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                line('결제 수단', '신한카드'),
                const PDivider(inset: PDividerInset.inset),
                line('할부', '3개월'),
                const PDivider(),
                line('메모', '부모님 선물'),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '세로 — 가로로 놓인 칸 사이, 줄 높이를 따른다(IntrinsicHeight)',
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  cell('수입', '3,200,000원'),
                  const PDivider(
                    axis: Axis.vertical,
                    inset: PDividerInset.inset,
                  ),
                  cell('지출', '1,840,000원'),
                  const PDivider(
                    axis: Axis.vertical,
                    inset: PDividerInset.inset,
                  ),
                  cell('남은 돈', '1,360,000원'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
