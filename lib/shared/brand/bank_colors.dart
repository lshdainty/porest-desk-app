import 'package:flutter/painting.dart';

/// 한국 은행/증권사/가상자산 거래소 브랜드 색.
/// porest-desk-front `shared/lib/porest/bank-colors.ts` 1:1 포팅.
class BrandColor {
  const BrandColor({required this.bg, this.fg = const Color(0xFFFFFFFF)});
  final Color bg;
  final Color fg;
}

/// 은행/증권사 카테고리. 자산 추가 다이얼로그 섹션 헤더로 활용.
enum BankCategory {
  retailBank('시중은행'),
  internetBank('인터넷은행'),
  regionalBank('지방은행'),
  specialBank('특수은행'),
  savingsInstitution('저축기관'),
  foreignBank('외국계'),
  other('기타'),
  brokerage('증권사'),
  commodityExchange('상품거래소'),
  cryptoExchange('가상자산');

  const BankCategory(this.label);
  final String label;
}

class BankEntry {
  const BankEntry({
    required this.name,
    required this.category,
    required this.color,
    this.aliases = const <String>[],
  });
  final String name;
  final BankCategory category;
  final BrandColor color;
  final List<String> aliases;
}

/// 투자 상품 등록 시 선택 가능한 카테고리 (증권사 + 상품거래소 + 가상자산).
const Set<BankCategory> investCategories = {
  BankCategory.brokerage,
  BankCategory.commodityExchange,
  BankCategory.cryptoExchange,
};

/// 기관이 정해 주는 보유 유형 — 증권사에서 코인을, 금거래소에서 주식을 담을 일은 없다.
const Map<BankCategory, String> categoryHoldingType = {
  BankCategory.brokerage: 'STOCK',
  BankCategory.commodityExchange: 'GOLD',
  BankCategory.cryptoExchange: 'CRYPTO',
};

/// 자산 추가 다이얼로그 섹션 표시 순서.
const List<BankCategory> bankCategoryOrder = [
  BankCategory.retailBank,
  BankCategory.internetBank,
  BankCategory.regionalBank,
  BankCategory.specialBank,
  BankCategory.savingsInstitution,
  BankCategory.foreignBank,
  BankCategory.other,
  BankCategory.brokerage,
  BankCategory.commodityExchange,
  BankCategory.cryptoExchange,
];

const List<BankEntry> bankEntries = <BankEntry>[
  // 시중은행
  BankEntry(
      name: '신한',
      category: BankCategory.retailBank,
      color: BrandColor(bg: Color(0xFF0046FF)),
      aliases: ['신한은행']),
  BankEntry(
      name: 'KB국민',
      category: BankCategory.retailBank,
      color: BrandColor(bg: Color(0xFFFFBC00), fg: Color(0xFF191919)),
      aliases: ['KB', '국민', 'KB국민은행']),
  BankEntry(
      name: '우리',
      category: BankCategory.retailBank,
      color: BrandColor(bg: Color(0xFF0067AC)),
      aliases: ['우리은행']),
  BankEntry(
      name: '하나',
      category: BankCategory.retailBank,
      color: BrandColor(bg: Color(0xFF008485)),
      aliases: ['KEB하나', '하나은행']),
  BankEntry(
      name: 'NH농협',
      category: BankCategory.retailBank,
      color: BrandColor(bg: Color(0xFF00A651)),
      aliases: ['농협', 'NH농협은행']),
  BankEntry(
      name: 'IBK기업',
      category: BankCategory.retailBank,
      color: BrandColor(bg: Color(0xFF004098)),
      aliases: ['기업', 'IBK', '기업은행']),
  BankEntry(
      name: 'SC제일',
      category: BankCategory.retailBank,
      color: BrandColor(bg: Color(0xFF009A44)),
      aliases: ['제일', 'SC', 'SC제일은행']),
  BankEntry(
      name: '씨티',
      category: BankCategory.retailBank,
      color: BrandColor(bg: Color(0xFF056DAE)),
      aliases: ['시티', '씨티은행', '한국씨티']),

  // 인터넷은행
  BankEntry(
      name: '카카오뱅크',
      category: BankCategory.internetBank,
      color: BrandColor(bg: Color(0xFFFEE500), fg: Color(0xFF191919)),
      aliases: ['카뱅']),
  BankEntry(
      name: '토스뱅크',
      category: BankCategory.internetBank,
      color: BrandColor(bg: Color(0xFF0064FF)),
      aliases: ['토스']),
  BankEntry(
      name: '케이뱅크',
      category: BankCategory.internetBank,
      color: BrandColor(bg: Color(0xFF0214A1)),
      aliases: ['K뱅크', 'K Bank']),

  // 지방은행
  BankEntry(
      name: '부산',
      category: BankCategory.regionalBank,
      color: BrandColor(bg: Color(0xFF0033A0)),
      aliases: ['부산은행', 'BNK부산']),
  BankEntry(
      name: '대구',
      category: BankCategory.regionalBank,
      color: BrandColor(bg: Color(0xFF1464AC)),
      aliases: ['대구은행', 'iM뱅크', 'DGB대구']),
  BankEntry(
      name: '경남',
      category: BankCategory.regionalBank,
      color: BrandColor(bg: Color(0xFF0E4C92)),
      aliases: ['경남은행', 'BNK경남']),
  BankEntry(
      name: '광주',
      category: BankCategory.regionalBank,
      color: BrandColor(bg: Color(0xFF00428A)),
      aliases: ['광주은행', 'JB광주']),
  BankEntry(
      name: '전북',
      category: BankCategory.regionalBank,
      color: BrandColor(bg: Color(0xFF0F3E8C)),
      aliases: ['전북은행', 'JB전북']),
  BankEntry(
      name: '제주',
      category: BankCategory.regionalBank,
      color: BrandColor(bg: Color(0xFFF47216)),
      aliases: ['제주은행']),

  // 특수은행
  BankEntry(
      name: 'KDB산업',
      category: BankCategory.specialBank,
      color: BrandColor(bg: Color(0xFF004098)),
      aliases: ['산업', '산업은행', 'KDB']),
  BankEntry(
      name: '수출입',
      category: BankCategory.specialBank,
      color: BrandColor(bg: Color(0xFF003A6C)),
      aliases: ['수출입은행', 'EXIM']),
  BankEntry(
      name: '수협',
      category: BankCategory.specialBank,
      color: BrandColor(bg: Color(0xFF003DA5)),
      aliases: ['수협은행', 'Sh수협']),

  // 저축기관
  BankEntry(
      name: '우체국',
      category: BankCategory.savingsInstitution,
      color: BrandColor(bg: Color(0xFFE4002B)),
      aliases: ['우체국예금', '우체국금융']),
  BankEntry(
      name: '새마을금고',
      category: BankCategory.savingsInstitution,
      color: BrandColor(bg: Color(0xFFD61E29)),
      aliases: ['새마을', 'MG']),
  BankEntry(
      name: '신협',
      category: BankCategory.savingsInstitution,
      color: BrandColor(bg: Color(0xFF003A70)),
      aliases: ['신용협동조합']),
  BankEntry(
      name: '산림조합',
      category: BankCategory.savingsInstitution,
      color: BrandColor(bg: Color(0xFF2E7D32)),
      aliases: ['산림조합중앙회']),
  BankEntry(
      name: 'SBI저축',
      category: BankCategory.savingsInstitution,
      color: BrandColor(bg: Color(0xFF0E3E85)),
      aliases: ['SBI저축은행', 'SBI']),
  BankEntry(
      name: 'OK저축',
      category: BankCategory.savingsInstitution,
      color: BrandColor(bg: Color(0xFFFECC00), fg: Color(0xFF191919)),
      aliases: ['OK저축은행']),
  BankEntry(
      name: '웰컴저축',
      category: BankCategory.savingsInstitution,
      color: BrandColor(bg: Color(0xFFE30613)),
      aliases: ['웰컴저축은행']),
  BankEntry(
      name: '페퍼저축',
      category: BankCategory.savingsInstitution,
      color: BrandColor(bg: Color(0xFFB3002D)),
      aliases: ['페퍼저축은행', 'Pepper']),

  // 외국계
  BankEntry(
      name: 'HSBC',
      category: BankCategory.foreignBank,
      color: BrandColor(bg: Color(0xFFDB0011)),
      aliases: ['홍콩상하이', '에이치에스비씨']),
  BankEntry(
      name: 'ICBC',
      category: BankCategory.foreignBank,
      color: BrandColor(bg: Color(0xFFD6001C)),
      aliases: ['공상은행', '중국공상은행']),
  BankEntry(
      name: 'BoA',
      category: BankCategory.foreignBank,
      color: BrandColor(bg: Color(0xFF012169)),
      aliases: ['뱅크오브아메리카', 'Bank of America']),
  BankEntry(
      name: '도이치',
      category: BankCategory.foreignBank,
      color: BrandColor(bg: Color(0xFF004A8F)),
      aliases: ['도이치뱅크', 'Deutsche']),
  BankEntry(
      name: 'JP모건',
      category: BankCategory.foreignBank,
      color: BrandColor(bg: Color(0xFF006CB7)),
      aliases: ['JPMorgan', 'JP모건체이스']),

  // 기타
  BankEntry(
      name: '현금',
      category: BankCategory.other,
      color: BrandColor(bg: Color(0xFF64748B)),
      aliases: ['지갑', 'Cash']),

  // 증권사
  BankEntry(
      name: '삼성증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF1428A0)),
      aliases: ['삼성']),
  BankEntry(
      name: '미래에셋',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF2C3E50)),
      aliases: ['미래에셋증권']),
  BankEntry(
      name: 'NH투자',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF00A651)),
      aliases: ['NH투자증권']),
  BankEntry(
      name: '한국투자',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF00529B)),
      aliases: ['한투', '한국투자증권']),
  BankEntry(
      name: 'KB증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFFFFBC00), fg: Color(0xFF191919))),
  BankEntry(
      name: '신한투자',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF0046FF)),
      aliases: ['신한금융투자', '신한투자증권']),
  BankEntry(
      name: '하나증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF008485))),
  BankEntry(
      name: '키움증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFFFF0033)),
      aliases: ['키움']),
  BankEntry(
      name: '메리츠증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFFE60012)),
      aliases: ['메리츠', '메리츠종합금융증권']),
  BankEntry(
      name: '대신증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFFF58220)),
      aliases: ['대신']),
  BankEntry(
      name: '유안타증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF10B981)),
      aliases: ['유안타', '동양']),
  BankEntry(
      name: '유진투자',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF003595)),
      aliases: ['유진투자증권']),
  BankEntry(
      name: '교보증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF004A8F)),
      aliases: ['교보']),
  BankEntry(
      name: 'IBK투자',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF004098)),
      aliases: ['IBK투자증권']),
  BankEntry(
      name: 'DB금융투자',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF008456)),
      aliases: ['DB', 'DB금투']),
  BankEntry(
      name: 'SK증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFFEA002C)),
      aliases: ['SK']),
  BankEntry(
      name: '현대차증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF002C5F)),
      aliases: ['현대차', 'HMC투자']),
  BankEntry(
      name: '하이투자',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF004098)),
      aliases: ['하이투자증권']),
  BankEntry(
      name: '한화투자',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFFFF7900)),
      aliases: ['한화투자증권', '한화']),
  BankEntry(
      name: 'BNK투자',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF0033A0)),
      aliases: ['BNK투자증권']),
  BankEntry(
      name: '한양증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF004098)),
      aliases: ['한양']),
  BankEntry(
      name: 'LS증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF005EB8)),
      aliases: ['이베스트', '이베스트투자', 'E-best']),
  BankEntry(
      name: '부국증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF003366)),
      aliases: ['부국']),
  BankEntry(
      name: '신영증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF005EB8)),
      aliases: ['신영']),
  BankEntry(
      name: '카카오페이증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFFFEE500), fg: Color(0xFF191919)),
      aliases: ['카카오페이']),
  BankEntry(
      name: '토스증권',
      category: BankCategory.brokerage,
      color: BrandColor(bg: Color(0xFF0064FF))),

  // 상품거래소 (실물 금). 금은방 체인은 표준 기관코드 체계가 없다.
  // KRX 금시장은 증권사 HTS 로 거래하지만, 담기는 건 g 단위 실물 금이라 여기에 둔다.
  BankEntry(
      name: 'KRX 금시장',
      category: BankCategory.commodityExchange,
      color: BrandColor(bg: Color(0xFFC9A227), fg: Color(0xFF191919)),
      aliases: ['한국거래소', 'KRX', '금시장']),
  BankEntry(
      name: '한국금거래소',
      category: BankCategory.commodityExchange,
      color: BrandColor(bg: Color(0xFFB8232F)),
      aliases: ['koreagoldx', '금거래소']),
  BankEntry(
      name: '한국표준금거래소',
      category: BankCategory.commodityExchange,
      color: BrandColor(bg: Color(0xFF8C6A1F)),
      aliases: ['표준금거래소']),
  BankEntry(
      name: '삼성금거래소',
      category: BankCategory.commodityExchange,
      color: BrandColor(bg: Color(0xFF1428A0)),
      aliases: ['삼성금']),
  BankEntry(
      name: '한국조폐공사',
      category: BankCategory.commodityExchange,
      color: BrandColor(bg: Color(0xFF00594F)),
      aliases: ['조폐공사', '오롯', 'KOMSCO']),
  BankEntry(
      name: '기타 금은방',
      category: BankCategory.commodityExchange,
      color: BrandColor(bg: Color(0xFFA78246), fg: Color(0xFF191919)),
      aliases: ['금은방', '직접보관', '실물']),

  // 가상자산
  BankEntry(
      name: '업비트',
      category: BankCategory.cryptoExchange,
      color: BrandColor(bg: Color(0xFF1F55F4)),
      aliases: ['Upbit', 'UPBIT', '두나무']),
  BankEntry(
      name: '빗썸',
      category: BankCategory.cryptoExchange,
      color: BrandColor(bg: Color(0xFFF2811D)),
      aliases: ['Bithumb', 'BITHUMB']),
  BankEntry(
      name: '코인원',
      category: BankCategory.cryptoExchange,
      color: BrandColor(bg: Color(0xFFF55826)),
      aliases: ['Coinone', 'COINONE']),
  BankEntry(
      name: '코빗',
      category: BankCategory.cryptoExchange,
      color: BrandColor(bg: Color(0xFF1D3FFF)),
      aliases: ['Korbit', 'KORBIT']),
];

/// 카테고리별로 묶인 은행·증권사 리스트 — 다이얼로그 섹션 헤더용.
final Map<BankCategory, List<BankEntry>> bankEntriesByCategory = (() {
  final m = <BankCategory, List<BankEntry>>{};
  for (final e in bankEntries) {
    (m[e.category] ??= <BankEntry>[]).add(e);
  }
  return m;
})();

final Map<String, BrandColor> _brandMap = (() {
  final m = <String, BrandColor>{};
  for (final e in bankEntries) {
    m[_normalize(e.name)] = e.color;
    for (final a in e.aliases) {
      m[_normalize(a)] = e.color;
    }
  }
  return m;
})();

final List<String> _sortedKeys = (() {
  final keys = _brandMap.keys.toList();
  keys.sort((a, b) => b.length.compareTo(a.length));
  return keys;
})();

String _normalize(String s) => s.replaceAll(RegExp(r'\s+'), '').trim();

/// 정확 매칭 → 포함 매칭(가장 긴 키 우선).
BrandColor? getBrandColor(List<String?> candidates) {
  for (final c in candidates) {
    if (c == null) continue;
    final n = _normalize(c);
    if (n.isEmpty) continue;
    final exact = _brandMap[n];
    if (exact != null) return exact;
    for (final k in _sortedKeys) {
      if (n.contains(k)) return _brandMap[k];
    }
  }
  return null;
}

/// fallback hue — 자산 이름 hash 기반 색상 생성.
Color hashColor(String text) {
  int hash = 0;
  for (final c in text.codeUnits) {
    hash = ((hash << 5) - hash + c) & 0xFFFFFFFF;
  }
  final hue = (hash & 0xFF) / 255.0 * 360;
  return HSLColor.fromAHSL(1.0, hue, 0.45, 0.45).toColor();
}
