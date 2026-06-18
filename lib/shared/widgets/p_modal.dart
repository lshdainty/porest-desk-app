import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

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
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        return Row(
          children: [
            if (controller.onDelete != null)
              PButton(
                label: deleteLabel,
                icon: LucideIcons.trash2,
                variant: PButtonVariant.ghost,
                dangerous: true,
                flush: PButtonFlush.left,
                onPressed: controller.submitting ? null : controller.onDelete,
              ),
            const Spacer(),
            PButton(
              label: cancelLabel,
              variant: PButtonVariant.ghost,
              onPressed: controller.submitting
                  ? null
                  : () => Navigator.of(ctx).pop(),
            ),
            const SizedBox(width: PSpace.x4),
            PButton(
              label: submitLabel,
              loading: controller.submitting,
              onPressed: controller.canSubmit && !controller.submitting
                  ? controller.onSubmit
                  : null,
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
///
/// 두 sizing 모드:
///   - [shrinkWrap]=false (default): `DraggableScrollableSheet` 로 sheet 가
///     화면 [initialChildSize] 비율 만큼 강제 점유. content 짧아도 sheet
///     크기 유지 (긴 form 의 add_tx_sheet 등 표준 — drag 로 min/max 조정).
///   - [shrinkWrap]=true: sheet 가 content 자연 합산 height 로 wrap. content
///     이 짧은 picker/단순 액션 시트 (range picker 등) 에 사용. caller 의
///     `contentBuilder` 는 ListView 대신 Column (or shrinkWrap ListView) 사용.
///     [initialChildSize]/[minChildSize]/[maxChildSize] 무시.
Future<T?> showPSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext, ScrollController) contentBuilder,
  Widget Function(BuildContext)? footerBuilder,
  List<Widget> headerActions = const [],
  double initialChildSize = 0.85,
  double minChildSize = 0.5,
  double maxChildSize = 0.95,
  bool shrinkWrap = false,
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
      if (shrinkWrap) {
        // wrap-content 모드 — content 자연 합산 height + max-h 88% cap.
        final mq = MediaQuery.of(sheetCtx);
        final bottomInset = mq.viewInsets.bottom > 0
            ? mq.viewInsets.bottom
            : mq.viewPadding.bottom;
        // dummy scroll controller — shrinkWrap 모드에선 caller 가 사용 안 함.
        final dummyCtrl = ScrollController();
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: mq.size.height * 0.88),
            child: SingleChildScrollView(
              child: _buildSheetColumn(
                sheetCtx,
                title: title,
                headerActions: headerActions,
                content: contentBuilder(sheetCtx, dummyCtrl),
                footerBuilder: footerBuilder,
                expanded: false,
              ),
            ),
          ),
        );
      }
      // default — DraggableScrollableSheet (긴 form 표준).
      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (innerCtx, scrollCtrl) {
          final mq = MediaQuery.of(innerCtx);
          final bottomInset = mq.viewInsets.bottom > 0
              ? mq.viewInsets.bottom
              : mq.viewPadding.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: _buildSheetColumn(
              innerCtx,
              title: title,
              headerActions: headerActions,
              content: contentBuilder(innerCtx, scrollCtrl),
              footerBuilder: footerBuilder,
              expanded: true,
            ),
          );
        },
      );
    },
  );
}

/// showPSheet 의 두 모드 (DraggableScrollableSheet / shrinkWrap) 가 공유하는
/// 내부 Column 골격 (drag handle + header + content + optional footer).
///
/// [expanded] true 면 content 영역을 `Expanded` 로 감싸 부모가 강제한 높이를
/// 다 차지 (Draggable 모드). false 면 자연 wrap (shrinkWrap 모드).
Widget _buildSheetColumn(
  BuildContext ctx, {
  required String title,
  required List<Widget> headerActions,
  required Widget content,
  required Widget Function(BuildContext)? footerBuilder,
  required bool expanded,
}) {
  final t = ctx.tokens;
  return Column(
    mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
    children: [
      // Drag handle — spec: 40×4 / surface-input / radius-full
      Container(
        margin: const EdgeInsets.only(top: PSpace.x8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: t.bgMuted,
          borderRadius: PRadius.brFull,
        ),
      ),
      // Header (제목 + 액션 + close) — spec: padding lg(16)
      Padding(
        padding: const EdgeInsets.fromLTRB(
            PSpace.lg, PSpace.md, PSpace.sm, PSpace.xs),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                // sheet spec(title-md 18/600) 정합 — 웹 SheetTitle/DrawerTitle 와 동일.
                style: PTypo.h4.copyWith(color: t.fgPrimary),
              ),
            ),
            ...headerActions,
            IconButton(
              icon: Icon(LucideIcons.x,
                  color: t.fgTertiary, size: PSpace.x20),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
      // Content — Draggable 모드면 Expanded 로 영역 강제, shrinkWrap 모드면 자연 wrap.
      if (expanded) Expanded(child: content) else content,
      // Footer (옵션, 고정)
      if (footerBuilder != null)
        Container(
          padding: const EdgeInsets.fromLTRB(
              PSpace.x20, PSpace.x12, PSpace.x20, PSpace.x16),
          color: t.bgSurface,
          child: footerBuilder(ctx),
        ),
    ],
  );
}

/// 표준 form-입력 AlertDialog wrapper — 비밀번호/저금 추가/그룹 수정 등.
///
/// title + content slot + actions slot 골격만 통일. 각 도메인 content
/// (입력 필드, validation 등) 는 사용처 직접 구성.
///
/// 사용 예:
/// ```dart
/// showDialog<bool>(
///   context: context,
///   builder: (_) => PFormAlertDialog(
///     title: '그룹 수정',
///     content: Column(...),
///     actions: [TextButton(...), FilledButton(...)],
///   ),
/// );
/// ```
class PFormAlertDialog extends StatelessWidget {
  const PFormAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.titleLeading,
  });

  final String title;

  /// title 좌측 prefix (예: 아이콘). 8px gap 후 title 텍스트.
  final Widget? titleLeading;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AlertDialog(
      backgroundColor: t.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: PRadius.brLg),
      title: titleLeading != null
          ? Row(
              children: [
                titleLeading!,
                const SizedBox(width: PSpace.sm),
                Expanded(child: Text(title)),
              ],
            )
          : Text(title),
      content: content,
      actions: actions,
    );
  }
}

/// 표준 확인 다이얼로그 — 위험 액션이면 [destructive]=true.
/// 확인 다이얼로그. [onConfirm] 미제공 시 확인 탭 즉시 닫고 true 반환(기존 동작).
///
/// [onConfirm] 제공 시(웹 ConfirmDialog `loading` 정합): 확인 탭 → 다이얼로그를
/// 연 채 **확인(저장) 버튼에만** 스피너를 표시하며 [onConfirm] 을 실행하고, 성공하면
/// 닫고 true. 예외가 발생하면 다이얼로그를 유지(스피너만 해제) — 에러 메시지는
/// [onConfirm] 내부에서 처리. 취소 버튼·바깥 탭은 실행 중에도 원래대로 동작한다.
Future<bool> showPConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool destructive = false,
  Future<void> Function()? onConfirm,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _PConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      onConfirm: onConfirm,
    ),
  );
  return ok == true;
}

class _PConfirmDialog extends StatefulWidget {
  const _PConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    this.onConfirm,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final Future<void> Function()? onConfirm;

  @override
  State<_PConfirmDialog> createState() => _PConfirmDialogState();
}

class _PConfirmDialogState extends State<_PConfirmDialog> {
  bool _busy = false;

  Future<void> _confirm() async {
    final action = widget.onConfirm;
    if (action == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      // 실패 — 다이얼로그 유지, 스피너만 해제 (에러 표시는 onConfirm 내부에서).
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AlertDialog(
      backgroundColor: t.bgSurface,
      title: Text(widget.title),
      content: Text(widget.message),
      actions: [
        // 취소는 작업 중에도 원래 상태 유지 — 비동기 작업은 확인(저장) 버튼 스피너로만 표시.
        PButton(
          label: widget.cancelLabel,
          variant: PButtonVariant.ghost,
          onPressed: () => Navigator.pop(context, false),
        ),
        PButton(
          label: widget.confirmLabel,
          variant: widget.destructive
              ? PButtonVariant.danger
              : PButtonVariant.primary,
          loading: _busy,
          onPressed: _busy ? null : _confirm,
        ),
      ],
    );
  }
}
