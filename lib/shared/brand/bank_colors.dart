import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/image_frame/p_card_art.dart'
    show institutionTextColor;
import 'package:groo_damda_app/shared/ds/institution_colors/institution_colors.dart';

/// 기관 색 표는 하나다 — groo-design `institution-colors.yaml`(스펙 JSON → `institution_colors.g.dart` →
/// [PInstitutionColors]). 이 파일은 자산 추가 다이얼로그의 섹션(은행 · 증권 · 거래소 · 가상자산)과 색 찾기를 그 표 위에
/// 얹은 얇은 길일 뿐이고, 색 값을 손으로 옮겨 적은 표(옛 `bank-colors.ts` 1:1 포팅)는 걷었다(03E-010).
class BrandColor {
  const BrandColor({required this.bg, this.text = PInstitutionText.white});

  /// 면 색 — 모드를 따르지 않는다.
  final Color bg;

  /// 표의 글자색 이름 — 흰 글자가 4.5 미만이면 짙은 글자(dark).
  final PInstitutionText text;

  /// 면 위 글자색(모드를 따라 고른다 — white 는 static-white, dark 는 fg-neutral · 다크 fg-neutral-inverted).
  Color fgOf(BuildContext context) => institutionTextColor(context, text);
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

  /// 표의 묶음 이름(institution-colors.yaml `category`).
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

BankCategory? _categoryOf(String label) {
  for (final c in BankCategory.values) {
    if (c.label == label) return c;
  }
  return null;
}

PInstitutionTable? _builtFor;
List<BankEntry> _built = const [];
Map<BankCategory, List<BankEntry>> _builtByCategory = const {};

void _ensureBuilt() {
  final table = PInstitutionColors.table;
  if (identical(table, _builtFor)) return;
  _built = List.unmodifiable([
    for (final e in table.entries)
      if (_categoryOf(e.category) case final category?)
        BankEntry(
          name: e.name,
          category: category,
          color: BrandColor(bg: e.color, text: e.text),
          aliases: e.aliases,
        ),
  ]);
  final byCategory = <BankCategory, List<BankEntry>>{};
  for (final e in _built) {
    (byCategory[e.category] ??= <BankEntry>[]).add(e);
  }
  _builtByCategory = byCategory;
  _builtFor = table;
}

/// 자산 추가 다이얼로그가 보이는 기관 — 표에서 "카드사" 묶음을 뺀 것(카드는 카드 카탈로그로 고른다). 표의 차례 그대로.
List<BankEntry> get bankEntries {
  _ensureBuilt();
  return _built;
}

/// 카테고리별로 묶인 은행·증권사 리스트 — 다이얼로그 섹션 헤더용.
Map<BankCategory, List<BankEntry>> get bankEntriesByCategory {
  _ensureBuilt();
  return _builtByCategory;
}

/// 기관 이름 → 기관 색. 후보를 차례로 찾는다(기관 이름 → 자산 이름). 표에 없으면 null.
BrandColor? getBrandColor(List<String?> candidates) {
  for (final name in candidates) {
    final hit = PInstitutionColors.find(name);
    if (hit != null) return BrandColor(bg: hit.color, text: hit.text);
  }
  return null;
}
