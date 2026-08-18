import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/constellation/application/constellation_providers.dart';
import 'package:porest_desk_app/features/memo/application/memo_providers.dart';
import 'package:porest_desk_app/features/memo/domain/memo.dart';
import 'package:porest_desk_app/features/memo/presentation/memo_edit_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/actions/item_actions.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 메모 하나에 할 수 있는 일 — 목록 행(스와이프)과 상세 다이얼로그가 같은 것을 부른다.
const memoActions = MemoActions();

class MemoActions implements ItemActions<Memo> {
  const MemoActions();

  @override
  bool canDelete(Memo m) => true;

  @override
  bool canEdit(Memo m) => true;

  @override
  String deleteConfirmMessage(BuildContext context, Memo m) =>
      AppLocalizations.of(context).memoDeleteConfirm;

  @override
  Future<bool> delete(BuildContext context, WidgetRef ref, Memo m) async {
    final l = AppLocalizations.of(context);
    try {
      final repo = await ref.read(memoRepositoryProvider.future);
      await repo.delete(m.rowId);
      ref.invalidate(memoListProvider);
      // 메모는 별자리(할일 게이미피케이션)에도 점수로 들어간다 — 지우면 같이 다시 센다.
      invalidateConstellation(ref);
      return true;
    } on ApiException catch (e) {
      if (context.mounted) {
        showPSnackBar(context, l.memoDeleteFailed(e.message),
            severity: PSnackSeverity.error);
      }
      return false;
    }
  }

  @override
  Future<void> edit(BuildContext context, WidgetRef ref, Memo m) async {
    // showMemoEditDialog 는 void — 닫히기를 기다릴 이유가 없다.
    showMemoEditDialog(context, edit: m);
  }

  /// 고정 토글 — 메모에만 있는 액션이라 [ItemActions] 밖에 둔다.
  ///
  /// 인터페이스에 넣으면 고정이 없는 다른 항목까지 빈 구현을 갖게 된다.
  Future<void> togglePin(BuildContext context, WidgetRef ref, Memo m) async {
    final l = AppLocalizations.of(context);
    try {
      final repo = await ref.read(memoRepositoryProvider.future);
      await repo.pin(m.rowId);
      ref.invalidate(memoListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        showPSnackBar(context, l.memoActionFailed(e.message),
            severity: PSnackSeverity.error);
      }
    }
  }
}
