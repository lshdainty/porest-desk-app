import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/mask_flags.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 이체 상세 — 보기 + 수정 + 삭제 (web `TransferDetailDialog` 미러).
///
/// 수정·삭제는 서버가 이자 지출·잔액 이력을 되돌렸다 다시 만든다. rowId 는 유지되므로
/// 이 이체를 가리키던 참조가 끊기지 않는다.
///
/// 시스템이 만든 이체(매수 예수금 충당·카드 자동결제)는 금액이 원본과 묶여 있어 고칠 수
/// 없다 — 버튼을 감추고 왜 그런지 적어 둔다.
void showTransferDetailSheet(BuildContext context, AssetTransfer transfer) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.expTypeTransfer,
    // 네댓 줄짜리 목록이라 화면 비율(기본 0.85)로 점유하면 아래가 통째로 빈다.
    // 다른 시트들과 같이 content 높이로 wrap 한다(웹 dialog 정합).
    shrinkWrap: true,
    contentBuilder: (ctx, _) => _TransferDetailBody(
      transfer: transfer,
      controller: controller,
    ),
    footerBuilder: (ctx) => AnimatedBuilder(
      animation: controller,
      builder: (c, _) {
        // 시스템이 만든 이체는 고치거나 지울 수 없다.
        final locked = transfer.autoSource != null;
        return PViewFooter(
          onDelete: locked ? null : controller.onDelete,
          deleting: controller.submitting,
          onEdit: locked
              ? null
              : () {
                  // 시트 콜백은 root navigator 로 닫는다 — caller context 로 pop 하면
                  // 페이지가 팝돼 스택이 소진된다.
                  Navigator.of(c, rootNavigator: true).pop();
                  showAddTxSheet(context, editTransfer: transfer);
                },
        );
      },
    ),
  ).whenComplete(controller.dispose);
}

/// 웹 `TransferDetailDialog` 정합 — "8월 3일 (월) 00:00".
///
/// 서버가 주는 `YYYY-MM-DDTHH:mm:ss` 를 그대로 찍으면 초까지 나오고 요일도 없다.
/// 시각은 00:00 이어도 감추지 않는다 — 목록 행은 감추지만(시각 없는 거래가 흔하다)
/// 상세는 웹과 같이 항상 보여 준다.
String _dateLabel(String? iso) {
  if (iso == null || iso.length < 10) return '-';
  final d = DateTime.tryParse(iso.substring(0, 10));
  if (d == null) return iso;
  final hhmm = iso.length >= 16 ? iso.substring(11, 16) : '';
  return hhmm.isEmpty ? monthDayDow(d) : '${monthDayDow(d)} $hhmm';
}

class _TransferDetailBody extends ConsumerStatefulWidget {
  const _TransferDetailBody({
    required this.transfer,
    required this.controller,
  });
  final AssetTransfer transfer;
  final PSheetController controller;

  @override
  ConsumerState<_TransferDetailBody> createState() => _TransferDetailBodyState();
}

class _TransferDetailBodyState extends ConsumerState<_TransferDetailBody> {
  @override
  void initState() {
    super.initState();
    widget.controller.onDelete = _delete;
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.actionDelete,
      message: l.transferDeleteConfirm,
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;

    widget.controller.setSubmitting(true);
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.deleteTransfer(widget.transfer.rowId);
      // 서버가 양쪽 자산의 잔액 이력을 되돌리므로 자산·거래 목록 모두 새로 받는다.
      ref.invalidate(assetsProvider);
      final d = widget.transfer.transferDate;
      if (d != null && d.length >= 7) {
        final parts = d.split('-');
        ref.invalidate(monthExpensesProvider(
            (year: int.parse(parts[0]), month: int.parse(parts[1]))));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, e.message, severity: PSnackSeverity.error);
    } finally {
      if (mounted) widget.controller.setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final tr = widget.transfer;
    final fee = tr.fee ?? 0;
    // 이체 상세는 지금까지 어떤 카드로도 가려지지 않았다 — 거래 상세와 같은 카드로 묶는다.
    // 금액만 가리고 수수료를 남기면 `이체금액 = 출금총액 − 수수료` 로 좁혀지므로 한 덩어리다.
    final masked =
        ref.watch(maskFlagsProvider('ledger.txDetail')).of(MaskKind.transfer);

    final rows = <(String, String)>[
      (l.expTransferFrom, tr.fromAssetName ?? '-'),
      (l.expTransferTo, tr.toAssetName ?? '-'),
      (l.expAmount, krwSigned(tr.amount, masked, unit: true)),
      if (fee > 0) (l.transferFeePrefix, krwSigned(fee, masked, unit: true)),
      // 보내는 쪽에서 실제로 빠져나간 금액 — 수수료가 있으면 이체 금액과 다르다.
      if (fee > 0)
        (l.transferWithdrawn, krwSigned(tr.amount + fee, masked, unit: true)),
      // 대출 상환에만 있다. 이자는 부채를 줄이지 않고 은행으로 나가는 비용이라,
      // 안 보여 주면 "왜 원금이 이만큼밖에 안 줄었지" 가 된다.
      if ((tr.interestAmount ?? 0) > 0) ...[
        (l.expInterest, krwSigned(tr.interestAmount!, masked, unit: true)),
        (l.transferPrincipal, krwSigned(tr.principalAmount ?? 0, masked, unit: true)),
      ],
      (l.expDate, _dateLabel(tr.transferDate)),
      if ((tr.description ?? '').isNotEmpty) (l.expDescription, tr.description!),
    ];

    // shrinkWrap sheet 라 바깥이 이미 스크롤 — 여기선 Column 을 쓴다(중첩 스크롤 금지).
    // 좌우 24 는 시트 헤더·footer 와 같은 자리에 서기 위한 값이다.
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 왜 고칠 수 없는지 알려 준다 — 버튼만 없으면 고장으로 보인다.
          if (tr.autoSource != null)
            Container(
              margin: const EdgeInsets.only(bottom: PSpace.x8),
              padding: const EdgeInsets.symmetric(
                  horizontal: PSpace.x12, vertical: PSpace.x8),
              decoration: BoxDecoration(
                color: context.tokens.bgMuted,
                borderRadius: PRadius.brMd,
              ),
              child: Text(
                switch (tr.autoSource) {
                  'TRADE_SETTLEMENT' => l.transferAutoTradeSettlement,
                  'CARD_PAYMENT' => l.transferAutoCardPayment,
                  'CARD_REFUND' => l.transferAutoCardRefund,
                  _ => l.transferAutoDefault,
                },
                style: PTypo.caption.copyWith(color: context.tokens.fgTertiary),
              ),
            ),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(label,
                        style: PTypo.caption.copyWith(color: t.fgTertiary)),
                  ),
                  const SizedBox(width: PSpace.x12),
                  Expanded(
                    child: Text(value,
                        style: PTypo.body.copyWith(
                            color: t.fgPrimary, fontWeight: PFontWeight.semi)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
