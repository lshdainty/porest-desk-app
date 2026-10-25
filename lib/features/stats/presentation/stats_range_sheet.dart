import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_chip.dart';
import 'package:groo_damda_app/shared/widgets/p_date_input.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import 'package:groo_damda_app/shared/widgets/p_tabs.dart';

/// 통계 기간 고르기 시트 — 월 · 분기 · 년 · 직접 + 시작 · 끝 날짜. 시트 이관은 다른 배치 몫이라 모양은 그대로 둔다(I-08 "그대로").
/// 고른 기간(월 · 분기 · 년은 이번 기간, 직접은 고른 날짜)을 돌려준다. 취소하면 null.
Future<StatsPeriod?> showStatsRangeSheet(
  BuildContext context,
  StatsPeriod current,
) async {
  // 가계부 FilterDialog 패턴 정합 — 상단 ToggleGroup (월/분기/년/직접) +
  // 항상 date range PDateInput + custom 시만 quick chips. apply 시 segMode +
  // from/to 모두 반영. shrinkWrap: true — content 자연 합산.
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  StatsSeg draftSeg = current.seg;
  DateTime draftFrom = current.from;
  DateTime draftTo = current.to;
  controller.setCanSubmit(!draftTo.isBefore(draftFrom));

  final picked = await showPSheet<({StatsSeg seg, DateTimeRange range})>(
    context,
    title: l.statsPeriodPickerTitle,
    shrinkWrap: true,
    contentBuilder: (sheetCtx, _) {
      controller.onSubmit ??= () async {
        Navigator.pop(sheetCtx, (
          seg: draftSeg,
          range: DateTimeRange(start: draftFrom, end: draftTo),
        ));
      };
      final quickRanges = <({String label, int days})>[
        (label: l.statsRange7d, days: 7),
        (label: l.statsRange30d, days: 30),
        (label: l.statsRange3m, days: 90),
        (label: l.statsRange6m, days: 180),
        (label: l.statsRange1y, days: 365),
      ];
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          void syncCan() =>
              controller.setCanSubmit(!draftTo.isBefore(draftFrom));
          void setSeg(StatsSeg v) {
            setSheet(() {
              draftSeg = v;
              final now = DateTime.now();
              if (v == StatsSeg.month) {
                draftFrom = DateTime(now.year, now.month, 1);
                draftTo = DateTime(now.year, now.month + 1, 0);
              } else if (v == StatsSeg.quarter) {
                final q = (now.month - 1) ~/ 3;
                draftFrom = DateTime(now.year, q * 3 + 1, 1);
                draftTo = DateTime(now.year, q * 3 + 4, 0);
              } else if (v == StatsSeg.year) {
                draftFrom = DateTime(now.year, 1, 1);
                draftTo = DateTime(now.year, 12, 31);
              }
            });
            syncCan();
          }

          return Padding(
            // 좌우는 시트 헤더·푸터와 같은 24 — 20 이면 본문이 제목보다 4 왼쪽에 선다.
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.xl,
              vertical: PSpace.x12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PTabs<StatsSeg>(
                  value: draftSeg,
                  variant: PTabsVariant.container,
                  size: PTabsSize.sm,
                  expand: true,
                  items: [
                    PTabItem(value: StatsSeg.month, label: l.statsSegMonth),
                    PTabItem(value: StatsSeg.quarter, label: l.statsSegQuarter),
                    PTabItem(value: StatsSeg.year, label: l.statsSegYear),
                    PTabItem(value: StatsSeg.custom, label: l.statsSegCustom),
                  ],
                  onChanged: setSeg,
                ),
                const SizedBox(height: PSpace.lg),
                Row(
                  children: [
                    Expanded(
                      child: PDateInput(
                        value: draftFrom,
                        onChanged: (d) {
                          if (d != null) {
                            setSheet(() {
                              draftFrom = d;
                              draftSeg = StatsSeg.custom;
                            });
                            syncCan();
                          }
                        },
                        firstDate: DateTime(2020),
                        lastDate: DateTime(DateTime.now().year + 5, 12, 31),
                      ),
                    ),
                    const SizedBox(width: PSpace.sm),
                    Text(
                      '~',
                      style: PTypo.body.copyWith(color: ctx.tokens.fgTertiary),
                    ),
                    const SizedBox(width: PSpace.sm),
                    Expanded(
                      child: PDateInput(
                        value: draftTo,
                        onChanged: (d) {
                          if (d != null) {
                            setSheet(() {
                              draftTo = d;
                              draftSeg = StatsSeg.custom;
                            });
                            syncCan();
                          }
                        },
                        firstDate: DateTime(2020),
                        lastDate: DateTime(DateTime.now().year + 5, 12, 31),
                      ),
                    ),
                  ],
                ),
                if (draftSeg == StatsSeg.custom) ...[
                  const SizedBox(height: PSpace.lg),
                  Wrap(
                    spacing: PSpace.sm,
                    runSpacing: PSpace.sm,
                    children: [
                      for (final q in quickRanges)
                        PChip(
                          label: q.label,
                          selected: false,
                          onTap: () {
                            final today = DateTime.now();
                            setSheet(() {
                              draftFrom = today.subtract(
                                Duration(days: q.days - 1),
                              );
                              draftTo = today;
                              draftSeg = StatsSeg.custom;
                            });
                            syncCan();
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
    footerBuilder: (ctx) =>
        PSheetFooter(controller: controller, submitLabel: l.actionApply),
  ).whenComplete(controller.dispose);
  if (picked == null) return null;
  if (picked.seg == StatsSeg.custom) {
    return StatsPeriod(
      seg: StatsSeg.custom,
      from: picked.range.start,
      to: picked.range.end,
    );
  }
  return current.ofSeg(picked.seg);
}
