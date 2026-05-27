import 'package:flutter/material.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import 'p_tooltip.dart';

/// front `<Button>` (shadcn) 미러 — variant 별 일관 스타일.
///
/// variants: primary / secondary / outline / ghost(중립) / accent(brand 강조) / danger
/// size: sm / md / lg
enum PButtonVariant { primary, secondary, outline, ghost, accent, danger }

enum PButtonSize { sm, md, lg }

class PButton extends StatelessWidget {
  const PButton({
    super.key,
    this.label,
    this.onPressed,
    this.icon,
    this.variant = PButtonVariant.primary,
    this.size = PButtonSize.md,
    this.loading = false,
    this.fullWidth = false,
    this.tooltip,
    this.iconColor,
    this.dangerous = false,
  }) : assert(label != null || icon != null,
            'PButton requires either a label or an icon');

  /// icon-only 생성자 — front `<Button size="icon" variant="ghost">` 대응.
  /// 가로 = 높이 (정사각), padding 작게.
  const PButton.icon({
    super.key,
    required IconData this.icon,
    this.onPressed,
    this.variant = PButtonVariant.ghost,
    this.size = PButtonSize.md,
    this.loading = false,
    this.tooltip,
    this.iconColor,
    this.dangerous = false,
  })  : label = null,
        fullWidth = false;

  final String? label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PButtonVariant variant;
  final PButtonSize size;
  final bool loading;
  final bool fullWidth;
  final String? tooltip;
  /// icon-only ghost 버튼에서 아이콘 색만 override (예: trash danger).
  /// label 모드에서도 icon 만 분리 색 적용.
  final Color? iconColor;
  /// ghost variant 에 위험(파괴적) 액션 색을 입힌다 — fg/icon → statusDangerFg.
  /// dialog footer 의 "삭제" 같이 filled `danger` 보다 절제된 표현이 필요한 곳.
  /// 다른 variant 와 함께 쓰면 무시.
  final bool dangerous;

  // DESIGN.desk.md / specs/components/button.md spec:
  // sm: h=32, padY=4 padX=8, font=caption(12), radius=sm(4), icon=14
  // md: h=40, padY=8 padX=12, font=body-md(15), radius=sm(4), icon=16
  // lg: h=48, padY=12 padX=16, font=title-sm(16), radius=md(8), icon=18
  double _height() => switch (size) {
        PButtonSize.sm => 32,
        PButtonSize.md => 40,
        PButtonSize.lg => 48,
      };

  EdgeInsetsGeometry _padding() => switch (size) {
        PButtonSize.sm =>
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        PButtonSize.md =>
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        PButtonSize.lg =>
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      };

  TextStyle _textStyle(PorestTokens t) => switch (size) {
        PButtonSize.sm => TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.caption,
              fontWeight: PFontWeight.medium,
              height: 1.0,
            ),
        PButtonSize.md => TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.bodyMd,
              fontWeight: PFontWeight.medium,
              height: 1.0,
            ),
        PButtonSize.lg => TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.titleSm,
              fontWeight: PFontWeight.medium,
              height: 1.0,
            ),
      };

  double _iconSize() => switch (size) {
        PButtonSize.sm => 14,
        PButtonSize.md => 16,
        PButtonSize.lg => 18,
      };

  BorderRadius _radius() => switch (size) {
        PButtonSize.sm => PRadius.brSm,
        PButtonSize.md => PRadius.brSm,
        PButtonSize.lg => PRadius.brMd,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final iconOnly = label == null;
    Color bg;
    Color fg;
    BorderSide border;
    switch (variant) {
      case PButtonVariant.primary:
        bg = t.bgBrand;
        fg = t.fgOnBrand;
        border = BorderSide.none;
        break;
      case PButtonVariant.secondary:
        bg = t.bgMuted;
        fg = t.fgPrimary;
        border = BorderSide(color: t.borderSubtle);
        break;
      case PButtonVariant.outline:
        bg = Colors.transparent;
        fg = t.fgPrimary;
        border = BorderSide(color: t.borderDefault);
        break;
      case PButtonVariant.ghost:
        bg = Colors.transparent;
        // icon-only ghost(아이콘 액션)는 보조톤 fgSecondary — front button.md v96 정합.
        fg = dangerous
            ? t.statusDangerFg
            : (iconOnly ? t.fgSecondary : t.fgPrimary);
        border = BorderSide.none;
        break;
      case PButtonVariant.accent:
        bg = Colors.transparent;
        fg = dangerous ? t.statusDangerFg : t.fgBrand;
        border = BorderSide.none;
        break;
      case PButtonVariant.danger:
        bg = t.statusDanger;
        fg = t.fgOnDanger;
        border = BorderSide.none;
        break;
    }

    final disabled = onPressed == null || loading;
    // icon-only는 radius-md 둥근 박스 (정사각 + 또렷한 hover/splash) — front button.md v96 정합.
    final radius = iconOnly ? PRadius.brMd : _radius();
    final h = _height();
    final btn = Material(
      color: disabled ? bg.withValues(alpha: 0.5) : bg,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: border,
      ),
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: radius,
        child: SizedBox(
          height: h,
          width: iconOnly ? h : null,
          child: Padding(
            padding: iconOnly ? EdgeInsets.zero : _padding(),
            child: Row(
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(
                    width: _iconSize(),
                    height: _iconSize(),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                else if (icon != null)
                  Icon(icon, size: _iconSize(), color: iconColor ?? fg),
                if (!iconOnly && (loading || icon != null))
                  const SizedBox(width: PSpace.sm),
                if (!iconOnly)
                  Text(label!, style: _textStyle(t).copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
    final tipped = tooltip != null
        ? PTooltip(message: tooltip!, child: btn)
        : btn;
    return fullWidth ? SizedBox(width: double.infinity, child: tipped) : tipped;
  }
}

/// front `<Field>` 등가 — 라벨 + 입력 + 헬퍼/에러 텍스트 묶음.
class PField extends StatelessWidget {
  const PField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.errorText,
    this.required = false,
  });

  final String label;
  final Widget child;
  final String? hint;
  final String? errorText;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: PTypo.caption.copyWith(
                    color: t.fgSecondary, fontWeight: PFontWeight.semi)),
            if (required) ...[
              const SizedBox(width: 2),
              Text('*',
                  style: PTypo.caption.copyWith(color: t.statusDanger)),
            ],
          ],
        ),
        const SizedBox(height: PSpace.x4),
        child,
        if (errorText != null) ...[
          const SizedBox(height: 2),
          Text(errorText!,
              style: PTypo.caption.copyWith(color: t.statusDanger)),
        ] else if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!,
              style: PTypo.caption.copyWith(color: t.fgTertiary)),
        ],
      ],
    );
  }
}
