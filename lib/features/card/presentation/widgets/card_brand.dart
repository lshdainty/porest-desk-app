import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/image_frame/p_card_art.dart'
    show institutionTextColor;
import 'package:groo_damda_app/shared/ds/institution_colors/institution_colors.dart';

/// 카드사 브랜드 색 매칭 결과.
///
/// 카드 비주얼 3단계 fallback 의 2단계 — imgUrl 이 없거나 로드 실패 시
/// 카드사 브랜드 색 그라데이션으로 표시할 색/글자색을 담는다.
/// [known] 이 false 면 브랜드 미상 → 호출처는 중립 그라데이션(3단계)으로 분기.
class CardBrand {
  const CardBrand({
    required this.bg1,
    required this.bg2,
    required this.text,
    required this.known,
  });

  /// 그라데이션 시작색 (기관 색 표의 면 색).
  final Color bg1;

  /// 그라데이션 끝색 (brand 색 78% 어둡게).
  final Color bg2;

  /// 표의 글자색 이름 — 면 위 글자는 [fgOf].
  final PInstitutionText text;

  /// 브랜드 매칭 성공 여부. false 면 bg1/bg2/text 는 의미 없음(중립 fallback 분기용).
  final bool known;

  /// 오버레이 글자/약자 색 — 기관 색 표의 글자색(흰 글자가 4.5 미만이면 짙은 글자).
  Color fgOf(BuildContext context) => institutionTextColor(context, text);

  /// 브랜드 미상 — 호출처가 기존 중립 그라데이션으로 분기하기 위한 sentinel.
  static const CardBrand unknown = CardBrand(
    bg1: Color(0xFF000000),
    bg2: Color(0xFF000000),
    text: PInstitutionText.white,
    known: false,
  );
}

/// company.name 으로 카드사 브랜드 색을 매칭 — 기관 색 표 하나(institution-colors.yaml)에서 찾는다(03E-010).
///
/// 정확 매칭 → 포함 매칭(가장 긴 키 우선, 공백 무시). 미상이면 [CardBrand.unknown].
/// 그라데이션 끝색은 brand 색을 78% 밝기로 어둡게(135deg 광택용).
CardBrand getCardBrand(String? companyName) {
  final hit = PInstitutionColors.find(companyName);
  if (hit == null) return CardBrand.unknown;
  return CardBrand(
    bg1: hit.color,
    bg2: _darken(hit.color, 0.78),
    text: hit.text,
    known: true,
  );
}

/// HSL 밝기 곱으로 색을 어둡게 — brand 색 [factor] 밝기.
Color _darken(Color c, double factor) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * factor).clamp(0.0, 1.0)).toColor();
}
