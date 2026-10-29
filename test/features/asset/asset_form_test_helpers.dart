// 자산 추가 · 수정 폼 시험의 공용 길잡이(I-17) — 칸을 "라벨 글" 로 찾는다. 폼의 칸은 ds Field 가 라벨을 쥐고 그 안에 입력이 있다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';

import '../../support/plain_text.dart';

/// 라벨이 [label] 인 Field.
Finder fieldWithLabel(String label) => find.byWidgetPredicate(
  (w) => w is PField && w.label != null && plainOf(w.label!) == label,
  description: 'PField "$label"',
);

/// 그 Field 안의 글 입력(TextField) — 금액 · 별칭 · 메모 칸.
Finder inputOf(String label) => find.descendant(
  of: fieldWithLabel(label),
  matching: find.byType(TextField),
);

/// 그 Field 안의 PInput(단위 글자 · 읽기 전용 같은 속성을 본다).
Finder pInputOf(String label) =>
    find.descendant(of: fieldWithLabel(label), matching: find.byType(PInput));

/// 라벨이 [label] 인 바닥 / 단추 PButton.
Finder buttonLabeled(String label) => find.byWidgetPredicate(
  (w) => w is PButton && w.label != null && plainOf(w.label!) == label,
  description: 'PButton "$label"',
);

/// 그 Field 의 뒤 단위 글자.
String? unitOf(WidgetTester tester, String label) =>
    tester.widget<PInput>(pInputOf(label)).suffixText;

/// 그 Field 의 읽기 전용 여부.
bool readOnlyOf(WidgetTester tester, String label) =>
    tester.widget<PInput>(pInputOf(label)).readOnly ?? false;

/// 입력칸에 글을 넣는다.
Future<void> typeInto(WidgetTester tester, String label, String text) async {
  await tester.enterText(inputOf(label), text);
  await tester.pumpAndSettle();
}

/// 입력칸이 지금 보이는 글.
String textOf(WidgetTester tester, String label) =>
    tester.widget<TextField>(inputOf(label)).controller!.text;

/// 카드 상품 칸을 눌러 고르기 시트를 열고 [name] 줄을 고른다(고르면 시트가 닫힌다).
Future<void> pickCardProduct(
  WidgetTester tester,
  String fieldLabel,
  String name,
) async {
  await tester.tap(
    find.descendant(
      of: fieldWithLabel(fieldLabel),
      matching: find.byType(PInputButton),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(findPlain(name).last);
  await tester.pumpAndSettle();
}
