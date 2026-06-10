import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

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
    this.minLines,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.enabled = true,
    this.autofocus = false,
    this.suffix,
    this.prefix,
    this.prefixText,
    this.suffixText,
    this.errorText,
    this.style,
    this.onSubmitted,
    this.focusNode,
    this.inputFormatters,
    this.autofillHints,
    this.search = false,
  });

  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final TextInputType? keyboardType;
  final bool numbersOnly;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final TextAlign textAlign;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool autofocus;
  final Widget? suffix;
  final Widget? prefix;
  final String? prefixText;
  final String? suffixText;
  final String? errorText;
  final TextStyle? style;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  /// true 면 헤더 검색(top__search) 정합 외형 — 테두리 없음 + radius-md + compact(36) + bodySm.
  final bool search;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final radius = search ? PRadius.brMd : PRadius.brSm;
    final restSide = search ? BorderSide.none : BorderSide(color: t.borderDefault);
    final baseFont = search ? PTypo.bodySm : PTypo.bodyLg;
    final isMultiLine = (maxLines ?? 1) > 1;
    final formatters = inputFormatters ??
        (numbersOnly ? [FilteringTextInputFormatter.digitsOnly] : null);
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      enabled: enabled,
      keyboardType:
          keyboardType ?? (numbersOnly ? TextInputType.number : null),
      inputFormatters: formatters,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: obscureText ? 1 : minLines,
      textAlign: textAlign,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      style: (style ?? baseFont).copyWith(color: t.fgPrimary),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: baseFont.copyWith(color: t.fgTertiary),
        filled: true,
        fillColor: t.bgMuted, // surface-input
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: PSpace.md, vertical: PSpace.sm),
        prefixIcon: prefix,
        suffixIcon: suffix,
        prefixText: prefixText,
        suffixText: suffixText,
        suffixStyle: PTypo.bodySm.copyWith(color: t.fgTertiary),
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: restSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: restSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: t.borderFocus),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: restSide,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: t.statusDanger),
        ),
      ),
    );
    if (isMultiLine) return field;
    return SizedBox(height: search ? 36 : 40, child: field);
  }
}
