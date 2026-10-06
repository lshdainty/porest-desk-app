import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/colors.dart';
import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';

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
    required this.bgInverse,
    required this.bgBrand,
    required this.bgBrandHover,
    required this.bgBrandPress,
    required this.bgBrandSubtle,
    required this.bgBrandMuted,
    required this.bgBrandSolid,
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
    required this.fgExpense,
    required this.fgIncome,
    required this.fgTransfer,
    required this.bgExpenseSubtle,
    required this.bgIncomeSubtle,
    required this.bgTransferSubtle,
    required this.bgBrandTint,
    required this.bgBrandTintStrong,
    required this.bgTableHead,
    required this.borderBrandSoft,
    required this.borderBrandMid,
    required this.statusSuccessBorder,
    required this.statusWarningBorder,
    required this.statusDangerBorder,
    required this.statusDangerPress,
    required this.statusInfoBorder,
    required this.surfaceHero,
    required this.bgHeroGradientStart,
    required this.bgHeroGradientEnd,
    required this.fgOnHeroChgUp,
    required this.fgOnHeroChgDown,
    required this.fgOnHeroSpot,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.shadowXl,
  });

  // Backgrounds
  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSurfaceRaised;
  final Color bgSunken;
  final Color bgMuted;
  final Color bgInverse;
  final Color bgBrand;
  final Color bgBrandHover;
  final Color bgBrandPress;
  final Color bgBrandSubtle;
  final Color bgBrandMuted;

  /// 채운 브랜드 버튼용 solid fill — 웹 `--bg-brand` 정합으로 light/dark 모두 primary 고정.
  /// (bgBrand 는 다크에서 primary-light 로 밝아져 흰 글씨 채움 버튼엔 부적합 — 버튼은 이 토큰 사용.)
  final Color bgBrandSolid;
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

  // Tx semantic — 거래 종류별 색
  // 지출=danger 톤 / 수입=brand 톤 / 이체=info 톤
  final Color fgExpense;
  final Color fgIncome;
  final Color fgTransfer;
  final Color bgExpenseSubtle;
  final Color bgIncomeSubtle;
  final Color bgTransferSubtle;

  // Interaction tints — brand/warm 변형
  final Color bgBrandTint; // brand 약한 톤
  final Color bgBrandTintStrong; // brand 진한 톤
  final Color bgTableHead; // 테이블 헤더 행 배경

  // Border 변형
  final Color borderBrandSoft; // brand 보더 약한 톤
  final Color borderBrandMid; // brand 보더 중간 톤

  // Status 변형
  final Color statusSuccessBorder;
  final Color statusWarningBorder;
  final Color statusDangerBorder;
  final Color statusDangerPress;
  final Color statusInfoBorder;

  // Hero — "always-on-dark" balance card.
  // 그라데이션은 light/dark 모드 무관하게 깊은 cobalt 톤 유지(hero 자체가 어두운
  // 배경). fg* 페어는 그 위에 올라가는 chg/spot 색.
  final Color surfaceHero;
  final Color bgHeroGradientStart;
  final Color bgHeroGradientEnd;
  final Color fgOnHeroChgUp;
  final Color fgOnHeroChgDown;
  final Color fgOnHeroSpot;

  // Elevation — theme-aware. 소비처는 PShadow.* 직접 참조 대신 이 게터 사용.
  // (PShadow.sm 직접 사용 시 다크에서도 라이트 그림자(5%)가 적용돼 거의 안 보임 —
  //  웹은 `.dark` 에서 --shadow-sm → --shadow-sm-dark 자동 swap.)
  // light: 두 레이어 cool-neutral / dark: 순흑 drop + inset 화이트 하이라이트.
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;
  final List<BoxShadow> shadowXl;

  /// 역할 색에서 옛 이름을 만든다 — 라이트 · 다크가 같은 식이다.
  ///
  /// 옛 이름은 porest-design 역할 색([PColors] · [PShadows], `porest_tokens.g.dart`)의 값을
  /// 따른다. 짝은 DESIGN.md v102 표의 "Desk 웹 이름" 칸이고, 웹 `index.css` 가 같은 짝으로
  /// 옛 로컬 이름을 잇는다 — 두 제품이 같은 값을 쓴다(앱 적용 5A, 2026-10-06).
  /// 역할 색에 짝이 없는 이름(호버 오버레이 · 틴트 · 히어로)만 호출하는 쪽이 값을 넘긴다.
  ///
  /// 새 코드는 이 이름 말고 `context.colors.fgNeutral` 처럼 역할 이름을 쓴다. 화면을 옮기면 걷는다.
  factory PorestTokens._fromRoles(
    PColors c,
    PShadows s, {
    required Color bgHoverSubtle,
    required Color bgHoverStrong,
    required Color bgBrandTint,
    required Color bgBrandTintStrong,
    required Color borderBrandMid,
    required Color surfaceHero,
    required Color bgHeroGradientStart,
    required Color bgHeroGradientEnd,
    required Color fgOnHeroChgUp,
    required Color fgOnHeroChgDown,
    required Color fgOnHeroSpot,
  }) => PorestTokens(
    bgCanvas: c.bgLayerBasement,
    bgSurface: c.bgLayerDefault,
    bgSurfaceRaised: c.bgLayerFloating,
    bgSunken: c.bgNeutralWeak,
    bgMuted: c.bgNeutralWeak,
    bgInverse: c.bgNeutralInverted,
    // 앱의 bgBrand 는 강조색이다(새로고침 · 진행 표시 · 차트 선 · 아이콘) — 다크에서 밝은
    // primary-light 였다. DESIGN 에서 primary · primary-light 는 fg-brand 의 별칭이라 그 값을
    // 따른다. 흰 글자를 얹는 채움은 bgBrandSolid 다(웹 --bg-brand 는 채움이라 bg-brand-solid).
    bgBrand: c.fgBrand,
    bgBrandHover: c.bgBrandSolidPressed,
    bgBrandPress: c.bgBrandSolidPressed,
    bgBrandSubtle: c.bgBrandWeak,
    bgBrandMuted: c.bgBrandWeakPressed,
    bgBrandSolid: c.bgBrandSolid,
    bgHoverSubtle: bgHoverSubtle,
    bgHoverStrong: bgHoverStrong,
    bgRowHover: c.bgLayerDefaultPressed,
    bgDisabled: c.bgDisabled,
    // progress.md track = surface-input(웹 .budget-bar 의 --bg-sunken) — surface-input 은
    // bg-neutral-weak 의 별칭이다.
    bgTrack: c.bgNeutralWeak,
    fgPrimary: c.fgNeutral,
    fgSecondary: c.fgNeutralMuted,
    fgTertiary: c.fgNeutralSubtle,
    fgDisabled: c.fgDisabled,
    fgPlaceholder: c.fgPlaceholder,
    fgOnBrand: c.staticWhite,
    fgBrand: c.fgBrand,
    fgBrandStrong: c.fgBrandContrast,
    fgLink: c.fgBrand,
    fgLinkHover: c.fgBrand,
    fgOnDanger: c.staticWhite,
    fgOnSuccess: c.staticWhite,
    borderSubtle: c.strokeNeutralSubtle,
    borderDefault: c.strokeNeutralWeak,
    borderStrong: c.strokeNeutralSolid,
    borderFocus: c.strokeFocusRing,
    borderBrand: c.strokeBrandSolid,
    // status* 는 채움(흰 글자를 얹는 자리), status*Fg 는 글자 · 아이콘, status*Border 는 선이다.
    statusSuccess: c.bgPositiveSolid,
    statusSuccessSubtle: c.bgPositiveWeak,
    statusSuccessFg: c.fgPositive,
    statusWarning: c.bgWarningSolid,
    statusWarningSubtle: c.bgWarningWeak,
    statusWarningFg: c.fgWarning,
    statusDanger: c.bgCriticalSolid,
    statusDangerSubtle: c.bgCriticalWeak,
    statusDangerFg: c.fgCritical,
    statusInfo: c.bgInformativeSolid,
    statusInfoSubtle: c.bgInformativeWeak,
    statusInfoFg: c.fgInformative,
    // Tx semantic — 지출=critical / 수입=brand / 이체=informative(웹 fg-expense · fg-income · fg-transfer)
    fgExpense: c.fgCritical,
    fgIncome: c.fgBrand,
    fgTransfer: c.fgInformative,
    bgExpenseSubtle: c.bgCriticalWeak,
    bgIncomeSubtle: c.bgBrandWeak,
    bgTransferSubtle: c.bgInformativeWeak,
    bgBrandTint: bgBrandTint,
    bgBrandTintStrong: bgBrandTintStrong,
    bgTableHead: c.bgLayerBasement,
    borderBrandSoft: c.strokeBrandWeak,
    borderBrandMid: borderBrandMid,
    statusSuccessBorder: c.strokePositiveSolid,
    statusWarningBorder: c.strokeWarningSolid,
    statusDangerBorder: c.strokeCriticalSolid,
    statusDangerPress: c.bgCriticalSolidPressed,
    statusInfoBorder: c.strokeInformativeSolid,
    surfaceHero: surfaceHero,
    bgHeroGradientStart: bgHeroGradientStart,
    bgHeroGradientEnd: bgHeroGradientEnd,
    fgOnHeroChgUp: fgOnHeroChgUp,
    fgOnHeroChgDown: fgOnHeroChgDown,
    fgOnHeroSpot: fgOnHeroSpot,
    // 옛 shadow-sm · md · lg · xl 은 s1 ~ s4 의 별칭이다(DESIGN.md v104).
    shadowSm: s.s1,
    shadowMd: s.s2,
    shadowLg: s.s3,
    shadowXl: s.s4,
  );

  /// Light 모드 의미론 토큰 — 역할 색([PColors.light])에서 만든다.
  static final PorestTokens light = PorestTokens._fromRoles(
    PColors.light,
    PShadows.light,
    bgHoverSubtle: PorestPalette.slate50,
    bgHoverStrong: PorestPalette.slate100,
    // 디자인 p-card--brand 라이트(mossy-50) — alphaBlend 시 그대로
    bgBrandTint: const Color(0xFFEAF2FB),
    bgBrandTintStrong: PorestPalette.cobalt100,
    borderBrandMid: PorestPalette.cobalt300,
    surfaceHero: PorestPalette.cobalt50,
    // desk-front .balance-hero: linear-gradient(135deg, bg-brand 0%, color-mix(srgb, bg-brand 60%, #000) 100%)
    // bg-brand = bg-brand-solid(#0147AD), end ≈ #012B68 (60% × bg-brand on black)
    bgHeroGradientStart: PColors.light.bgBrandSolid,
    bgHeroGradientEnd: const Color(0xFF012B68),
    fgOnHeroChgUp: PorestPalette.heroChgUp,
    fgOnHeroChgDown: PorestPalette.heroChgDown,
    // desk-front .balance-hero::after: radial gradient(fg-on-brand 22%, transparent 70%) — 흰색 광원
    fgOnHeroSpot: PorestPalette.slate0,
  );

  /// Dark 모드 의미론 토큰 — 역할 색([PColors.dark])에서 만든다.
  static final PorestTokens dark = PorestTokens._fromRoles(
    PColors.dark,
    PShadows.dark,
    bgHoverSubtle: const Color(0x0AFFFFFF),
    bgHoverStrong: const Color(0x14FFFFFF),
    // cobalt400 @12% — canvas(#1A1F2E) 위 합성 시 #222E44 (디자인 정합)
    bgBrandTint: const Color(0x1F5FA0E5),
    bgBrandTintStrong: const Color(0x385FA0E5), // cobalt400 @22%
    borderBrandMid: const Color(0x8097C2EE), // cobalt300 @ 50%
    surfaceHero: const Color(0x80001A42), // cobalt900 @ 50%
    // 웹 .dark .balance-hero: primary-light → 브랜드 채움 그라디언트. 어두운 페이지에서 카드를
    // 밝게 도드라지게 한다. primary-light 는 fg-brand(다크)의 별칭이고, 끝은 채움 역할이다.
    bgHeroGradientStart: PColors.dark.fgBrand,
    bgHeroGradientEnd: PColors.dark.bgBrandSolid,
    // 다크 = 더 밝은 코발트 그라데이션 → 50% 혼합으로 더 옅게(웹 .dark .chg 정합)
    fgOnHeroChgUp: PorestPalette.heroChgUpDark,
    fgOnHeroChgDown: PorestPalette.heroChgDownDark,
    fgOnHeroSpot: PorestPalette.slate0,
  );

  @override
  PorestTokens copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgSurfaceRaised,
    Color? bgSunken,
    Color? bgMuted,
    Color? bgInverse,
    Color? bgBrand,
    Color? bgBrandHover,
    Color? bgBrandPress,
    Color? bgBrandSubtle,
    Color? bgBrandMuted,
    Color? bgBrandSolid,
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
    Color? fgExpense,
    Color? fgIncome,
    Color? fgTransfer,
    Color? bgExpenseSubtle,
    Color? bgIncomeSubtle,
    Color? bgTransferSubtle,
    Color? bgBrandTint,
    Color? bgBrandTintStrong,
    Color? bgTableHead,
    Color? borderBrandSoft,
    Color? borderBrandMid,
    Color? statusSuccessBorder,
    Color? statusWarningBorder,
    Color? statusDangerBorder,
    Color? statusDangerPress,
    Color? statusInfoBorder,
    Color? surfaceHero,
    Color? bgHeroGradientStart,
    Color? bgHeroGradientEnd,
    Color? fgOnHeroChgUp,
    Color? fgOnHeroChgDown,
    Color? fgOnHeroSpot,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
    List<BoxShadow>? shadowXl,
  }) {
    return PorestTokens(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSurfaceRaised: bgSurfaceRaised ?? this.bgSurfaceRaised,
      bgSunken: bgSunken ?? this.bgSunken,
      bgMuted: bgMuted ?? this.bgMuted,
      bgInverse: bgInverse ?? this.bgInverse,
      bgBrand: bgBrand ?? this.bgBrand,
      bgBrandHover: bgBrandHover ?? this.bgBrandHover,
      bgBrandPress: bgBrandPress ?? this.bgBrandPress,
      bgBrandSubtle: bgBrandSubtle ?? this.bgBrandSubtle,
      bgBrandMuted: bgBrandMuted ?? this.bgBrandMuted,
      bgBrandSolid: bgBrandSolid ?? this.bgBrandSolid,
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
      fgExpense: fgExpense ?? this.fgExpense,
      fgIncome: fgIncome ?? this.fgIncome,
      fgTransfer: fgTransfer ?? this.fgTransfer,
      bgExpenseSubtle: bgExpenseSubtle ?? this.bgExpenseSubtle,
      bgIncomeSubtle: bgIncomeSubtle ?? this.bgIncomeSubtle,
      bgTransferSubtle: bgTransferSubtle ?? this.bgTransferSubtle,
      bgBrandTint: bgBrandTint ?? this.bgBrandTint,
      bgBrandTintStrong: bgBrandTintStrong ?? this.bgBrandTintStrong,
      bgTableHead: bgTableHead ?? this.bgTableHead,
      borderBrandSoft: borderBrandSoft ?? this.borderBrandSoft,
      borderBrandMid: borderBrandMid ?? this.borderBrandMid,
      statusSuccessBorder: statusSuccessBorder ?? this.statusSuccessBorder,
      statusWarningBorder: statusWarningBorder ?? this.statusWarningBorder,
      statusDangerBorder: statusDangerBorder ?? this.statusDangerBorder,
      statusDangerPress: statusDangerPress ?? this.statusDangerPress,
      statusInfoBorder: statusInfoBorder ?? this.statusInfoBorder,
      surfaceHero: surfaceHero ?? this.surfaceHero,
      bgHeroGradientStart: bgHeroGradientStart ?? this.bgHeroGradientStart,
      bgHeroGradientEnd: bgHeroGradientEnd ?? this.bgHeroGradientEnd,
      fgOnHeroChgUp: fgOnHeroChgUp ?? this.fgOnHeroChgUp,
      fgOnHeroChgDown: fgOnHeroChgDown ?? this.fgOnHeroChgDown,
      fgOnHeroSpot: fgOnHeroSpot ?? this.fgOnHeroSpot,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
      shadowXl: shadowXl ?? this.shadowXl,
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
      bgInverse: l(bgInverse, other.bgInverse),
      bgBrand: l(bgBrand, other.bgBrand),
      bgBrandHover: l(bgBrandHover, other.bgBrandHover),
      bgBrandPress: l(bgBrandPress, other.bgBrandPress),
      bgBrandSubtle: l(bgBrandSubtle, other.bgBrandSubtle),
      bgBrandMuted: l(bgBrandMuted, other.bgBrandMuted),
      bgBrandSolid: l(bgBrandSolid, other.bgBrandSolid),
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
      fgExpense: l(fgExpense, other.fgExpense),
      fgIncome: l(fgIncome, other.fgIncome),
      fgTransfer: l(fgTransfer, other.fgTransfer),
      bgExpenseSubtle: l(bgExpenseSubtle, other.bgExpenseSubtle),
      bgIncomeSubtle: l(bgIncomeSubtle, other.bgIncomeSubtle),
      bgTransferSubtle: l(bgTransferSubtle, other.bgTransferSubtle),
      bgBrandTint: l(bgBrandTint, other.bgBrandTint),
      bgBrandTintStrong: l(bgBrandTintStrong, other.bgBrandTintStrong),
      bgTableHead: l(bgTableHead, other.bgTableHead),
      borderBrandSoft: l(borderBrandSoft, other.borderBrandSoft),
      borderBrandMid: l(borderBrandMid, other.borderBrandMid),
      statusSuccessBorder: l(statusSuccessBorder, other.statusSuccessBorder),
      statusWarningBorder: l(statusWarningBorder, other.statusWarningBorder),
      statusDangerBorder: l(statusDangerBorder, other.statusDangerBorder),
      statusDangerPress: l(statusDangerPress, other.statusDangerPress),
      statusInfoBorder: l(statusInfoBorder, other.statusInfoBorder),
      surfaceHero: l(surfaceHero, other.surfaceHero),
      bgHeroGradientStart: l(bgHeroGradientStart, other.bgHeroGradientStart),
      bgHeroGradientEnd: l(bgHeroGradientEnd, other.bgHeroGradientEnd),
      fgOnHeroChgUp: l(fgOnHeroChgUp, other.fgOnHeroChgUp),
      fgOnHeroChgDown: l(fgOnHeroChgDown, other.fgOnHeroChgDown),
      fgOnHeroSpot: l(fgOnHeroSpot, other.fgOnHeroSpot),
      shadowSm: BoxShadow.lerpList(shadowSm, other.shadowSm, t) ?? shadowSm,
      shadowMd: BoxShadow.lerpList(shadowMd, other.shadowMd, t) ?? shadowMd,
      shadowLg: BoxShadow.lerpList(shadowLg, other.shadowLg, t) ?? shadowLg,
      shadowXl: BoxShadow.lerpList(shadowXl, other.shadowXl, t) ?? shadowXl,
    );
  }
}

/// 컨텍스트에서 토큰 꺼내는 짧은 helper.
extension PorestTokensX on BuildContext {
  PorestTokens get tokens => Theme.of(this).extension<PorestTokens>()!;
}
