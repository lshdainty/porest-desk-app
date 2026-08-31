import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/mask_flags.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense/presentation/tx_detail_dialog.dart';

/// 아직 오지 않은 거래인가 — 서버가 합계에서 빼는 기준과 같다.
bool _isScheduled(String? expenseDate) {
  if (expenseDate == null) return false;
  final normalized = expenseDate.length == 10
      ? '${expenseDate}T23:59:59'
      : expenseDate;
  return DateTime.parse(normalized).isAfter(DateTime.now());
}

class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    required this.expense,
    required this.category,
    required this.flags,
    this.interactive = true,
    super.key,
  });

  final Expense expense;
  final ExpenseCategory? category;

  /// 화면 카드 + 종류 카드. 행이 자기 종류(수입/지출)로 판정한다.
  final MaskFlags flags;

  /// false 면 InkWell tap 비활성 — 단순 표시 용도 (예: 가맹점 history).
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    // 카테고리 색은 백엔드 카테고리 우선, 없으면 거래에 임베드된 categoryColor, 없으면 토큰
    final colorRaw = category?.color ?? expense.categoryColor;
    final iconRaw = category?.icon ?? expense.categoryIcon;
    final cName =
        category?.categoryName ?? expense.categoryName ?? l.expUncategorized;

    final fg = resolveChartColor(context, colorRaw, fallback: t.fgBrand);
    final bg = softBg(context, fg);
    final icon = lucideByName(iconRaw, fallback: LucideIcons.tag);

    return InkWell(
      onTap: interactive ? () => showTxDetailDialog(context, expense) : null,
      borderRadius: BorderRadius.circular(10),
      // 아직 오지 않은 거래는 행째로 흐리게 — 합계에도 안 들어가는 값이라 지나간
      // 거래와 같은 무게로 보이면 안 된다. 배지만으로는 눈에 잘 안 걸린다.
      // 웹 LedgerRow 의 dim(opacity-60) 정합.
      child: Opacity(
        opacity: _isScheduled(expense.expenseDate) ? 0.6 : 1,
        child: Padding(
          // design `.m-scroll .tx-list .tx-row`: 12px 10px + radius 10 (플랫 행 리듬).
          // web pl-1.5(6)−ml-1(4) = 순 좌측 +2 정합(사용자 결정). 우측 0.
          // 좌우는 페이지가 쥔다. 행이 여기서 좌측 2 를 더 얹으면 그만큼 날짜 헤더와
          // 어긋난다 — 미세하지만 목록 전체가 헤더보다 오른쪽으로 밀려 보인다.
          padding: const EdgeInsets.fromLTRB(0, PSpace.x12, 0, PSpace.x12),
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
                child: Icon(icon, size: 18, color: fg),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            expense.merchant ?? expense.description ?? cName,
                            style: PTypo.body.copyWith(
                              color: t.fgPrimary,
                              fontWeight: PFontWeight.semi,
                              letterSpacing: -0.07,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 아직 오지 않은 거래(반복거래 선생성분) — 합계에는 안 들어간다.
                        if (_isScheduled(expense.expenseDate)) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: t.bgMuted,
                              borderRadius: PRadius.brXs,
                            ),
                            child: Text(
                              AppLocalizations.of(context).expScheduled,
                              style: PTypo.micro.copyWith(
                                color: t.fgTertiary,
                                fontWeight: PFontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        // 분할 거래 표시 — 분할 아이콘 + 개수(쉬운 식별).
                        if (expense.splitCategoryRowIds.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Icon(LucideIcons.split, size: 12, color: t.fgBrand),
                          const SizedBox(width: 2),
                          Text(
                            '${expense.splitCategoryRowIds.length}',
                            style: PTypo.caption.copyWith(
                              color: t.fgBrand,
                              fontWeight: PFontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$cName · ${expense.assetName ?? '-'}',
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PSpace.x8),
              Text(
                krwSigned(
                  expense.signedAmount,
                  flags.ofType(expense.expenseType),
                  sign: expense.signedAmount > 0 ? '+' : '',
                  unit: true,
                ),
                // 행 금액은 지출/수입 무관 일반 텍스트색 — 색 구분은 날짜 헤더 일 합계만(사용자 결정).
                style: PTypo.money.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
