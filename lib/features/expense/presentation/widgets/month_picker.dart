import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

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
        PButton.icon(
          icon: LucideIcons.chevronLeft,
          onPressed: onPrev,
        ),
        const SizedBox(width: PSpace.x4),
        Text(yearMonth(month),
            style: PTypo.h4.copyWith(color: t.fgPrimary)),
        const SizedBox(width: PSpace.x4),
        PButton.icon(
          icon: LucideIcons.chevronRight,
          onPressed: onNext,
        ),
      ],
    );
  }
}
