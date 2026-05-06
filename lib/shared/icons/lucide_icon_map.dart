import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 백엔드 카테고리/자산 `icon` 컬럼 (lucide-react 이름) → Flutter `IconData` 매핑.
///
/// front 의 `iconNameToPascal('shopping-bag')` → `ShoppingBag` 같은 식으로
/// kebab-case / camelCase / lower 셋 다 정규화해서 lookup.
IconData lucideByName(String? name, {IconData fallback = LucideIcons.tag}) {
  if (name == null || name.isEmpty) return fallback;
  final key = _normalize(name);
  return _byName[key] ?? fallback;
}

String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[-_\s]'), '');

/// 자주 쓰이는 lucide 아이콘만 등록. 누락 시 [`lucideByName`] 의 fallback (tag) 사용.
final Map<String, IconData> _byName = {
  // food / drink
  'utensils': LucideIcons.utensils,
  'coffee': LucideIcons.coffee,
  'beer': LucideIcons.beer,
  'wine': LucideIcons.wine,
  'pizza': LucideIcons.pizza,
  'cookie': LucideIcons.cookie,
  'candy': LucideIcons.candy,
  // transport
  'car': LucideIcons.car,
  'bus': LucideIcons.bus,
  'train': LucideIcons.train,
  'plane': LucideIcons.plane,
  'bike': LucideIcons.bike,
  'fuel': LucideIcons.fuel,
  // shopping / living
  'shoppingbag': LucideIcons.shoppingBag,
  'shoppingcart': LucideIcons.shoppingCart,
  'shirt': LucideIcons.shirt,
  'home': LucideIcons.home,
  'building': LucideIcons.building,
  'briefcase': LucideIcons.briefcase,
  // medical
  'cross': LucideIcons.cross,
  'pill': LucideIcons.pill,
  'heart': LucideIcons.heart,
  'stethoscope': LucideIcons.stethoscope,
  // leisure
  'gamepad': LucideIcons.gamepad,
  'gamepad2': LucideIcons.gamepad2,
  'film': LucideIcons.film,
  'music': LucideIcons.music,
  'dumbbell': LucideIcons.dumbbell,
  // bill / utility
  'filetext': LucideIcons.fileText,
  'receipt': LucideIcons.receipt,
  'lightbulb': LucideIcons.lightbulb,
  'wifi': LucideIcons.wifi,
  'phone': LucideIcons.phone,
  // education
  'book': LucideIcons.book,
  'bookopen': LucideIcons.bookOpen,
  'graduationcap': LucideIcons.graduationCap,
  'pencil': LucideIcons.pencil,
  // money / finance
  'piggybank': LucideIcons.piggyBank,
  'wallet': LucideIcons.wallet,
  'banknote': LucideIcons.banknote,
  'creditcard': LucideIcons.creditCard,
  'landmark': LucideIcons.landmark,
  'coins': LucideIcons.coins,
  'trendingup': LucideIcons.trendingUp,
  'trendingdown': LucideIcons.trendingDown,
  // misc
  'gift': LucideIcons.gift,
  'tag': LucideIcons.tag,
  'star': LucideIcons.star,
  'circle': LucideIcons.circle,
};

/// 자산 타입 fallback 아이콘.
IconData assetTypeIcon(String type) => switch (type.toUpperCase()) {
      'CASH' => LucideIcons.banknote,
      'CARD' => LucideIcons.creditCard,
      'BANK_ACCOUNT' || 'ACCOUNT' || 'SAVINGS' => LucideIcons.landmark,
      'INVESTMENT' || 'STOCK' => LucideIcons.trendingUp,
      _ => LucideIcons.wallet,
    };
