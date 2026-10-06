import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/progress_circle/p_progress_circle.dart';

/// 카탈로그(/dev/ds) — 크기 × 톤 × 값 없음 · 있음. staticWhite 는 사진 위 딤(overlay-dim) 위에 놓는다.
class ProgressCircleDemo extends StatelessWidget {
  const ProgressCircleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(PProgressCircleTone tone) => DemoRow(
      label: tone.name,
      children: [
        for (final size in PProgressCircleSize.values)
          for (final value in [null, 40.0, 75.0])
            PProgressCircle(size: size, tone: tone, value: value),
      ],
    );
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '크기 × 톤 — 값 없음(돈다) · 값 40% · 값 75%',
          children: [
            row(PProgressCircleTone.neutral),
            row(PProgressCircleTone.brand),
          ],
        ),
        DemoBlock(
          title: 'staticWhite — 사진 위 딤(overlay-dim) 위에 놓는다',
          children: [
            Container(
              padding: const EdgeInsets.all(PSpacing.x3),
              decoration: BoxDecoration(
                // overlay-dim-light 50% · overlay-dim-dark 65% 의 검정
                color: Color.fromRGBO(0, 0, 0, dark ? 0.65 : 0.5),
                borderRadius: BorderRadius.circular(PRounded.r2),
              ),
              child: Wrap(
                spacing: PSpacing.x3,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final size in PProgressCircleSize.values)
                    for (final value in [null, 60.0])
                      PProgressCircle(
                        size: size,
                        tone: PProgressCircleTone.staticWhite,
                        value: value,
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
