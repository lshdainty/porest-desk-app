import 'package:flutter/painting.dart';

/// DESIGN.desk.md `rounded.*` spec 매핑.
///
/// xs(2) / sm(4) / md(8) / lg(12) / xl(16) / xl2(20) / full(9999).
/// (spec 의 `2xl` 은 Dart identifier 제약으로 `xl2` 로 명명.)
abstract final class PRadius {
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xl2 = 20;
  static const double full = 9999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brXl2 = BorderRadius.all(Radius.circular(xl2));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));

  /// 카테고리/자산 아이콘 타일 corner radius — 크기 비례(round(size×0.3))로 어느
  /// 크기에서나 동일한 둥글기 유지. 기준 40px→12px(=lg). 고정 radius 를 작은 타일에
  /// 쓰면 원에 가까워져 더 둥글어 보이는 문제 방지. 웹 `tileRadius(size)` 정합.
  /// 28→8 / 32→10 / 36→11 / 38→11 / 40→12 / 44→13 / 48→14.
  static BorderRadius tile(double size) =>
      BorderRadius.all(Radius.circular((size * 0.3).roundToDouble()));
}
