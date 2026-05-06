import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';

/// Phase 7 에서 월 선택기 + 거래 목록 + 일일 헤더 추가.
class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView(
      padding: const EdgeInsets.all(PSpace.x20),
      children: [
        Text('가계부 / Expense', style: PTypo.h2.copyWith(color: t.fgPrimary)),
        const SizedBox(height: PSpace.x4),
        Text('월 선택 + 거래 목록 + 일일 구분 헤더',
            style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
      ],
    );
  }
}
