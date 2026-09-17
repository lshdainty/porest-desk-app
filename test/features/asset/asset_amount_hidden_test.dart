// 자산별 금액 숨김 — **두 축이 합집합인가**, 그리고 폼이 그 값을 잃지 않는가.
//
// 화면 카드 가리기는 "이 화면의 이 묶음을 가린다" 는 사용자 설정이고, 자산 숨김은
// "이 자산은 늘 가린다" 는 자산의 속성이다. 한쪽이 다른 쪽을 덮으면 켜 둔 것이 왜
// 안 듣는지 사용자가 알 수 없다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations_en.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations_ko.dart';
import 'package:porest_desk_app/shared/widgets/masked_amount.dart';

Future<String> pumpAmount(
  WidgetTester tester, {
  required bool cardHidden,
  required bool force,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hideCardProvider.overrideWith((ref, card) => cardHidden)],
      child: MaterialApp(
        home: Scaffold(
          body: MaskedAmount(
            12000,
            card: 'asset.accounts',
            force: force,
            suffix: '',
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final text = tester.widget<Text>(find.byType(Text));
  return text.data ?? '';
}

void main() {
  group('MaskedAmount force — 합집합', () {
    testWidgets('둘 다 꺼져 있으면 금액이 보인다', (tester) async {
      final t = await pumpAmount(tester, cardHidden: false, force: false);
      expect(t, contains('12,000'));
    });

    testWidgets('자산만 가려도 가려진다 — 카드 설정과 무관하다', (tester) async {
      final t = await pumpAmount(tester, cardHidden: false, force: true);
      expect(t, contains('••'));
    });

    testWidgets('카드만 가려도 가려진다 — 종전 동작 그대로', (tester) async {
      final t = await pumpAmount(tester, cardHidden: true, force: false);
      expect(t, contains('••'));
    });

    // 합집합이라는 뜻 — 자산을 안 가려 뒀다고 카드 설정이 풀리면 안 된다.
    testWidgets('카드가 가리고 있으면 force=false 가 그걸 풀지 않는다', (tester) async {
      final t = await pumpAmount(tester, cardHidden: true, force: false);
      expect(t, contains('••'));
    });
  });

  group('문구', () {
    test('배지와 스위치 문구가 ko·en 양쪽에 있다', () {
      for (final l in [AppLocalizationsKo(), AppLocalizationsEn()]) {
        expect(l.assetAmountHiddenBadge, isNotEmpty);
        expect(l.assetHideThisAmount, isNotEmpty);
        expect(l.assetHideThisAmountDesc, isNotEmpty);
      }
    });

    // 합계는 이 값을 보지 않는다(사용자 결정) — 설명이 그걸 분명히 해야 한다.
    test('설명이 "합계는 그대로" 를 말한다', () {
      expect(AppLocalizationsKo().assetHideThisAmountDesc, contains('합계'));
      expect(AppLocalizationsEn().assetHideThisAmountDesc, contains('Totals'));
    });

    // 화면 단위 토글(`assetHideAmount`)과 뜻이 다르므로 키를 갈라 둔다.
    test('화면 단위 토글 문구와 섞이지 않는다', () {
      final ko = AppLocalizationsKo();
      expect(ko.assetHideThisAmount, isNot(equals(ko.assetHideAmount)));
    });
  });
}
