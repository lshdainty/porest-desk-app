import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';

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
    final l = AppLocalizations.of(context);
    final isIncome = expense.expenseType == 'INCOME';
    final colorStr = categoryColorOverride ?? expense.categoryColor;
    final fg = resolveChartColor(context, colorStr, fallback: t.fgBrand);
    final bg = softBg(context, fg);
    final iconData = lucideByName(
      categoryIconOverride ?? expense.categoryIcon,
      fallback: LucideIcons.tag,
    );
    final time = _timeLabel(expense.expenseDate);
    final subParts = [
      expense.categoryName,
      expense.assetName,
      time,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    // design app.css `.tx-flat .tx-row`: 12px 10px + radius 10 — 플랫 리스트 행 리듬.
    //
    // **좌우는 0 이다. 좌우 여백은 목록(페이지)이 쥔다.**
    // 행이 여기서 더 얹으면 그만큼 날짜 헤더와 어긋난다 — 미세하지만 목록 전체가
    // 헤더보다 오른쪽으로 밀려 보인다(사용자 신고 2026-09-14: 헤더 24 / 행 34).
    // 웹은 이 결정을 2026-08-19 에 했고(`porest-desk-front` f8899d6
    // "fix(ledger): 거래 행이 날짜 헤더와 같은 지점에서 시작하도록",
    // `LedgerRow` 의 `px-1 -mx-1` 로 상쇄) 앱만 10 을 들고 있었다.
    //
    // 로딩 자리표시(PDayGroupSkeleton)도 좌우 0 이라, 10 을 두면 **데이터가 오는
    // 순간 행이 10 튄다** — 그쪽 주석이 "같은 여백" 이라고 적고 있었는데 사실이
    // 아니었다. 정렬은 p_expense_row_alignment_test 가 잰다.
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: PRadius.tile(40),
            ),
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
                      l.expTxFallback,
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
                krwSigned(
                  expense.amount,
                  masked,
                  // U+2212(−) — ASCII 하이픈과 폭이 달라 한 카드 안에서 섞이면
                  // tabular figures 정렬이 어긋난다(QA #22). web `entities/expense/ui/
                  // expense-row.tsx` 도 `MINUS` 를 쓴다.
                  sign: isIncome ? '+' : '−',
                  unit: true,
                ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: row,
    );
  }
}
