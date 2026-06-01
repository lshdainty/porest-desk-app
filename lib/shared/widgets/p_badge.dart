import 'package:flutter/material.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// specs/components/badge.md 미러 — pill shape, font micro/11/bold.
///
/// 강조 강도: solid > soft > outline.
/// 의미 분기: neutral(primary/secondary/danger) / semantic(success/info/warning/error).
///
/// 동적 색상(카테고리·캘린더 등)이 필요할 때는 [PBadge.softColor] 또는
/// [PBadge.outlineColor] 명명 생성자로 색상 override.
enum PBadgeVariant {
  // solid (3)
  primary,
  secondary,
  danger,
  // soft (4 semantic + brand)
  softBrand,
  softSuccess,
  softInfo,
  softWarning,
  softError,
  // outline (5)
  outline,
  outlineSuccess,
  outlineInfo,
  outlineWarning,
  outlineError,
}

class PBadge extends StatelessWidget {
  const PBadge({
    super.key,
    required this.label,
    this.variant = PBadgeVariant.secondary,
    this.dotColor,
    this.icon,
  })  : _customFg = null,
        _customBorder = null;

  /// 동적 색(카테고리 등)을 soft 톤(16% alpha bg + fg)으로 표시.
  const PBadge.softColor({
    super.key,
    required this.label,
    required Color color,
    this.dotColor,
    this.icon,
  })  : variant = PBadgeVariant.softBrand,
        _customFg = color,
        _customBorder = null;

  /// 동적 색을 outline 톤(border + fg)으로 표시.
  const PBadge.outlineColor({
    super.key,
    required this.label,
    required Color color,
    this.dotColor,
    this.icon,
  })  : variant = PBadgeVariant.outline,
        _customFg = color,
        _customBorder = color;

  final String label;
  final PBadgeVariant variant;

  /// 좌측 6×6 colored dot — neutral outline에 색상 의미 부가 시.
  final Color? dotColor;

  /// 좌측 12px 아이콘 — 상태 강조(check/alert 등) 용도.
  final IconData? icon;

  // softColor / outlineColor 생성자 내부 사용. public 생성자에선 null.
  final Color? _customFg;
  final Color? _customBorder;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg, borderColor) = _resolve(t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border:
            borderColor != null ? Border.all(color: borderColor, width: 1) : null,
        borderRadius: PRadius.brFull, // pill — badge.md SoT(모든 badge pill, square 는 spec 외)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: PTypo.micro.copyWith(
              color: fg,
              fontWeight: PFontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color?) _resolve(PorestTokens t) {
    // custom override 우선
    if (_customFg != null) {
      // softColor: bg = custom 16% alpha, fg = custom
      // outlineColor: bg = transparent, border = custom, fg = custom
      if (_customBorder != null) {
        return (Colors.transparent, _customFg, _customBorder);
      }
      return (_customFg.withValues(alpha: 0.16), _customFg, null);
    }
    switch (variant) {
      case PBadgeVariant.primary:
        return (t.bgBrand, t.fgOnBrand, null);
      case PBadgeVariant.secondary:
        return (t.bgMuted, t.fgPrimary, null);
      case PBadgeVariant.danger:
        return (t.statusDanger, t.fgOnDanger, null);
      case PBadgeVariant.softBrand:
        return (t.bgBrandSubtle, t.fgBrand, null);
      case PBadgeVariant.softSuccess:
        return (t.statusSuccessSubtle, t.statusSuccessFg, null);
      case PBadgeVariant.softInfo:
        return (t.statusInfoSubtle, t.statusInfoFg, null);
      case PBadgeVariant.softWarning:
        return (t.statusWarningSubtle, t.statusWarningFg, null);
      case PBadgeVariant.softError:
        return (t.statusDangerSubtle, t.statusDangerFg, null);
      case PBadgeVariant.outline:
        return (Colors.transparent, t.fgPrimary, t.borderDefault);
      case PBadgeVariant.outlineSuccess:
        return (Colors.transparent, t.statusSuccessFg, t.statusSuccess);
      case PBadgeVariant.outlineInfo:
        return (Colors.transparent, t.statusInfoFg, t.statusInfo);
      case PBadgeVariant.outlineWarning:
        return (Colors.transparent, t.statusWarningFg, t.statusWarning);
      case PBadgeVariant.outlineError:
        return (Colors.transparent, t.statusDangerFg, t.statusDanger);
    }
  }
}
