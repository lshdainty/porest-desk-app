import 'package:flutter/painting.dart';

/// porest-desk-front `--shadow-*` 토큰 매핑.
///
/// CSS는 `0 1px 2px rgba(28,36,20,0.05)` 처럼 모씨 그린-블랙 톤. Flutter도 동일 색감.
abstract final class PShadow {
  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0D1C2414), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0F1C2414), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0A1C2414), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x141C2414), offset: Offset(0, 4), blurRadius: 8, spreadRadius: -2),
    BoxShadow(color: Color(0x0D1C2414), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -2),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1F1C2414), offset: Offset(0, 12), blurRadius: 24, spreadRadius: -6),
    BoxShadow(color: Color(0x0F1C2414), offset: Offset(0, 4), blurRadius: 8, spreadRadius: -4),
  ];
  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x2E1C2414), offset: Offset(0, 24), blurRadius: 48, spreadRadius: -12),
  ];

  // Dark — 단순한 검은 톤
  static const List<BoxShadow> xsDark = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> smDark = [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> mdDark = [
    BoxShadow(color: Color(0x73000000), offset: Offset(0, 4), blurRadius: 10),
  ];
  static const List<BoxShadow> lgDark = [
    BoxShadow(color: Color(0x8C000000), offset: Offset(0, 16), blurRadius: 32),
  ];
  static const List<BoxShadow> xlDark = [
    BoxShadow(color: Color(0xA6000000), offset: Offset(0, 32), blurRadius: 64),
  ];
}
