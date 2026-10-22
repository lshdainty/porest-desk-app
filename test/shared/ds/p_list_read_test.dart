// List 줄의 낭독(03-D 결정 4 A) — 누르는 줄 · 링크 줄 · 부모 줄은 줄 하나가 한 번 읽힌다. 제목 + 설명 + 값이 이름 하나이고,
// 화살표 · 작은 버튼 같은 조작 요소는 따로 읽힌다. 읽는 순서는 꺾쇠 단추 → 줄 → 하위 줄이고 하위 줄은 꺾쇠 노드 밖이다.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_parent_item.dart';

Widget _host(Widget child, {double width = 360}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

void _noop() {}

/// 접근성 트리를 읽는 순서대로 — 이름이 있는 노드만.
List<String> _reading(WidgetTester tester, String start) => tester.semantics
    .simulatedAccessibilityTraversal(startNode: find.semantics.byLabel(start))
    .map((n) => n.label)
    .where((l) => l.isNotEmpty)
    .toList();

void main() {
  group('누르는 줄', () {
    testWidgets('글 값 + 화살표 — 이름은 제목 + 설명 + 값, 화살표는 읽지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          PList(
            semanticLabel: '설정',
            children: [
              PListButtonItem(
                title: '기본 통화',
                detail: '표시할 통화',
                suffix: const PListSuffix(
                  children: [Text('대한민국 원'), Icon(LucideIcons.chevronRight)],
                ),
                onTap: _noop,
              ),
            ],
          ),
        ),
      );
      expect(_reading(tester, '설정'), ['설정', '기본 통화\n표시할 통화\n대한민국 원']);
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^기본 통화')));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('금액 값(PListValue)도 한 이름 — 읽는 말은 원래 금액이다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          PList(
            semanticLabel: '거래',
            children: [
              PListButtonItem(
                title: '점심 식사',
                suffix: const PListValue(
                  child: Text('−12,000원', semanticsLabel: '−12,000원'),
                ),
                onTap: _noop,
              ),
            ],
          ),
        ),
      );
      expect(_reading(tester, '거래'), ['거래', '점심 식사\n−12,000원']);
      handle.dispose();
    });

    testWidgets('작은 버튼은 따로 읽히고 줄의 이름에 들어가지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          PList(
            semanticLabel: '메모',
            children: [
              PListButtonItem(
                title: '장보기 메모',
                suffix: PListSuffix(
                  children: [
                    const Text('3개'),
                    PListAction(
                      child: Semantics(
                        container: true,
                        button: true,
                        label: '삭제',
                        onTap: _noop,
                        child: const SizedBox.square(dimension: 44),
                      ),
                    ),
                  ],
                ),
                onTap: _noop,
              ),
            ],
          ),
        ),
      );
      expect(_reading(tester, '메모'), ['메모', '장보기 메모\n3개', '삭제']);
      handle.dispose();
    });

    testWidgets('좁은 줄에서 값이 아래로 내려가도 이름은 그대로 하나다', (tester) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpWidget(
        _host(
          PList(
            semanticLabel: '설정',
            children: [
              PListButtonItem(
                title: '기본 통화',
                detail: '표시할 통화',
                suffix: const PListSuffix(
                  children: [Text('대한민국 원'), Icon(LucideIcons.chevronRight)],
                ),
                onTap: _noop,
              ),
            ],
          ),
        ),
      );
      expect(find.byKey(const ValueKey('plist-value-below')), findsOneWidget);
      expect(_reading(tester, '설정'), ['설정', '기본 통화\n표시할 통화\n대한민국 원']);
      handle.dispose();
    });

    testWidgets('막힌 줄 — 이름은 같고 막힘으로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const PList(
            semanticLabel: '설정',
            children: [
              PListButtonItem(
                title: '기본 통화',
                suffix: Text('대한민국 원'),
                onTap: null,
              ),
            ],
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^기본 통화')));
      expect(node.label, '기본 통화\n대한민국 원');
      expect(node.getSemanticsData().flagsCollection.isEnabled.name, 'isFalse');
      handle.dispose();
    });

    testWidgets('보기만 하는 줄도 줄 하나 = 한 노드 — 값이 이름에 들어간다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const PList(
            semanticLabel: '정보',
            children: [PListItem(title: '결제 알림', suffix: Text('켜짐'))],
          ),
        ),
      );
      expect(_reading(tester, '정보'), ['정보', '결제 알림\n켜짐']);
      handle.dispose();
    });
  });

  group('링크 줄', () {
    testWidgets('이름 하나 — 링크로 읽히고 값이 들어간다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          PList(
            semanticLabel: '도움말',
            children: [
              PListLinkItem(
                title: '설명서',
                detail: '자세히 알아보세요',
                suffix: const PListSuffix(
                  children: [Text('새 창'), Icon(LucideIcons.externalLink)],
                ),
                onTap: _noop,
              ),
            ],
          ),
        ),
      );
      expect(_reading(tester, '도움말'), ['도움말', '설명서\n자세히 알아보세요\n새 창']);
      final node = tester.getSemantics(find.bySemanticsLabel(RegExp('^설명서')));
      expect(node.getSemanticsData().flagsCollection.isLink, isTrue);
      handle.dispose();
    });
  });

  group('부모 줄 · 하위 줄', () {
    Widget food({bool open = true}) => PList(
      semanticLabel: '지출 카테고리',
      children: [
        PListParentItem(
          title: '식비',
          detail: '지출 · 하위 2개',
          suffix: const Text('45,000원'),
          expandLabel: '식비 하위 카테고리',
          defaultOpen: open,
          onTap: _noop,
          children: [
            PListButtonItem(
              title: '외식',
              suffix: const Text('30,000원'),
              onTap: _noop,
            ),
            PListButtonItem(
              title: '배달음식',
              suffix: const Text('15,000원'),
              onTap: _noop,
            ),
          ],
        ),
        PListButtonItem(title: '기타', onTap: _noop),
      ],
    );

    testWidgets('읽는 순서 — 꺾쇠 단추 → 줄(값 포함) → 하위 줄 → 다음 줄', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(food()));
      expect(_reading(tester, '지출 카테고리'), [
        '지출 카테고리',
        '식비 하위 카테고리',
        '식비\n지출 · 하위 2개\n45,000원',
        '외식\n30,000원',
        '배달음식\n15,000원',
        '기타',
      ]);
      handle.dispose();
    });

    testWidgets('하위 줄은 꺾쇠 단추 노드 밖이고 부모 줄의 이름에도 들어가지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(food()));
      final chevron = tester.getSemantics(find.bySemanticsLabel('식비 하위 카테고리'));
      final parent = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^식비\n')),
      );
      final child = tester.getSemantics(find.bySemanticsLabel(RegExp('^외식')));
      bool inside(SemanticsNode outer, SemanticsNode node) {
        var found = false;
        outer.visitChildren((c) {
          if (c.id == node.id || inside(c, node)) found = true;
          return !found;
        });
        return found;
      }

      expect(inside(chevron, child), isFalse);
      expect(inside(chevron, parent), isFalse);
      expect(inside(parent, child), isFalse);
      expect(parent.label.contains('외식'), isFalse);
      expect(chevron.label.contains('외식'), isFalse);
      handle.dispose();
    });

    testWidgets('접히면 하위 줄은 읽지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(food(open: false)));
      expect(_reading(tester, '지출 카테고리'), [
        '지출 카테고리',
        '식비 하위 카테고리',
        '식비\n지출 · 하위 2개\n45,000원',
        '기타',
      ]);
      handle.dispose();
    });
  });
}
