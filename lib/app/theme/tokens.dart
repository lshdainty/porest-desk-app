import 'package:flutter/material.dart';

import 'colors.dart';

/// POREST 의미론적 토큰 (light/dark 분기 적용된 의미 단위).
///
/// porest-desk-front 의 `--bg-canvas`, `--fg-primary` 같은 semantic 토큰을 이식한 것.
/// 모든 위젯은 raw 팔레트([PorestPalette]) 대신 이 토큰만 참조해야 다크 모드가 자동 동작한다.
///
/// 사용 예:
/// ```dart
/// final t = Theme.of(context).extension<PorestTokens>()!;
/// Container(color: t.bgCanvas, child: Text('hi', style: TextStyle(color: t.fgPrimary)));
/// ```
@immutable
class PorestTokens extends ThemeExtension<PorestTokens> {
  const PorestTokens({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgSurfaceRaised,
    required this.bgSunken,
    required this.bgMuted,
    required this.bgSectionWarm,
    required this.bgInverse,
    required this.bgBrand,
    required this.bgBrandHover,
    required this.bgBrandPress,
    required this.bgBrandSubtle,
    required this.bgBrandMuted,
    required this.bgHoverSubtle,
    required this.bgHoverStrong,
    required this.bgRowHover,
    required this.bgDisabled,
    required this.bgTrack,
    required this.fgPrimary,
    required this.fgSecondary,
    required this.fgTertiary,
    required this.fgDisabled,
    required this.fgPlaceholder,
    required this.fgOnBrand,
    required this.fgOnWarm,
    required this.fgBrand,
    required this.fgBrandStrong,
    required this.fgLink,
    required this.fgLinkHover,
    required this.fgOnDanger,
    required this.fgOnSuccess,
    required this.borderSubtle,
    required this.borderDefault,
    required this.borderStrong,
    required this.borderFocus,
    required this.borderBrand,
    required this.borderWarm,
    required this.statusSuccess,
    required this.statusSuccessSubtle,
    required this.statusSuccessFg,
    required this.statusWarning,
    required this.statusWarningSubtle,
    required this.statusWarningFg,
    required this.statusDanger,
    required this.statusDangerSubtle,
    required this.statusDangerFg,
    required this.statusInfo,
    required this.statusInfoSubtle,
    required this.statusInfoFg,
    required this.surfaceHero,
  });

  // Backgrounds
  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSurfaceRaised;
  final Color bgSunken;
  final Color bgMuted;
  final Color bgSectionWarm;
  final Color bgInverse;
  final Color bgBrand;
  final Color bgBrandHover;
  final Color bgBrandPress;
  final Color bgBrandSubtle;
  final Color bgBrandMuted;
  final Color bgHoverSubtle;
  final Color bgHoverStrong;
  final Color bgRowHover;
  final Color bgDisabled;
  final Color bgTrack;

  // Foregrounds
  final Color fgPrimary;
  final Color fgSecondary;
  final Color fgTertiary;
  final Color fgDisabled;
  final Color fgPlaceholder;
  final Color fgOnBrand;
  final Color fgOnWarm;
  final Color fgBrand;
  final Color fgBrandStrong;
  final Color fgLink;
  final Color fgLinkHover;
  final Color fgOnDanger;
  final Color fgOnSuccess;

  // Borders
  final Color borderSubtle;
  final Color borderDefault;
  final Color borderStrong;
  final Color borderFocus;
  final Color borderBrand;
  final Color borderWarm;

  // Status
  final Color statusSuccess;
  final Color statusSuccessSubtle;
  final Color statusSuccessFg;
  final Color statusWarning;
  final Color statusWarningSubtle;
  final Color statusWarningFg;
  final Color statusDanger;
  final Color statusDangerSubtle;
  final Color statusDangerFg;
  final Color statusInfo;
  final Color statusInfoSubtle;
  final Color statusInfoFg;

  // Hero
  final Color surfaceHero;

  /// Light 모드 의미론 토큰 (CSS `:root` 매핑).
  static const PorestTokens light = PorestTokens(
    bgCanvas: PorestPalette.mist100,
    bgSurface: PorestPalette.mist0,
    bgSurfaceRaised: PorestPalette.mist0,
    bgSunken: PorestPalette.mist200,
    bgMuted: PorestPalette.mist100,
    bgSectionWarm: PorestPalette.bark100,
    bgInverse: PorestPalette.mossy900,
    bgBrand: PorestPalette.mossy500,
    bgBrandHover: PorestPalette.mossy600,
    bgBrandPress: PorestPalette.mossy700,
    bgBrandSubtle: PorestPalette.mossy50,
    bgBrandMuted: PorestPalette.mossy100,
    bgHoverSubtle: PorestPalette.mist100,
    bgHoverStrong: PorestPalette.mist200,
    bgRowHover: PorestPalette.mist50,
    bgDisabled: PorestPalette.mist100,
    bgTrack: PorestPalette.mist300,
    fgPrimary: PorestPalette.mist950,
    fgSecondary: PorestPalette.mist700,
    fgTertiary: PorestPalette.mist600,
    fgDisabled: PorestPalette.mist400,
    fgPlaceholder: PorestPalette.mist500,
    fgOnBrand: PorestPalette.mist0,
    fgOnWarm: PorestPalette.bark900,
    fgBrand: PorestPalette.mossy700,
    fgBrandStrong: PorestPalette.mossy800,
    fgLink: PorestPalette.mossy700,
    fgLinkHover: PorestPalette.mossy800,
    fgOnDanger: PorestPalette.mist0,
    fgOnSuccess: PorestPalette.mist0,
    borderSubtle: PorestPalette.mist200,
    borderDefault: PorestPalette.mist300,
    borderStrong: PorestPalette.mist400,
    borderFocus: PorestPalette.mossy500,
    borderBrand: PorestPalette.mossy500,
    borderWarm: PorestPalette.bark300,
    statusSuccess: PorestPalette.mossy600,
    statusSuccessSubtle: PorestPalette.mossy50,
    statusSuccessFg: PorestPalette.mossy800,
    statusWarning: PorestPalette.sunlit500,
    statusWarningSubtle: PorestPalette.sunlit100,
    statusWarningFg: PorestPalette.sunlit700,
    statusDanger: PorestPalette.berry500,
    statusDangerSubtle: PorestPalette.berry100,
    statusDangerFg: PorestPalette.berry700,
    statusInfo: PorestPalette.sky500,
    statusInfoSubtle: PorestPalette.sky100,
    statusInfoFg: PorestPalette.sky700,
    surfaceHero: PorestPalette.mossy50,
  );

  /// Dark 모드 의미론 토큰 (CSS `.dark` 오버라이드 매핑).
  static const PorestTokens dark = PorestTokens(
    bgCanvas: PorestPalette.mossy950,
    bgSurface: PorestPalette.darkSurface,
    bgSurfaceRaised: PorestPalette.darkSurfaceRaised,
    bgSunken: PorestPalette.darkSunken,
    bgMuted: PorestPalette.darkMuted,
    bgSectionWarm: PorestPalette.darkSectionWarm,
    bgInverse: PorestPalette.mist100,
    bgBrand: PorestPalette.mossy400,
    bgBrandHover: PorestPalette.mossy300,
    bgBrandPress: PorestPalette.mossy200,
    bgBrandSubtle: Color(0x80453F1A), // oklch(0.28 0.045 110 / 0.5) 근사
    bgBrandMuted: PorestPalette.darkBrandMuted,
    bgHoverSubtle: Color(0x0AFFFFFF),
    bgHoverStrong: Color(0x14FFFFFF),
    bgRowHover: Color(0x08FFFFFF),
    bgDisabled: Color(0x0DFFFFFF),
    bgTrack: Color(0x24FFFFFF),
    fgPrimary: PorestPalette.mist100,
    fgSecondary: PorestPalette.mist400,
    fgTertiary: PorestPalette.mist500,
    fgDisabled: PorestPalette.mist700,
    fgPlaceholder: PorestPalette.mist600,
    fgOnBrand: PorestPalette.mossy950,
    fgOnWarm: PorestPalette.bark100,
    fgBrand: PorestPalette.mossy300,
    fgBrandStrong: PorestPalette.mossy200,
    fgLink: PorestPalette.mossy300,
    fgLinkHover: PorestPalette.mossy200,
    fgOnDanger: PorestPalette.mist0,
    fgOnSuccess: PorestPalette.mossy950,
    borderSubtle: Color(0x12FFFFFF),
    borderDefault: Color(0x1FFFFFFF),
    borderStrong: Color(0x33FFFFFF),
    borderFocus: PorestPalette.mossy400,
    borderBrand: PorestPalette.mossy400,
    borderWarm: Color(0x1AFFFFFF),
    statusSuccess: PorestPalette.mossy400,
    statusSuccessSubtle: Color(0x66453F1A),
    statusSuccessFg: PorestPalette.mossy200,
    statusWarning: PorestPalette.sunlit500,
    statusWarningSubtle: Color(0x59635022),
    statusWarningFg: PorestPalette.sunlit300,
    statusDanger: PorestPalette.berry500,
    statusDangerSubtle: Color(0x595A2926),
    statusDangerFg: PorestPalette.berry300,
    statusInfo: PorestPalette.sky500,
    statusInfoSubtle: Color(0x59243C5C),
    statusInfoFg: PorestPalette.sky300,
    surfaceHero: Color(0x80453F1A),
  );

  @override
  PorestTokens copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgSurfaceRaised,
    Color? bgSunken,
    Color? bgMuted,
    Color? bgSectionWarm,
    Color? bgInverse,
    Color? bgBrand,
    Color? bgBrandHover,
    Color? bgBrandPress,
    Color? bgBrandSubtle,
    Color? bgBrandMuted,
    Color? bgHoverSubtle,
    Color? bgHoverStrong,
    Color? bgRowHover,
    Color? bgDisabled,
    Color? bgTrack,
    Color? fgPrimary,
    Color? fgSecondary,
    Color? fgTertiary,
    Color? fgDisabled,
    Color? fgPlaceholder,
    Color? fgOnBrand,
    Color? fgOnWarm,
    Color? fgBrand,
    Color? fgBrandStrong,
    Color? fgLink,
    Color? fgLinkHover,
    Color? fgOnDanger,
    Color? fgOnSuccess,
    Color? borderSubtle,
    Color? borderDefault,
    Color? borderStrong,
    Color? borderFocus,
    Color? borderBrand,
    Color? borderWarm,
    Color? statusSuccess,
    Color? statusSuccessSubtle,
    Color? statusSuccessFg,
    Color? statusWarning,
    Color? statusWarningSubtle,
    Color? statusWarningFg,
    Color? statusDanger,
    Color? statusDangerSubtle,
    Color? statusDangerFg,
    Color? statusInfo,
    Color? statusInfoSubtle,
    Color? statusInfoFg,
    Color? surfaceHero,
  }) {
    return PorestTokens(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSurfaceRaised: bgSurfaceRaised ?? this.bgSurfaceRaised,
      bgSunken: bgSunken ?? this.bgSunken,
      bgMuted: bgMuted ?? this.bgMuted,
      bgSectionWarm: bgSectionWarm ?? this.bgSectionWarm,
      bgInverse: bgInverse ?? this.bgInverse,
      bgBrand: bgBrand ?? this.bgBrand,
      bgBrandHover: bgBrandHover ?? this.bgBrandHover,
      bgBrandPress: bgBrandPress ?? this.bgBrandPress,
      bgBrandSubtle: bgBrandSubtle ?? this.bgBrandSubtle,
      bgBrandMuted: bgBrandMuted ?? this.bgBrandMuted,
      bgHoverSubtle: bgHoverSubtle ?? this.bgHoverSubtle,
      bgHoverStrong: bgHoverStrong ?? this.bgHoverStrong,
      bgRowHover: bgRowHover ?? this.bgRowHover,
      bgDisabled: bgDisabled ?? this.bgDisabled,
      bgTrack: bgTrack ?? this.bgTrack,
      fgPrimary: fgPrimary ?? this.fgPrimary,
      fgSecondary: fgSecondary ?? this.fgSecondary,
      fgTertiary: fgTertiary ?? this.fgTertiary,
      fgDisabled: fgDisabled ?? this.fgDisabled,
      fgPlaceholder: fgPlaceholder ?? this.fgPlaceholder,
      fgOnBrand: fgOnBrand ?? this.fgOnBrand,
      fgOnWarm: fgOnWarm ?? this.fgOnWarm,
      fgBrand: fgBrand ?? this.fgBrand,
      fgBrandStrong: fgBrandStrong ?? this.fgBrandStrong,
      fgLink: fgLink ?? this.fgLink,
      fgLinkHover: fgLinkHover ?? this.fgLinkHover,
      fgOnDanger: fgOnDanger ?? this.fgOnDanger,
      fgOnSuccess: fgOnSuccess ?? this.fgOnSuccess,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      borderBrand: borderBrand ?? this.borderBrand,
      borderWarm: borderWarm ?? this.borderWarm,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusSuccessSubtle: statusSuccessSubtle ?? this.statusSuccessSubtle,
      statusSuccessFg: statusSuccessFg ?? this.statusSuccessFg,
      statusWarning: statusWarning ?? this.statusWarning,
      statusWarningSubtle: statusWarningSubtle ?? this.statusWarningSubtle,
      statusWarningFg: statusWarningFg ?? this.statusWarningFg,
      statusDanger: statusDanger ?? this.statusDanger,
      statusDangerSubtle: statusDangerSubtle ?? this.statusDangerSubtle,
      statusDangerFg: statusDangerFg ?? this.statusDangerFg,
      statusInfo: statusInfo ?? this.statusInfo,
      statusInfoSubtle: statusInfoSubtle ?? this.statusInfoSubtle,
      statusInfoFg: statusInfoFg ?? this.statusInfoFg,
      surfaceHero: surfaceHero ?? this.surfaceHero,
    );
  }

  @override
  PorestTokens lerp(ThemeExtension<PorestTokens>? other, double t) {
    if (other is! PorestTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return PorestTokens(
      bgCanvas: l(bgCanvas, other.bgCanvas),
      bgSurface: l(bgSurface, other.bgSurface),
      bgSurfaceRaised: l(bgSurfaceRaised, other.bgSurfaceRaised),
      bgSunken: l(bgSunken, other.bgSunken),
      bgMuted: l(bgMuted, other.bgMuted),
      bgSectionWarm: l(bgSectionWarm, other.bgSectionWarm),
      bgInverse: l(bgInverse, other.bgInverse),
      bgBrand: l(bgBrand, other.bgBrand),
      bgBrandHover: l(bgBrandHover, other.bgBrandHover),
      bgBrandPress: l(bgBrandPress, other.bgBrandPress),
      bgBrandSubtle: l(bgBrandSubtle, other.bgBrandSubtle),
      bgBrandMuted: l(bgBrandMuted, other.bgBrandMuted),
      bgHoverSubtle: l(bgHoverSubtle, other.bgHoverSubtle),
      bgHoverStrong: l(bgHoverStrong, other.bgHoverStrong),
      bgRowHover: l(bgRowHover, other.bgRowHover),
      bgDisabled: l(bgDisabled, other.bgDisabled),
      bgTrack: l(bgTrack, other.bgTrack),
      fgPrimary: l(fgPrimary, other.fgPrimary),
      fgSecondary: l(fgSecondary, other.fgSecondary),
      fgTertiary: l(fgTertiary, other.fgTertiary),
      fgDisabled: l(fgDisabled, other.fgDisabled),
      fgPlaceholder: l(fgPlaceholder, other.fgPlaceholder),
      fgOnBrand: l(fgOnBrand, other.fgOnBrand),
      fgOnWarm: l(fgOnWarm, other.fgOnWarm),
      fgBrand: l(fgBrand, other.fgBrand),
      fgBrandStrong: l(fgBrandStrong, other.fgBrandStrong),
      fgLink: l(fgLink, other.fgLink),
      fgLinkHover: l(fgLinkHover, other.fgLinkHover),
      fgOnDanger: l(fgOnDanger, other.fgOnDanger),
      fgOnSuccess: l(fgOnSuccess, other.fgOnSuccess),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      borderDefault: l(borderDefault, other.borderDefault),
      borderStrong: l(borderStrong, other.borderStrong),
      borderFocus: l(borderFocus, other.borderFocus),
      borderBrand: l(borderBrand, other.borderBrand),
      borderWarm: l(borderWarm, other.borderWarm),
      statusSuccess: l(statusSuccess, other.statusSuccess),
      statusSuccessSubtle: l(statusSuccessSubtle, other.statusSuccessSubtle),
      statusSuccessFg: l(statusSuccessFg, other.statusSuccessFg),
      statusWarning: l(statusWarning, other.statusWarning),
      statusWarningSubtle: l(statusWarningSubtle, other.statusWarningSubtle),
      statusWarningFg: l(statusWarningFg, other.statusWarningFg),
      statusDanger: l(statusDanger, other.statusDanger),
      statusDangerSubtle: l(statusDangerSubtle, other.statusDangerSubtle),
      statusDangerFg: l(statusDangerFg, other.statusDangerFg),
      statusInfo: l(statusInfo, other.statusInfo),
      statusInfoSubtle: l(statusInfoSubtle, other.statusInfoSubtle),
      statusInfoFg: l(statusInfoFg, other.statusInfoFg),
      surfaceHero: l(surfaceHero, other.surfaceHero),
    );
  }
}

/// 컨텍스트에서 토큰 꺼내는 짧은 helper.
extension PorestTokensX on BuildContext {
  PorestTokens get tokens => Theme.of(this).extension<PorestTokens>()!;
}
