import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/shared/ds/button/p_button.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';

/// 카탈로그(/dev/ds) — 변형 × 크기 × 배치, ghost 글자색, 상태, 가장자리 맞춤. 누름은 직접 눌러 본다.
class ButtonDemo extends StatelessWidget {
  const ButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    void noop() {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '변형 × 크기 — 글자(앞 아이콘) · 아이콘만',
          children: [
            for (final variant in PButtonVariant.values)
              DemoRow(
                label: variant.name,
                children: [
                  for (final size in PButtonSize.values)
                    PButton(
                      label: '추가',
                      prefixIcon: LucideIcons.plus,
                      variant: variant,
                      size: size,
                      onPressed: noop,
                    ),
                  for (final size in PButtonSize.values)
                    PButton.icon(
                      icon: LucideIcons.plus,
                      semanticLabel: '추가',
                      variant: variant,
                      size: size,
                      onPressed: noop,
                    ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title: 'ghost 글자색 — 배경 · 누름은 ghost 그대로',
          children: [
            DemoRow(
              label: 'ghostColor',
              children: [
                for (final ghostColor in PButtonGhostColor.values)
                  PButton(
                    label: ghostColor.name,
                    suffixIcon: LucideIcons.chevronRight,
                    variant: PButtonVariant.ghost,
                    ghostColor: ghostColor,
                    onPressed: noop,
                  ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '상태 — 기본 · 로딩 · 비활성(누름은 직접 눌러 본다)',
          children: [
            for (final variant in PButtonVariant.values)
              DemoRow(
                label: variant.name,
                children: [
                  PButton(label: '기본', variant: variant, onPressed: noop),
                  PButton(
                    label: '로딩',
                    variant: variant,
                    loading: true,
                    onPressed: noop,
                  ),
                  PButton(label: '비활성', variant: variant, onPressed: null),
                ],
              ),
          ],
        ),
        DemoBlock(
          title: '가장자리 맞춤(flush) — 그 방향 가로 여백만 0, ghost 는 글자색으로만 반응한다',
          children: [
            DemoRow(
              label: 'flush',
              children: [
                PButton(
                  label: '왼쪽 맞춤',
                  variant: PButtonVariant.ghost,
                  flush: PButtonFlush.left,
                  onPressed: noop,
                ),
                PButton(
                  label: '오른쪽 맞춤',
                  suffixIcon: LucideIcons.chevronRight,
                  variant: PButtonVariant.ghost,
                  flush: PButtonFlush.right,
                  onPressed: noop,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
