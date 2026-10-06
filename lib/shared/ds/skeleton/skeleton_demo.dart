import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/button/p_button.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/skeleton/p_skeleton.dart';

/// 카탈로그(/dev/ds) — 모서리, 글 자리, 목록 한 줄, 기다리는 영역(1초 · 5초를 다시 볼 수 있게).
class SkeletonDemo extends StatefulWidget {
  const SkeletonDemo({super.key});

  @override
  State<SkeletonDemo> createState() => _SkeletonDemoState();
}

class _SkeletonDemoState extends State<SkeletonDemo> {
  // 기다리는 영역을 처음부터 다시 — 키를 바꿔 새로 그린다
  Key _run = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '모서리 — 0 · 4 · 6 · 8(기본) · 12 · 16 · full',
          children: [
            DemoRow(
              label: 'radius',
              children: [
                for (final r in PSkeletonRadius.values)
                  PSkeleton(width: 40, height: 40, radius: r),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '글 자리 — 높이는 그 글자의 줄 높이, 마지막 줄은 짧게',
          children: [
            PSkeleton.text(PTypography.t5, width: 160),
            PSkeleton.text(PTypography.t4, width: 240),
            PSkeleton.text(PTypography.t4, width: 150),
          ],
        ),
        DemoBlock(
          title: '목록 한 줄 — 타일(12) + 두 줄',
          children: [
            Row(
              spacing: PSpacing.x3,
              children: [
                const PSkeleton(
                  width: 40,
                  height: 40,
                  radius: PSkeletonRadius.r12,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: PSpacing.x1,
                  children: [
                    PSkeleton.text(PTypography.t4, width: 120),
                    PSkeleton.text(PTypography.t2, width: 80),
                  ],
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '기다리는 영역 — 1초까지 빈 자리, 1초부터 스켈레톤, 5초부터 오래 걸림 글',
          children: [
            PLoadingRegion(
              key: _run,
              pending: true,
              fallback: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: PSpacing.x2,
                children: [
                  PSkeleton.text(PTypography.t4, width: 200),
                  PSkeleton.text(PTypography.t4, width: 140),
                ],
              ),
              child: const SizedBox.shrink(),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: PButton(
                label: '처음부터 다시',
                variant: PButtonVariant.neutralWeak,
                size: PButtonSize.small,
                onPressed: () => setState(() => _run = UniqueKey()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
