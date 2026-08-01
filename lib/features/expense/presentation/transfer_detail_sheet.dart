import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 이체 상세 — 보기 + 삭제 (web `TransferDetailDialog` 미러).
///
/// 이체는 수정 API 가 없다(생성/삭제만). 값을 바꾸려면 지우고 다시 넣는 방식이라
/// 편집 버튼 대신 삭제만 둔다 — 없는 기능을 약속하지 않기 위해서.
void showTransferDetailSheet(BuildContext context, AssetTransfer transfer) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.expTypeTransfer,
    contentBuilder: (ctx, scrollCtrl) => _TransferDetailBody(
      transfer: transfer,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => AnimatedBuilder(
      animation: controller,
      builder: (c, _) => PViewFooter(
        onDelete: controller.onDelete,
        deleting: controller.submitting,
        onConfirm: () => Navigator.of(c).pop(),
      ),
    ),
  ).whenComplete(controller.dispose);
}

class _TransferDetailBody extends ConsumerStatefulWidget {
  const _TransferDetailBody({
    required this.transfer,
    required this.scrollController,
    required this.controller,
  });
  final AssetTransfer transfer;
  final ScrollController scrollController;
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
      showPSnackBar(context, l.transferDeleted,
          severity: PSnackSeverity.success);
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

    final rows = <(String, String)>[
      (l.expTransferFrom, tr.fromAssetName ?? '-'),
      (l.expTransferTo, tr.toAssetName ?? '-'),
      (l.expAmount, krwSigned(tr.amount, false, unit: true)),
      if (fee > 0) (l.transferFeePrefix, krwSigned(fee, false, unit: true)),
      // 보내는 쪽에서 실제로 빠져나간 금액 — 수수료가 있으면 이체 금액과 다르다.
      if (fee > 0)
        (l.transferWithdrawn, krwSigned(tr.amount + fee, false, unit: true)),
      (l.expDate, (tr.transferDate ?? '-').replaceFirst('T', ' ')),
      if ((tr.description ?? '').isNotEmpty) (l.expDescription, tr.description!),
    ];

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
      children: [
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
    );
  }
}
