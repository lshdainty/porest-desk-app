import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/mask_flags.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';

/// 아직 오지 않은 이체인가 — 거래와 같은 기준(서버 집계도 오늘까지만 센다).
bool _isScheduled(String? date) {
  if (date == null) return false;
  final normalized = date.length == 10 ? '${date}T23:59:59' : date;
  return DateTime.parse(normalized).isAfter(DateTime.now());
}

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
    required this.flags,
    this.perspectiveAssetRowId,
    this.onTap,
    super.key,
  });

  final AssetTransfer transfer;

  /// 화면 카드 + 종류 카드. 이체 행은 언제나 이체 종류다.
  final MaskFlags flags;
  final int? perspectiveAssetRowId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final fee = transfer.fee ?? 0;

    final isOut =
        perspectiveAssetRowId != null &&
        transfer.fromAssetRowId == perspectiveAssetRowId;
    final isIn =
        perspectiveAssetRowId != null &&
        transfer.toAssetRowId == perspectiveAssetRowId;
    final int shown = isOut ? transfer.amount + fee : transfer.amount;
    final String sign = isOut ? '-' : (isIn ? '+' : '');

    final route =
        '${transfer.fromAssetName ?? '-'} → ${transfer.toAssetName ?? '-'}';
    // 시각 표시 — 00:00 이면 생략(ExpenseRow 와 동일 규칙).
    final raw = transfer.transferDate ?? '';
    final hhmm = raw.length >= 16 ? raw.substring(11, 16) : '';
    final timeLabel = (hhmm.isNotEmpty && hhmm != '00:00') ? ' · $hhmm' : '';
    final sub = fee > 0
        ? '$route · ${l.transferFeePrefix} ${krwSigned(fee, flags.of(MaskKind.transfer))}$timeLabel'
        : '$route$timeLabel';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      // 아직 오지 않은 이체는 행째로 흐리게 — 지출 행과 같은 규칙(웹 dim 정합).
      child: Opacity(
        opacity: _isScheduled(transfer.transferDate) ? 0.6 : 1,
        child: Padding(
          // 좌우는 페이지가 쥔다. 행이 여기서 좌측 2 를 더 얹으면 그만큼 날짜 헤더와
          // 어긋난다 — 미세하지만 목록 전체가 헤더보다 오른쪽으로 밀려 보인다.
          padding: const EdgeInsets.fromLTRB(0, PSpace.x12, 0, PSpace.x12),
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
                child: Icon(
                  LucideIcons.arrowLeftRight,
                  size: 18,
                  color: t.fgTertiary,
                ),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            transfer.description?.isNotEmpty == true
                                ? transfer.description!
                                : l.expTypeTransfer,
                            style: PTypo.body.copyWith(
                              color: t.fgPrimary,
                              fontWeight: PFontWeight.semi,
                              letterSpacing: -0.07,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 이체도 미래 날짜로 넣을 수 있다 — 거래와 같은 표시를 준다.
                        if (_isScheduled(transfer.transferDate)) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: t.bgMuted,
                              borderRadius: PRadius.brXs,
                            ),
                            child: Text(
                              l.expScheduled,
                              style: PTypo.micro.copyWith(
                                color: t.fgTertiary,
                                fontWeight: PFontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                krwSigned(
                  shown,
                  flags.of(MaskKind.transfer),
                  sign: sign,
                  unit: true,
                ),
                style: PTypo.money.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
