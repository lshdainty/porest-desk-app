import 'package:flutter/painting.dart';

/// 카드사 브랜드 색 매칭 결과.
///
/// 카드 비주얼 3단계 fallback 의 2단계 — imgUrl 이 없거나 로드 실패 시
/// 카드사 브랜드 색 그라데이션으로 표시할 색/글자색을 담는다.
/// [known] 이 false 면 브랜드 미상 → 호출처는 중립 그라데이션(3단계)으로 분기.
class CardBrand {
  const CardBrand({
    required this.bg1,
    required this.bg2,
    required this.fg,
    required this.known,
  });

  /// 그라데이션 시작색 (브랜드 raw 색).
  final Color bg1;

  /// 그라데이션 끝색 (brand 색 78% 어둡게).
  final Color bg2;

  /// 오버레이 글자/약자 색.
  final Color fg;

  /// 브랜드 매칭 성공 여부. false 면 bg1/bg2/fg 는 의미 없음(중립 fallback 분기용).
  final bool known;

  /// 브랜드 미상 — 호출처가 기존 중립 그라데이션으로 분기하기 위한 sentinel.
  static const CardBrand unknown = CardBrand(
    bg1: Color(0xFF000000),
    bg2: Color(0xFF000000),
    fg: Color(0xFFFFFFFF),
    known: false,
  );
}

/// 카드사 브랜드 엔트리. 디자인 `CARD_BRANDS` 미러 — 브랜드 색은
/// chart_palette / bank_colors 와 동일하게 raw palette 인용이 허용되는 예외 영역.
class _CardBrandEntry {
  const _CardBrandEntry({
    required this.match,
    required this.bg,
    this.fg = const Color(0xFFFFFFFF),
  });

  /// company.name 포함 매칭에 쓰일 키.
  final String match;

  /// 브랜드 raw 색.
  final Color bg;

  /// 오버레이 글자색 (밝은 브랜드 색은 어두운 글자).
  final Color fg;
}

/// 디자인 `CARD_BRANDS` — 카드사 브랜드 색맵 (raw 예외 영역).
const List<_CardBrandEntry> _cardBrands = <_CardBrandEntry>[
  _CardBrandEntry(match: '우리카드', bg: Color(0xFF0067AC)),
  _CardBrandEntry(match: '신한카드', bg: Color(0xFF0046FF)),
  _CardBrandEntry(match: '삼성카드', bg: Color(0xFF1428A0)),
  _CardBrandEntry(match: '현대카드', bg: Color(0xFF1C2951)),
  _CardBrandEntry(
    match: 'KB국민카드',
    bg: Color(0xFFFFBC00),
    fg: Color(0xFF1A1F2E),
  ),
  _CardBrandEntry(match: '롯데카드', bg: Color(0xFFED1C24)),
  _CardBrandEntry(match: '하나카드', bg: Color(0xFF008C74)),
  _CardBrandEntry(match: 'NH농협카드', bg: Color(0xFF00A149)),
  _CardBrandEntry(match: '카카오뱅크', bg: Color(0xFFFEE500), fg: Color(0xFF1A1F2E)),
  _CardBrandEntry(match: '토스뱅크', bg: Color(0xFF0064FF)),
];

String _normalize(String s) => s.replaceAll(RegExp(r'\s+'), '').trim();

/// company.name 으로 카드사 브랜드 색을 매칭.
///
/// 정확 매칭 → 포함 매칭(가장 긴 키 우선). 미상이면 [CardBrand.unknown].
/// 그라데이션 끝색은 brand 색을 78% 밝기로 어둡게(135deg 광택용).
CardBrand getCardBrand(String? companyName) {
  if (companyName == null) return CardBrand.unknown;
  final n = _normalize(companyName);
  if (n.isEmpty) return CardBrand.unknown;

  _CardBrandEntry? hit;
  for (final e in _cardBrands) {
    if (n == _normalize(e.match)) {
      hit = e;
      break;
    }
  }
  if (hit == null) {
    // 포함 매칭 — 가장 긴 키 우선 (예: 'NH농협카드' > '농협').
    final sorted = [..._cardBrands]
      ..sort((a, b) => b.match.length.compareTo(a.match.length));
    for (final e in sorted) {
      if (n.contains(_normalize(e.match))) {
        hit = e;
        break;
      }
    }
  }
  if (hit == null) return CardBrand.unknown;

  return CardBrand(
    bg1: hit.bg,
    bg2: _darken(hit.bg, 0.78),
    fg: hit.fg,
    known: true,
  );
}

/// HSL 밝기 곱으로 색을 어둡게 — brand 색 [factor] 밝기.
Color _darken(Color c, double factor) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * factor).clamp(0.0, 1.0)).toColor();
}
