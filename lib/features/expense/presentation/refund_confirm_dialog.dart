import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/presentation/closed_cycle_notice.dart';
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
/// 환불일은 **거래일부터 오늘까지**만 고른다(D16) — 서버도 그 밖이면 400 이다.
///
/// 확인하면 `YYYY-MM-DDT12:00:00` 을 돌려준다. **정오**인 이유 — 자정으로 보내면 같은
/// 날 앞서 찍힌 거래보다 과거가 되어 카드 회차 판정이 하루 밀린다. 취소면 null.
///
/// 카드 거래면 한 줄 더 말한다. 결제가 끝난 회차면 통계에서만 빠지고 계좌 잔액은
/// 그대로라는 한 문구(D1, 삭제와 같은 말), 아니면 결제계좌가 없을 때의 안내다.
/// 서버에 묻지 않는다.
Future<String?> showRefundConfirmDialog(
  BuildContext context, {
  required Expense expense,
  required Asset? asset,
}) => showDialog<String>(
  context: context,
  builder: (ctx) => _RefundConfirmDialog(expense: expense, asset: asset),
);

/// 환불일로 고를 수 있는 범위 — 거래일부터 오늘까지(D16).
///
/// 날짜만 견준다(시각을 버린다). 칸이 `YYYY-MM-DD` 를 자정으로 읽으므로 거래 시각을
/// 남겨 두면 거래일 당일이 범위 밖으로 떨어진다. 아직 오지 않은 거래(예정)는 거래일이
/// 오늘보다 뒤라 범위가 뒤집힌다 — 그때는 오늘 하루로 좁혀 두고 판정은 서버에 맡긴다.
({DateTime first, DateTime last}) refundDateRange(
  Expense expense, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final raw = expense.expenseDate;
  final txDay = raw == null || raw.length < 10
      ? null
      : DateTime.tryParse(raw.substring(0, 10));
  final first = txDay == null || txDay.isAfter(today) ? today : txDay;
  return (first: first, last: today);
}

class _RefundConfirmDialog extends StatefulWidget {
  const _RefundConfirmDialog({required this.expense, required this.asset});
  final Expense expense;
  final Asset? asset;

  @override
  State<_RefundConfirmDialog> createState() => _RefundConfirmDialogState();
}

class _RefundConfirmDialogState extends State<_RefundConfirmDialog> {
  late final _range = refundDateRange(widget.expense);

  /// 기본은 오늘 — 대개 그날 처리한다.
  late DateTime _date = _range.last;

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
    final isCreditCard = asset?.assetType == 'CREDIT_CARD';
    final hasPaymentAsset = asset?.paymentAssetRowId != null;
    // 결제가 끝난 회차면 "기록만" 한 문구가 먼저다 — 그때는 결제계좌가 있든 없든
    // 아무 돈도 안 움직인다(D1).
    final note =
        closedCycleNote(l, closedCycleSpanOfExpense(e, asset)) ??
        (isCreditCard && !hasPaymentAsset
            ? l.expRefundConfirmBodyCardNoAccount
            : null);
    return PFormAlertDialog(
      title: l.expRefundConfirmTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.expRefundConfirmBody(
              krwSigned(e.amount.abs(), false, unit: true),
              e.assetName ?? l.expValueNone,
            ),
            style: PTypo.bodySm.copyWith(color: t.fgSecondary),
          ),
          if (note != null) ...[
            const SizedBox(height: PSpace.x8),
            Text(
              note,
              key: const ValueKey('refund-card-note'),
              style: PTypo.bodySm.copyWith(color: t.fgSecondary),
            ),
          ],
          const SizedBox(height: PSpace.x16),
          PField(
            label: l.expRefundDate,
            child: PDateInput(
              value: _date,
              firstDate: _range.first,
              lastDate: _range.last,
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
