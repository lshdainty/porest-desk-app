import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/features/expense/domain/refund_preview.dart';
import 'package:porest_desk_app/features/expense/presentation/paid_refund_note.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 삭제 확인 결과 — 눌렀는가와, 확인창이 **예고한** 환급액.
///
/// 예고한 값을 들고 나가는 이유: 실제 환급액이 그와 다를 때만 사후 토스트를 띄운다.
/// 같으면 사용자가 확인창에서 이미 읽었다(설계 13-2).
typedef DeleteConfirmResult = ({bool ok, int? previewed});

/// 거래 삭제 확인 — **환급 안내 한 줄**을 함께 그린다(설계 13-2).
///
/// 결제 완료 회차의 카드 거래를 지우면 돈이 결제계좌로 돌아간다. 돈이 움직이는데
/// 확인창이 아무 말도 안 하면, 계좌에 출처 모를 입금이 하나 생긴 것으로 보인다
/// (이체 메모에만 남는다).
///
/// 그래서 [preview] 를 받아 [PaidRefundNote] 로 그린다 — 도는 중 스켈레톤 / 금액 /
/// "이미 환급된 거래" / 결제한 달이 지나 기록만 정리 / 못 물어봤으면 금액 없는 문구.
/// **삭제 버튼은 기다리지 않는다**: 느린 네트워크가 삭제를 막으면 안 된다.
Future<DeleteConfirmResult> showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required Future<RefundPreview>? preview,
  required bool isCreditCard,
  required bool cardHasPaymentAsset,
}) async {
  final result = await showDialog<DeleteConfirmResult>(
    context: context,
    builder: (ctx) => _DeleteConfirmDialog(
      title: title,
      message: message,
      preview: preview,
      isCreditCard: isCreditCard,
      cardHasPaymentAsset: cardHasPaymentAsset,
    ),
  );
  return result ?? (ok: false, previewed: null);
}

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({
    required this.title,
    required this.message,
    required this.preview,
    required this.isCreditCard,
    required this.cardHasPaymentAsset,
  });
  final String title;
  final String message;
  final Future<RefundPreview>? preview;
  final bool isCreditCard;
  final bool cardHasPaymentAsset;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  RefundPreview? _preview;

  /// 예고할 금액 — 없으면 null. 실제 환급액을 이 값과 비교해 토스트를 가른다.
  int? get _previewedAmount {
    final p = _preview;
    return p != null && p.hasRefund ? p.refundAmount : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return PFormAlertDialog(
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: PTypo.bodySm.copyWith(color: t.fgSecondary),
          ),
          if (widget.isCreditCard)
            PaidRefundNote(
              preview: widget.preview,
              cardHasPaymentAsset: widget.cardHasPaymentAsset,
              onResolved: (p) => _preview = p,
            ),
        ],
      ),
      actions: [
        PButton(
          label: l.actionCancel,
          variant: PButtonVariant.secondary,
          size: PButtonSize.lg,
          fullWidth: true,
          onPressed: () => Navigator.pop(context, (ok: false, previewed: null)),
        ),
        PButton(
          label: l.actionDelete,
          variant: PButtonVariant.danger,
          size: PButtonSize.lg,
          fullWidth: true,
          // 미리보기를 기다리지 않는다 — 느린 네트워크가 삭제를 막으면 안 된다.
          onPressed: () =>
              Navigator.pop(context, (ok: true, previewed: _previewedAmount)),
        ),
      ],
    );
  }
}
