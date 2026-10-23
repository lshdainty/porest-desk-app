import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_aggregates.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/header_row/p_header_row.dart';
import 'package:groo_damda_app/shared/widgets/p_skeleton.dart';

/// 날짜 묶음 머리 — List Header `mediumWeak`(t4 14 / 19 · 500 · `fg-neutral-subtle` · 좌우 24 · 위아래 8 · gap 10) 값이다(I-07 14).
///
/// 글 `"26. 10. 22(목) · 오늘"` + 그날 합계(지출 `fg-neutral` · 수입 `fg-brand` + "+" · t4 500 고정폭). 합계가 머리 폭의 절반을
/// 넘으면 제목 아래 줄 오른쪽 끝으로 내려간다(`PHeaderRow` — List Header 와 같은 판정). 머리말 `headingLevel: 2`.
///
/// 가계부 · 검색이 함께 쓴다 — 두 화면이 각자 그리면 반드시 갈라진다. 합계는 월 헤더와 같은 규칙(환불 상계 + 예정 제외 —
/// `expenseSum`/`incomeSum`)이고 이체는 순자산 증감이 0 이라 호출부가 빼고 넘긴다.
class PDayHeader extends StatelessWidget {
  const PDayHeader({
    super.key,
    required this.date,
    required this.items,
    required this.flags,
    this.gutter,
  });

  final DateTime date;

  /// 그날의 거래 — 합계 계산에만 쓴다.
  final List<Expense> items;

  /// 금액마다 자기 종류로 가림 판정을 한다.
  final MaskFlags flags;

  /// **임시 인자** — 좌우 여백 기본 24(List Header). 바깥 24 를 아직 쥔 호스트(검색)만 0 을 준다 — 호스트가 바깥 24 를 걷을 때
  /// 함께 걷는다(I-06 의 List 줄 `gutter` 와 같은 뜻).
  final double? gutter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final ds = _ymd(date);
    final now = DateTime.now();
    final rel = ds == _ymd(now)
        ? l.txmToday
        : ds == _ymd(now.subtract(const Duration(days: 1)))
        ? l.txmYesterday
        : null;
    final label = formatDay(date);
    final text =
        '${date.year % 100}. ${date.month}. ${date.day}(${label.dow})${rel == null ? '' : ' · $rel'}';
    final style = PTypography.t4.copyWith(
      color: c.fgNeutralSubtle,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final dayExpense = expenseSum(items);
    final dayIncome = incomeSum(items);
    final sums = (dayExpense > 0 || dayIncome > 0)
        ? Row(
            mainAxisSize: MainAxisSize.min,
            spacing: PSpacing.x2,
            children: [
              if (dayExpense > 0)
                Text(
                  krwSigned(
                    dayExpense,
                    flags.of(MaskKind.expense),
                    sign: '−',
                    unit: true,
                  ),
                  style: style.copyWith(color: c.fgNeutral),
                ),
              if (dayIncome > 0)
                Text(
                  krwSigned(
                    dayIncome,
                    flags.of(MaskKind.income),
                    sign: '+',
                    unit: true,
                  ),
                  style: style.copyWith(color: c.fgBrand),
                ),
            ],
          )
        : null;
    return Padding(
      key: const ValueKey('day-header'),
      padding: EdgeInsets.symmetric(
        horizontal: gutter ?? PSpacing.globalGutter,
        vertical: PSpacing.x2,
      ),
      child: PHeaderRow(
        gap: PSpacing.x2_5,
        expandTitle: true,
        title: Semantics(
          header: true,
          headingLevel: 2,
          container: true,
          label: text,
          child: ExcludeSemantics(child: Text(text, style: style)),
        ),
        action: sums,
      ),
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 날짜 그룹 한 덩어리의 로딩 자리표시 — 헤더 한 줄 + 행 [rows] 개.
///
/// 실제 [PDayHeader] · `ExpenseRow` 와 **같은 여백**을 쓴다. 다르면 데이터가 오는
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
            SizedBox(width: PSpacing.x2),
            PSkeleton.line(width: 24, height: 11),
            Spacer(),
            PSkeleton.line(width: 60, height: 11),
            SizedBox(width: PSpacing.x2),
            PSkeleton.line(width: 60, height: 11),
          ],
        ),
        // 행 placeholder — 카드 다이어트: 카드/구분선 없이 행 리듬(12/10)만.
        Column(
          children: [
            for (int i = 0; i < rows; i++)
              const Padding(
                padding: EdgeInsets.fromLTRB(0, PSpacing.x3, 0, PSpacing.x3),
                child: Row(
                  children: [
                    // ExpenseRow icon tile 정합 — 40px → tile(40)=12=brLg.
                    PSkeleton(
                      width: 40,
                      height: 40,
                      borderRadius: PRadius.brLg,
                    ),
                    SizedBox(width: PSpacing.x3),
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
                    SizedBox(width: PSpacing.x2),
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
