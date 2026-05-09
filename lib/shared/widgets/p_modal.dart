import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

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

/// add_tx_sheet 와 동일한 표준 bottom sheet helper.
///
/// 구조: drag handle → 좌측 큰 제목 + 우측 X (+ extra actions) → 본문 (scrollable).
/// `bodyBuilder` 는 `ScrollController` 를 받아 ListView/CustomScrollView 등을 직접 구성.
Future<T?> showPSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext, ScrollController) bodyBuilder,
  List<Widget> headerActions = const [],
  double initialChildSize = 0.85,
  double minChildSize = 0.5,
  double maxChildSize = 0.95,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.tokens.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(PRadius.xl2)),
    ),
    builder: (sheetCtx) {
      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (innerCtx, scrollCtrl) {
          final t = innerCtx.tokens;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(innerCtx).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: PSpace.x8),
                  width: PSpace.x32 + PSpace.x4,
                  height: PSpace.x4,
                  decoration: BoxDecoration(
                    color: t.borderDefault,
                    borderRadius: PRadius.brXs2,
                  ),
                ),
                // Header (제목 + 액션 + close)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      PSpace.x16, PSpace.x12, PSpace.x8, PSpace.x4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: PTypo.h3.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.heavy,
                          ),
                        ),
                      ),
                      ...headerActions,
                      IconButton(
                        icon: Icon(LucideIcons.x,
                            color: t.fgTertiary, size: PSpace.x20),
                        onPressed: () => Navigator.of(innerCtx).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(child: bodyBuilder(innerCtx, scrollCtrl)),
              ],
            ),
          );
        },
      );
    },
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
