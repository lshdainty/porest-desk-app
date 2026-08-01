import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';

/// 이체 한 건 — `ExpenseRow` 와 같은 행 리듬을 공유한다(web `TransferRow` 미러).
///
/// 지출/수입과 달리 한 건이 자산 두 개에 걸쳐서, 부호가 "보는 관점"에 따라 달라진다.
/// - [perspectiveAssetRowId] 없음(전체 거래 목록): 관점이 없으므로 중립 — "A → B" 와 금액만.
///   이체는 순자산 증감이 0(수수료 제외)이라 +/- 를 붙이면 지출·수입 합계와 헷갈린다.
/// - [perspectiveAssetRowId] 있음(자산 상세): 그 자산 기준으로 출금이면 -(금액+수수료),
///   입금이면 +금액. 수수료는 보내는 쪽에서만 빠진다(서버 recordTransfer 규칙과 동일).
class TransferRow extends StatelessWidget {
  const TransferRow({
    required this.transfer,
    required this.masked,
    this.perspectiveAssetRowId,
    this.onTap,
    super.key,
  });

  final AssetTransfer transfer;
  final bool masked;
  final int? perspectiveAssetRowId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final fee = transfer.fee ?? 0;

    final isOut = perspectiveAssetRowId != null &&
        transfer.fromAssetRowId == perspectiveAssetRowId;
    final isIn = perspectiveAssetRowId != null &&
        transfer.toAssetRowId == perspectiveAssetRowId;
    final int shown = isOut ? transfer.amount + fee : transfer.amount;
    final String sign = isOut ? '-' : (isIn ? '+' : '');

    final route =
        '${transfer.fromAssetName ?? '-'} → ${transfer.toAssetName ?? '-'}';
    final sub = fee > 0
        ? '$route · ${l.transferFeePrefix} ${krwSigned(fee, masked)}'
        : route;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, PSpace.x12, 0, PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: PRadius.tile(40),
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.arrowLeftRight,
                  size: 18, color: t.fgTertiary),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transfer.description?.isNotEmpty == true
                        ? transfer.description!
                        : l.expTypeTransfer,
                    style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.semi,
                        letterSpacing: -0.07),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Text(
              krwSigned(shown, masked, sign: sign, unit: true),
              style: PTypo.money.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.14),
            ),
          ],
        ),
      ),
    );
  }
}
