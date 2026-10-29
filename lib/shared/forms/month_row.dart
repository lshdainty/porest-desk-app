import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';

/// 달 줄 — 달 글 + 아래 꺾쇠(‹ › 없음, 10-29 — 연 · 월은 휠로만 옮긴다)와 오른쪽 동작(스펙 부품이 아니라 ds 를 조합한 줄 조각). 달 글을 누르면 달 고르기.
/// 예산 · 캘린더가 함께 쓰고, 둘레 여백 · 글 크기 · 최소 높이만 화면이 정한다.
class MonthRow extends StatelessWidget {
  const MonthRow({
    super.key,
    required this.month,
    required this.onPick,
    required this.trailing,
    required this.padding,
    required this.labelStyle,
    this.minHeight = 0,
  });

  final DateTime month;
  final VoidCallback onPick;
  final Widget trailing;
  final EdgeInsets padding;
  final TextStyle labelStyle;

  /// 줄 최소 높이 — 캘린더 52. 글자가 커지면 늘어난다.
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: padding,
        // 한 줄에 안 들어가면(좁은 폭 · 큰 글자) 오른쪽 동작이 아래 줄 오른쪽 끝으로 내려간다(03G-029 A — 웹 `ml-auto` 와 같다)
        child: Align(
          alignment: Alignment.centerLeft,
          child: OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.end,
            overflowSpacing: 0,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: PressArea(
                      enabled: true,
                      onTap: onPick,
                      touchMin: 0,
                      semantics: (child, enabled, onTap) => Semantics(
                        container: true,
                        button: true,
                        label: yearMonth(month),
                        onTap: onTap,
                        excludeSemantics: true,
                        child: child,
                      ),
                      builder: (context, pressed, size) => Container(
                        constraints: const BoxConstraints(
                          minHeight: PTouch.min,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: PSpacing.x2_5,
                        ),
                        decoration: BoxDecoration(
                          color: pressed
                              ? c.bgLayerDefaultPressed
                              : c.bgLayerDefaultPressed.withValues(alpha: 0),
                          borderRadius: BorderRadius.circular(PRounded.r2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: PSpacing.x1,
                          children: [
                            Flexible(
                              child: Text(
                                yearMonth(month),
                                style: labelStyle.copyWith(
                                  color: c.fgNeutral,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronDown,
                              size: 16,
                              color: c.fgNeutralMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // 글 버튼은 가운데 맞춤 상자라 폭을 다 채우려 한다 — 제 폭만 쓰게 푼다
              UnconstrainedBox(child: trailing),
            ],
          ),
        ),
      ),
    );
  }
}
