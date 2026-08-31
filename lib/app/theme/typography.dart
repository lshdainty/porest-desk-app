import 'package:flutter/painting.dart';

/// 폰트 굵기 토큰 — 웹 `--fw-*` 와 1:1 매핑.
abstract final class PFontWeight {
  static const FontWeight regular = FontWeight.w400; // --fw-regular
  static const FontWeight medium = FontWeight.w500; // --fw-medium
  static const FontWeight semi = FontWeight.w600; // --fw-semi
  static const FontWeight bold = FontWeight.w700; // --fw-bold
  // heavy (800) 제거됨 — SoT 최대 700 (bold). 옛 위젯 PFontWeight.heavy 호출
  // 26 places 모두 PFontWeight.bold 로 마이그 (display heading 가벼움 800→700).
}

/// 폰트 크기 토큰 — 웹 `--fs-*` 와 1:1 매핑 (px).
abstract final class PFontSize {
  static const double micro = 11; // --fs-micro
  static const double caption = 12; // --fs-caption
  static const double bodySm = 13; // --fs-body-sm
  static const double body = 14; // --fs-body
  static const double bodyMd = 15; // --fs-body-md (spec body-md)
  static const double bodyLg = 16; // --fs-body-lg
  static const double titleSm = 16; // spec title-sm (== body-lg)
  static const double h4 = 18; // SoT title-md
  static const double titleMd = 18; // SoT title-md
  static const double h3 = 20; // --fs-h3 (== title-lg)
  static const double h2 = 24; // --fs-h2 (== display-sm)
  static const double h1 = 30; // --fs-h1
  static const double displayMd = 32; // SoT display-md
  static const double displayLg = 40; // SoT display-lg
  static const double displayXl = 56; // SoT display-xl
}

/// 라인 하이트 토큰 — 웹 `--lh-*` 와 1:1 매핑 (Flutter `height` 속성).
abstract final class PLineHeight {
  static const double tight = 1.15; // --lh-tight
  static const double snug = 1.3; // --lh-snug
  static const double normal = 1.5; // --lh-normal
  static const double loose = 1.7; // --lh-loose
}

/// 자간 토큰 — 웹 `--tracking-*` 의 em ratio (절대 px 환산 헬퍼).
///
/// 웹은 em(상대값), Flutter `letterSpacing` 은 px(절대값). 사용 시:
/// ```dart
/// Text(s, style: TextStyle(
///   fontSize: PFontSize.h4,
///   letterSpacing: PTracking.tight(PFontSize.h4),
/// ))
/// ```
/// 또는 prefab [PTypo] 스타일이 이미 letterSpacing 을 포함.
abstract final class PTracking {
  static const double tightEm = -0.022;
  static const double snugEm = -0.012;
  static const double wideEm = 0.04;

  static double tight(double fontSize) => fontSize * tightEm;
  static double snug(double fontSize) => fontSize * snugEm;
  static double normal(double _) => 0;
  static double wide(double fontSize) => fontSize * wideEm;
}

/// porest-desk-front 의 타이포 토큰 1:1 매핑.
///
/// 폰트 패밀리는 [pubspec.yaml] 에 등록된 `Pretendard` 와 `JetBrainsMono`.
/// 색상은 [`PorestTokens`] 가 적용 시점에 [`TextStyle.copyWith`] 로 덧씌운다.
abstract final class PTypo {
  static const String sans = 'Pretendard';
  static const String mono = 'JetBrainsMono';

  // Display — porest-design SoT (DESIGN.desk.md L92-109) 정합
  static const TextStyle displayXl = TextStyle(
    fontFamily: sans,
    fontSize: 56,
    height: 1.05,
    letterSpacing: -1.12,
    fontWeight: FontWeight.w700, // SoT 정합
  );
  static const TextStyle displayLg = TextStyle(
    fontFamily: sans,
    fontSize: 40,
    height: 1.1,
    letterSpacing: -0.4,
    fontWeight: FontWeight.w700, // SoT 정합
  );
  static const TextStyle displayMd = TextStyle(
    fontFamily: sans,
    fontSize: 32,
    height: 1.2,
    letterSpacing: -0.32,
    fontWeight: FontWeight.w700, // SoT 정합
  );

  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: sans,
    fontSize: 30,
    height: 1.15,
    letterSpacing: -0.66,
    fontWeight: FontWeight.w700, // bold, lh-tight (spec 일치)
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: sans,
    fontSize: 24,
    height: 1.3,
    letterSpacing: -0.288,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: sans,
    fontSize: 20,
    height: 1.4,
    letterSpacing: -0.24,
    fontWeight: FontWeight.w600, // SoT title-lg lh 1.4
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: sans,
    fontSize: 18,
    height: 1.4,
    letterSpacing: -0.216,
    fontWeight: FontWeight.w600, // SoT title-md 18/1.4
  );

  // Body — SoT body-lg lh 1.6
  static const TextStyle bodyLg = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    height: 1.6,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodySm = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );
  // Label — SoT label-md 14/500/1.4 (DESIGN.desk.md). 폼 라벨(control 위)은
  // label.md 컴포넌트 spec에 따라 leading-none(height 1.0)으로 override
  // (PSectionLabel.header) — control 위에 붙을 때 vertical rhythm 유지.
  static const TextStyle labelMd = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle micro = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    height: 1.5,
    letterSpacing: 0.44,
    fontWeight: FontWeight.w500,
  );

  // 금액·숫자 — 라벨과 동일 sans(Pretendard) + tabular figures(정렬용). 웹(.num: sans+tnum) 정합.
  static const TextStyle moneyLg = TextStyle(
    fontFamily: sans,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle money = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
