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
}
