import 'package:flutter/material.dart';

import 'colors.dart';
import 'radius.dart';
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
        seed: PorestPalette.mossy500,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        tokens: PorestTokens.dark,
        seed: PorestPalette.mossy400,
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
        shape: RoundedRectangleBorder(borderRadius: PRadius.brXl),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.bgMuted,
        hintStyle: PTypo.body.copyWith(color: tokens.fgPlaceholder),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: PRadius.brMd,
          borderSide: BorderSide(color: tokens.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PRadius.brMd,
          borderSide: BorderSide(color: tokens.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PRadius.brMd,
          borderSide: BorderSide(color: tokens.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: PRadius.brMd,
          borderSide: BorderSide(color: tokens.statusDanger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.bgBrand,
          foregroundColor: tokens.fgOnBrand,
          shape: RoundedRectangleBorder(borderRadius: PRadius.brMd),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: PTypo.bodySm.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.fgBrand,
          shape: RoundedRectangleBorder(borderRadius: PRadius.brMd),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: PTypo.bodySm.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.fgPrimary,
          side: BorderSide(color: tokens.borderDefault),
          shape: RoundedRectangleBorder(borderRadius: PRadius.brMd),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: PTypo.bodySm.copyWith(fontWeight: FontWeight.w500),
        ),
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
