import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/mask_flags.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_aggregates.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';

/// 날짜 그룹 헤더 — `"26. 9. 12(토) · 오늘"` + 그날 합계.
///
/// 가계부(`expense_screen` 의 `_DayGroup`)에서 떼어냈다. 검색 결과도 같은 모양으로
/// 묶어야 해서 공용으로 둔다 — **두 화면이 각자 그리면 반드시 갈라진다**(검색은
/// 원래 자체 행에 부제로 날짜를 넣고 구분선을 그렸다).
///
/// 합계는 월 헤더와 같은 규칙이다 — 환불 상계 + 예정 제외(`expenseSum`/`incomeSum`).
/// 이체는 순자산 증감이 0 이라 합계에 넣지 않는다(호출부가 빼고 넘긴다).
class PDayHeader extends StatelessWidget {
  const PDayHeader({
    super.key,
    required this.date,
    required this.items,
    required this.flags,
  });

  final DateTime date;

  /// 그날의 거래 — 합계 계산에만 쓴다.
  final List<Expense> items;

  /// 금액마다 자기 종류로 가림 판정을 한다.
  final MaskFlags flags;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final ds = _ymd(date);
    final now = DateTime.now();
    final rel = ds == _ymd(now)
        ? l.txmToday
        : ds == _ymd(now.subtract(const Duration(days: 1)))
        ? l.txmYesterday
        : null;
    final label = formatDay(date);
    final dayExpense = expenseSum(items);
    final dayIncome = incomeSum(items);

    // txm dayhead — "yy. m. d(요일) · 오늘/어제" + 일 합계 (design .txm-dayhead).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${date.year % 100}. ${date.month}. ${date.day}(${label.dow})',
          style: PTypo.bodySm.copyWith(
            color: t.fgSecondary,
            fontWeight: PFontWeight.semi,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (rel != null)
          Text(' · $rel', style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
        const Spacer(),
        if (dayExpense > 0)
          Text(
            krwSigned(
              dayExpense,
              flags.of(MaskKind.expense),
              sign: '−',
              unit: true,
            ),
            style: PTypo.caption.copyWith(
              color: t.fgExpense,
              fontWeight: PFontWeight.semi,
            ),
          ),
        if (dayIncome > 0) ...[
          if (dayExpense > 0) const SizedBox(width: PSpace.x8),
          Text(
            krwSigned(
              dayIncome,
              flags.of(MaskKind.income),
              sign: '+',
              unit: true,
            ),
            style: PTypo.caption.copyWith(
              color: t.fgIncome,
              fontWeight: PFontWeight.semi,
            ),
          ),
        ],
      ],
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 날짜 그룹 한 덩어리의 로딩 자리표시 — 헤더 한 줄 + 행 [rows] 개.
///
/// 실제 [PDayHeader] · `PExpenseRow` 와 **같은 여백**을 쓴다. 다르면 데이터가 오는
/// 순간 행이 좌우로 튄다.
class PDayGroupSkeleton extends StatelessWidget {
  const PDayGroupSkeleton({super.key, required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            PSkeleton.line(width: 48, height: 13),
            SizedBox(width: PSpace.x8),
            PSkeleton.line(width: 24, height: 11),
            Spacer(),
            PSkeleton.line(width: 60, height: 11),
            SizedBox(width: PSpace.x8),
            PSkeleton.line(width: 60, height: 11),
          ],
        ),
        // 행 placeholder — 카드 다이어트: 카드/구분선 없이 행 리듬(12/10)만.
        Column(
          children: [
            for (int i = 0; i < rows; i++)
              const Padding(
                padding: EdgeInsets.fromLTRB(0, PSpace.x12, 0, PSpace.x12),
                child: Row(
                  children: [
                    // PExpenseRow icon tile 정합 — 40px → tile(40)=12=brLg.
                    PSkeleton(
                      width: 40,
                      height: 40,
                      borderRadius: PRadius.brLg,
                    ),
                    SizedBox(width: PSpace.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PSkeleton.line(width: 120, height: 14),
                          SizedBox(height: 2),
                          PSkeleton.line(width: 80, height: 11),
                        ],
                      ),
                    ),
                    SizedBox(width: PSpace.x8),
                    PSkeleton.line(width: 80, height: 14),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
