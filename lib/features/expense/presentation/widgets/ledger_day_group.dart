import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_actions.dart';
import 'package:groo_damda_app/features/expense/presentation/transfer_detail_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/transfer_row.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';

/// 줄 끝 ⋮ 자리 — 줄의 뒤 붙이개(웹 swipe-actions `suffixNode` 와 같은 자리)다. 단추 40(누르는 44)은 화면 끝에서 16 ~ 56 에 서고(글리프 가운데
/// 36), 금액 끝은 56 이다: 줄 오른쪽 여백 16 + 자리 36 + 붙이개 사이 4. 단추는 자리보다 왼쪽으로 4 겹쳐(웹 `-ml-x1`) 40 전체가 눌린다.
/// 밀기가 없는 줄(이체 · 시스템 거래)도 같은 폭을 **비워** 금액 자리를 맞춘다(Q6 A, 웹 · 앱 한 벌).
const double kLedgerMoreSlot = PSpacing.x9;

/// 줄 오른쪽 여백(줄 끝 단추가 화면 끝에서 16 에 선다).
const double kLedgerRowEndGutter = PSpacing.x4;

/// 금액 끝이 화면 끝에서 떨어진 거리 — 이체 줄 · 스켈레톤이 거래 줄과 맞춘다.
const double kLedgerAmountEnd =
    kLedgerRowEndGutter + kLedgerMoreSlot + PSpacing.x1;

/// 자리(폭 [kLedgerMoreSlot])보다 [overhang] 만큼 왼쪽으로 넓은 자식을 놓고, **그 바깥도 눌리게** 한다 — Flutter 는 기본으로 부모 크기
/// 밖을 누르면 받지 않아 OverflowBox · Transform 으로 내민 단추의 바깥 조각이 줄 누름이 된다(웹은 음수 여백이라 40 전체가 눌린다).
class _HangLeft extends SingleChildRenderObjectWidget {
  const _HangLeft({
    required this.slot,
    required this.overhang,
    required super.child,
  });

  final double slot;
  final double overhang;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHangLeft(slot, overhang);

  @override
  void updateRenderObject(BuildContext context, _RenderHangLeft r) {
    r
      ..slot = slot
      ..overhang = overhang;
  }
}

class _RenderHangLeft extends RenderShiftedBox {
  _RenderHangLeft(this._slot, this._overhang) : super(null);

  double _slot;
  double _overhang;

  set slot(double v) {
    if (v == _slot) return;
    _slot = v;
    markNeedsLayout();
  }

  set overhang(double v) {
    if (v == _overhang) return;
    _overhang = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.constrain(Size(_slot, 0));
      return;
    }
    c.layout(
      BoxConstraints(maxHeight: constraints.maxHeight),
      parentUsesSize: true,
    );
    size = constraints.constrain(Size(_slot, c.size.height));
    (c.parentData! as BoxParentData).offset = Offset(-_overhang, 0);
  }

  // 자식이 자기 크기 밖(왼쪽 overhang)까지 눌리게 — 부모 크기 검사를 건너뛴다.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    final offset = (c.parentData! as BoxParentData).offset;
    final hit = result.addWithPaintOffset(
      offset: offset,
      position: position,
      hitTest: (r, p) => c.hitTest(r, position: p),
    );
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }
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
    final categories = ref.watch(categoriesProvider).value ?? const [];
    // 삭제 확인창이 결제가 끝난 회차인지 가르는 데 쓴다 — 카드의 cardClosedThrough.
    final assets = ref.watch(assetsProvider).value;

    return Padding(
      padding: EdgeInsets.only(top: first ? PSpacing.x1 : PSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PDayHeader(date: date, items: items, flags: flags),
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
                // 거래 줄은 ds List 줄(제 좌우 24)이다 — 바깥 24 는 없다(I-07 4). ⋮ 는 줄의 뒤 붙이개라 강조 바탕이 줄 끝까지 이어진다.
                final row = ExpenseRow(
                  expense: e,
                  category: e.categoryRowId == null
                      ? null
                      : categories.byRowId(e.categoryRowId!),
                  flags: flags,
                  highlighted: isFocus,
                  endGutter: kLedgerRowEndGutter,
                  trailing: actions.isEmpty
                      ? const SizedBox(width: kLedgerMoreSlot)
                      : _HangLeft(
                          slot: kLedgerMoreSlot,
                          overhang: PSpacing.x1,
                          child: PListAction(
                            child: PSwipeActionsMore(
                              actions: actions,
                              rowLabel: name,
                            ),
                          ),
                        ),
                );
                final line = PSwipeActions(
                  actions: actions,
                  rowLabel: name,
                  child: row,
                );
                return KeyedSubtree(key: k, child: line);
              },
            ),
          // 이체는 시각이 없어(LocalDate) 그날의 맨 뒤 — web 정렬(내림차순)과 동일한 자리.
          for (final tr in transfers)
            Padding(
              // 거래 줄과 금액 자리가 같게 ⋮ 자리만큼 비운다.
              padding: const EdgeInsetsDirectional.only(
                end: kLedgerAmountEnd - PSpacing.globalGutter,
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
                kLedgerAmountEnd,
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
