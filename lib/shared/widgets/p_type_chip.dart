import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// 지출/수입/이체 같은 토글 chip — front FilterDialog 의 거래 종류 칸 미러.
///
/// active 상태는 success/danger fg 색으로 텍스트·체크 아이콘 표시.
class PTypeChip extends StatelessWidget {
  const PTypeChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  /// active 텍스트·체크 색. 미지정 시 `fgBrandStrong`.
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final ac = activeColor ?? t.fgBrandStrong;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? t.bgBrandSubtle : t.bgMuted,
          border: Border.all(
              color: active ? t.borderBrand : t.borderSubtle),
          borderRadius: PRadius.brSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (active) Icon(LucideIcons.check, size: 12, color: ac),
            if (active) const SizedBox(width: 4),
            Text(label,
                style: PTypo.bodySm.copyWith(
                  fontWeight: PFontWeight.bold,
                  color: active ? ac : t.fgTertiary,
                )),
          ],
        ),
      ),
    );
  }
}
