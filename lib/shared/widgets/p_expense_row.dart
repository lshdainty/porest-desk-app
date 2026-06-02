import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/format/chart_palette.dart';
import '../../core/format/krw.dart';
import '../../features/expense/domain/expense.dart';
import '../icons/lucide_icon_map.dart';

/// front `<ExpenseRow>` (shared/ui/porest/expense-row.tsx) 미러.
///
/// 거래 1건을 list 안의 row 로 표시 — icon-with-soft-bg + merchant/title +
/// sub(category · asset · time) + amount.
///
/// - vertical padding 12 (front `--row-py` default)
/// - icon 40×40 + radius brMd (front 의 12px 와 동일)
/// - sub separator " · " (front 의 dot span 과 시각 의도 동일)
/// - **time '00:00' 은 숨김** (front formatExpenseTimeLabel 정책 정합)
/// - amount: income → fgIncome, expense → fgExpense + tabular nums
///
/// 사용:
/// ```dart
/// PExpenseRow(expense: e, masked: false, onTap: () => ...)
/// ```
class PExpenseRow extends StatelessWidget {
  const PExpenseRow({
    super.key,
    required this.expense,
    this.masked = false,
    this.onTap,
    this.categoryColorOverride,
    this.categoryIconOverride,
    this.right,
  });

  final Expense expense;
  final bool masked;
  final VoidCallback? onTap;

  /// category provider 에서 받은 color 가 expense.categoryColor 와 다른 경우
  /// override (caller 가 resolved color 직접 전달).
  final String? categoryColorOverride;
  final String? categoryIconOverride;

  /// 우측 amount 자리 override (custom widget 표시 시).
  final Widget? right;

  /// front `formatExpenseTimeLabel` 미러 — '00:00' 은 의미 없으므로 숨김.
  String? _timeLabel(String? raw) {
    if (raw == null || raw.length < 16) return null;
    final time = raw.substring(11, 16);
    return time == '00:00' ? null : time;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isIncome = expense.expenseType == 'INCOME';
    final colorStr = categoryColorOverride ?? expense.categoryColor;
    final fg = resolveChartColor(context, colorStr, fallback: t.fgBrand);
    final bg = softBg(context, fg);
    final iconData = lucideByName(
        categoryIconOverride ?? expense.categoryIcon,
        fallback: LucideIcons.tag);
    final time = _timeLabel(expense.expenseDate);
    final subParts = [
      expense.categoryName,
      expense.assetName,
      time,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, borderRadius: PRadius.tile(40)),
            alignment: Alignment.center,
            child: Icon(iconData, size: 18, color: fg),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.merchant ??
                      expense.description ??
                      expense.categoryName ??
                      '거래',
                  style: PTypo.body.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.semi,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subParts,
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: PSpace.x8),
          right ??
              Text(
                krwSigned(expense.amount, masked,
                    sign: isIncome ? '+' : '-', unit: true),
                style: PTypo.body.copyWith(
                  color: isIncome ? t.fgIncome : t.fgExpense,
                  fontWeight: PFontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
