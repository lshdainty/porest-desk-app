// I-06 이 ds 에 더한 자리 — 카드 머리 덧붙임(10) · 목록 줄 제목 뒤 배지 · 취소선 · 좌우 여백 · 도넛 범례 좁은 줄 · Progress 이름 줄.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 360,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width * 2, 1600);
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
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('PCardHeader.titleSuffix', () {
    Widget header({Widget? suffix}) => PCardScope(
      variant: PCardVariant.standard,
      body: PCardBody.content,
      child: PCardHeader(
        title: '최근 할 일',
        actionLabel: '전체 보기',
        onAction: () {},
        titleSuffix: suffix,
      ),
    );

    testWidgets('덧붙임이 제목 바로 뒤 같은 줄에 선다(제목 ↔ 덧붙임 6)', (tester) async {
      await _pump(tester, header(suffix: const PBadge(label: '연체 23건')));
      final title = tester.getRect(find.byKey(const ValueKey('card-title')));
      final badge = tester.getRect(find.byType(PBadge));
      expect(badge.left - title.right, closeTo(6, 0.5));
      expect((badge.center.dy - title.center.dy).abs(), lessThan(2));
    });

    testWidgets('의미 트리에서 header 는 제목 글만 — 덧붙임이 이름에 섞이지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, header(suffix: const PBadge(label: '연체 23건')));
      final node = tester.getSemantics(find.bySemanticsLabel('최근 할 일'));
      expect(node.flagsCollection.isHeader, isTrue);
      expect(node.label, '최근 할 일');
      expect(find.bySemanticsLabel('최근 할 일 연체 23건'), findsNothing);
      handle.dispose();
    });

    testWidgets('200% 에서 좁으면 덧붙임이 다음 줄로 — 넘침 없음', (tester) async {
      await _pump(
        tester,
        header(suffix: const PBadge(label: '연체 23건')),
        width: 320,
        scale: 2,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('덧붙임이 없으면 이전 모양 그대로(Wrap 없음)', (tester) async {
      await _pump(tester, header());
      expect(find.byKey(const ValueKey('card-title-wrap')), findsNothing);
    });
  });

  group('PListItem 확장', () {
    testWidgets('제목 뒤 배지가 제목과 이어 붙는다', (tester) async {
      await _pump(
        tester,
        const PList(
          children: [
            PListItem(
              title: '골목 찌개집',
              titleSuffix: [PBadge(label: '예정')],
            ),
          ],
        ),
      );
      final title = tester.getRect(find.byKey(const ValueKey('plist-title')));
      final badge = tester.getRect(find.byType(PBadge));
      expect(badge.left, greaterThan(title.left));
      expect(badge.top, greaterThanOrEqualTo(title.top - 1));
      expect(badge.bottom, lessThanOrEqualTo(title.bottom + 1));
    });

    testWidgets('취소선 · gutter 0 이면 좌우 여백 0', (tester) async {
      await _pump(
        tester,
        const PList(
          children: [
            PListItem(title: '완료', titleStrike: true, gutter: 0),
            PListItem(title: '기본'),
          ],
        ),
      );
      final titles = tester
          .widgetList<Text>(find.byKey(const ValueKey('plist-title')))
          .toList();
      expect(titles.first.style?.decoration, TextDecoration.lineThrough);
      final lefts = tester
          .widgetList(find.byKey(const ValueKey('plist-title')))
          .map((w) => tester.getTopLeft(find.byWidget(w)).dx)
          .toList();
      expect(lefts[0], 0);
      expect(lefts[1], 24);
    });
  });

  group('PChartDonutLegend 좁은 줄', () {
    const item = PChartDonutLegendItem(
      key: 'a',
      label: '카페·간식·디저트 모임 지출 항목',
      color: PChartColor.orange,
      percent: '25%',
      amount: '987,654,321원',
    );

    testWidgets('100% · 360 은 한 줄 — 이름 Expanded', (tester) async {
      await _pump(tester, const PChartDonutLegend(items: [item]));
      expect(tester.takeException(), isNull);
      final label = tester.getRect(
        find.byKey(const ValueKey('chart-donut-label')),
      );
      final amount = tester.getRect(
        find.byKey(const ValueKey('chart-donut-amount')),
      );
      expect((label.center.dy - amount.center.dy).abs(), lessThan(8));
    });

    testWidgets('200% 는 % · 금액이 이름 아래로 — 넘침 0 · 이름 모든 글자', (tester) async {
      await _pump(tester, const PChartDonutLegend(items: [item]), scale: 2);
      expect(tester.takeException(), isNull);
      final label = tester.getRect(
        find.byKey(const ValueKey('chart-donut-label')),
      );
      final amount = tester.getRect(
        find.byKey(const ValueKey('chart-donut-amount')),
      );
      expect(amount.top, greaterThanOrEqualTo(label.bottom - 1));
      expect(find.text('카페·간식·디저트 모임 지출 항목'), findsOneWidget);
    });
  });

  group('PProgress 이름 줄', () {
    testWidgets('오른쪽 글이 길면 이름 아래로 — 이름이 한 글자 폭이 되지 않는다', (tester) async {
      await _pump(
        tester,
        const PProgress(label: '전체 예산', value: 3909345678, max: 3000000),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      final name = tester.getRect(find.text('전체 예산'));
      expect(name.width, greaterThan(100));
    });

    testWidgets('금액 줄은 쉼표 · " / " 뒤에서만 끊긴다(보호 글자 포함)', (tester) async {
      await _pump(
        tester,
        const PProgress(label: '식비 예산', value: 987654321, max: 100000000),
      );
      final line = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => (t.data ?? '').contains('/'));
      expect(line.data, contains('​'));
      expect(line.data, contains('⁠'));
    });
  });
}
