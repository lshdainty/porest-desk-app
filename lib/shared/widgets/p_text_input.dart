import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// specs/components/input.md 미러 — single size md.
///
/// Spec:
/// - Height: 40px
/// - Padding (Y · X): 8 · 12 (`spacing-sm` · `spacing-md`)
/// - Font: body-lg (16px / 400)
/// - Radius: sm (4px)
/// - Border: 1px `border-default`
/// - Background: `surface-input` (light #F0F2F7, dark #2D3346)
class PTextInput extends StatelessWidget {
  const PTextInput({
    super.key,
    this.controller,
    this.value,
    this.onChanged,
    this.placeholder,
    this.keyboardType,
    this.numbersOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.enabled = true,
    this.autofocus = false,
    this.suffix,
    this.prefix,
    this.style,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final TextInputType? keyboardType;
  final bool numbersOnly;
  final bool obscureText;
  final int? maxLines;
  final TextAlign textAlign;
  final bool enabled;
  final bool autofocus;
  final Widget? suffix;
  final Widget? prefix;
  final TextStyle? style;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isMultiLine = (maxLines ?? 1) > 1;
    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      enabled: enabled,
      keyboardType:
          keyboardType ?? (numbersOnly ? TextInputType.number : null),
      inputFormatters:
          numbersOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      textAlign: textAlign,
      style: (style ?? PTypo.bodyLg).copyWith(color: t.fgPrimary),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: PTypo.bodyLg.copyWith(color: t.fgTertiary),
        filled: true,
        fillColor: t.bgMuted, // surface-input
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: PSpace.md, vertical: PSpace.sm),
        prefixIcon: prefix,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: t.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: t.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: t.borderFocus),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: t.borderDefault),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: t.statusDanger),
        ),
      ),
    );
    if (isMultiLine) return field;
    return SizedBox(height: 40, child: field);
  }
}
