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
    this.secret = false,
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

  /// 값이 자격증명이라 **플랫폼이 기억하면 안 되는** 입력칸.
  ///
  /// [obscureText] 는 화면만 가린다. Flutter 의 `TextField` 는 `obscureText` 로
  /// `smartDashesType`·`smartQuotesType` 만 끄고(text_field.dart 생성자 initializer),
  /// `autocorrect`·`enableSuggestions`·`enableIMEPersonalizedLearning` 은
  /// 그대로 기본값 true 로 흘려보낸다 — 즉 **가려 놓고도 키보드 사전에 남는다.**
  /// 안드로이드에서는 `enableIMEPersonalizedLearning` 이 `IME_FLAG_NO_PERSONALIZED_LEARNING`
  /// 으로 내려가므로 이 셋을 직접 꺼야 학습이 막힌다.
  ///
  /// 보기/숨기기 토글이 붙은 칸은 [obscureText] 가 사용자 조작으로 false 가 되므로
  /// 마스킹과 별도 축이어야 한다 — 그래서 [obscureText] 에 묶지 않고 따로 둔다.
  /// [obscureText] 가 true 면 이 값과 무관하게 자격증명으로 취급한다.
  final bool secret;
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
    final restSide = search
        ? BorderSide.none
        : BorderSide(color: t.borderDefault);
    final baseFont = search ? PTypo.bodySm : PTypo.bodyLg;
    final isMultiLine = (maxLines ?? 1) > 1;
    // 토글로 잠깐 벗겨 봐도 자격증명인 사실은 변하지 않는다.
    final isSecret = secret || obscureText;
    final formatters =
        inputFormatters ??
        (numbersOnly ? [FilteringTextInputFormatter.digitsOnly] : null);
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      enabled: enabled,
      keyboardType: keyboardType ?? (numbersOnly ? TextInputType.number : null),
      inputFormatters: formatters,
      obscureText: obscureText,
      // 자격증명일 때만 끈다. 아닐 때 null 로 두는 건 기존 동작 보존 —
      // `autocorrect` 는 nullable 이고 Flutter 가 autofillHints 로 추론한다.
      // 붙여넣기는 그대로 둔다(선택·클립보드 경로를 건드리지 않는다) —
      // API 키는 손으로 칠 수 있는 길이가 아니다.
      autocorrect: isSecret ? false : null,
      enableSuggestions: !isSecret,
      enableIMEPersonalizedLearning: !isSecret,
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
          horizontal: PSpace.md,
          vertical: PSpace.sm,
        ),
        prefixIcon: prefix,
        suffixIcon: suffix,
        prefixText: prefixText,
        suffixText: suffixText,
        suffixStyle: PTypo.bodySm.copyWith(color: t.fgTertiary),
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: radius, borderSide: restSide),
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
