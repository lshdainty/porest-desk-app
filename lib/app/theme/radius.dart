import 'package:flutter/painting.dart';

/// porest-desk-front `--radius-*` 토큰 매핑.
abstract final class PRadius {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double tile = 10; // category tile, pill button bg
  static const double lg = 12;
  static const double card = 14; // tx-row card, dashboard card
  static const double xl = 16;
  static const double xl2 = 20;
  static const double pill = 999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brTile = BorderRadius.all(Radius.circular(tile));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brCard = BorderRadius.all(Radius.circular(card));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brXl2 = BorderRadius.all(Radius.circular(xl2));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));
}
