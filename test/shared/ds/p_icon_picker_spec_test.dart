// Icon Picker 가 스펙 값대로인지 — 고름 × 상태 × 라이트 · 다크(앱은 시트만 — 팝오버 7열은 1280 이상 웹 몫). 값은
// test/fixtures/design_spec/icon-picker.json · category-icons.json, 웹은 같은 JSON 을 크로미움에서 잰다. 아래 동작 묶음은
// 웹 icon-picker.test.tsx 가 잡는 것(세트 · 찾기 · 키보드 · 열기 · 닫기 · 접근성)을 앱 위젯으로 같이 잡는다.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/icon_picker/category_icons.dart';
import 'package:groo_damda_app/shared/ds/icon_picker/category_icons.g.dart';
import 'package:groo_damda_app/shared/ds/icon_picker/p_icon_picker.dart';
import 'package:groo_damda_app/shared/ds/input/text_control.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';
import '../../support/spec_check.dart';

Widget _host(
  Brightness mode,
  Widget child, {
  double width = 390,
  double height = 560,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  ),
);

Finder _cell(String id) => find.byKey(ValueKey('icon-$id'));
// 툴팁도 Focus 를 두므로 칸이 직접 건 노드를 읽는다
FocusNode _node(WidgetTester tester, String id) => tester
    .widgetList<Focus>(
      find.descendant(of: _cell(id), matching: find.byType(Focus)),
    )
    .firstWhere((f) => f.focusNode?.debugLabel == 'icon-$id')
    .focusNode!;
final _search = find.byType(PTextFrame);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// 키 이벤트가 먼저 있어야 초점 모드가 keyboard 가 된다.
Future<void> _keyboardFocus(WidgetTester tester, String id) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
  _node(tester, id).requestFocus();
  await _settle(tester);
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

/// 화면 읽기 프로그램에 보낸 알림.
List<String> _listenAnnouncements(WidgetTester tester) {
  final said = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
    SystemChannels.accessibility,
    (message) async {
      final m = message as Map;
      if (m['type'] == 'announce') {
        said.add((m['data'] as Map)['message'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        ),
  );
  return said;
}

class _Panel extends StatefulWidget {
  const _Panel({
    super.key,
    this.selectedId,
    this.initialQuery = '',
    this.autofocus = false,
  });

  final String? selectedId;
  final String initialQuery;
  final bool autofocus;

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  final picks = <String>[];

  @override
  Widget build(BuildContext context) => PIconPickerPanel(
    selectedId: widget.selectedId,
    initialQuery: widget.initialQuery,
    autofocus: widget.autofocus,
    onSelect: picks.add,
  );
}

_PanelState _panel(WidgetTester tester) =>
    tester.state<_PanelState>(find.byType(_Panel));

void main() {
  final spec = DesignSpec.load('icon-picker');
  final icons =
      jsonDecode(
            File(
              'test/fixtures/design_spec/category-icons.json',
            ).readAsStringSync(),
          )['data']
          as Map<String, dynamic>;

  group('세트 — category-icons.json', () {
    test('생성 파일은 스펙 JSON 의 data 와 같다 — 148개 · 13 묶음', () {
      final data = kCategoryIconsSpec['data'] as Map;
      expect(data['entries'], equals(icons['entries']));
      expect(data['groups'], equals(icons['groups']));
      expect(data['default'], icons['default']);
      expect(kCategoryIcons, hasLength(148));
      expect(kCategoryIconGroups, hasLength(13));
      expect(kCategoryIconSections, hasLength(13));
      expect(
        kCategoryIconSections.fold<int>(0, (a, s) => a + s.icons.length),
        148,
      );
    });

    test('그림 표는 JSON 과 같은 집합이다 — id 마다 그림이 있고 남는 그림이 없다', () {
      final ids = {for (final e in icons['entries'] as List) e['id'] as String};
      expect(kCategoryIconGlyphs.keys.toSet(), ids);
      expect(kCategoryIconGlyphsBold.keys.toSet(), ids);
      expect(ids, hasLength(148));
      // 고른 칸은 같은 그림의 선 2.5(w500) 글꼴이다
      for (final id in ids) {
        final plain = kCategoryIconGlyphs[id]!;
        final bold = kCategoryIconGlyphsBold[id]!;
        expect(bold.codePoint, plain.codePoint, reason: id);
        expect(plain.fontFamily, 'Lucide', reason: id);
        expect(bold.fontFamily, 'Lucide500', reason: id);
      }
    });

    test('이름은 세트 안에서 겹치지 않는다 · id 도 겹치지 않는다', () {
      expect({for (final i in kCategoryIcons) i.name}, hasLength(148));
      expect({for (final i in kCategoryIcons) i.id}, hasLength(148));
      expect(kDefaultCategoryIcon, 'tag');
      expect(kCategoryIconGlyphs.containsKey(kDefaultCategoryIcon), isTrue);
    });

    test('저장 값 → 세트 — id · 옛 이름(home → house), 세트 밖 · 빈 값은 null', () {
      expect(findCategoryIcon('coffee')!.name, '커피');
      expect(findCategoryIcon('home')!.id, 'house');
      expect(findCategoryIcon(' coffee ')!.id, 'coffee');
      expect(findCategoryIcon('rocket'), isNull);
      expect(findCategoryIcon(''), isNull);
      expect(findCategoryIcon(null), isNull);
    });

    test('찾기 — 이름 · 찾는 말 · id, 소문자 · 공백 없이 부분 일치, 세트 차례 그대로', () {
      List<String> ids(String q) => [
        for (final i in searchCategoryIcons(q)) i.id,
      ];
      expect(ids('커피'), contains('coffee'));
      expect(ids(' 커 피 '), contains('coffee'));
      expect(ids('COFFEE'), contains('coffee'));
      expect(ids('월세'), contains('house'));
      expect(ids('home'), contains('house'));
      expect(ids('유니콘'), isEmpty);
      expect(searchCategoryIcons(''), hasLength(148));
      expect(searchCategoryIcons('   '), hasLength(148));
      // 세트 차례
      final all = [for (final i in kCategoryIcons) i.id];
      final found = ids('카페');
      expect(
        found,
        equals([
          for (final id in all)
            if (found.contains(id)) id,
        ]),
      );
    });

    test('세트 밖 저장 값도 그린다 — lucide 전체에서 찾고 없으면 태그', () {
      expect(categoryGlyph('rocket'), LucideIcons.rocket);
      expect(categoryGlyph('home'), kCategoryIconGlyphs['house']);
      expect(categoryGlyph('definitely-not-an-icon'), LucideIcons.tag);
    });
  });

  group('스펙 값 — 고름 × 상태', () {
    for (final mode in Brightness.values) {
      for (final combo in [
        for (final c in spec.combos(['selected', 'surface']))
          if (c['surface'] == 'sheet') c, // 팝오버(7열 · 408)는 1280 이상 웹 몫
      ]) {
        for (final state in spec.states) {
          testWidgets('${mode.name} · ${combo.values.join(' · ')} · $state', (
            tester,
          ) async {
            final selected = combo['selected'] == 'selected';
            final want = spec.resolve(combo, state);
            final k = SpecCheck(mode, want, '${mode.name} $combo $state');
            const id = 'utensils';
            await tester.pumpWidget(
              _host(mode, _Panel(selectedId: selected ? id : null)),
            );
            await _settle(tester);
            final cell = _cell(id);
            TestGesture? held;
            TestGesture? mouse;
            if (state == 'pressed') {
              held = await tester.startGesture(tester.getCenter(cell));
              await _settle(tester);
              await _settle(tester); // 누름은 100ms 뒤 확정되고 그다음 프레임부터 색이 바뀐다
            } else if (state == 'hovered') {
              mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
              await mouse.addPointer(location: Offset.zero);
              await mouse.moveTo(tester.getCenter(cell));
              await _settle(tester);
            } else if (state == 'focused') {
              await _keyboardFocus(tester, id);
            }

            // 칸 — 48 · 모서리 12 · 바탕은 호버 · 누름만
            final box = tester.getRect(cell);
            k.px('cell.size', box.width);
            k.px('cell.size', box.height);
            final face =
                tester
                        .widget<DecoratedBox>(
                          find.descendant(
                            of: cell,
                            matching: find.byKey(
                              const ValueKey('icon-cell-face'),
                            ),
                          ),
                        )
                        .decoration
                    as BoxDecoration;
            k.px('cell.radius', (face.borderRadius! as BorderRadius).topLeft.x);
            k.color('cell.background', face.color ?? const Color(0x00000000));
            k.m(['cell.cursor']);
            // 툴팁도 마우스 영역을 두므로 모양을 정한 쪽(defer 가 아닌)을 읽는다
            final cursor = tester
                .widgetList<MouseRegion>(
                  find.descendant(of: cell, matching: find.byType(MouseRegion)),
                )
                .map((r) => r.cursor)
                .firstWhere((c) => c != MouseCursor.defer);
            k.cursor('cell.cursor', cursor);

            // 아이콘 — 24, 선 2(고른 칸은 2.5 — w500 글꼴), 색
            final icon = tester.widget<Icon>(
              find.descendant(of: cell, matching: find.byType(Icon)),
            );
            k.px('icon.size', icon.size!);
            k.color('icon.color', icon.color!);
            final plain = kCategoryIconGlyphs[id]!;
            final bold = kCategoryIconGlyphsBold[id]!;
            final wantStroke = want['icon.strokeWidth'] as num;
            expect(
              icon.icon,
              wantStroke == 2.5 ? bold : plain,
              reason: '${k.where} icon.strokeWidth $wantStroke',
            );
            k.m(['icon.strokeWidth']);

            // 고른 칸 — 안쪽 2px stroke-neutral-contrast
            final marked = find.descendant(
              of: cell,
              matching: find.byKey(const ValueKey('icon-cell-selected')),
            );
            if (selected) {
              final line =
                  (tester.widget<DecoratedBox>(marked).decoration
                          as BoxDecoration)
                      .border!
                      .top;
              k.px('cell.borderWidth', line.width);
              k.color('cell.borderColor', line.color);
              expect(
                tester.getSize(marked),
                const Size(48, 48),
              ); // 안쪽 — 아이콘이 밀리지 않는다
            } else {
              expect(marked, findsNothing);
            }

            if (state == 'pressed') {
              final anim = tester.widget<AnimatedScale>(
                find.descendant(of: cell, matching: find.byType(AnimatedScale)),
              );
              k.pressScale('cell.scale', anim.scale, 48);
              k.motion(
                'cell.scaleDuration',
                'cell.scaleEasing',
                anim.duration,
                anim.curve,
              );
            }
            if (state == 'focused') {
              final ring = find.descendant(
                of: cell,
                matching: find.byKey(const ValueKey('icon-cell-focus-ring')),
              );
              final w =
                  (want['focusRing.width'] as num) +
                  (want['focusRing.offset'] as num);
              final size = tester.getSize(ring);
              if ((size.width - 48) / 2 != w) {
                k.fail('focusRing: 칸 둘레 ${(size.width - 48) / 2} · 스펙 $w');
              }
              final border =
                  (tester.widget<DecoratedBox>(ring).decoration
                          as BoxDecoration)
                      .border!
                      .top;
              k.color('focusRing.color', border.color);
              k.px('focusRing.width', border.width);
              k.m(['focusRing.offset']);
            }

            // 시트 — 좌우 24 · 6열 · 찾기 칸 밑줄형 40 · 끝 흐림
            final scroll = tester.getRect(find.byType(PScrollFog));
            final grid = tester.getRect(_cell(kCategoryIcons.first.id));
            k.px('surface.paddingX', grid.left - scroll.left);
            k.m([
              'surface.paddingX',
              'surface.component',
              'scroll.scrollFog',
              'search.variant',
              'search.match',
              'trigger.component',
              'grid.role',
              'grid.keyboard',
              'cell.name',
              'cell.role',
              'cell.touchTarget',
              'cell.background',
              'count.display',
              'empty.size',
            ]);
            expect(
              tester.widget<PScrollFog>(find.byType(PScrollFog)).use,
              PScrollFogUse.overlayBody,
              reason: 'scroll.scrollFog 켬',
            );
            k.px('search.height', tester.getSize(_search).height);
            final first = [
              for (final i in kCategoryIcons.take(6))
                tester.getRect(_cell(i.id)),
            ];
            k.px('grid.columns', first.length);
            // 6열 — 같은 줄에 6칸, 7번째는 아랫줄
            expect(
              tester.getRect(_cell(kCategoryIcons[6].id)).top,
              greaterThan(first.first.top + 40),
              reason: '${k.where} grid.columns',
            );
            k.px(
              'grid.rowGap',
              tester.getRect(_cell(kCategoryIcons[6].id)).top -
                  first.first.bottom,
            );
            k.m(['grid.columns']);
            for (var i = 0; i + 1 < first.length; i++) {
              if (first[i + 1].left - first[i].right < 4 - 0.01) {
                k.fail(
                  'grid.columnGapMin: ${first[i + 1].left - first[i].right}',
                );
              }
            }
            k.m(['grid.columnGapMin']);

            // 묶음 머리 — 14 · 500 · fg-neutral-subtle, 위 12 · 아래 8
            final header = find.byKey(const ValueKey('icon-group-식비'));
            final style = tester.widget<Text>(header).style!;
            k.typo('groupHeader.typography', style);
            k.weight('groupHeader.fontWeight', style);
            k.color('groupHeader.foreground', style.color!);
            final h = tester.getRect(header);
            final fogTop = scroll.top + 20; // 흐림 여백 20
            k.px('groupHeader.paddingTop', h.top - fogTop - 12 + 12);
            k.px('groupHeader.paddingBottom', grid.top - h.bottom);
            // 찾기 칸에서 머리 글까지 32 = 흐림 여백 20 + 위 12
            expect(h.top - tester.getRect(_search).bottom, 32);
            k.m(['groupHeader.paddingTop']);
            // 찾는 동안 — 격자 위 12(searchGap)
            k.coverage({'grid.searchGap'});
            expect(k.failures, isEmpty);

            await held?.cancel();
            await mouse?.removePointer();
          });
        }
      }
    }
  });

  group('격자 열 수', () {
    test('시트 본문 폭 — 6열까지, 남는 폭은 칸 사이에 고르게(사이 최소 4)', () {
      var m = iconGridMetrics(308); // 48 × 6 + 4 × 5
      expect((m.columns, m.gap), (6, 4.0));
      m = iconGridMetrics(342); // 390 폰 시트 본문
      expect(m.columns, 6);
      expect(m.gap, closeTo((342 - 288) / 5, 1e-9));
      m = iconGridMetrics(312); // 360 폰 시트 본문
      expect(m.columns, 6);
      expect(m.gap, closeTo(4.8, 1e-9));
      // 308 보다 좁은 폰은 들어가는 만큼
      m = iconGridMetrics(272);
      expect(m.columns, 5);
      expect(m.gap, greaterThanOrEqualTo(4));
      expect(iconGridMetrics(200).columns, 3);
      expect(iconGridMetrics(40).columns, 1);
    });

    testWidgets('폭 360 — 칸 사이 4.8 로 고르게', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, const _Panel(), width: 360),
      );
      await _settle(tester);
      final a = tester.getRect(_cell(kCategoryIcons[0].id));
      final b = tester.getRect(_cell(kCategoryIcons[1].id));
      expect(b.left - a.right, closeTo(4.8, 0.01));
      final last = tester.getRect(_cell(kCategoryIcons[5].id));
      expect(last.right, closeTo(360 - 24, 0.01)); // 오른쪽 여백 24 에 닿는다
    });
  });

  group('격자', () {
    testWidgets('148개 · 13 묶음 — 묶음 머리가 이름, 마지막 줄의 빈 자리도 열은 제자리', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, const _Panel()));
      await _settle(tester);
      expect(find.byType(PIconPickerCell), findsNWidgets(148));
      for (final g in kCategoryIconGroups) {
        expect(find.byKey(ValueKey('icon-group-$g')), findsOneWidget);
      }
      // 마지막 줄이 덜 차도 첫 칸과 같은 열에 선다 — 식비 23개: 4줄 + 5칸
      final row = [for (final i in kCategoryIcons.take(18)) i.id];
      final x0 = tester.getTopLeft(_cell(row[0])).dx;
      expect(tester.getTopLeft(_cell(row[18 - 6])).dx, x0);
    });

    testWidgets('칸을 누르면 그 id 를 한 번 알린다', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, const _Panel()));
      await _settle(tester);
      await tester.tap(_cell('soup'));
      await tester.pump();
      expect(_panel(tester).picks, ['soup']);
    });

    testWidgets('Tab 하나 — 고른 칸만, 없으면 첫 칸', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, const _Panel(selectedId: 'coffee')),
      );
      await _settle(tester);
      for (final i in kCategoryIcons) {
        expect(
          tester
              .widgetList<Focus>(
                find.descendant(of: _cell(i.id), matching: find.byType(Focus)),
              )
              .firstWhere((f) => f.focusNode?.debugLabel == 'icon-${i.id}')
              .skipTraversal,
          i.id != 'coffee',
          reason: i.id,
        );
      }
      await tester.pumpWidget(
        _host(Brightness.light, _Panel(key: UniqueKey())),
      );
      await _settle(tester);
      final skip = tester
          .widgetList<Focus>(
            find.descendant(
              of: _cell(kCategoryIcons.first.id),
              matching: find.byType(Focus),
            ),
          )
          .firstWhere((f) => f.focusNode?.debugLabel != null)
          .skipTraversal;
      expect(skip, isFalse);
    });

    testWidgets('열면 초점은 고른 칸 — 고른 칸이 스크롤 상자 가운데에 온다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const _Panel(selectedId: 'church', autofocus: true),
        ),
      );
      await _settle(tester);
      expect(_node(tester, 'church').hasFocus, isTrue);
      final box = tester.getRect(find.byType(PScrollFog));
      final cell = tester.getRect(_cell('church'));
      // 끝까지 스크롤해도 가운데에 못 오는 마지막 묶음은 아래 흐림 여백 위에 선다
      expect(cell.bottom, lessThanOrEqualTo(box.bottom - 80 + 0.5));
      expect(cell.top, greaterThan(box.top));
      // 첫 칸도 같은 규칙
      await tester.pumpWidget(
        _host(Brightness.light, _Panel(key: UniqueKey(), autofocus: true)),
      );
      await _settle(tester);
      expect(_node(tester, kCategoryIcons.first.id).hasFocus, isTrue);
    });

    testWidgets('세트 밖 저장 값 — 고른 칸이 없고 첫 칸에 초점', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, const _Panel(autofocus: true)),
      );
      await _settle(tester);
      expect(find.byKey(const ValueKey('icon-cell-selected')), findsNothing);
    });
  });

  group('찾기', () {
    testWidgets('치는 대로 세트를 거른다 — 묶음 머리 없이 세트 차례 그대로, 격자 위 12 + 흐림 20', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, const _Panel()));
      await _settle(tester);
      await tester.enterText(find.byType(EditableText), '카페');
      await tester.pump();
      final expected = [for (final i in searchCategoryIcons('카페')) i.id];
      expect(expected, isNotEmpty);
      expect(find.byType(PIconPickerCell), findsNWidgets(expected.length));
      expect(find.byKey(const ValueKey('icon-group-카페')), findsNothing);
      final tops = [for (final id in expected) tester.getTopLeft(_cell(id))];
      // 세트 차례 — 위에서 아래로, 같은 줄은 왼쪽에서 오른쪽으로
      for (var i = 0; i + 1 < tops.length; i++) {
        expect(
          tops[i + 1].dy > tops[i].dy ||
              (tops[i + 1].dy == tops[i].dy && tops[i + 1].dx > tops[i].dx),
          isTrue,
        );
      }
      // 찾기 칸에서 격자까지 32 — 흐림 20 + searchGap 12
      expect(tops.first.dy - tester.getRect(_search).bottom, 32);
      // 지우면 묶음이 돌아온다
      await tester.enterText(find.byType(EditableText), '');
      await tester.pump();
      expect(find.byType(PIconPickerCell), findsNWidgets(148));
    });

    testWidgets('한국어 이름 · 찾는 말 · 영어 id, 공백 · 대소문자 무시', (tester) async {
      await tester.pumpWidget(_host(Brightness.light, const _Panel()));
      await _settle(tester);
      for (final q in ['커피', ' 커 피 ', 'COFFEE', '스타벅스']) {
        await tester.enterText(find.byType(EditableText), q);
        await tester.pump();
        expect(_cell('coffee'), findsOneWidget, reason: q);
      }
      await tester.enterText(find.byType(EditableText), '월세');
      await tester.pump();
      expect(_cell('house'), findsOneWidget);
    });

    testWidgets("0건 — \"'유니콘'에 대한 아이콘이 없어요\"(Result Section medium)", (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, const _Panel()));
      await _settle(tester);
      await tester.enterText(find.byType(EditableText), ' 유니콘 ');
      await tester.pump();
      final result = tester.widget<PResultSection>(find.byType(PResultSection));
      expect(result.title, "'유니콘'에 대한 아이콘이 없어요"); // 앞뒤 공백은 뗀다
      expect(result.description, '다른 말로 찾거나 묶음에서 골라주세요.');
      expect(result.size, PResultSize.medium);
      expect(result.kind, PResultKind.empty);
      expect(find.byType(PIconPickerCell), findsNothing);
    });

    testWidgets('결과 수는 치기를 멈추면 한 번만 알린다(0건은 알리지 않는다)', (tester) async {
      final said = _listenAnnouncements(tester);
      await tester.pumpWidget(_host(Brightness.light, const _Panel()));
      await _settle(tester);
      await tester.enterText(find.byType(EditableText), '카');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(EditableText), '카페');
      await tester.pump(const Duration(milliseconds: 300));
      expect(said, isEmpty); // 아직 치는 중
      await tester.pump(const Duration(milliseconds: 300));
      final n = searchCategoryIcons('카페').length;
      expect(said, ['검색 결과 $n개']);
      await tester.pump(const Duration(seconds: 2));
      expect(said, hasLength(1)); // 한 번만
      await tester.enterText(find.byType(EditableText), '유니콘');
      await tester.pump(const Duration(seconds: 1));
      expect(said, hasLength(1)); // 0건은 Result Section 이 읽는다
    });

    testWidgets('한글 조합 중 ↓ 는 조합의 것 — 격자로 옮기지 않는다, 조합이 끝나면 첫 칸으로', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Brightness.light, const _Panel()));
      await _settle(tester);
      await tester.showKeyboard(find.byType(EditableText));
      // "ㅋ" 을 조합하는 중
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ㅋ',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
      );
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      final search = tester.widget<EditableText>(find.byType(EditableText));
      expect(search.focusNode.hasFocus, isTrue); // 격자로 옮기지 않았다
      // 조합을 마친 글 — ↓ 는 격자의 첫 칸으로
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '커',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();
      final first = searchCategoryIcons('커').first.id;
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_node(tester, first).hasFocus, isTrue);
    });

    testWidgets('Esc — 찾는 말이 있으면 지우고 찾기 칸으로, 비었으면 시트에 맡긴다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const _Panel(initialQuery: '커피', autofocus: false),
        ),
      );
      await _settle(tester);
      _node(tester, 'coffee').requestFocus();
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.escape);
      expect(find.byType(PIconPickerCell), findsNWidgets(148));
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '',
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    });
  });

  group('키보드', () {
    Future<void> pumpPanel(
      WidgetTester tester, {
      TextDirection dir = TextDirection.ltr,
    }) async {
      await tester.pumpWidget(
        _host(Brightness.light, _Panel(key: UniqueKey()), direction: dir),
      );
      await _settle(tester);
    }

    testWidgets('← → 는 차례대로 — 줄 끝에서 다음 줄로, 끝에서 멈춘다', (tester) async {
      await pumpPanel(tester);
      final ids = [for (final i in kCategoryIcons) i.id];
      await _keyboardFocus(tester, ids[0]);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_node(tester, ids[1]).hasFocus, isTrue);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      await _key(tester, LogicalKeyboardKey.arrowLeft); // 처음에서 멈춘다
      expect(_node(tester, ids[0]).hasFocus, isTrue);
      for (var i = 0; i < 6; i++) {
        await _key(tester, LogicalKeyboardKey.arrowRight);
      }
      expect(_node(tester, ids[6]).hasFocus, isTrue); // 다음 줄 첫 칸
    });

    testWidgets('↑ ↓ 는 보이는 위아래 줄의 가장 가까운 칸 — 묶음 머리를 넘는다', (tester) async {
      await pumpPanel(tester);
      final ids = [for (final i in kCategoryIcons) i.id];
      await _keyboardFocus(tester, ids[1]);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_node(tester, ids[7]).hasFocus, isTrue);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_node(tester, ids[1]).hasFocus, isTrue);
      // 식비의 마지막 줄 → 카페(다음 묶음) 첫 줄 — 식비 23개: 마지막 줄 18 ~ 22, 카페는 다음 묶음
      await _keyboardFocus(tester, ids[20]);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(
        kCategoryIcons.firstWhere((i) => _node(tester, i.id).hasFocus).group,
        '카페',
      );
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_node(tester, ids[20]).hasFocus, isTrue);
    });

    testWidgets('Home · End 는 그 줄의 처음 · 끝', (tester) async {
      await pumpPanel(tester);
      final ids = [for (final i in kCategoryIcons) i.id];
      await _keyboardFocus(tester, ids[9]);
      await _key(tester, LogicalKeyboardKey.home);
      expect(_node(tester, ids[6]).hasFocus, isTrue);
      await _key(tester, LogicalKeyboardKey.end);
      expect(_node(tester, ids[11]).hasFocus, isTrue);
    });

    testWidgets('Enter · Space 로 고른다', (tester) async {
      await pumpPanel(tester);
      await _keyboardFocus(tester, 'pizza');
      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.space);
      expect(_panel(tester).picks, ['pizza', 'pizza']);
    });

    testWidgets('RTL — ← → 가 반대', (tester) async {
      await pumpPanel(tester, dir: TextDirection.rtl);
      final ids = [for (final i in kCategoryIcons) i.id];
      await _keyboardFocus(tester, ids[3]);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_node(tester, ids[2]).hasFocus, isTrue);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_node(tester, ids[3]).hasFocus, isTrue);
    });

    testWidgets('키보드로 옮긴 칸이 흐림 밖에 보인다 — 맨 아래 칸으로 가면 스크롤된다', (tester) async {
      await pumpPanel(tester);
      final ids = [for (final i in kCategoryIcons) i.id];
      await _keyboardFocus(tester, ids.first);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      final box = tester.getRect(find.byType(PScrollFog));
      // 한 줄씩 내려가며 끝까지 — 초점 칸이 아래 흐림(80) 안으로 들어가지 않는다
      for (var i = 0; i < 40; i++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
        final focused = kCategoryIcons.firstWhere(
          (c) => _node(tester, c.id).hasFocus,
        );
        final r = tester.getRect(_cell(focused.id));
        expect(r.bottom, lessThanOrEqualTo(box.bottom - 80 + 1), reason: '$i');
        expect(r.top, greaterThanOrEqualTo(box.top + 20 - 1), reason: '$i');
      }
    });
  });

  group('트리거 · 시트', () {
    Future<(_PickerHost, GlobalKey<_PickerHostState>)> pumpPicker(
      WidgetTester tester, {
      String? value,
      bool disabled = false,
    }) async {
      final key = GlobalKey<_PickerHostState>();
      final host = _PickerHost(key: key, value: value, disabled: disabled);
      await tester.pumpWidget(_host(Brightness.light, host));
      await _settle(tester);
      return (host, key);
    }

    testWidgets('트리거의 값 — 세트 안은 한국어 이름, 빈 값은 태그, 세트 밖은 지금 아이콘, 옛 이름은 집', (
      tester,
    ) async {
      for (final (value, name) in [
        ('coffee', '커피'),
        (null, '태그'),
        ('', '태그'),
        ('rocket', '지금 아이콘'),
        ('home', '집'),
      ]) {
        await pumpPicker(tester, value: value);
        final button = tester.widget<PInputButton>(find.byType(PInputButton));
        expect(button.value, name, reason: '$value');
        expect(button.suffixIcon, LucideIcons.chevronDown);
        expect(
          button.prefixIcon,
          categoryGlyph(
            findCategoryIcon(value)?.id ??
                ((value ?? '').isEmpty ? 'tag' : value!),
          ),
        );
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('누르면 시트가 열리고 고르면 바로 닫힌다 — 값을 한 번 알리고 초점은 트리거로', (tester) async {
      final (_, key) = await pumpPicker(tester, value: 'coffee');
      await tester.tap(find.byType(PInputButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(findRichPlain('아이콘'), findsWidgets); // 시트 제목
      expect(find.byType(PIconPickerPanel), findsOneWidget);
      expect(
        tester.widget<PInputButton>(find.byType(PInputButton)).expanded,
        isTrue,
      );
      // 열면 초점은 고른 칸
      await tester.pump(const Duration(milliseconds: 100));
      expect(_node(tester, 'coffee').hasFocus, isTrue);
      await tester.tap(_cell('bus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(key.currentState!.picks, ['bus']);
      expect(find.byType(PIconPickerPanel), findsNothing);
      expect(
        tester.widget<PInputButton>(find.byType(PInputButton)).expanded,
        isFalse,
      );
    });

    testWidgets('고르지 않고 닫으면 알리지 않는다 — 세트 밖 저장 값도 그대로', (tester) async {
      final (_, key) = await pumpPicker(tester, value: 'rocket');
      await tester.tap(find.byType(PInputButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // 고른 칸이 없다
      expect(find.byKey(const ValueKey('icon-cell-selected')), findsNothing);
      await tester.tap(find.bySemanticsLabel('닫기').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(PIconPickerPanel), findsNothing);
      expect(key.currentState!.picks, isEmpty);
    });

    testWidgets('막힘 — 열리지 않는다', (tester) async {
      await pumpPicker(tester, value: 'coffee', disabled: true);
      await tester.tap(find.byType(PInputButton), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PIconPickerPanel), findsNothing);
    });

    testWidgets('이름은 Field 라벨 + 값 — "아이콘 커피"', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPicker(tester, value: 'coffee');
      final node = tester.getSemantics(find.bySemanticsLabel('아이콘').first);
      expect(node.label, '아이콘');
      expect(node.value, '커피');
      handle.dispose();
    });
  });

  group('접근성 · 가장 나쁜 값', () {
    testWidgets('칸은 한국어 이름 · 고른 상태로 읽힌다 — 영어 id 는 읽지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, const _Panel(selectedId: 'coffee')),
      );
      await _settle(tester);
      final data = tester
          .getSemantics(find.bySemanticsLabel('커피').first)
          .getSemanticsData();
      expect(data.label, '커피');
      expect(data.flagsCollection.isSelected, ui.Tristate.isTrue);
      // 앱은 칸마다 Semantics(selected, label, button: true) — 버튼으로 읽는다(03B-009c)
      expect(data.flagsCollection.isButton, isTrue);
      expect(find.bySemanticsLabel('coffee'), findsNothing);
      final other = tester
          .getSemantics(find.bySemanticsLabel('식사').first)
          .getSemanticsData();
      expect(other.flagsCollection.isSelected, isNot(ui.Tristate.isTrue));
      handle.dispose();
    });

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} · 폭 360 · 148개 · 고른 칸 · 찾는 말 — 넘치지 않는다', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            mode,
            const _Panel(selectedId: 'church', initialQuery: '카'),
            width: 360,
          ),
        );
        await _settle(tester);
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(EditableText), '');
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(PIconPickerCell), findsNWidgets(148));
      });
    }
  });
}

/// 트리거 견본 — 고른 값을 모은다.
class _PickerHost extends StatefulWidget {
  const _PickerHost({super.key, this.value, this.disabled = false});

  final String? value;
  final bool disabled;

  @override
  State<_PickerHost> createState() => _PickerHostState();
}

class _PickerHostState extends State<_PickerHost> {
  final picks = <String>[];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: PField(
      label: '아이콘',
      disabled: widget.disabled,
      child: PIconPicker(value: widget.value, onChanged: picks.add),
    ),
  );
}
