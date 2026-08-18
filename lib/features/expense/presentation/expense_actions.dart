import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/actions/item_actions.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

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

  @override
  bool canEdit(Expense e) => e.autoSource == null;

  @override
  String deleteConfirmMessage(BuildContext context, Expense e) {
    final l = AppLocalizations.of(context);
    // 환불이 달려 있으면 그것도 함께 사라진다 — 모르고 지우면 지출 총액이 조용히 바뀐다.
    final refundCount = e.refundCount;
    if (refundCount <= 0) return l.expDeleteConfirm;
    return '${l.expDeleteConfirm}\n\n'
        '${l.expDeleteRefundWarn(refundCount, krw(e.refundedAmount))}';
  }

  @override
  Future<bool> delete(BuildContext context, WidgetRef ref, Expense e) async {
    final l = AppLocalizations.of(context);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      await repo.delete(e.rowId);
      _invalidateAfterDelete(ref, e);
      if (context.mounted) {
        showPSnackBar(context, l.expDeleted, severity: PSnackSeverity.success);
      }
      return true;
    } on ApiException catch (err) {
      if (context.mounted) {
        showPSnackBar(
          context,
          '${l.expDeleteFailed}: ${err.message}',
          severity: PSnackSeverity.error,
        );
      }
      return false;
    }
  }

  @override
  Future<void> edit(BuildContext context, WidgetRef ref, Expense e) async {
    // showAddTxSheet 은 void — 시트가 닫히기를 기다리지 않는다. 스와이프에서 부를 때도
    // 기다릴 이유가 없다(닫힌 뒤 할 일이 없다).
    showAddTxSheet(context, edit: e);
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
