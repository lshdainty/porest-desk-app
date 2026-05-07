import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// front shadcn `<Input>` 미러 — bgSurface 배경, height 36, semantic 토큰 일관 사용.
///
/// 다이얼로그·시트의 입력란은 이 위젯을 통해서만 사용. 기본값:
/// - 높이 36
/// - 배경 `bgSurface` (white/dark surface)
/// - 보더 `borderSubtle`
/// - radius `brSm` (=6)
/// - padding 좌우 12
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
      style: (style ?? PTypo.bodySm).copyWith(color: t.fgPrimary),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: PTypo.bodySm.copyWith(color: t.fgTertiary),
        filled: true,
        fillColor: t.bgSurface,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
            horizontal: PSpace.x12, vertical: isMultiLine ? 10 : 8),
        prefixIcon: prefix,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: t.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: t.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: t.borderBrand),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: t.borderSubtle),
        ),
      ),
    );
    if (isMultiLine) return field;
    return SizedBox(height: 36, child: field);
  }
}
