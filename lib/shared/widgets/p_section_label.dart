import 'package:flutter/material.dart';

import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// 폼·섹션 위의 작은 텍스트 라벨. 9+ private `_Label`/`_SectionLabel` 변종에서
/// 추출. 시각 위계는 [PSectionLabelVariant] 로 분기.
///
/// variant:
/// - [PSectionLabelVariant.label] *(default)* — form field label.
///   caption (12px) + fgSecondary. 입력 위 라벨에 사용.
/// - [PSectionLabelVariant.eyebrow] — uppercase-feel eyebrow.
///   caption + fgTertiary + semi + letterSpacing. 섹션 시작 표시.
/// - [PSectionLabelVariant.header] — large section header.
///   bodySm (13px) + fgPrimary + semi + optional leading icon.
enum PSectionLabelVariant { label, eyebrow, header }

class PSectionLabel extends StatelessWidget {
  const PSectionLabel(
    this.text, {
    super.key,
    this.variant = PSectionLabelVariant.label,
    this.icon,
  });

  final String text;
  final PSectionLabelVariant variant;

  /// header variant 전용 leading 아이콘.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = switch (variant) {
      PSectionLabelVariant.label =>
        PTypo.caption.copyWith(color: t.fgSecondary),
      PSectionLabelVariant.eyebrow => PTypo.caption.copyWith(
          color: t.fgTertiary,
          fontWeight: PFontWeight.semi,
          letterSpacing: 0.6,
        ),
      PSectionLabelVariant.header => PTypo.bodySm.copyWith(
          color: t.fgPrimary,
          fontWeight: PFontWeight.semi,
        ),
    };
    if (variant == PSectionLabelVariant.header && icon != null) {
      return Row(
        children: [
          Icon(icon, size: PSpace.x16, color: t.fgSecondary),
          const SizedBox(width: PSpace.x4),
          Text(text, style: style),
        ],
      );
    }
    return Text(text, style: style);
  }
}
