import 'package:flutter/material.dart';

import 'colors.dart';
import 'radius.dart';
import 'spacing.dart';
import 'tokens.dart';
import 'typography.dart';

/// POREST Desk 모바일 앱의 light/dark ThemeData 빌더.
///
/// Material 3 베이스 위에 [PorestTokens] 를 [ThemeExtension] 으로 얹어 두 채널 사용:
/// - 표준 Material 위젯 (Buttons, AppBar 등) → ColorScheme + Material 톤
/// - POREST 커스텀 위젯 → `context.tokens.bgCanvas` 류
abstract final class PorestTheme {
  static ThemeData light() => _build(
        brightness: Brightness.light,
        tokens: PorestTokens.light,
        seed: PorestPalette.cobalt500,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        tokens: PorestTokens.dark,
        seed: PorestPalette.cobalt400,
      );

  static ThemeData _build({
    required Brightness brightness,
    required PorestTokens tokens,
    required Color seed,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      primary: tokens.bgBrand,
      onPrimary: tokens.fgOnBrand,
      surface: tokens.bgSurface,
      onSurface: tokens.fgPrimary,
      surfaceContainer: tokens.bgMuted,
      surfaceContainerHigh: tokens.bgSurfaceRaised,
      surfaceContainerLow: tokens.bgCanvas,
      surfaceContainerLowest: tokens.bgCanvas,
      surfaceContainerHighest: tokens.bgSurfaceRaised,
      error: tokens.statusDanger,
      onError: tokens.fgOnDanger,
      outline: tokens.borderDefault,
      outlineVariant: tokens.borderSubtle,
    );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.bgCanvas,
      canvasColor: tokens.bgSurface,
      dividerColor: tokens.borderSubtle,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      extensions: [tokens],
      textTheme: _textTheme(tokens.fgPrimary, tokens.fgSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bgSurface,
        foregroundColor: tokens.fgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: PTypo.h4.copyWith(color: tokens.fgPrimary),
      ),
      cardTheme: CardThemeData(
        color: tokens.bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: PRadius.brLg),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(PRadius.xl2)),
        ),
        modalBackgroundColor: tokens.bgSurface,
        modalBarrierColor: Colors.black54,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.bgSurface,
        surfaceTintColor: Colors.transparent,
        // specs/components/dialog.md md(default): radius-xl(20)
        shape: RoundedRectangleBorder(borderRadius: PRadius.brXl2),
      ),
      // specs/components/input.md spec:
      // height 40 (minimumSize 외부에서) / radius-sm(4) / padding sm·md (8·12)
      // bg surface-input / border-default / border-focus(1.5)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.bgMuted,
        hintStyle: PTypo.bodyLg.copyWith(color: tokens.fgPlaceholder),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: PSpace.md, vertical: PSpace.sm),
        border: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: tokens.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: tokens.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: tokens.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: PRadius.brSm,
          borderSide: BorderSide(color: tokens.statusDanger),
        ),
      ),
      // specs/components/button.md spec — md(default):
      // h=40 / padding y·x (8·12) / font body-md(15) weight-medium(500) / radius-sm(4)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // 채운 버튼은 solid 고정 — 다크에서도 primary (bgBrand 는 light 라 부적합)
          backgroundColor: tokens.bgBrandSolid,
          foregroundColor: tokens.fgOnBrand,
          disabledBackgroundColor: tokens.bgDisabled,
          disabledForegroundColor: tokens.fgDisabled,
          shape: RoundedRectangleBorder(borderRadius: PRadius.brSm),
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.md, vertical: PSpace.sm),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontFamily: PTypo.sans,
            fontSize: PFontSize.bodyMd,
            fontWeight: PFontWeight.medium,
            height: 1.0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.fgBrand,
          shape: RoundedRectangleBorder(borderRadius: PRadius.brSm),
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.md, vertical: PSpace.sm),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontFamily: PTypo.sans,
            fontSize: PFontSize.bodyMd,
            fontWeight: PFontWeight.medium,
            height: 1.0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.fgPrimary,
          side: BorderSide(color: tokens.borderDefault),
          shape: RoundedRectangleBorder(borderRadius: PRadius.brSm),
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.md, vertical: PSpace.sm),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontFamily: PTypo.sans,
            fontSize: PFontSize.bodyMd,
            fontWeight: PFontWeight.medium,
            height: 1.0,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.fgBrand,
        circularTrackColor: tokens.bgBrandMuted,
        linearTrackColor: tokens.bgBrandMuted,
        strokeWidth: 2,
      ),
      // specs/components/checkbox.md spec — md(default):
      // 18×18 / border-strong 1px / radius-sm / checked = bgBrand fill + fgOnBrand check
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return tokens.bgDisabled;
          if (states.contains(WidgetState.selected)) return tokens.bgBrand;
          return tokens.bgSurface;
        }),
        checkColor: WidgetStateProperty.all(tokens.fgOnBrand),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return BorderSide.none;
          return BorderSide(color: tokens.borderStrong, width: 1);
        }),
        shape: RoundedRectangleBorder(borderRadius: PRadius.brSm),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      // specs/components/switch.md — track + thumb, brand 채움
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return tokens.fgDisabled;
          return tokens.fgOnBrand;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return tokens.bgDisabled;
          if (states.contains(WidgetState.selected)) return tokens.bgBrand;
          return tokens.bgTrack;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      // Radio (사용처 적지만 일관 스타일)
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return tokens.fgDisabled;
          if (states.contains(WidgetState.selected)) return tokens.bgBrand;
          return tokens.borderStrong;
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      iconTheme: IconThemeData(color: tokens.fgSecondary, size: 20),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.bgSurface,
        indicatorColor: tokens.bgBrandSubtle,
        labelTextStyle: WidgetStatePropertyAll(
          PTypo.micro.copyWith(color: tokens.fgSecondary),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: tokens.fgSecondary, size: 22),
        ),
        height: 72,
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    TextStyle p(TextStyle s) => s.copyWith(color: primary);
    TextStyle s(TextStyle st) => st.copyWith(color: secondary);
    return TextTheme(
      displayLarge: p(PTypo.displayLg),
      displayMedium: p(PTypo.displayMd),
      displaySmall: p(PTypo.h1),
      headlineLarge: p(PTypo.h1),
      headlineMedium: p(PTypo.h2),
      headlineSmall: p(PTypo.h3),
      titleLarge: p(PTypo.h3),
      titleMedium: p(PTypo.h4),
      titleSmall: p(PTypo.bodyLg.copyWith(fontWeight: FontWeight.w600)),
      bodyLarge: p(PTypo.bodyLg),
      bodyMedium: p(PTypo.body),
      bodySmall: s(PTypo.bodySm),
      labelLarge: p(PTypo.body.copyWith(fontWeight: FontWeight.w600)),
      labelMedium: s(PTypo.caption),
      labelSmall: s(PTypo.micro),
    );
  }
}
