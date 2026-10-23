import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';

/// 아직 오지 않은 이체인가 — 거래와 같은 기준(서버 집계도 오늘까지만 센다).
bool _isScheduled(String? date) {
  if (date == null) return false;
  final normalized = date.length == 10 ? '${date}T23:59:59' : date;
  return DateTime.parse(normalized).isAfter(DateTime.now());
}

/// 이체 한 건 — 거래 줄과 **같은 ds List 줄 값**이다(I-07 5).
///
/// 앞 타일 40(모서리 12 · 회색 `chart-gray-weak` 바탕 + `chart-gray` 아이콘 20) · 제목 t5 400(줄을 바꾼다) · 설명 Tag Group
/// t3 한 줄 말줄임("A → B" · 수수료 · 시각) · 금액 t5 700 고정폭 `fg-neutral`. 줄이 제 좌우 24 · 위아래 12 를 가지므로 부르는
/// 쪽은 좌우 여백을 두지 않는다(아직 쥔 호스트만 [gutter] 0).
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
    this.gutter,
    super.key,
  });

  final AssetTransfer transfer;

  /// 화면 카드 + 종류 카드. 이체 행은 언제나 이체 종류다.
  final MaskFlags flags;
  final int? perspectiveAssetRowId;
  final VoidCallback? onTap;

  /// **임시 인자** — 기본(null)은 ds List 줄의 24. 좌우 24 를 아직 쥐고 있는 호스트는 0.
  final double? gutter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
    final scheduled = _isScheduled(transfer.transferDate);

    final tags = PTagGroup(
      size: PTagGroupSize.t3,
      overflow: PTagGroupOverflow.truncate,
      items: [
        PTag(route),
        if (fee > 0)
          PTag(
            '${l.transferFeePrefix} ${krwSigned(fee, flags.of(MaskKind.transfer))}',
          ),
        if (hhmm.isNotEmpty && hhmm != '00:00') PTag(hhmm),
      ],
    );
    // 이체도 미래 날짜로 넣을 수 있다 — 거래와 같은 "예정" 배지. 합계에 안 드는 줄은 제목 · 금액만 옅게.
    final detail = scheduled
        ? Row(
            children: [
              PBadge(label: l.expScheduled),
              const SizedBox(width: PSpacing.x1_5),
              Flexible(child: tags),
            ],
          )
        : tags;

    return PListButtonItem(
      title: transfer.description?.isNotEmpty == true
          ? transfer.description!
          : l.expTypeTransfer,
      titleColor: scheduled ? c.fgNeutralSubtle : null,
      gutter: gutter,
      detailChild: detail,
      prefix: PListTile(
        background: c.chartGrayWeak,
        color: c.chartGray,
        child: const Icon(LucideIcons.arrowLeftRight),
      ),
      suffix: PListValue.amount(
        krwSigned(shown, flags.of(MaskKind.transfer), sign: sign, unit: true),
        style: TextStyle(
          color: scheduled ? c.fgNeutralSubtle : c.fgNeutral,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      onTap: onTap,
    );
  }
}
