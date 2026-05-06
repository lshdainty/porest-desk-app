import 'package:flutter/material.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// front `<Button>` (shadcn) 미러 — variant 별 일관 스타일.
///
/// variants: primary / secondary / outline / ghost / danger
/// size: sm / md / lg
enum PButtonVariant { primary, secondary, outline, ghost, danger }

enum PButtonSize { sm, md, lg }

class PButton extends StatelessWidget {
  const PButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = PButtonVariant.primary,
    this.size = PButtonSize.md,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PButtonVariant variant;
  final PButtonSize size;
  final bool loading;
  final bool fullWidth;

  EdgeInsetsGeometry _padding() => switch (size) {
        PButtonSize.sm =>
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        PButtonSize.md =>
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        PButtonSize.lg =>
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      };

  TextStyle _textStyle(PorestTokens t) => switch (size) {
        PButtonSize.sm => PTypo.caption.copyWith(fontWeight: FontWeight.w600),
        PButtonSize.md => PTypo.bodySm.copyWith(fontWeight: FontWeight.w600),
        PButtonSize.lg => PTypo.body.copyWith(fontWeight: FontWeight.w700),
      };

  double _iconSize() => switch (size) {
        PButtonSize.sm => 14,
        PButtonSize.md => 16,
        PButtonSize.lg => 18,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
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
        fg = t.fgSecondary;
        border = BorderSide.none;
        break;
      case PButtonVariant.danger:
        bg = t.statusDanger;
        fg = Colors.white;
        border = BorderSide.none;
        break;
    }

    final disabled = onPressed == null || loading;
    final btn = Material(
      color: disabled ? bg.withValues(alpha: 0.5) : bg,
      shape: RoundedRectangleBorder(
        borderRadius: PRadius.brMd,
        side: border,
      ),
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: PRadius.brMd,
        child: Padding(
          padding: _padding(),
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
                Icon(icon, size: _iconSize(), color: fg),
              if ((loading || icon != null)) const SizedBox(width: 6),
              Text(label, style: _textStyle(t).copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
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
                    color: t.fgSecondary, fontWeight: FontWeight.w600)),
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
