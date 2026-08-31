import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// 폼·섹션 위의 작은 텍스트 라벨. 9+ private `_Label`/`_SectionLabel` 변종에서
/// 추출. 시각 위계는 [PSectionLabelVariant] 로 분기.
///
/// variant:
/// - [PSectionLabelVariant.label] *(default)* — form field label.
///   caption (12px) + fgSecondary. 입력 위 라벨에 사용.
/// - [PSectionLabelVariant.eyebrow] — uppercase-feel eyebrow.
///   caption + fgTertiary + semi + letterSpacing. 섹션 시작 표시.
/// - [PSectionLabelVariant.header] — form label (강조). label.md spec 미러:
///   label-md (14/500) + fgPrimary + leading-none(height 1.0) + optional leading
///   icon. control 위 폼 라벨(예: 캘린더 일정 폼). leading-none 으로 gap 이
///   광학적으로 커지지 않게 유지(label.md: "line-height 1.4면 form gap 이 커짐").
/// - [PSectionLabelVariant.section] — 설정 화면 섹션 제목("테마"/"통화" 등).
///   web SectionLabel(label-sm 13/600/tertiary) 미러.
enum PSectionLabelVariant { label, eyebrow, header, section }

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
      PSectionLabelVariant.label => PTypo.caption.copyWith(
        color: t.fgSecondary,
      ),
      PSectionLabelVariant.eyebrow => PTypo.caption.copyWith(
        color: t.fgTertiary,
        fontWeight: PFontWeight.semi,
        letterSpacing: 0.6,
      ),
      PSectionLabelVariant.header => PTypo.labelMd.copyWith(
        color: t.fgPrimary,
        height: 1.0, // label.md leading-none — control 위 폼 라벨 vertical rhythm
      ),
      PSectionLabelVariant.section => PTypo.bodySm.copyWith(
        color: t.fgTertiary,
        fontWeight: PFontWeight.semi,
        letterSpacing:
            0.5, // web SectionLabel letterSpacing 0.04em(≈0.5px@13) 미러
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
