import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

/// 받는 중 · 설치 화면을 여는 중 — 값 있는 ds ProgressCircle 24 + 옆에 R9 메타 글.
/// 서버가 길이를 안 주면 비율을 모른다([ratio] 가 null) — 그때는 값 없는 원이다.
/// 업데이트 게이트와 설정 > 업데이트가 같이 쓴다(I-05 17 · 23).
Widget updateProgressRow(
  BuildContext context, {
  required String label,
  required double? ratio,
}) {
  final c = context.colors;
  return Row(
    children: [
      SizedBox(
        width: 24,
        height: 24,
        child: PProgressCircle(
          size: PProgressCircleSize.s24,
          tone: PProgressCircleTone.neutral,
          value: ratio == null ? null : (ratio.clamp(0.0, 1.0)) * 100,
        ),
      ),
      const SizedBox(width: PSpacing.x2),
      Expanded(
        child: Text(
          label,
          style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
        ),
      ),
    ],
  );
}
