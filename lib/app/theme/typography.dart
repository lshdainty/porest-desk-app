import 'package:flutter/painting.dart';

/// 폰트 굵기 토큰 — 웹 `--fw-*` 와 1:1 매핑.
///
/// 사용:
/// ```dart
/// Text('hello', style: TextStyle(fontWeight: PFontWeight.bold));
/// PTypo.body.copyWith(fontWeight: PFontWeight.semi);
/// ```
abstract final class PFontWeight {
  static const FontWeight regular = FontWeight.w400; // --fw-regular
  static const FontWeight medium = FontWeight.w500;  // --fw-medium
  static const FontWeight semi = FontWeight.w600;    // --fw-semi
  static const FontWeight bold = FontWeight.w700;    // --fw-bold
  static const FontWeight heavy = FontWeight.w800;   // --fw-heavy
}

/// porest-desk-front 의 타이포 토큰 1:1 매핑.
///
/// 폰트 패밀리는 [pubspec.yaml] 에 등록된 `Pretendard` 와 `JetBrainsMono`.
/// 색상은 [`PorestTokens`] 가 적용 시점에 [`TextStyle.copyWith`] 로 덧씌운다.
abstract final class PTypo {
  static const String sans = 'Pretendard';
  static const String mono = 'JetBrainsMono';

  // Display
  static const TextStyle displayXl = TextStyle(
    fontFamily: sans, fontSize: 56, height: 1.15, letterSpacing: -1.232,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle displayLg = TextStyle(
    fontFamily: sans, fontSize: 44, height: 1.15, letterSpacing: -0.968,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle displayMd = TextStyle(
    fontFamily: sans, fontSize: 36, height: 1.15, letterSpacing: -0.792,
    fontWeight: FontWeight.w700,
  );

  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: sans, fontSize: 30, height: 1.3, letterSpacing: -0.66,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: sans, fontSize: 24, height: 1.3, letterSpacing: -0.288,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: sans, fontSize: 20, height: 1.3, letterSpacing: -0.24,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: sans, fontSize: 17, height: 1.3, letterSpacing: -0.204,
    fontWeight: FontWeight.w600,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontFamily: sans, fontSize: 16, height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle body = TextStyle(
    fontFamily: sans, fontSize: 14, height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodySm = TextStyle(
    fontFamily: sans, fontSize: 13, height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: sans, fontSize: 12, height: 1.5,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle micro = TextStyle(
    fontFamily: sans, fontSize: 11, height: 1.5, letterSpacing: 0.44,
    fontWeight: FontWeight.w500,
  );

  // Mono — 금액·숫자
  static const TextStyle moneyLg = TextStyle(
    fontFamily: mono, fontSize: 22, height: 1.2,
    fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle money = TextStyle(
    fontFamily: mono, fontSize: 14, height: 1.4,
    fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()],
  );
}
