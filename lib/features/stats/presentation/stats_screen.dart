import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';

/// v0.2 에서 fl_chart 로 채움.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView(
      padding: const EdgeInsets.all(PSpace.x20),
      children: [
        Text('통계 / Stats', style: PTypo.h2.copyWith(color: t.fgPrimary)),
        const SizedBox(height: PSpace.x4),
        Text('자산 사용 · 예산 vs 실제 · 카테고리 추이 · 가맹점 분석 · YoY',
            style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
      ],
    );
  }
}
