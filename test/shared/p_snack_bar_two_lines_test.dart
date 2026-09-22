// 토스트 제목은 2줄까지(sonner.md ⓒ) — 실제 글꼴(Pretendard)로 폰 폭마다 잰다.
//
// 테스트 기본 글꼴은 글자마다 네모 한 칸이라 한글 폭이 실제와 다르다. 줄 수는 글꼴에
// 달렸으니 앱이 쓰는 Pretendard 를 파일에서 읽어 올린다.
//
// 결제가 끝난 회차 안내([잔액 고치기])가 폰에서 3줄로 접혔다(2026-09-22). 버튼을 글
// 옆에 두면 글 폭이 버튼만큼 줄고, SnackBar 의 content 글꼴 자간(0.25)까지 물려받아
// 390 폭에서도 3줄이었다. 버튼을 아래 줄로 내리고 자간을 0 으로 두면 2줄이다.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

Future<void> _loadPretendard() async {
  final bytes = File('assets/fonts/PretendardVariable.ttf').readAsBytesSync();
  final loader = FontLoader('Pretendard')
    ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  await loader.load();
}

Future<void> _show(
  WidgetTester tester,
  double width,
  String message, {
  String? actionLabel,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      theme: PorestTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  showPSnackBar(
    ctx,
    message,
    severity: PSnackSeverity.info,
    duration: const Duration(seconds: 6),
    actionLabel: actionLabel,
    onAction: actionLabel == null ? null : () {},
  );
  await tester.pumpAndSettle();
}

int _lines(WidgetTester tester, String message) {
  final p = tester.renderObject<RenderParagraph>(find.text(message));
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: message.length),
  );
  return boxes.map((b) => b.top.round()).toSet().length;
}

void main() {
  setUpAll(_loadPretendard);
  final l = lookupAppLocalizations(const Locale('ko'));

  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('폭 $width — 결제가 끝난 회차 안내는 버튼이 있어도 2줄', (tester) async {
      await _show(
        tester,
        width,
        l.expClosedCycleLine,
        actionLabel: l.expFixBalance,
      );
      expect(_lines(tester, l.expClosedCycleLine), lessThanOrEqualTo(2));
    });
  }

  testWidgets('제목 자간은 0 — SnackBar content 글꼴의 0.25 를 물려받지 않는다', (
    tester,
  ) async {
    await _show(
      tester,
      390,
      l.expClosedCycleLine,
      actionLabel: l.expFixBalance,
    );
    final p = tester.renderObject<RenderParagraph>(
      find.text(l.expClosedCycleLine),
    );
    expect(p.text.style?.letterSpacing, 0);
  });

  testWidgets('아이콘은 제목 첫 줄에 붙는다 — 두 줄이어도 가운데로 안 내려간다', (tester) async {
    await _show(
      tester,
      360,
      l.expClosedCycleLine,
      actionLabel: l.expFixBalance,
    );
    final icon = tester.getRect(find.byIcon(LucideIcons.info));
    final text = tester.getRect(find.text(l.expClosedCycleLine));
    // 첫 줄 높이 16 × 1.4 = 22.4 안에 아이콘(20)이 든다 — margin-top 2.
    expect(icon.top, moreOrLessEquals(text.top + 2, epsilon: 0.5));
  });
}
