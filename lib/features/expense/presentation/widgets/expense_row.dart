import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../app/theme/radius.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/format/chart_palette.dart';
import '../../../../core/format/krw.dart';
import '../../../../shared/icons/lucide_icon_map.dart';
import '../../domain/expense.dart';
import '../../domain/expense_category.dart';
import '../tx_detail_dialog.dart';

class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    required this.expense,
    required this.category,
    required this.masked,
    this.interactive = true,
    super.key,
  });

  final Expense expense;
  final ExpenseCategory? category;
  final bool masked;
  /// false 면 InkWell tap 비활성 — 단순 표시 용도 (예: 가맹점 history).
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final positive = expense.signedAmount > 0;

    // 카테고리 색은 백엔드 카테고리 우선, 없으면 거래에 임베드된 categoryColor, 없으면 토큰
    final colorRaw = category?.color ?? expense.categoryColor;
    final iconRaw = category?.icon ?? expense.categoryIcon;
    final cName = category?.categoryName ?? expense.categoryName ?? '미지정';

    final fg = resolveChartColor(context, colorRaw, fallback: t.fgBrand);
    final bg = softBg(context, fg);
    final icon = lucideByName(iconRaw, fallback: LucideIcons.tag);

    return InkWell(
      onTap: interactive ? () => showTxDetailDialog(context, expense) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: bg, borderRadius: PRadius.tile(40)),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.merchant ?? expense.description ?? cName,
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.semi,
                        letterSpacing: -0.07),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$cName · ${expense.assetName ?? '-'}',
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Text(
              masked
                  ? krwMasked(expense.signedAmount, masked, sign: true)
                  : '${krwMasked(expense.signedAmount, masked, sign: true)}원',
              style: PTypo.money.copyWith(
                  color: positive ? t.fgIncome : t.fgExpense,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.14),
            ),
          ],
        ),
      ),
    );
  }
}
