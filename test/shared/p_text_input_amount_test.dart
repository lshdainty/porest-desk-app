// 금액칸의 입력 정책 — 부호·소수 차단(QA #10)과 값 상한(QA #12).
//
// `numbersOnly` 는 '숫자만' 이라는 계약이다. 예전 `inputFormatters ?? …` 는
// 호출부가 포매터를 하나라도 주면 digitsOnly 를 조용히 버렸다 — 상한 포매터를
// 얹는 순간 밟는 함정이라 합성으로 바꿨고, 그 계약을 여기서 고정한다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/format/amount_limits.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

Future<TextEditingController> _pump(
  WidgetTester tester, {
  int? amountMax,
  List<TextInputFormatter>? inputFormatters,
}) async {
  final ctrl = TextEditingController();
  await tester.pumpWidget(
    MaterialApp(
      theme: PorestTheme.light(),
      home: Scaffold(
        body: PTextInput(
          controller: ctrl,
          numbersOnly: true,
          amountMax: amountMax,
          inputFormatters: inputFormatters,
        ),
      ),
    ),
  );
  return ctrl;
}

void main() {
  testWidgets('numbersOnly 는 부호와 소수점을 아예 안 받는다', (tester) async {
    final ctrl = await _pump(tester);
    await tester.enterText(find.byType(TextField), '-1');
    expect(ctrl.text, '1');
    await tester.enterText(find.byType(TextField), '1000.5');
    expect(ctrl.text, '10005');
  });

  testWidgets('호출부가 포매터를 줘도 digitsOnly 는 살아 있다', (tester) async {
    final ctrl = await _pump(
      tester,
      inputFormatters: [LengthLimitingTextInputFormatter(3)],
    );
    await tester.enterText(find.byType(TextField), '12a345');
    expect(ctrl.text, '123');
  });

  testWidgets('amountMax 를 넘는 값은 타이핑 자체가 안 된다', (tester) async {
    final ctrl = await _pump(tester, amountMax: kAmountMax);
    // 100억 정각까지는 들어간다.
    await tester.enterText(find.byType(TextField), '10000000000');
    expect(ctrl.text, '10000000000');
    // QA 가 웹에서 친 999억 — 자릿수만 세는 방식이면 통과했을 값.
    await tester.enterText(find.byType(TextField), '99999999999');
    expect(ctrl.text, '10000000000');
  });

  testWidgets('잔액칸은 1,000억까지 — 거래 상한과 별개다', (tester) async {
    final ctrl = await _pump(tester, amountMax: kBalanceMax);
    await tester.enterText(find.byType(TextField), '100000000000');
    expect(ctrl.text, '100000000000');
    // QA 가 만든 99조.
    await tester.enterText(find.byType(TextField), '99999999999999');
    expect(ctrl.text, '100000000000');
  });
}
