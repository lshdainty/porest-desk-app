import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_aggregates.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_actions.dart';
import 'package:groo_damda_app/features/expense/presentation/transfer_detail_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/transfer_row.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/header_row/p_header_row.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';

/// 줄 끝 ⋮ 자리 — 단추 40 + 오른쪽 12. 밀기가 없는 줄(이체 · 시스템 거래)도 같은 폭을 비워 금액 자리를 맞춘다.
const double kLedgerMoreSlot = PSpacing.x10 + PSpacing.x3;

/// 날짜 묶음 머리 — List Header `mediumWeak`(t4 14 / 19 · 500 · `fg-neutral-subtle` · 좌우 24 · 위아래 8) 값이다(I-07 14).
///
/// 글 "26. 10. 22(목) · 오늘". **그날 합계는 폰에서 지금처럼 둔다**(Q1 A) — 지출 `fg-neutral` · 수입 `fg-brand` + "+" · t4 · 500 ·
/// 고정폭. 합계가 머리 폭의 절반을 넘으면 제목 아래 줄 오른쪽 끝으로 내려간다(Header Row — List Header 와 같은 판정).
/// 머리말 `headingLevel: 2`. 검색이 쓰는 `PDayHeader` 는 그대로 둔다(I-08 몫).
class LedgerDayHeader extends StatelessWidget {
  const LedgerDayHeader({
    super.key,
    required this.date,
    required this.items,
    required this.flags,
  });

  final DateTime date;

  /// 그날의 거래 — 합계 계산에만 쓴다(이체는 순자산 증감이 0 이라 호출부가 빼고 넘긴다).
  final List<Expense> items;
  final MaskFlags flags;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final ds = ledgerKey(date);
    final now = DateTime.now();
    final rel = ds == ledgerKey(now)
        ? l.txmToday
        : ds == ledgerKey(now.subtract(const Duration(days: 1)))
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
    TextStyle sum(Color color) => style.copyWith(color: color);
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
                  style: sum(c.fgNeutral),
                ),
              if (dayIncome > 0)
                Text(
                  krwSigned(
                    dayIncome,
                    flags.of(MaskKind.income),
                    sign: '+',
                    unit: true,
                  ),
                  style: sum(c.fgBrand),
                ),
            ],
          )
        : null;
    return Padding(
      key: const ValueKey('ledger-day-header'),
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.globalGutter,
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

  static String ledgerKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 날짜 묶음 하나 — 머리 + 거래 줄 + 이체 줄. 묶음 위 12 · 첫 묶음 4.
///
/// 거래 줄은 밀기(ds Swipe Actions) + 줄 끝 ⋮ 로 [수정, 삭제] 를 한다. 시스템이 만든 거래는 동작이 없어 밀기 · ⋮ 모두 없다.
/// 이체 줄은 감싸지 않는다. 알림 · 검색에서 들어온 줄은 `bg-brand-weak` 로 강조한다.
class LedgerDayGroup extends ConsumerWidget {
  const LedgerDayGroup({
    super.key,
    required this.date,
    required this.items,
    required this.categoriesAsync,
    required this.flags,
    required this.first,
    this.transfers = const [],
    this.rowKeys,
    this.focusTxId,
  });

  final DateTime date;
  final List<Expense> items;
  final List<AssetTransfer> transfers;
  final AsyncValue<dynamic> categoriesAsync;
  final MaskFlags flags;
  final bool first;
  final Map<int, GlobalKey>? rowKeys;
  final int? focusTxId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    // 삭제 확인창이 결제가 끝난 회차인지 가르는 데 쓴다 — 카드의 cardClosedThrough.
    final assets = ref.watch(assetsProvider).value;

    return Padding(
      padding: EdgeInsets.only(top: first ? PSpacing.x1 : PSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LedgerDayHeader(date: date, items: items, flags: flags),
          for (final e in items)
            Builder(
              builder: (_) {
                final isFocus = focusTxId == e.rowId;
                final k = isFocus
                    ? (rowKeys?.putIfAbsent(e.rowId, () => GlobalKey()))
                    : null;
                final actions = expenseActions.dsSwipeActions(
                  context,
                  ref,
                  e,
                  asset: e.assetRowId == null
                      ? null
                      : assets?.byRowId(e.assetRowId!),
                );
                final name = expenseActions.displayNameOf(context, e);
                // TODO(I-06 머지 뒤): 거래 줄이 ds List 줄(제 좌우 24)이 되면 이 왼쪽 24 를 걷는다(I-07 4).
                final row = Padding(
                  padding: const EdgeInsets.only(left: PSpacing.globalGutter),
                  child: ExpenseRow(
                    expense: e,
                    category: e.categoryRowId == null
                        ? null
                        : categories.byRowId(e.categoryRowId!),
                    flags: flags,
                  ),
                );
                Widget line = PSwipeActions(
                  actions: actions,
                  rowLabel: name,
                  child: Row(
                    children: [
                      Expanded(child: row),
                      if (actions.isEmpty)
                        const SizedBox(width: kLedgerMoreSlot)
                      else
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: PSpacing.x3,
                          ),
                          child: PSwipeActionsMore(
                            actions: actions,
                            rowLabel: name,
                          ),
                        ),
                    ],
                  ),
                );
                // 알림 · 검색에서 들어온 줄 — List `highlighted`(bg-brand-weak)와 같은 바탕 · 모서리.
                if (isFocus) {
                  line = DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.bgBrandWeak,
                      borderRadius: BorderRadius.circular(PRounded.r2_5),
                    ),
                    child: line,
                  );
                }
                return KeyedSubtree(key: k, child: line);
              },
            ),
          // 이체는 시각이 없어(LocalDate) 그날의 맨 뒤 — web 정렬(내림차순)과 동일한 자리.
          for (final tr in transfers)
            Padding(
              // 줄 자체가 오른쪽 24 를 가지므로 거래 줄(⋮ 자리만)과 금액 자리가 같게 24 를 덜어 낸다.
              padding: const EdgeInsetsDirectional.only(
                end: kLedgerMoreSlot - PSpacing.globalGutter,
              ),
              child: TransferRow(
                key: ValueKey('t${tr.rowId}'),
                transfer: tr,
                flags: flags,
                onTap: () => showTransferDetailSheet(context, tr),
              ),
            ),
        ],
      ),
    );
  }
}

/// 불러오는 동안의 날짜 묶음 — 머리 한 줄 + 거래 줄 [rows] 개(List 두 줄 줄 66 = 위아래 12 + 타일 40 · 글 42).
class LedgerDaySkeleton extends StatelessWidget {
  const LedgerDaySkeleton({super.key, required this.rows, this.first = false});

  final int rows;
  final bool first;

  /// 줄 하나의 높이 — 위아래 12 + 제목 t5(22) + 설명 t3(18) + 사이 2.
  static const double rowHeight = 66;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: first ? PSpacing.x1 : PSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
              vertical: PSpacing.x2,
            ),
            child: Row(
              children: [
                PSkeleton.text(PTypography.t4, width: 96),
                const Spacer(),
                PSkeleton.text(PTypography.t4, width: 72),
              ],
            ),
          ),
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                PSpacing.globalGutter,
                PSpacing.x3,
                kLedgerMoreSlot,
                PSpacing.x3,
              ),
              child: Row(
                children: [
                  const PSkeleton(
                    width: PSpacing.x10,
                    height: PSpacing.x10,
                    radius: PSkeletonRadius.r12,
                  ),
                  const SizedBox(width: PSpacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: PSpacing.x0_5,
                      children: [
                        PSkeleton.text(PTypography.t5, width: 120),
                        PSkeleton.text(PTypography.t3, width: 80),
                      ],
                    ),
                  ),
                  const SizedBox(width: PSpacing.x2),
                  PSkeleton.text(PTypography.t5, width: 80),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
