import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/todo/application/todo_providers.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_edit_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/actions/item_actions.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 할일 하나에 할 수 있는 일 — 목록 행(스와이프)과 상세 다이얼로그가 같은 것을 부른다.
const todoActions = TodoActions();

class TodoActions implements ItemActions<Todo> {
  const TodoActions();

  /// 할일은 전부 사용자가 만든 것이라 막을 게 없다.
  @override
  bool canDelete(Todo t) => true;

  @override
  bool canEdit(Todo t) => true;

  @override
  String deleteConfirmMessage(BuildContext context, Todo t) =>
      AppLocalizations.of(context).todoDeleteConfirm(t.title);

  @override
  Future<bool> delete(BuildContext context, WidgetRef ref, Todo t) async {
    final l = AppLocalizations.of(context);
    try {
      final repo = await ref.read(todoRepositoryProvider.future);
      await repo.delete(t.rowId);
      ref.invalidate(todoListProvider);
      return true;
    } on ApiException catch (e) {
      if (context.mounted) {
        showPSnackBar(
          context,
          '${l.todoDeleteFailed}: ${e.message}',
          severity: PSnackSeverity.error,
        );
      }
      return false;
    }
  }

  @override
  Future<void> edit(BuildContext context, WidgetRef ref, Todo t) async {
    // showTodoEditDialog 는 void — 닫히기를 기다릴 이유가 없다.
    showTodoEditDialog(context, edit: t);
  }
}
