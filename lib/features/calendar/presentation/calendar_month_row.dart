import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/forms/month_row.dart';

/// 달 줄 — 흰 면 맨 위(I-09 6). 높이 52 · 왼쪽 6 · 오른쪽 16, ← 달 → 와 오른쪽 캘린더 고르기 칩.
class CalendarMonthRow extends StatelessWidget {
  const CalendarMonthRow({
    super.key,
    required this.month,
    required this.onPick,
    required this.calendarCount,
    required this.dotColors,
    required this.onFilterTap,
  });

  final DateTime month;
  final VoidCallback onPick;
  final int calendarCount;
  final List<Color> dotColors;
  final VoidCallback onFilterTap;

  /// 줄 높이.
  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    return MonthRow(
      month: month,
      onPick: onPick,
      minHeight: height,
      // 달 글 상자 안 여백 10 만큼 덜어 글이 화면 여백 24 에 선다
      padding: const EdgeInsets.only(
        left: PSpacing.globalGutter - PSpacing.x2_5,
        right: PSpacing.x4,
      ),
      labelStyle: PTypography.t6,
      trailing: CalendarFilterChip(
        count: calendarCount,
        dotColors: dotColors,
        onPressed: onFilterTap,
      ),
    );
  }
}

/// 캘린더 고르기 여는 칩 — 보이는 캘린더 색 점(8 · 최대 셋 · 겹침 −2) + "{n}개" + 아래 꺾쇠.
class CalendarFilterChip extends StatelessWidget {
  const CalendarFilterChip({
    super.key,
    required this.count,
    required this.dotColors,
    required this.onPressed,
  });

  final int count;
  final List<Color> dotColors;
  final VoidCallback onPressed;

  static const double dotSize = 8;
  static const double dotOverlap = 2;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dots = dotColors.take(3).toList();
    return PChip(
      label: l.calCalendarChipCount(count),
      semanticLabel: l.calFilterChipName(count),
      onPressed: onPressed,
      suffixIcon: LucideIcons.chevronDown,
      leading: dots.isEmpty
          ? null
          : ExcludeSemantics(
              child: SizedBox(
                key: const ValueKey('calendar-filter-dots'),
                width: dotSize + (dots.length - 1) * (dotSize - dotOverlap),
                height: dotSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < dots.length; i++)
                      Positioned(
                        left: i * (dotSize - dotOverlap),
                        child: Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: dots[i],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
