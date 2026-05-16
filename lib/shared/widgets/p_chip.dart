import 'package:flutter/material.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// Chip — pill 형태 단일선택 토글. 필터/카테고리/태그/타입 선택 등에 사용.
///
/// porest-design에는 chip 전용 spec이 없어(toggle-group spec은 2~5 segmented 한정),
/// desk-app inline `_Chip` 13변종에서 추출한 공통 인터페이스로 정의.
///
/// - [variant]: solid = active 시 brand 채움(fgOnBrand 텍스트) /
///   subtle = active 시 brandSubtle bg(fgPrimary 텍스트, 약한 강조)
/// - [shape]: pill = brFull(기본) / rounded = brMd
/// - [color]: 동적 색 override — category/brand chip에서 brand 톤 대신 사용.
///   subtle 모드: bg = color@16% alpha, fg = color
///   solid 모드: bg = color, fg = onColor(자동 contrast)
/// - [icon] + [iconColor]: 좌측 아이콘
/// - [trailing]: 우측 위젯 (count 등)
enum PChipVariant { solid, subtle }

enum PChipShape { pill, rounded }

enum PChipSize { sm, md }

class PChip extends StatelessWidget {
  const PChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.variant = PChipVariant.solid,
    this.shape = PChipShape.pill,
    this.size = PChipSize.md,
    this.color,
    this.icon,
    this.iconColor,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final PChipVariant variant;
  final PChipShape shape;
  final PChipSize size;
  final Color? color;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = shape == PChipShape.pill ? PRadius.brFull : PRadius.brMd;
    final padding = _padding();
    final (bg, fg, borderColor, borderWidth) = _colors(t);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            border: borderColor != null
                ? Border.all(color: borderColor, width: borderWidth)
                : null,
            borderRadius: radius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: iconColor ?? fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: _textStyle().copyWith(
                  color: fg,
                  fontWeight:
                      selected ? PFontWeight.semi : PFontWeight.medium,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsetsGeometry _padding() {
    switch (size) {
      case PChipSize.sm:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
      case PChipSize.md:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  TextStyle _textStyle() {
    switch (size) {
      case PChipSize.sm:
        return PTypo.caption;
      case PChipSize.md:
        return PTypo.bodySm;
    }
  }

  (Color, Color, Color?, double) _colors(PorestTokens t) {
    if (!selected) {
      return (t.bgSurface, t.fgSecondary, t.borderSubtle, 1);
    }
    final custom = color;
    if (custom != null) {
      switch (variant) {
        case PChipVariant.solid:
          return (custom, _onColor(custom), null, 1);
        case PChipVariant.subtle:
          return (
            custom.withValues(alpha: 0.16),
            custom,
            custom.withValues(alpha: 0.5),
            1.5,
          );
      }
    }
    switch (variant) {
      case PChipVariant.solid:
        return (t.bgBrand, t.fgOnBrand, null, 1);
      case PChipVariant.subtle:
        return (t.bgBrandSubtle, t.fgPrimary, t.borderBrand, 1.5);
    }
  }

  Color _onColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
