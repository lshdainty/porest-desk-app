import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/colors.dart';
import 'package:porest_desk_app/app/theme/shadow.dart';

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
  final Color bgBrandTint;        // brand 약한 톤
  final Color bgBrandTintStrong;  // brand 진한 톤
  final Color bgTableHead;        // 테이블 헤더 행 배경

  // Border 변형
  final Color borderBrandSoft;    // brand 보더 약한 톤
  final Color borderBrandMid;     // brand 보더 중간 톤

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

  /// Light 모드 의미론 토큰 (DESIGN.desk.md spec 매핑).
  static const PorestTokens light = PorestTokens(
    bgCanvas: PorestPalette.slate50,
    bgSurface: PorestPalette.slate0,
    bgSurfaceRaised: PorestPalette.slate0,
    bgSunken: PorestPalette.slate100,
    bgMuted: PorestPalette.slate100,
    bgInverse: PorestPalette.slate950,
    bgBrand: PorestPalette.cobalt500,
    bgBrandHover: PorestPalette.cobalt600,
    bgBrandPress: PorestPalette.cobalt700,
    // desk-front `--bg-brand-subtle: color-mix(srgb, --color-primary 8%, transparent)`
    // = cobalt500(#0147AD) @ 8% alpha. solid cobalt50 사용 시 톤이 짙어 web 정합 X.
    bgBrandSubtle: Color(0x140147AD), // cobalt500 @ 8% alpha (0x14 ≈ 0.078)
    bgBrandMuted: Color(0x240147AD),  // cobalt500 @ 14% alpha (0x24 ≈ 0.141)
    bgBrandSolid: PorestPalette.cobalt500, // 버튼 채움 — primary 고정
    bgHoverSubtle: PorestPalette.slate50,
    bgHoverStrong: PorestPalette.slate100,
    bgRowHover: PorestPalette.slate50,
    bgDisabled: PorestPalette.slate100,
    // progress.md track = surface-input — 웹 .budget-bar(--bg-sunken) 정합.
    bgTrack: PorestPalette.slate100,
    fgPrimary: PorestPalette.slate950,
    fgSecondary: PorestPalette.slate700,
    fgTertiary: PorestPalette.slate600,
    fgDisabled: PorestPalette.slate400,
    fgPlaceholder: PorestPalette.slate500,
    fgOnBrand: PorestPalette.slate0,
    // desk-front `--fg-brand`/`--fg-brand-strong`/`--fg-link` 전부 light=--color-primary
    // (cobalt500 #0147AD). 더 진한 톤(cobalt700/800) 쓰면 web과 톤 불일치.
    fgBrand: PorestPalette.cobalt500,
    fgBrandStrong: PorestPalette.cobalt500,
    fgLink: PorestPalette.cobalt500,
    fgLinkHover: PorestPalette.cobalt500,
    fgOnDanger: PorestPalette.slate0,
    fgOnSuccess: PorestPalette.slate0,
    borderSubtle: PorestPalette.slate200,
    borderDefault: PorestPalette.slate200,
    borderStrong: PorestPalette.slate500,
    borderFocus: PorestPalette.cobalt500,
    borderBrand: PorestPalette.cobalt500,
    statusSuccess: PorestPalette.statusSuccessBase,
    statusSuccessSubtle: Color(0x1F16803F), // success @ 12% alpha
    statusSuccessFg: PorestPalette.statusSuccessBase,
    statusWarning: PorestPalette.statusWarningBase,
    statusWarningSubtle: Color(0x1FC84D0E), // warning @ 12% alpha
    statusWarningFg: PorestPalette.statusWarningBase,
    statusDanger: PorestPalette.statusErrorBase,
    statusDangerSubtle: Color(0x1FDC2626), // error @ 12% alpha
    statusDangerFg: PorestPalette.statusErrorBase,
    statusInfo: PorestPalette.statusInfoBase,
    statusInfoSubtle: Color(0x1F1D6FCB), // info @ 12% alpha
    statusInfoFg: PorestPalette.statusInfoBase,
    // Tx semantic — desk-front fg-expense=danger-fg, fg-income=fg-brand, fg-transfer=info-fg
    fgExpense: PorestPalette.statusErrorBase,
    fgIncome: PorestPalette.cobalt700,
    fgTransfer: PorestPalette.statusInfoBase,
    bgExpenseSubtle: Color(0x1FDC2626),
    bgIncomeSubtle: PorestPalette.cobalt50,
    bgTransferSubtle: Color(0x1F1D6FCB),
    // Interaction tints
    bgBrandTint: Color(0xFFEAF2FB),       // 디자인 p-card--brand 라이트(mossy-50) — alphaBlend 시 그대로
    bgBrandTintStrong: PorestPalette.cobalt100,
    bgTableHead: PorestPalette.slate100,
    // Border 변형
    borderBrandSoft: PorestPalette.cobalt200,
    borderBrandMid: PorestPalette.cobalt300,
    // Status 변형 (spec border = base color)
    statusSuccessBorder: PorestPalette.statusSuccessBase,
    statusWarningBorder: PorestPalette.statusWarningBase,
    statusDangerBorder: PorestPalette.statusErrorBase,
    statusDangerPress: PorestPalette.statusErrorBase,
    statusInfoBorder: PorestPalette.statusInfoBase,
    surfaceHero: PorestPalette.cobalt50,
    // desk-front .balance-hero: linear-gradient(135deg, bg-brand 0%, color-mix(srgb, bg-brand 60%, #000) 100%)
    // bg-brand=cobalt500 #0147AD, end ≈ #012B68 (60% × cobalt500 on black)
    bgHeroGradientStart: PorestPalette.cobalt500,
    bgHeroGradientEnd: Color(0xFF012B68),
    fgOnHeroChgUp: PorestPalette.heroChgUp,
    fgOnHeroChgDown: PorestPalette.heroChgDown,
    // desk-front .balance-hero::after: radial gradient(fg-on-brand 22%, transparent 70%) — 흰색 광원
    fgOnHeroSpot: PorestPalette.slate0,
    shadowSm: PShadow.sm,
    shadowMd: PShadow.md,
    shadowLg: PShadow.lg,
    shadowXl: PShadow.xl,
  );

  /// Dark 모드 의미론 토큰 (DESIGN.desk.md spec 매핑).
  static const PorestTokens dark = PorestTokens(
    bgCanvas: PorestPalette.slate950,
    bgSurface: PorestPalette.slate900,
    // design tokens.css dark: `--bg-surface-raised: #2d3346` — surface(#242938) 한 단계 위
    // 패널. 모바일 카드 다이어트의 keep(raised) 카드가 다크에서도 떠 보이게 한다.
    bgSurfaceRaised: PorestPalette.slate850,
    bgSunken: PorestPalette.slate950,
    bgMuted: PorestPalette.slate850,
    bgInverse: PorestPalette.slate50,
    bgBrand: PorestPalette.cobalt400,
    bgBrandHover: PorestPalette.cobalt300,
    bgBrandPress: PorestPalette.cobalt200,
    // desk-front dark: `--bg-brand-subtle: color-mix(srgb, --color-primary 12%, transparent)`
    // = cobalt500(#0147AD) @ 12% alpha. solid cobalt900 사용 시 거의 검정이라 web 정합 X.
    bgBrandSubtle: Color(0x1F0147AD), // cobalt500 @ 12% alpha (0x1F ≈ 0.122)
    bgBrandMuted: Color(0x380147AD),  // cobalt500 @ 22% alpha (0x38 ≈ 0.220)
    bgBrandSolid: PorestPalette.cobalt500, // 버튼 채움 — 다크에서도 primary 고정(light 아님)
    bgHoverSubtle: Color(0x0AFFFFFF),
    bgHoverStrong: Color(0x14FFFFFF),
    bgRowHover: Color(0x08FFFFFF),
    bgDisabled: Color(0x0DFFFFFF),
    // progress.md track = surface-input-dark(#2D3346) — 종전 흰색 14% 알파는
    // 스펙 근거 없는 임의 값(웹 .budget-bar 보다 밝게 보이던 원인).
    bgTrack: PorestPalette.slate850,
    fgPrimary: PorestPalette.slate50,
    fgSecondary: PorestPalette.slateDarkText2,
    fgTertiary: PorestPalette.slateDarkText3,
    fgDisabled: PorestPalette.slateDarkTextDisabled,
    fgPlaceholder: PorestPalette.slateDarkText3,
    fgOnBrand: PorestPalette.slate0,
    // desk-front dark: 전부 --color-primary-light (#5FA0E5 = cobalt400) 사용.
    fgBrand: PorestPalette.cobalt400,
    fgBrandStrong: PorestPalette.cobalt400,
    fgLink: PorestPalette.cobalt400,
    fgLinkHover: PorestPalette.cobalt400,
    fgOnDanger: PorestPalette.slate0,
    fgOnSuccess: PorestPalette.slate0,
    borderSubtle: PorestPalette.slate800,
    borderDefault: PorestPalette.slate800,
    borderStrong: PorestPalette.slateDarkBorderStrong,
    borderFocus: PorestPalette.cobalt400,
    borderBrand: PorestPalette.cobalt400,
    statusSuccess: PorestPalette.statusSuccessBase,
    statusSuccessSubtle: Color(0x2E16803F), // success @ 18% alpha
    statusSuccessFg: PorestPalette.statusSuccessLight,
    statusWarning: PorestPalette.statusWarningBase,
    statusWarningSubtle: Color(0x2EC84D0E),
    statusWarningFg: PorestPalette.statusWarningLight,
    statusDanger: PorestPalette.statusErrorBase,
    statusDangerSubtle: Color(0x2EDC2626),
    statusDangerFg: PorestPalette.statusErrorLight,
    statusInfo: PorestPalette.statusInfoBase,
    statusInfoSubtle: Color(0x2E1D6FCB),
    statusInfoFg: PorestPalette.statusInfoLight,
    // Tx semantic — desk-front 다크 미러
    // 지출=error-light(#F87171), 수입=primary-light(cobalt400 #5FA0E5).
    // 웹 --fg-income(=fg-brand=primary-light)와 정합. cobalt300은 한 톤 밝아 어긋났음.
    fgExpense: PorestPalette.statusErrorLight,
    fgIncome: PorestPalette.cobalt400,
    fgTransfer: PorestPalette.statusInfoLight,
    bgExpenseSubtle: Color(0x2EDC2626),
    bgIncomeSubtle: Color(0x80001A42),    // cobalt900 @ 50%
    bgTransferSubtle: Color(0x2E1D6FCB),
    // Interaction tints — cobalt 근사 hex+alpha
    bgBrandTint: Color(0x1F5FA0E5),       // cobalt400 @12% — canvas(#1A1F2E) 위 합성 시 #222E44 (디자인 정합)
    bgBrandTintStrong: Color(0x385FA0E5), // cobalt400 @22%
    bgTableHead: Color(0x0AFFFFFF),       // oklch(1 0 0 / 0.04)
    // Border 변형 — cobalt brand
    borderBrandSoft: Color(0x665FA0E5),   // cobalt400 @ 40%
    borderBrandMid: Color(0x8097C2EE),    // cobalt300 @ 50%
    // Status 변형 (dark mode = base color border)
    statusSuccessBorder: PorestPalette.statusSuccessBase,
    statusWarningBorder: PorestPalette.statusWarningBase,
    statusDangerBorder: PorestPalette.statusErrorBase,
    statusDangerPress: PorestPalette.statusErrorLight,
    statusInfoBorder: PorestPalette.statusInfoBase,
    surfaceHero: Color(0x80001A42),       // cobalt900 @ 50%
    // Hero gradient (dark) — primary-light(cobalt400 #5FA0E5) 기반.
    // 어두운 페이지 배경에서 카드를 밝게 도드라지게 + 디자인 시스템 dark brand 원칙
    // (fgBrand/border 등 전부 cobalt400=primary-light) 정합. start는 primary-light,
    // end는 primary(cobalt500)로 흘려 하단 split 영역 대비 확보.
    bgHeroGradientStart: PorestPalette.cobalt400, // primary-light #5FA0E5
    bgHeroGradientEnd: PorestPalette.cobalt500,    // primary #0147AD
    // 다크 = 더 밝은 코발트 그라데이션 → 50% 혼합으로 더 옅게(웹 .dark .chg 정합)
    fgOnHeroChgUp: PorestPalette.heroChgUpDark,
    fgOnHeroChgDown: PorestPalette.heroChgDownDark,
    fgOnHeroSpot: PorestPalette.slate0,
    shadowSm: PShadow.smDark,
    shadowMd: PShadow.mdDark,
    shadowLg: PShadow.lgDark,
    shadowXl: PShadow.xlDark,
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
