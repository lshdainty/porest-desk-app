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

  // Dark mode 전용 surface 변종 (직접 OKLCH 정의되어 있던 것들)
  static const Color darkSurface = Color(0xFF18180C);
  static const Color darkSurfaceRaised = Color(0xFF202012);
  static const Color darkSunken = Color(0xFF0C0C04);
  static const Color darkMuted = Color(0xFF19190E);
  static const Color darkSectionWarm = Color(0xFF261A0F);
  static const Color darkBrandMuted = Color(0xFF1F200B);

  // Hero(.balance-hero) 내부 always-on-dark 색 — 그라데이션 mossy700→mossy900 위에 사용.
  // 라이트/다크 분기 없음 (hero 는 항상 어둡기 때문).
  static const Color heroChgUp = Color(0xFFB8E0A0);
  static const Color heroChgDown = Color(0xFFF0B6A8);
  static const Color heroSpot = Color(0xFFC8C480);
}
