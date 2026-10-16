// 금액 색(D1) — 수입만 fg-brand, 지출 · 이체는 fg-neutral. 빨강 · 파랑(critical · informative)은 증감 · 오류에만 쓴다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';

void main() {
  for (final dark in [false, true]) {
    test('금액 색 ${dark ? "다크" : "라이트"}', () {
      final theme = dark ? GrooTheme.dark() : GrooTheme.light();
      final c = theme.extension<PColors>()!;
      final t = theme.extension<GrooTokens>()!;
      expect(t.fgIncome, c.fgBrand, reason: '수입만 brand');
      expect(t.fgExpense, c.fgNeutral, reason: '지출은 neutral');
      expect(t.fgTransfer, c.fgNeutral, reason: '이체는 neutral');
      expect(t.statusDangerFg, c.fgCritical, reason: '오류 · 초과 · 증가');
      expect(t.statusInfoFg, c.fgInformative, reason: '감소');
    });
  }
}
