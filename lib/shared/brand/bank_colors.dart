import 'package:flutter/painting.dart';

/// 한국 은행/증권사/가상자산 거래소 브랜드 색.
/// porest-desk-front `shared/lib/porest/bank-colors.ts` 1:1 포팅.
class BrandColor {
  const BrandColor({required this.bg, this.fg = const Color(0xFFFFFFFF)});
  final Color bg;
  final Color fg;
}

class _BankEntry {
  const _BankEntry(this.name, this.color, [this.aliases = const <String>[]]);
  final String name;
  final BrandColor color;
  final List<String> aliases;
}

const _entries = <_BankEntry>[
  // 시중은행
  _BankEntry('신한', BrandColor(bg: Color(0xFF0046FF)), ['신한은행']),
  _BankEntry('KB국민', BrandColor(bg: Color(0xFFFFBC00), fg: Color(0xFF191919)),
      ['KB', '국민', 'KB국민은행']),
  _BankEntry('우리', BrandColor(bg: Color(0xFF0067AC)), ['우리은행']),
  _BankEntry('하나', BrandColor(bg: Color(0xFF008485)), ['KEB하나', '하나은행']),
  _BankEntry('NH농협', BrandColor(bg: Color(0xFF00A651)), ['농협', 'NH농협은행']),
  _BankEntry('IBK기업', BrandColor(bg: Color(0xFF004098)), ['기업', 'IBK', '기업은행']),
  _BankEntry('SC제일', BrandColor(bg: Color(0xFF009A44)), ['제일', 'SC', 'SC제일은행']),
  _BankEntry('씨티', BrandColor(bg: Color(0xFF056DAE)), ['시티', '씨티은행', '한국씨티']),

  // 인터넷은행
  _BankEntry('카카오뱅크',
      BrandColor(bg: Color(0xFFFEE500), fg: Color(0xFF191919)), ['카뱅']),
  _BankEntry('토스뱅크', BrandColor(bg: Color(0xFF0064FF)), ['토스']),
  _BankEntry('케이뱅크', BrandColor(bg: Color(0xFFFF6F20)), ['K뱅크', 'K Bank']),

  // 지방은행
  _BankEntry('부산', BrandColor(bg: Color(0xFF0033A0)), ['부산은행', 'BNK부산']),
  _BankEntry('대구', BrandColor(bg: Color(0xFF1464AC)),
      ['대구은행', 'iM뱅크', 'DGB대구']),
  _BankEntry('경남', BrandColor(bg: Color(0xFF0E4C92)), ['경남은행', 'BNK경남']),
  _BankEntry('광주', BrandColor(bg: Color(0xFF00428A)), ['광주은행', 'JB광주']),
  _BankEntry('전북', BrandColor(bg: Color(0xFF0F3E8C)), ['전북은행', 'JB전북']),
  _BankEntry('제주', BrandColor(bg: Color(0xFFF47216)), ['제주은행']),

  // 특수은행
  _BankEntry('KDB산업', BrandColor(bg: Color(0xFF004098)), ['산업', '산업은행', 'KDB']),
  _BankEntry('수출입', BrandColor(bg: Color(0xFF003A6C)), ['수출입은행', 'EXIM']),
  _BankEntry('수협', BrandColor(bg: Color(0xFF003DA5)), ['수협은행', 'Sh수협']),

  // 저축기관
  _BankEntry('우체국', BrandColor(bg: Color(0xFFE4002B)), ['우체국예금', '우체국금융']),
  _BankEntry('새마을금고', BrandColor(bg: Color(0xFFD61E29)), ['새마을', 'MG']),
  _BankEntry('신협', BrandColor(bg: Color(0xFF003A70)), ['신용협동조합']),
  _BankEntry('산림조합', BrandColor(bg: Color(0xFF2E7D32)), ['산림조합중앙회']),
  _BankEntry('SBI저축', BrandColor(bg: Color(0xFF0E3E85)), ['SBI저축은행', 'SBI']),
  _BankEntry('OK저축', BrandColor(bg: Color(0xFFFECC00), fg: Color(0xFF191919)),
      ['OK저축은행']),
  _BankEntry('웰컴저축', BrandColor(bg: Color(0xFFE30613)), ['웰컴저축은행']),
  _BankEntry('페퍼저축', BrandColor(bg: Color(0xFFB3002D)), ['페퍼저축은행', 'Pepper']),

  // 외국계
  _BankEntry('HSBC', BrandColor(bg: Color(0xFFDB0011)), ['홍콩상하이', '에이치에스비씨']),
  _BankEntry('ICBC', BrandColor(bg: Color(0xFFD6001C)), ['공상은행', '중국공상은행']),
  _BankEntry('BoA', BrandColor(bg: Color(0xFF012169)),
      ['뱅크오브아메리카', 'Bank of America']),
  _BankEntry('도이치', BrandColor(bg: Color(0xFF004A8F)), ['도이치뱅크', 'Deutsche']),
  _BankEntry('JP모건', BrandColor(bg: Color(0xFF006CB7)), ['JPMorgan', 'JP모건체이스']),

  // 기타
  _BankEntry('현금', BrandColor(bg: Color(0xFF64748B)), ['지갑', 'Cash']),

  // 증권사
  _BankEntry('삼성증권', BrandColor(bg: Color(0xFF1428A0)), ['삼성']),
  _BankEntry('미래에셋', BrandColor(bg: Color(0xFF2C3E50)), ['미래에셋증권']),
  _BankEntry('NH투자', BrandColor(bg: Color(0xFF00A651)), ['NH투자증권']),
  _BankEntry('한국투자', BrandColor(bg: Color(0xFF00529B)), ['한투', '한국투자증권']),
  _BankEntry('KB증권', BrandColor(bg: Color(0xFFFFBC00), fg: Color(0xFF191919))),
  _BankEntry('신한투자', BrandColor(bg: Color(0xFF0046FF)),
      ['신한금융투자', '신한투자증권']),
  _BankEntry('하나증권', BrandColor(bg: Color(0xFF008485))),
  _BankEntry('키움증권', BrandColor(bg: Color(0xFFFF0033)), ['키움']),
  _BankEntry('메리츠증권', BrandColor(bg: Color(0xFFE60012)),
      ['메리츠', '메리츠종합금융증권']),
  _BankEntry('대신증권', BrandColor(bg: Color(0xFFF58220)), ['대신']),
  _BankEntry('유안타증권', BrandColor(bg: Color(0xFF10B981)), ['유안타', '동양']),
  _BankEntry('유진투자', BrandColor(bg: Color(0xFF003595)), ['유진투자증권']),
  _BankEntry('교보증권', BrandColor(bg: Color(0xFF004A8F)), ['교보']),
  _BankEntry('IBK투자', BrandColor(bg: Color(0xFF004098)), ['IBK투자증권']),
  _BankEntry('DB금융투자', BrandColor(bg: Color(0xFF008456)), ['DB', 'DB금투']),
  _BankEntry('SK증권', BrandColor(bg: Color(0xFFEA002C)), ['SK']),
  _BankEntry('현대차증권', BrandColor(bg: Color(0xFF002C5F)), ['현대차', 'HMC투자']),
  _BankEntry('하이투자', BrandColor(bg: Color(0xFF004098)), ['하이투자증권']),
  _BankEntry('한화투자', BrandColor(bg: Color(0xFFFF7900)), ['한화투자증권', '한화']),
  _BankEntry('BNK투자', BrandColor(bg: Color(0xFF0033A0)), ['BNK투자증권']),
  _BankEntry('한양증권', BrandColor(bg: Color(0xFF004098)), ['한양']),
  _BankEntry('LS증권', BrandColor(bg: Color(0xFF005EB8)),
      ['이베스트', '이베스트투자', 'E-best']),
  _BankEntry('부국증권', BrandColor(bg: Color(0xFF003366)), ['부국']),
  _BankEntry('신영증권', BrandColor(bg: Color(0xFF005EB8)), ['신영']),
  _BankEntry('카카오페이증권',
      BrandColor(bg: Color(0xFFFEE500), fg: Color(0xFF191919)), ['카카오페이']),
  _BankEntry('토스증권', BrandColor(bg: Color(0xFF0064FF))),

  // 가상자산
  _BankEntry('업비트', BrandColor(bg: Color(0xFF1F55F4)),
      ['Upbit', 'UPBIT', '두나무']),
  _BankEntry('빗썸', BrandColor(bg: Color(0xFFF2811D)), ['Bithumb', 'BITHUMB']),
  _BankEntry('코인원', BrandColor(bg: Color(0xFFF55826)), ['Coinone', 'COINONE']),
  _BankEntry('코빗', BrandColor(bg: Color(0xFF1D3FFF)), ['Korbit', 'KORBIT']),
];

final Map<String, BrandColor> _brandMap = (() {
  final m = <String, BrandColor>{};
  for (final e in _entries) {
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
