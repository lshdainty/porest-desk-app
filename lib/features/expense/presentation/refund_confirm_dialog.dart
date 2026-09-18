import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 환불 처리 확인 — 웹 `TxDetailDialog` 의 확인 대화상자 미러(설계서 7절).
///
/// 확인만 받는 게 아니라 **환불일**을 받는다. 카드사 환급은 며칠 걸려서 "언제
/// 돌려받았나" 는 사용자만 안다. 그래서 [showPConfirmDialog] 가 아니라 칸이 들어가는
/// [PFormAlertDialog] 다.
///
/// 확인하면 `YYYY-MM-DDT12:00:00` 을 돌려준다. **정오**인 이유 — 자정으로 보내면 같은
/// 날 앞서 찍힌 거래보다 과거가 되어 카드 회차 판정이 하루 밀린다. 취소면 null.
Future<String?> showRefundConfirmDialog(
  BuildContext context, {
  required Expense expense,
  required Asset? asset,
}) => showDialog<String>(
  context: context,
  builder: (ctx) => _RefundConfirmDialog(expense: expense, asset: asset),
);

class _RefundConfirmDialog extends StatefulWidget {
  const _RefundConfirmDialog({required this.expense, required this.asset});
  final Expense expense;
  final Asset? asset;

  @override
  State<_RefundConfirmDialog> createState() => _RefundConfirmDialogState();
}

class _RefundConfirmDialogState extends State<_RefundConfirmDialog> {
  /// 기본은 오늘 — 대개 그날 처리한다.
  DateTime _date = DateTime.now();

  String get _iso {
    final d = _date;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-${day}T12:00:00';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final e = widget.expense;
    final asset = widget.asset;
    // 카드면 한 줄 더 말한다 — 이미 낸 돈이 어디로 가는지가 사용자의 관심사다.
    final isCreditCard = asset?.assetType == 'CREDIT_CARD';
    final hasPaymentAsset = asset?.paymentAssetRowId != null;
    return PFormAlertDialog(
      title: l.expRefundConfirmTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.expRefundConfirmBody(
              krw(e.amount.abs()),
              e.assetName ?? l.expValueNone,
            ),
            style: PTypo.bodySm.copyWith(color: t.fgSecondary),
          ),
          if (isCreditCard) ...[
            const SizedBox(height: PSpace.x8),
            Text(
              hasPaymentAsset
                  ? l.expRefundConfirmBodyCard
                  : l.expRefundConfirmBodyCardNoAccount,
              style: PTypo.bodySm.copyWith(color: t.fgSecondary),
            ),
          ],
          const SizedBox(height: PSpace.x16),
          PField(
            label: l.expRefundDate,
            child: PDateInput(
              value: _date,
              onChanged: (d) {
                if (d != null) setState(() => _date = d);
              },
            ),
          ),
        ],
      ),
      actions: [
        PButton(
          label: l.actionCancel,
          variant: PButtonVariant.secondary,
          size: PButtonSize.lg,
          fullWidth: true,
          onPressed: () => Navigator.pop(context),
        ),
        PButton(
          label: l.expRefundConfirm,
          size: PButtonSize.lg,
          fullWidth: true,
          onPressed: () => Navigator.pop(context, _iso),
        ),
      ],
    );
  }
}
