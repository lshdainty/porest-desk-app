// 가리는 것과 플랫폼이 기억하는 것은 다른 축이다.
//
// Flutter 의 `TextField` 는 `obscureText` 로 `smartDashesType`·`smartQuotesType` 만 끈다
// (text_field.dart 생성자 initializer). `autocorrect`·`enableSuggestions`·
// `enableIMEPersonalizedLearning` 은 기본값 true 그대로 플랫폼에 내려가므로,
// **가려 놓고도 키보드 예측 사전에 남는다.** 이 테스트가 그 셋을 붙들어 둔다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

Widget _app(Widget child) => MaterialApp(
  theme: PorestTheme.dark(),
  home: Scaffold(body: Center(child: child)),
);

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

void main() {
  // 왜 PTextInput 이 직접 꺼야 하는지의 근거. 프레임워크가 언젠가 이걸 바꾸면
  // 여기서 먼저 깨지고, 그때 PTextInput 의 강제도 걷어낼 수 있다.
  testWidgets('Flutter 는 obscureText 로 예측·학습을 끄지 않는다', (tester) async {
    await tester.pumpWidget(_app(const TextField(obscureText: true)));

    final e = _editable(tester);
    expect(e.obscureText, isTrue);
    expect(e.autocorrect, isTrue, reason: 'obscureText 가 autocorrect 를 안 끈다');
    expect(
      e.enableSuggestions,
      isTrue,
      reason: 'obscureText 가 enableSuggestions 를 안 끈다',
    );
    expect(
      e.enableIMEPersonalizedLearning,
      isTrue,
      reason: 'obscureText 가 IME 개인화 학습을 안 끈다 — 가려도 사전에 남는다',
    );
  });

  testWidgets('평범한 입력칸은 예측·학습을 그대로 둔다 (대조군)', (tester) async {
    await tester.pumpWidget(_app(const PTextInput(placeholder: '메모')));

    final e = _editable(tester);
    expect(e.obscureText, isFalse);
    expect(e.autocorrect, isTrue);
    expect(e.enableSuggestions, isTrue);
    expect(
      e.enableIMEPersonalizedLearning,
      isTrue,
      reason: 'Flutter 기본값 — 이게 true 라서 자격증명 칸을 따로 꺼야 한다',
    );
  });

  testWidgets('obscureText 만 켜도 자격증명으로 취급한다', (tester) async {
    await tester.pumpWidget(
      _app(const PTextInput(placeholder: '비밀번호', obscureText: true)),
    );

    final e = _editable(tester);
    expect(e.obscureText, isTrue);
    expect(e.autocorrect, isFalse);
    expect(e.enableSuggestions, isFalse);
    expect(e.enableIMEPersonalizedLearning, isFalse);
  });

  testWidgets('secret 은 벗겨 보는 동안에도 학습을 막는다', (tester) async {
    // 보기 토글로 obscureText 가 false 가 된 순간이 바로 구멍이다.
    await tester.pumpWidget(
      _app(
        const PTextInput(
          placeholder: 'App Key',
          obscureText: false,
          secret: true,
        ),
      ),
    );

    final e = _editable(tester);
    expect(e.obscureText, isFalse, reason: '벗겨 본 상태');
    expect(e.autocorrect, isFalse);
    expect(e.enableSuggestions, isFalse);
    expect(e.enableIMEPersonalizedLearning, isFalse);
  });

  testWidgets('가려도 붙여넣기는 된다', (tester) async {
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);
    await tester.pumpWidget(
      _app(
        PTextInput(
          controller: ctrl,
          placeholder: 'App Key',
          obscureText: true,
          secret: true,
        ),
      ),
    );

    // 클립보드 붙여넣기와 같은 경로 — 컨트롤러/입력 커넥션으로 값이 통째로 들어온다.
    const pasted = 'PSb2xkZW4tc2VjcmV0LWtleS0xMjM0NTY3ODkw';
    await tester.enterText(find.byType(EditableText), pasted);
    await tester.pump();

    expect(ctrl.text, pasted);
    // 선택·복사·붙여넣기 경로를 막는 설정이 끼어들지 않았는지 같이 본다.
    expect(_editable(tester).selectionEnabled, isTrue);
  });
}
