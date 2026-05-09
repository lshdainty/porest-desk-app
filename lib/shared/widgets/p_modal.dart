import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// 표준 footer — 좌측 삭제(편집 모드만) / 우측 취소 + 저장. controller listen.
class PSheetFooter extends StatelessWidget {
  const PSheetFooter({
    super.key,
    required this.controller,
    required this.submitLabel,
    this.cancelLabel = '취소',
    this.deleteLabel = '삭제',
  });
  final PSheetController controller;
  final String submitLabel;
  final String cancelLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        return Row(
          children: [
            if (controller.onDelete != null)
              TextButton.icon(
                onPressed: controller.submitting ? null : controller.onDelete,
                icon: Icon(LucideIcons.trash2,
                    size: PSpace.x12, color: t.statusDangerFg),
                label: Text(deleteLabel,
                    style: TextStyle(color: t.statusDangerFg)),
              ),
            const Spacer(),
            TextButton(
              onPressed: controller.submitting
                  ? null
                  : () => Navigator.of(ctx).pop(),
              child: Text(cancelLabel),
            ),
            const SizedBox(width: PSpace.x4),
            FilledButton(
              onPressed: controller.canSubmit && !controller.submitting
                  ? controller.onSubmit
                  : null,
              child: controller.submitting
                  ? const SizedBox(
                      width: PSpace.x16,
                      height: PSpace.x16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(submitLabel),
            ),
          ],
        );
      },
    );
  }
}

/// content 와 footer 가 공유하는 작업 상태 (showPSheet 표준 컨트롤러).
///
/// content 측 (입력 폼) 의 setState 시 [setCanSubmit]/[setSubmitting] 호출 →
/// footer 의 AnimatedBuilder 가 listen → 버튼 활성/로딩 상태 자동 반영.
/// footer 측의 onPressed 는 [onSubmit] 을 호출.
class PSheetController extends ChangeNotifier {
  bool submitting = false;
  bool canSubmit = false;
  Future<void> Function()? onSubmit;
  Future<void> Function()? onDelete;

  void setSubmitting(bool v) {
    if (submitting == v) return;
    submitting = v;
    notifyListeners();
  }

  void setCanSubmit(bool v) {
    if (canSubmit == v) return;
    canSubmit = v;
    notifyListeners();
  }

  /// content snapshot 등이 바뀌어 footer 가 다시 그려져야 할 때 호출.
  /// (canSubmit/submitting 외에 footer 가 참조하는 값이 바뀐 경우)
  void bump() => notifyListeners();
}

/// add_tx_sheet 와 동일한 표준 bottom sheet helper.
///
/// 구조 (모두 helper 가 강제):
///   - drag handle (고정)
///   - header: 좌측 큰 제목 + headerActions + 우측 X (고정 높이)
///   - content: 스크롤 영역. `contentBuilder(ctx, scrollController)` 가 ListView/CustomScrollView 직접 구성
///   - footer: optional, 고정 높이. `footerBuilder(ctx)` 로 Row 등 액션 위젯 전달
Future<T?> showPSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext, ScrollController) contentBuilder,
  Widget Function(BuildContext)? footerBuilder,
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
          final mq = MediaQuery.of(innerCtx);
          // 키보드(viewInsets) 와 home indicator(viewPadding) 중 큰 값으로
          // bottom 여백을 잡아 footer 버튼이 잘리지 않게 함.
          final bottomInset = mq.viewInsets.bottom > 0
              ? mq.viewInsets.bottom
              : mq.viewPadding.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
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
                // Content (scroll)
                Expanded(child: contentBuilder(innerCtx, scrollCtrl)),
                // Footer (고정)
                if (footerBuilder != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                        PSpace.x20, PSpace.x12, PSpace.x20, PSpace.x16),
                    color: t.bgSurface,
                    child: footerBuilder(innerCtx),
                  ),
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
