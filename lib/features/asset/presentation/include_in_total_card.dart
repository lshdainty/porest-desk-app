import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';

/// 자산 추가/수정 다이얼로그(계좌/투자/카드) 공용 "전체 자산 합계에 포함" 토글 행 카드.
///
/// 좌측 둥근 아이콘박스(wallet, bgMuted) + 가운데 제목·부제 + 우측 [PSwitch].
/// 카드 시각은 [PCard] (bordered variant) 사용 — 자체 Container+Decoration 모방 금지(CLAUDE.md).
class IncludeInTotalCard extends StatelessWidget {
  const IncludeInTotalCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return PCard(
      variant: PCardVariant.bordered,
      padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x12, vertical: PSpace.x12),
      child: Row(
        children: [
          // 좌측 둥근 아이콘박스 — bgMuted.
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.bgMuted,
              borderRadius: PRadius.brMd,
            ),
            child: Icon(LucideIcons.wallet, size: 20, color: t.fgSecondary),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.assetIncludeInTotal,
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.assetIncludeInTotalDesc,
                  style: PTypo.caption.copyWith(color: t.fgSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x12),
          PSwitch(
            value: value,
            onChanged: onChanged,
            semanticLabel: l.assetIncludeInTotal,
          ),
        ],
      ),
    );
  }
}
