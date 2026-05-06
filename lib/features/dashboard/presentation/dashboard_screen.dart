import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';

/// Phase 7 에서 카드 + 차트로 채움. 지금은 placeholder.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView(
      padding: const EdgeInsets.all(PSpace.x20),
      children: [
        Text('홈 / Dashboard', style: PTypo.h2.copyWith(color: t.fgPrimary)),
        const SizedBox(height: PSpace.x4),
        Text('대시보드 · 자산·수입·지출·카테고리 분석',
            style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
      ],
    );
  }
}
