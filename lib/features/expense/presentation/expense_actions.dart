import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/expense/presentation/closed_cycle_notice.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/actions/item_actions.dart';
import 'package:porest_desk_app/shared/widgets/p_swipe_actions.dart';

/// 거래 하나에 할 수 있는 일 — 목록 행(스와이프)과 상세 시트가 같은 것을 부른다.
///
/// 삭제는 지우고 끝나는 일이 아니다. 그 달의 목록과 자산 잔액이 같이 바뀌어야 해서
/// 무효화까지가 한 묶음이다. 한쪽에만 있으면 다른 경로로 지웠을 때 화면이 안 바뀐다.
const expenseActions = ExpenseActions();

class ExpenseActions implements ItemActions<Expense> {
  const ExpenseActions();

  /// 시스템이 만든 거래(매도 실현손익·이체 이자)는 원본을 지워야 사라진다.
  @override
  bool canDelete(Expense e) => e.autoSource == null;

  /// 환불된 거래도 못 고친다 — 돈이 이미 자산으로 돌아가 되돌릴 기준이 없다
  /// (서버도 EXP_043 으로 막는다). 먼저 환불을 취소해야 한다.
  @override
  bool canEdit(Expense e) => e.autoSource == null && !e.isRefunded;

  @override
  String deleteConfirmTitle(BuildContext context, Expense e) =>
      AppLocalizations.of(context).expDelete;

  /// 확인창이 부를 이름. 상세 화면 제목과 같은 규칙이다 — 상호명이 없으면 적요,
  /// 그것도 없으면 카테고리. 거래는 이름을 안 가질 수 있어 마지막에 기본값을 둔다.
  String displayNameOf(BuildContext context, Expense e) =>
      e.merchant ??
      e.description ??
      e.categoryName ??
      AppLocalizations.of(context).expTxFallback;

  /// 환불이 거래를 만들지 않으므로 "함께 사라지는 환불" 경고는 없다 — 환불은
  /// 원거래에 찍힌 표식이고, 원거래를 지우면 표식도 같이 없어진다.
  @override
  String deleteConfirmMessage(BuildContext context, Expense e) =>
      AppLocalizations.of(context).expDeleteConfirm(displayNameOf(context, e));

  /// 삭제 확인창 본문 — 결제가 끝난 회차의 카드 거래면 한 문구를 덧붙인다(D1).
  ///
  /// 상세와 스와이프가 **같은 것**을 부른다. 서버에 묻지 않으므로 스와이프처럼 문구가
  /// 액션을 만들 때 굳는 자리에서도 상세와 같은 말을 한다.
  String deleteConfirmMessageWith(
    BuildContext context,
    Expense e,
    Asset? asset,
  ) => withClosedCycleNote(
    AppLocalizations.of(context),
    deleteConfirmMessage(context, e),
    closedCycleSpanOfExpense(e, asset),
  );

  /// 목록 행을 밀었을 때 드러나는 액션 — 수정·삭제.
  ///
  /// 확인창 문구가 액션을 만들 때 굳는 선언형이라 여기서 다 정한다. 상세 시트의
  /// 삭제와 같은 제목·같은 본문이다(spec alert-dialog).
  List<PSwipeAction> swipeActions(
    BuildContext context,
    WidgetRef ref,
    Expense e, {
    required Asset? asset,
  }) {
    final l = AppLocalizations.of(context);
    return [
      if (canEdit(e))
        PSwipeAction(
          label: l.actionEdit,
          icon: LucideIcons.pencil,
          kind: PSwipeKind.primary,
          onSelect: () => edit(context, ref, e),
        ),
      if (canDelete(e))
        PSwipeAction(
          label: l.actionDelete,
          icon: LucideIcons.trash2,
          kind: PSwipeKind.destructive,
          confirmTitle: deleteConfirmTitle(context, e),
          confirmMessage: deleteConfirmMessageWith(context, e, asset),
          onSelect: () => delete(context, ref, e, asset: asset),
        ),
    ];
  }

  /// 지운다.
  ///
  /// 열린 회차에서 미리 낸 돈이 남아 결제계좌로 돌아갔으면 그 금액을 토스트로 알린다
  /// (D4) — 스와이프로 지워도 같다. 미리보기가 없으니 예고한 금액과 견주지 않는다.
  /// 결제가 끝난 회차의 거래였으면 토스트에 [잔액 고치기] 를 단다(D9).
  ///
  /// [asset] 은 부르는 쪽이 이미 들고 있는 그 거래의 자산이다(목록·상세 둘 다 자산
  /// 목록을 보고 있다). 안 주면 자산 목록 캐시에서 찾는다.
  @override
  Future<bool> delete(
    BuildContext context,
    WidgetRef ref,
    Expense e, {
    Asset? asset,
  }) async {
    // 행은 지워지며 사라지고 상세 시트는 닫힌다 — 토스트는 그보다 오래 사는 자리에.
    final host = hostContextOf(context);
    // 지우기 전에 짚어 둔다 — 결제가 끝난 회차였으면 [잔액 고치기] 를 단다(D9).
    final fixBalance = fixBalanceTargetOf(e, asset ?? assetOfExpense(ref, e));
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      final refunded = await repo.delete(e.rowId);
      _invalidateAfterDelete(ref, e);
      if (host.mounted) {
        showChangeResultToast(
          host,
          refundedAmount: refunded,
          fixBalanceAssetId: fixBalance,
        );
      }
      return true;
    } on ApiException {
      return false;
    }
  }

  @override
  Future<void> edit(BuildContext context, WidgetRef ref, Expense e) async {
    // showAddTxSheet 은 void — 시트가 닫히기를 기다리지 않는다. 스와이프에서 부를 때도
    // 기다릴 이유가 없다(닫힌 뒤 할 일이 없다).
    showAddTxSheet(context, edit: e);
  }

  /// 환불 표식을 찍는다 — 거래는 남고 합계에서만 빠진다(삭제와 같은 규칙).
  ///
  /// 확인창은 부르는 쪽이 띄운다. 상세만 부르는 자리라서 여기 두면 목록 스와이프가
  /// 쓰지 않는 문구를 안고 있게 된다.
  ///
  /// 성공하면 서버가 돌려준 거래를 준다 — 상세가 그걸로 다시 그려 배너가 뜬다.
  /// 미리 낸 돈이 계좌로 돌아갔으면 토스트로 알리고(D4), 결제가 끝난 회차였으면
  /// [잔액 고치기] 를 단다(D9). 실패는 null 이다(토스트는 인터셉터가 이미 띄웠다).
  Future<Expense?> refund(
    BuildContext context,
    WidgetRef ref,
    Expense e, {
    String? refundedAt,
    Asset? asset,
  }) async {
    final host = hostContextOf(context);
    final fixBalance = fixBalanceTargetOf(e, asset ?? assetOfExpense(ref, e));
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      final updated = await repo.refund(e.rowId, refundedAt: refundedAt);
      _invalidateAfterRefund(ref);
      if (host.mounted) {
        showChangeResultToast(
          host,
          refundedAmount: updated.refundedAmount,
          fixBalanceAssetId: fixBalance,
        );
      }
      return updated;
    } on ApiException {
      return null;
    }
  }

  /// 환불 표식을 걷는다 — 옛 환급 이체가 묶인 거래면 서버가 그 이체까지 되돌린다.
  Future<Expense?> cancelRefund(WidgetRef ref, Expense e) async {
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      final updated = await repo.cancelRefund(e.rowId);
      _invalidateAfterRefund(ref);
      return updated;
    } on ApiException {
      return null;
    }
  }

  /// 환불은 달 하나로 끝나지 않는다 — 옛 환급 이체를 되돌리면 **오늘** 날짜가
  /// 바뀌므로 원거래 달과 이번 달이 함께 바뀐다. 그래서 달을 가리지 않고 전부 무효화한다.
  void _invalidateAfterRefund(WidgetRef ref) {
    ref.invalidate(monthExpensesProvider);
    invalidateAfterExpenseChange(ref);
  }

  /// 지운 거래가 속한 달의 목록과 자산 잔액을 다시 읽게 한다.
  ///
  /// 날짜가 없으면 어느 달을 무효화할지 알 수 없어 목록은 건너뛴다 — 자산은 날짜와
  /// 무관하게 다시 계산돼야 하므로 그건 항상 한다.
  void _invalidateAfterDelete(WidgetRef ref, Expense e) {
    final date = e.expenseDate;
    if (date != null && date.length >= 10) {
      final parts = date.substring(0, 10).split('-');
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y != null && m != null) {
        ref.invalidate(monthExpensesProvider((year: y, month: m)));
      }
    }
    // origin/main 에서 invalidateAssetsAfterExpense → invalidateAfterExpenseChange 로
    // 바뀌었다(캐시 무효화 범위 확장). 자산뿐 아니라 통계까지 같이 다시 읽는다.
    invalidateAfterExpenseChange(ref);
  }
}

/// 거래가 단 자산 — 확인창 문구와 결과 토스트가 카드인지·닫힌 회차인지 본다.
Asset? assetOfExpense(WidgetRef ref, Expense e) {
  final id = e.assetRowId;
  if (id == null) return null;
  return ref.read(assetsProvider).value?.byRowId(id);
}
