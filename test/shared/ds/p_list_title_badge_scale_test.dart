// List 줄 제목 옆 배지(titleSuffix) — WidgetSpan 은 자리째 글자 배율을 받는데 배지 안 글자도 이미 배율을 받아
// 배율이 두 번 걸리던 결함. 기준: 200% 에서 줄 안 배지 크기 == 홀로 둔 PBadge 크기, 100% 에서는 그대로.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

Future<void> _pump(WidgetTester tester, Widget child, double scale) async {
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  const badge = PBadge(label: '오늘의 목표');

  Future<Size> inRow(WidgetTester tester, double scale) async {
    await _pump(
      tester,
      const PList(
        children: [
          PListItem(title: '관측 리포트', titleSuffix: [badge]),
        ],
      ),
      scale,
    );
    // getRect 는 그려지는 크기(WidgetSpan 배율 포함)다 — getSize 는 배율 전 크기라 결함을 못 본다
    return tester.getRect(find.byType(PBadge)).size;
  }

  Future<Size> alone(WidgetTester tester, double scale) async {
    await _pump(tester, const Row(children: [badge]), scale);
    // getRect 는 그려지는 크기(WidgetSpan 배율 포함)다 — getSize 는 배율 전 크기라 결함을 못 본다
    return tester.getRect(find.byType(PBadge)).size;
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('${(scale * 100).round()}% — 줄 안 배지 크기 == 홀로 둔 배지', (
      tester,
    ) async {
      final solo = await alone(tester, scale);
      final inside = await inRow(tester, scale);
      expect(inside.width, closeTo(solo.width, 0.5));
      expect(inside.height, closeTo(solo.height, 0.5));
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('${(scale * 100).round()}% — 제목 ↔ 배지 간격은 배율과 상관없이 6', (
      tester,
    ) async {
      await _pump(
        tester,
        const PList(
          children: [
            PListItem(title: '식비', titleSuffix: [badge]),
          ],
        ),
        scale,
      );
      // 제목 글 오른쪽 끝(마지막 글자)과 배지 왼쪽 — 제목 상자는 줄 폭이라 글 끝을 따로 잰다
      final title = find.byKey(const ValueKey('plist-title'));
      final rp = tester.renderObject<RenderParagraph>(title);
      final boxes = rp.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: keepAll('식비').length),
      );
      final textEnd = tester.getTopLeft(title).dx + boxes.last.right;
      final badgeLeft = tester.getRect(find.byType(PBadge)).left;
      expect(badgeLeft - textEnd, closeTo(6, 0.6));
    });
  }

  testWidgets('좁은 줄 · 200% — 긴 배지 글의 말줄임 시작점이 홀로 둔 배지와 같다', (tester) async {
    const long = PBadge(label: '아주 긴 배지 글자가 줄 폭을 넘어서 말줄임이 되는 경우');
    await _pump(
      tester,
      const PList(
        children: [
          PListItem(title: '제목', titleSuffix: [long]),
        ],
      ),
      2,
    );
    final available = tester
        .getSize(find.byKey(const ValueKey('plist-title')))
        .width;
    final inside = tester.getRect(find.byType(PBadge));
    // 줄 안에서 배지가 쓸 수 있는 폭 = 제목 칸 폭 − 간격 6
    await _pump(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: available - 6),
          child: const Row(children: [Flexible(child: long)]),
        ),
      ),
      2,
    );
    final solo = tester.getRect(find.byType(PBadge));
    expect(inside.width, closeTo(solo.width, 0.5));
    expect(inside.height, closeTo(solo.height, 0.5));
  });
}
