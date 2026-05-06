import 'package:flutter/material.dart';

import '../../../../app/theme/radius.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/format/krw.dart';
import '../../domain/expense.dart';

class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    required this.expense,
    required this.category,
    required this.asset,
    required this.masked,
    super.key,
  });

  final Expense expense;
  final Category category;
  final Asset asset;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final positive = expense.signedAmount > 0;
    return InkWell(
      onTap: () {}, // Phase 후속: TxDetailDialog
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            // 카테고리 아이콘 타일
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: category.bg, borderRadius: PRadius.brSm),
              alignment: Alignment.center,
              child: Icon(category.icon, size: 18, color: category.color),
            ),
            const SizedBox(width: PSpace.x12),
            // 가운데: merchant + 카테고리·자산
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.merchant ?? expense.description ?? category.name,
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${category.name} · ${asset.name}',
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Text(
              krwMasked(expense.signedAmount, masked, sign: true),
              style: PTypo.money.copyWith(
                  color: positive ? t.statusSuccess : t.fgPrimary,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
