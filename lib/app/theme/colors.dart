import 'package:flutter/painting.dart';

/// POREST 디자인 시스템의 원시 컬러 팔레트.
///
/// porest-desk-front `index.css`의 OKLCH 정의를 sRGB로 빌드 타임에 변환한 결과.
/// 의미론적 사용은 [`PorestTokens`](tokens.dart) 를 통해서만 — 컴포넌트는 이 raw 토큰을
/// 직접 참조하지 말 것 (다크 모드 분기가 깨짐).
abstract final class PorestPalette {
  // Mist (cool neutral)
  static const Color mist0 = Color(0xFFFFFFFF);
  static const Color mist50 = Color(0xFFF9FCFB);
  static const Color mist100 = Color(0xFFF3F8F6);
  static const Color mist200 = Color(0xFFE8EEEC);
  static const Color mist300 = Color(0xFFDBE1DF);
  static const Color mist400 = Color(0xFFC1C9C7);
  static const Color mist500 = Color(0xFF919B98);
  static const Color mist600 = Color(0xFF646E6D);
  static const Color mist700 = Color(0xFF414A49);
  static const Color mist800 = Color(0xFF222B2B);
  static const Color mist900 = Color(0xFF0C1313);
  static const Color mist950 = Color(0xFF030606);

  // Mossy (primary brand)
  static const Color mossy50 = Color(0xFFF6F7EC);
  static const Color mossy100 = Color(0xFFECEEDB);
  static const Color mossy200 = Color(0xFFD8DABE);
  static const Color mossy300 = Color(0xFFBCBE98);
  static const Color mossy400 = Color(0xFF94966B);
  static const Color mossy500 = Color(0xFF6B6C43);
  static const Color mossy600 = Color(0xFF585A32);
  static const Color mossy700 = Color(0xFF454626);
  static const Color mossy800 = Color(0xFF313218);
  static const Color mossy900 = Color(0xFF1F1F0D);
  static const Color mossy950 = Color(0xFF0F0F04);

  // Bark (warm)
  static const Color bark50 = Color(0xFFFCF7F1);
  static const Color bark100 = Color(0xFFF7ECE0);
  static const Color bark200 = Color(0xFFEBD9C6);
  static const Color bark300 = Color(0xFFD7C0A8);
  static const Color bark400 = Color(0xFFAE927A);
  static const Color bark500 = Color(0xFF856854);
  static const Color bark600 = Color(0xFF674B3C);
  static const Color bark700 = Color(0xFF4D362B);
  static const Color bark800 = Color(0xFF34231D);
  static const Color bark900 = Color(0xFF1E130F);

  // Status — Sunlit (warning)
  static const Color sunlit100 = Color(0xFFFEF3DE);
  static const Color sunlit300 = Color(0xFFEED299);
  static const Color sunlit500 = Color(0xFFD1A550);
  static const Color sunlit700 = Color(0xFF966C1E);

  // Status — Berry (danger)
  static const Color berry100 = Color(0xFFFFEAE8);
  static const Color berry300 = Color(0xFFF1B2AC);
  static const Color berry500 = Color(0xFFC65D57);
  static const Color berry700 = Color(0xFF903C3A);

  // Status — Sky (info)
  static const Color sky100 = Color(0xFFE7F6FF);
  static const Color sky300 = Color(0xFFB0DCF2);
  static const Color sky500 = Color(0xFF58A3C5);
  static const Color sky700 = Color(0xFF2C7191);

  // Status — Sprout (success secondary)
  static const Color sprout100 = Color(0xFFE9F7E3);
  static const Color sprout300 = Color(0xFFC5DEAE);
  static const Color sprout500 = Color(0xFF96B66D);
  static const Color sprout700 = Color(0xFF627837);

  // Cobalt — primary brand (porest-desk-front `--color-primary: #0147ad` 미러)
  // primary-light: #5fa0e5 — 다크 모드 brand 표현용.
  static const Color cobalt50  = Color(0xFFF0F6FC);
  static const Color cobalt100 = Color(0xFFE0EDF8);
  static const Color cobalt200 = Color(0xFFC7DFF6);
  static const Color cobalt300 = Color(0xFF97C2EE);
  static const Color cobalt400 = Color(0xFF5FA0E5);
  static const Color cobalt500 = Color(0xFF0147AD);
  static const Color cobalt600 = Color(0xFF013D97);
  static const Color cobalt700 = Color(0xFF013380);
  static const Color cobalt800 = Color(0xFF002660);
  static const Color cobalt900 = Color(0xFF001A42);

  // Dark mode 전용 surface 변종 (mossy/HR 브랜드 용 — desk-app 에선 사용 안 함)
  static const Color darkSurface = Color(0xFF18180C);
  static const Color darkSurfaceRaised = Color(0xFF202012);
  static const Color darkSunken = Color(0xFF0C0C04);
  static const Color darkMuted = Color(0xFF19190E);
  static const Color darkSectionWarm = Color(0xFF261A0F);
  static const Color darkBrandMuted = Color(0xFF1F200B);

  // Dark mode brand muted (cobalt 톤) — desk 브랜드용 어두운 navy-tinted 배경.
  static const Color darkBrandMutedCobalt = Color(0xFF0B1326);

  // === Slate (DESIGN.desk.md neutral palette — toss 스타일 cool grey/navy) ===
  // bg-page / surface / text / border 의미론 토큰의 raw 매핑.
  static const Color slate0 = Color(0xFFFFFFFF);
  static const Color slate50 = Color(0xFFF5F6FA); // bg-page (light)
  static const Color slate100 = Color(0xFFF0F2F7); // surface-input (light)
  static const Color slate200 = Color(0xFFE5E8EF); // border-default (light)
  static const Color slate300 = Color(0xFFC8CDD7); // border-default+
  static const Color slate400 = Color(0xFF828995); // text-disabled (light)
  static const Color slate500 = Color(0xFF7D8593); // border-strong (light)
  static const Color slate600 = Color(0xFF62697A); // text-tertiary (light)
  static const Color slate700 = Color(0xFF4E5968); // text-secondary (light)
  static const Color slate800 = Color(0xFF353B4D); // border-default-dark
  static const Color slate850 = Color(0xFF2D3346); // surface-input-dark
  static const Color slate900 = Color(0xFF242938); // surface-default-dark
  static const Color slate950 = Color(0xFF1A1F2E); // bg-page-dark / text-primary (light)

  // dark 모드 text/border 보조 톤
  static const Color slateDarkText2 = Color(0xFFB0B8C4); // text-secondary-dark
  static const Color slateDarkText3 = Color(0xFF9DA3B0); // text-tertiary-dark
  static const Color slateDarkTextDisabled = Color(0xFF7A8294);
  static const Color slateDarkBorderStrong = Color(0xFF8B95A8);

  // === Status (DESIGN.desk.md semantic functional palette) ===
  // 각 base + light 페어. base는 light mode 텍스트/배경, light는 dark mode fg.
  static const Color statusSuccessBase = Color(0xFF16803F);
  static const Color statusSuccessLight = Color(0xFF4ADE80);
  static const Color statusErrorBase = Color(0xFFDC2626);
  static const Color statusErrorLight = Color(0xFFF87171);
  static const Color statusWarningBase = Color(0xFFC84D0E);
  static const Color statusWarningLight = Color(0xFFFB923C);
  static const Color statusInfoBase = Color(0xFF1D6FCB);
  static const Color statusInfoLight = Color(0xFF60A5FA);

  // Hero(.balance-hero) 내부 always-on-dark 색 — 그라데이션 mossy700→mossy900 위에 사용.
  // 라이트/다크 분기 없음 (hero 는 항상 어둡기 때문).
  static const Color heroChgUp = Color(0xFFB8E0A0);
  static const Color heroChgDown = Color(0xFFF0B6A8);
  static const Color heroSpot = Color(0xFFC8C480);

  // === Chart palette (desk-front --color-chart-* 미러, 10색 페어) ===
  // 차트 카테고리 구분용. base = light 모드, light = dark 모드 fg.
  static const Color chartRed = Color(0xFFC73838);
  static const Color chartOrange = Color(0xFFB36418);
  static const Color chartYellow = Color(0xFF8C7400);
  static const Color chartGreen = Color(0xFF2D8060);
  static const Color chartBlue = Color(0xFF2C70BF);
  static const Color chartIndigo = Color(0xFF5E60C8);
  static const Color chartViolet = Color(0xFF8B4DBA);
  static const Color chartPink = Color(0xFFB83B7A);
  static const Color chartBrown = Color(0xFF9A6536);
  static const Color chartGray = Color(0xFF6B7484);

  static const Color chartRedLight = Color(0xFFECA0A0);
  static const Color chartOrangeLight = Color(0xFFE8B266);
  static const Color chartYellowLight = Color(0xFFD4B83A);
  static const Color chartGreenLight = Color(0xFF6BCB86);
  static const Color chartBlueLight = Color(0xFF7BBBED);
  static const Color chartIndigoLight = Color(0xFFABB0F0);
  static const Color chartVioletLight = Color(0xFFD2A8EC);
  static const Color chartPinkLight = Color(0xFFECA0BC);
  static const Color chartBrownLight = Color(0xFFDCB088);
  static const Color chartGrayLight = Color(0xFFB5BBC5);
}
