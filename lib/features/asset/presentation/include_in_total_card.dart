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
    final l = AppLocalizations.of(context);
    return _AssetToggleCard(
      icon: LucideIcons.wallet,
      title: l.assetIncludeInTotal,
      desc: l.assetIncludeInTotalDesc,
      value: value,
      onChanged: onChanged,
    );
  }
}

/// 자산 하나의 금액만 가리는 토글 — 합계 포함 바로 아래에 선다.
///
/// 화면 카드 가리기(설정 › 금액 가리기)와 **별개 축**이다. 그쪽은 "이 화면의 이 묶음을
/// 가린다" 는 사용자 설정이고, 이건 "이 자산은 늘 가린다" 는 자산의 속성이라 둘은
/// 합집합으로 판정한다 — 하나라도 켜져 있으면 가려진다.
class HideAmountCard extends StatelessWidget {
  const HideAmountCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _AssetToggleCard(
      icon: LucideIcons.eyeOff,
      title: l.assetHideThisAmount,
      desc: l.assetHideThisAmountDesc,
      value: value,
      onChanged: onChanged,
    );
  }
}

/// 두 토글이 같은 모양이라 껍데기를 한 자리에 둔다 — 한쪽만 고쳐 어긋나지 않게.
class _AssetToggleCard extends StatelessWidget {
  const _AssetToggleCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PCard(
      variant: PCardVariant.bordered,
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x12,
        vertical: PSpace.x12,
      ),
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
            child: Icon(icon, size: 20, color: t.fgSecondary),
          ),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(desc, style: PTypo.caption.copyWith(color: t.fgSecondary)),
              ],
            ),
          ),
          const SizedBox(width: PSpace.x12),
          PSwitch(value: value, onChanged: onChanged, semanticLabel: title),
        ],
      ),
    );
  }
}
