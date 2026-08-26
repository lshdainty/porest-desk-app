// 증권사 API Key 는 시크릿과 짝이 되는 자격증명의 반쪽이다.
// 한동안 Key 만 평문으로 떠 있었다 — 다시 벗겨지면 여기서 깨진다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/subscription/data/subscription_repository.dart';
import 'package:porest_desk_app/features/subscription/presentation/broker_connect_card.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

// 라벨은 서버가 준다 — 나무는 App Key/App Secret, 토스는 Client ID/Client Secret.
const _conn = BrokerConnection(
  broker: 'NAMU',
  displayName: '나무증권',
  issueUrl: 'https://example.test/issue',
  keyLabel: 'App Key',
  secretLabel: 'App Secret',
  connected: false,
  verified: false,
  primary: false,
);

Widget _app() => ProviderScope(
      child: MaterialApp(
        theme: PorestTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: BrokerConnectCard(
              connection: _conn,
              showPrimaryAction: false,
            ),
          ),
        ),
      ),
    );

/// 서버가 준 라벨이 그대로 placeholder 라 그걸로 칸을 집는다.
EditableText _fieldFor(WidgetTester tester, String label) {
  final field = tester
      .widgetList<TextField>(find.byType(TextField))
      .firstWhere((f) => f.decoration?.hintText == label,
          orElse: () => throw StateError('"$label" 입력칸을 못 찾았다'));
  return tester.widgetList<EditableText>(find.byType(EditableText)).firstWhere(
      (e) => e.controller == field.controller,
      orElse: () => throw StateError('"$label" 의 EditableText 를 못 찾았다'));
}

void main() {
  testWidgets('Key 와 Secret 둘 다 처음엔 가려져 있다', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    for (final label in ['App Key', 'App Secret']) {
      final e = _fieldFor(tester, label);
      expect(e.obscureText, isTrue, reason: '$label 이 평문으로 보인다');
      // 가리는 것만으론 부족하다 — 키보드 사전에 남으면 다른 앱에서 예측으로 뜬다.
      expect(e.autocorrect, isFalse, reason: '$label autocorrect');
      expect(e.enableSuggestions, isFalse, reason: '$label enableSuggestions');
      expect(e.enableIMEPersonalizedLearning, isFalse,
          reason: '$label IME 개인화 학습');
    }
  });

  testWidgets('붙여넣은 키가 그대로 들어간다', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    const key = 'PSxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
    const secret = 'SEyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy';
    await tester.enterText(_finderFor(tester, 'App Key'), key);
    await tester.enterText(_finderFor(tester, 'App Secret'), secret);
    await tester.pump();

    expect(_fieldFor(tester, 'App Key').controller.text, key);
    expect(_fieldFor(tester, 'App Secret').controller.text, secret);
  });

  testWidgets('눈 아이콘으로 잠깐 벗겨 봐도 학습은 계속 막힌다', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    // 서버 라벨이 그대로 토글 이름이 된다 — 칸이 둘이라 이름이 달라야 구분된다.
    final keyToggle = find.bySemanticsLabel('App Key 표시 전환');
    expect(keyToggle, findsOneWidget);

    await tester.tap(keyToggle);
    await tester.pump();

    final key = _fieldFor(tester, 'App Key');
    expect(key.obscureText, isFalse, reason: '토글이 안 먹었다');
    expect(key.enableIMEPersonalizedLearning, isFalse,
        reason: '벗겨 본 동안이 오히려 학습이 열리는 구멍이다');
    expect(key.autocorrect, isFalse);
    expect(key.enableSuggestions, isFalse);

    // 다른 칸은 건드리지 않는다.
    expect(_fieldFor(tester, 'App Secret').obscureText, isTrue);

    // 다시 누르면 가려진다.
    await tester.tap(keyToggle);
    await tester.pump();
    expect(_fieldFor(tester, 'App Key').obscureText, isTrue);
  });
}

Finder _finderFor(WidgetTester tester, String label) {
  final target = _fieldFor(tester, label);
  return find.byWidgetPredicate(
      (w) => w is EditableText && w.controller == target.controller);
}
