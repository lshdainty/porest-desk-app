import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/format/date.dart';

/// "← YYYY년 M월 →" 좌우 화살표로 월 이동.
class MonthPicker extends StatelessWidget {
  const MonthPicker({
    required this.month,
    required this.onPrev,
    required this.onNext,
    super.key,
  });
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: Icon(LucideIcons.chevronLeft, color: t.fgSecondary),
        ),
        const SizedBox(width: PSpace.x4),
        Text(yearMonth(month),
            style: PTypo.h4.copyWith(color: t.fgPrimary)),
        const SizedBox(width: PSpace.x4),
        IconButton(
          onPressed: onNext,
          icon: Icon(LucideIcons.chevronRight, color: t.fgSecondary),
        ),
      ],
    );
  }
}
