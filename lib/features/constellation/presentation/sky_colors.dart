import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 할 일 밤하늘의 색(01-033 C) — 고정 남색 hex 대신 **역할 색**이다. 하늘은 `bg-neutral-inverted`(라이트에서 짙은 하늘,
/// 다크에서는 밝은 하늘 — 사용자가 대가로 받아들인 모습), 별 · 선 · 글은 `fg-neutral-inverted` 의 투명도다.
/// [alpha] 는 0 ~ 255.
Color skyInk(PColors c, int alpha) =>
    c.fgNeutralInverted.withValues(alpha: alpha / 255);

/// 하늘 바탕 그라디언트 — 위 왼쪽 짙게 → 아래 오른쪽(눌림 단계). 셋이면 가운데는 두 색의 중간.
LinearGradient skyGradient(PColors c, {bool three = false}) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    c.bgNeutralInverted,
    if (three)
      Color.lerp(c.bgNeutralInverted, c.bgNeutralInvertedPressed, 0.5)!,
    c.bgNeutralInvertedPressed,
  ],
  stops: three ? const [0, 0.55, 1] : null,
);

/// 오늘 진행 단계 아이콘 — 별빛 0 달 · 1 반짝 · 3 반짝이 · 5 별(웹 `stageIconOf` 와 같다).
IconData skyStageIcon(int points) {
  if (points >= 5) return LucideIcons.star;
  if (points >= 3) return LucideIcons.sparkles;
  if (points >= 1) return LucideIcons.sparkle;
  return LucideIcons.moon;
}
