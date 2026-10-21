// Card Art 의 글이 안 드는 면(03-D 결정 3 A, card-art.yaml label.fit) — 면 높이가 (회사 줄 + 카드 이름 한 줄) × 글자 배율
// + 아래 여백보다 낮으면 회사 이름 · 카드 이름 대신 회사 첫 글자 면(small 과 같은 모양)으로 바뀐다.
// 웹은 틀 높이 컨테이너 쿼리(medium `calc(2.1875rem + 8px)` · large `calc(2.5rem + 14px)`), 앱은 같은 식을 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/image_frame/p_card_art.dart';

import '../../support/design_spec.dart';

final _card = DesignSpec.load('card-art');

Widget _host(double width, {Brightness mode = Brightness.light}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: PCardArt(issuer: '신한카드', name: '딥드림 체크', width: width),
    ),
  ),
);

Finder _text(String s) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').replaceAll('⁠', '') == s,
);

void main() {
  test('스펙 — 안 들면 첫 글자 면', () {
    expect(_card.resolve({}, 'enabled')['label.fit'], '안 들면 첫 글자 면');
  });

  group('식 — 면 높이 ≥ (회사 줄 + 카드 이름 한 줄) × 배율 + 아래 여백', () {
    bool fits(
      double h,
      PCardArtSize size,
      double s,
      double issuer,
      double name,
    ) => cardArtLabelFits(
      height: h,
      size: size,
      textScaler: TextScaler.linear(s),
      issuerLine: issuer,
      nameLine: name,
    );

    test('medium — 16 + 19 = 35 × 배율 + 8', () {
      expect(fits(43, PCardArtSize.medium, 1, 16, 19), isTrue);
      expect(fits(42.9, PCardArtSize.medium, 1, 16, 19), isFalse);
      // 200% — 70 + 8 = 78
      expect(fits(78, PCardArtSize.medium, 2, 16, 19), isTrue);
      expect(fits(77.9, PCardArtSize.medium, 2, 16, 19), isFalse);
    });

    test('large — 18 + 22 = 40 × 배율 + 14', () {
      expect(fits(54, PCardArtSize.large, 1, 18, 22), isTrue);
      expect(fits(53.9, PCardArtSize.large, 1, 18, 22), isFalse);
      // 200% — 80 + 14 = 94 (스펙 노트: large 는 200% 에서도 든다 — 폭 240 면 높이 151)
      expect(fits(94, PCardArtSize.large, 2, 18, 22), isTrue);
      expect(fits(240 / 1.586, PCardArtSize.large, 2, 18, 22), isTrue);
    });
  });

  group('그려진 면', () {
    // 폭 96 ~ 123 (높이 60.5 ~ 77.6) 에서 글자 200% 면 78 이 넘친다
    for (final mode in Brightness.values) {
      for (final (width, scale, label) in [
        (96.0, 1.0, true),
        (
          96.0,
          1.5,
          true,
        ), // 3 + ... = 52.5 + 8 = 60.5 — 딱 들어간다(96 / 1.586 = 60.53)
        (96.0, 2.0, false),
        (123.0, 2.0, false),
        (124.0, 2.0, true),
        (160.0, 2.0, true),
        (240.0, 2.0, true), // large 는 200% 에서도 든다
      ]) {
        testWidgets('${mode.name} 폭 $width · 글자 ${(scale * 100).round()}% — '
            '${label ? '회사 · 카드 이름' : '첫 글자'}', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          await tester.pumpWidget(_host(width, mode: mode));
          expect(_text('신한카드'), label ? findsOneWidget : findsNothing);
          expect(_text('딥드림 체크'), label ? findsOneWidget : findsNothing);
          expect(_text('신'), label ? findsNothing : findsOneWidget);
          if (!label) {
            // 작은 면과 같은 모양 — 면 높이의 40%, 글자 배율을 따르지 않는다
            final initial = tester.widget<Text>(_text('신'));
            expect(initial.style!.fontSize, cardArtInitialSize(width / 1.586));
            expect(initial.textScaler, TextScaler.noScaling);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
