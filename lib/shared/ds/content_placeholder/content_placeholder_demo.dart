import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/content_placeholder/p_content_placeholder.dart';

/// 카탈로그(/dev/ds) — 틀 크기에 따라 그림이 높이의 50%(16 ~ 160). 모서리는 담는 틀이 자른다.
class ContentPlaceholderDemo extends StatelessWidget {
  const ContentPlaceholderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    Widget framed(double w, double h, double radius) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: w, height: h, child: const PContentPlaceholder()),
    );

    return DemoBlock(
      title: '틀 — 40 썸네일(6) · 56 카드 그림(8) · 160 × 100 · 화면 폭 사진',
      children: [
        DemoRow(
          label: 'frame',
          children: [
            framed(40, 40, PRounded.r1_5),
            framed(56, 56, PRounded.r2),
            framed(160, 100, PRounded.r2),
          ],
        ),
        framed(double.infinity, 180, 0),
      ],
    );
  }
}
