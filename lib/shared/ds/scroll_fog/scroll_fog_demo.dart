import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/scroll_fog/p_scroll_fog.dart';

/// 카탈로그(/dev/ds) — 상자(세로) · 가로 줄 · 시트 본문(위 20 · 아래 80).
class ScrollFogDemo extends StatelessWidget {
  const ScrollFogDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget line(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpacing.x1_5),
      child: Text(text, style: PTypography.t4.copyWith(color: c.fgNeutral)),
    );
    Widget chip(String text) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.x3_5,
        vertical: PSpacing.x1_5,
      ),
      decoration: BoxDecoration(
        color: c.bgNeutralWeak,
        borderRadius: BorderRadius.circular(PRounded.full),
      ),
      child: Text(text, style: PTypography.t3.copyWith(color: c.fgNeutral)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: 'box — 위 · 아래 20',
          children: [
            SizedBox(
              height: 140,
              child: PScrollFog(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (var i = 1; i <= 12; i++) line('줄 $i')],
                ),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: 'row — 좌 · 우 20, 여백 24',
          children: [
            SizedBox(
              height: 40,
              child: PScrollFog(
                use: PScrollFogUse.row,
                child: Row(
                  spacing: PSpacing.betweenChips,
                  children: [
                    for (final t in [
                      '전체',
                      '식비',
                      '교통',
                      '쇼핑',
                      '주거',
                      '의료',
                      '여가',
                      '교육',
                    ])
                      chip(t),
                  ],
                ),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: 'overlayBody — 위 20 · 아래 80',
          children: [
            SizedBox(
              height: 200,
              child: PScrollFog(
                use: PScrollFogUse.overlayBody,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (var i = 1; i <= 16; i++) line('항목 $i')],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
