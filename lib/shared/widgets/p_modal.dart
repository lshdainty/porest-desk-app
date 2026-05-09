import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../app/theme/tokens.dart';

/// 모든 다이얼로그/시트 진입점을 통일하는 helper — front `ModalShell` 미러.
///
/// 이미 곳곳에서 `WoltModalSheet.show + WoltModalSheetPage` 가 반복되어
/// 신규 코드는 이 helper 를 통해 일관 스타일 (제목바 + close 버튼)을 얻는다.
Future<T?> showPModalSheet<T>(
  BuildContext context, {
  required String title,
  required Widget body,
  bool barrierDismissible = true,
  List<Widget> extraTrailingActions = const [],
}) {
  return WoltModalSheet.show<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: Text(title),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor:
            Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...extraTrailingActions,
            IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: Navigator.of(modalCtx).pop,
            ),
          ],
        ),
        child: body,
      ),
    ],
  );
}

/// 표준 확인 다이얼로그 — 위험 액션이면 [destructive]=true.
Future<bool> showPConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final t = ctx.tokens;
      return AlertDialog(
        backgroundColor: t.bgSurface,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: t.statusDanger)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return ok == true;
}
