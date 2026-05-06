import 'package:flutter/material.dart';

/// 카테고리 팔레트 (hex). 모바일에서 새로 생성하는 카테고리는 hex 로 저장 →
/// 웹/앱 양쪽에서 공통으로 표시 가능.
class CatPalette {
  const CatPalette(this.color);
  final Color color;

  static const List<CatPalette> all = [
    CatPalette(Color(0xFFB45A2E)), // 따뜻한 오렌지
    CatPalette(Color(0xFF7B6E47)), // 베이지/카키
    CatPalette(Color(0xFF3F6FB0)), // 블루
    CatPalette(Color(0xFFB04C8F)), // 핑크
    CatPalette(Color(0xFF4F8A55)), // 그린
    CatPalette(Color(0xFFC04A3A)), // 레드
    CatPalette(Color(0xFF7E55A8)), // 퍼플
    CatPalette(Color(0xFF5C6E72)), // 그레이
    CatPalette(Color(0xFF3589A8)), // 시안
    CatPalette(Color(0xFF8B5E3C)), // 브라운
    CatPalette(Color(0xFF5E7A2E)), // 올리브
    CatPalette(Color(0xFFC04060)), // 매그놀리아
  ];

  static const List<String> icons = [
    'utensils', 'coffee', 'bus', 'shopping-bag', 'home', 'heart',
    'gift', 'piggy-bank', 'book-open', 'car', 'plane',
    'dumbbell', 'gamepad-2', 'film', 'music',
    'shirt', 'wrench', 'fuel', 'pill', 'phone', 'wifi',
    'tv', 'briefcase', 'graduation-cap',
    'trending-up', 'banknote', 'landmark', 'tag',
    'credit-card', 'wallet',
  ];

  String toHex() {
    final v = color.toARGB32() & 0xFFFFFF;
    return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static int? indexByColor(String? raw) {
    if (raw == null) return null;
    for (int i = 0; i < all.length; i++) {
      if (all[i].toHex().toLowerCase() == raw.toLowerCase()) return i;
    }
    return null;
  }
}
