import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';

/// Month picker bottom drawer — 디자이너 정합 (year header prev/next + 12 month grid + 오늘로/닫기).
/// mobile drawer 패턴 — showPSheet (공통 layout). desktop/tablet dialog 는 follow-up.
Future<DateTime?> showMonthPickerSheet(BuildContext context, DateTime initial) {
  final l = AppLocalizations.of(context);
  return showPSheet<DateTime>(
    context,
    title: l.budgetSelectMonth,
    shrinkWrap: true,
    contentBuilder: (sheetCtx, _) {
      final t = sheetCtx.tokens;
      final now = DateTime.now();
      int viewYear = initial.year;
      final selectedYear = initial.year;
      final selectedMonth = initial.month;
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpace.xl,
              PSpace.x4,
              PSpace.xl,
              PSpace.x20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // year header — prev / year text / next
                Row(
                  children: [
                    PButton.icon(
                      tooltip: AppLocalizations.of(context).actionPrev,
                      icon: LucideIcons.chevronLeft,
                      onPressed: () => setSheet(() => viewYear -= 1),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          yearOnly(DateTime(viewYear)),
                          style: PTypo.bodyLg.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    PButton.icon(
                      tooltip: AppLocalizations.of(context).actionNext,
                      icon: LucideIcons.chevronRight,
                      onPressed: () => setSheet(() => viewYear += 1),
                    ),
                  ],
                ),
                const SizedBox(height: PSpace.x16),
                // 4x3 month grid (1월 ~ 12월)
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.0,
                  mainAxisSpacing: PSpace.x8,
                  crossAxisSpacing: PSpace.x8,
                  children: [
                    for (int m = 1; m <= 12; m++)
                      _MonthGridButton(
                        label: monthOnly(DateTime(viewYear, m)),
                        selected:
                            viewYear == selectedYear && m == selectedMonth,
                        onTap: () =>
                            Navigator.of(ctx).pop(DateTime(viewYear, m, 1)),
                      ),
                  ],
                ),
                const SizedBox(height: PSpace.x12),
                // footer: 오늘로 + 닫기 — 화면 폭을 반씩 나눠 갖는다
                // (spec drawer.md "flex:1 평등 분배"). Spacer 로 양끝에 붙이면
                // 구석의 작은 알약이 돼 한 손으로 누를 폭이 안 나온다.
                Row(
                  children: [
                    Expanded(
                      child: PButton(
                        label: l.calGoToToday,
                        icon: LucideIcons.locateFixed,
                        variant: PButtonVariant.ghost,
                        size: PButtonSize.sm,
                        fullWidth: true,
                        onPressed: () => Navigator.of(
                          ctx,
                        ).pop(DateTime(now.year, now.month, 1)),
                      ),
                    ),
                    const SizedBox(width: PSpace.x8),
                    Expanded(
                      child: PButton(
                        label: l.actionClose,
                        variant: PButtonVariant.ghost,
                        size: PButtonSize.sm,
                        fullWidth: true,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _MonthGridButton extends StatelessWidget {
  const _MonthGridButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      // 선택 월 = 채움(흰 글씨) 버튼 → primary 고정(bgBrandSolid). 캘린더 월그리드(calendar_screen bgBrandSolid) 정합. bgBrand(다크 light)는 fill 부적합.
      color: selected ? t.bgBrandSolid : Colors.transparent,
      borderRadius: PRadius.brMd,
      child: InkWell(
        borderRadius: PRadius.brMd,
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: PTypo.bodySm.copyWith(
              color: selected ? t.fgOnBrand : t.fgPrimary,
              fontWeight: selected ? PFontWeight.bold : PFontWeight.medium,
            ),
          ),
        ),
      ),
    );
  }
}
