// Menu Sheet 가 스펙 값(test/fixtures/design_spec/menu-sheet.json)대로 그려지는지 — 정렬(layout) × 톤(tone) × 상태 × 라이트 ·
// 다크를 모두 돈다. 웹은 같은 JSON 을 크로미움에서 잰다(desk-front `npm run ds:check`).
//
// 문장으로 된 값은 그린 결과나 동작으로 본다 — 최대 높이 "화면 높이의 90%" 는 긴 목록으로, 누름 축소 "콘텐츠 2px 거리" 는 그려진
// 배율로, z-index(100 · 101)는 Bottom Sheet 라우트가 쌓이는 차례로(같은 라우트다) 잰다. 딤 · 끌어내리기 · 모션은 Bottom Sheet 와
// 같은 라우트 위에 있어 p_bottom_sheet_spec_test 가 잰다 — 여기서는 Menu Sheet 가 그 위에서 다른 자리(모서리 20 · 손잡이 늘 ·
// 닫기 버튼 없음)만 본다.
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/ds/menu_sheet/p_menu_sheet.dart';

import '../../support/design_spec.dart';

final _spec = DesignSpec.load('menu-sheet');

PColors _colors(Brightness mode) =>
    mode == Brightness.dark ? PColors.dark : PColors.light;

ThemeData _theme(Brightness mode) =>
    mode == Brightness.dark ? PorestTheme.dark() : PorestTheme.light();

void _viewport(WidgetTester tester, Size size, {double safeBottom = 0}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(bottom: safeBottom);
  tester.view.viewPadding = FakeViewPadding(bottom: safeBottom);
  addTearDown(tester.view.reset);
}

Widget _app(Brightness mode, Widget home) => MaterialApp(
  theme: _theme(mode),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: home,
);

const _root = ValueKey('p-bottom-sheet-root');
const _item = ValueKey('p-menu-sheet-item');

Rect _rect(WidgetTester tester, Key key) =>
    tester.getRect(find.byKey(key).first);

void _expectColor(Object? want, Brightness mode, Color actual, [String? why]) {
  expect(
    sameColor(specColor(pickMode(want, mode)), actual),
    isTrue,
    reason: '${why ?? ''} 기대 ${pickMode(want, mode)} 실제 ${colorHex(actual)}',
  );
}

void _expectType(
  Map<String, dynamic> want,
  TextStyle style, {
  FontWeight? weight,
}) {
  expect(style.fontSize, (want['fontSize'] as num).toDouble());
  expect(
    style.fontSize! * style.height!,
    closeTo((want['lineHeight'] as num).toDouble(), 0.01),
  );
  if (weight != null) expect(style.fontWeight, weight);
}

/// 시험할 줄(첫 묶음의 첫 줄)이 [tone] · [enabled] 이고, 첫 묶음에는 줄이 둘(첫 줄은 마지막이 아니다 — 선이 있다), 둘째 묶음이
/// 하나다. 정렬이 `textOnly` 면 아이콘 · 설명이 없다.
PMenuSheetContent _content({
  PMenuSheetLayout layout = PMenuSheetLayout.textWithIcon,
  PMenuSheetTone tone = PMenuSheetTone.neutral,
  bool enabled = true,
  bool header = true,
  VoidCallback? onFirst,
  VoidCallback? onSecond,
}) {
  final textOnly = layout == PMenuSheetLayout.textOnly;
  return PMenuSheetContent(
    title: header ? '주간 회의 메모' : null,
    description: header ? '이 메모의 동작이에요.' : null,
    semanticLabel: header ? null : '주간 회의 메모 더보기',
    layout: layout,
    groups: [
      PMenuSheetGroup([
        PMenuSheetItem(
          label: '내보내기',
          description: textOnly ? null : '파일로 저장해요.',
          icon: textOnly ? null : LucideIcons.folderOutput,
          tone: tone,
          enabled: enabled,
          onSelect: onFirst,
        ),
        PMenuSheetItem(
          label: '정렬 바꾸기',
          icon: textOnly ? null : LucideIcons.arrowDownUp,
          onSelect: onSecond,
        ),
      ]),
      PMenuSheetGroup([
        PMenuSheetItem(
          label: '삭제',
          icon: textOnly ? null : LucideIcons.trash2,
          tone: PMenuSheetTone.critical,
        ),
      ]),
    ],
  );
}

Widget _view(PMenuSheetContent content) =>
    Scaffold(body: PMenuSheetView(content: content));

/// 라우트로 띄우는 홈 — 버튼을 누르면 시트가 뜬다. [picked] 에 고른 줄 · 닫힌 뒤의 결과를 적는다.
class _Host extends StatelessWidget {
  const _Host({
    required this.groups,
    this.layout = PMenuSheetLayout.textWithIcon,
    this.title = '주간 회의 메모',
    this.semanticLabel,
    this.picked,
  });

  final List<PMenuSheetGroup> groups;
  final PMenuSheetLayout layout;
  final String? title;
  final String? semanticLabel;
  final ValueChanged<PMenuSheetItem?>? picked;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: GestureDetector(
        key: const ValueKey('open'),
        onTap: () async {
          final result = await PMenuSheet.show(
            context,
            title: title,
            semanticLabel: semanticLabel,
            layout: layout,
            groups: groups,
          );
          picked?.call(result);
        },
        child: const SizedBox(width: 120, height: 48, child: Text('열기')),
      ),
    ),
  );
}

/// 이름 글 — 낱말 단위 줄바꿈(keepAll)이 글자 사이에 끼워 넣는 문자 때문에 find.text 가 못 찾는다. 읽는 이름으로 찾는다.
Finder _label(String name) =>
    find.byWidgetPredicate((w) => w is Text && w.semanticsLabel == name);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('open')));
  await tester.pumpAndSettle();
}

void main() {
  for (final mode in [Brightness.light, Brightness.dark]) {
    for (final combo in _spec.combos(['layout', 'tone'])) {
      for (final state in ['enabled', 'hovered', 'pressed', 'disabled']) {
        testWidgets(
          '${combo['layout']} · ${combo['tone']} · $state · ${mode.name} — 시트가 스펙 값이다',
          (tester) async {
            // 480 보다 넓은 화면 — 가운데에 최대 폭으로 선다
            _viewport(tester, const Size(600, 900));
            final want = _spec.resolve(
              combo,
              state == 'disabled' ? 'disabled' : state,
            );
            final textOnly = combo['layout'] == 'textOnly';
            final critical = combo['tone'] == 'critical';
            final colors = _colors(mode);
            await tester.pumpWidget(
              _app(
                mode,
                _view(
                  _content(
                    layout: textOnly
                        ? PMenuSheetLayout.textOnly
                        : PMenuSheetLayout.textWithIcon,
                    tone: critical
                        ? PMenuSheetTone.critical
                        : PMenuSheetTone.neutral,
                    enabled: state != 'disabled',
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            TestGesture? gesture;
            if (state == 'hovered') {
              gesture = await tester.createGesture(
                kind: PointerDeviceKind.mouse,
              );
              await gesture.addPointer(location: Offset.zero);
              addTearDown(gesture.removePointer);
              await gesture.moveTo(tester.getCenter(find.byKey(_item).first));
              await tester.pumpAndSettle();
            } else if (state == 'pressed') {
              gesture = await tester.startGesture(
                tester.getCenter(find.byKey(_item).first),
              );
              await tester.pump(const Duration(milliseconds: 100));
              await tester.pumpAndSettle();
            }

            // ── 시트 ──
            final sheet = _rect(tester, _root);
            expect(sheet.width, (want['root.maxWidth'] as num).toDouble());
            expect(sheet.center.dx, 300);
            expect(sheet.bottom, 900);
            final decoration =
                tester.widget<DecoratedBox>(find.byKey(_root)).decoration
                    as BoxDecoration;
            expect(want['root.radius'], 20);
            expect(
              decoration.borderRadius,
              const BorderRadius.vertical(top: Radius.circular(20)),
            );
            _expectColor(want['root.background'], mode, decoration.color!);
            expect(want['root.shadow'], 'none');
            expect(decoration.boxShadow, isNull);

            // ── 손잡이 — 늘 있다 ──
            final bar = find.byKey(const ValueKey('p-bottom-sheet-handle-bar'));
            expect(bar, findsOneWidget);
            final h = tester.getRect(bar);
            expect(
              h.size,
              Size(
                (want['handle.width'] as num).toDouble(),
                (want['handle.height'] as num).toDouble(),
              ),
            );
            expect(h.top - sheet.top, want['handle.top']);
            expect(h.center.dx, sheet.center.dx);
            final hd =
                tester.widget<DecoratedBox>(bar).decoration as BoxDecoration;
            expect(hd.borderRadius, BorderRadius.circular(PRounded.full));
            expect(want['handle.radius'], 9999);
            _expectColor(want['handle.background'], mode, hd.color!, 'handle');

            // ── 위 닫기 버튼 · 바닥 취소 버튼은 없다 ──
            expect(
              find.byKey(const ValueKey('p-bottom-sheet-close')),
              findsNothing,
            );

            // ── 머리 — 위 24 · 가운데 ──
            final title = _rect(tester, const ValueKey('p-menu-sheet-title'));
            final desc = _rect(
              tester,
              const ValueKey('p-menu-sheet-description'),
            );
            final gutter = (want['root.paddingX'] as num).toDouble();
            expect(title.top - sheet.top, want['root.paddingTop']);
            expect(title.center.dx, closeTo(sheet.center.dx, 0.01));
            expect(desc.top - title.bottom, want['header.gap']);
            expect(want['header.textAlign'], 'center');
            final titleStyle = tester
                .widget<Text>(find.byKey(const ValueKey('p-menu-sheet-title')))
                .style!;
            _expectType(
              want['title.typography'] as Map<String, dynamic>,
              titleStyle,
              weight: FontWeight.w700,
            );
            expect(want['title.fontWeight'], 700);
            _expectColor(want['title.foreground'], mode, titleStyle.color!);
            final descStyle = tester
                .widget<Text>(
                  find.byKey(const ValueKey('p-menu-sheet-description')),
                )
                .style!;
            _expectType(
              want['description.typography'] as Map<String, dynamic>,
              descStyle,
            );
            _expectColor(
              want['description.foreground'],
              mode,
              descStyle.color!,
            );

            // ── 묶음 — 좌우 화면 여백 · 머리 아래 16 · 묶음 사이 10 · 아래 16 ──
            final groups = find.byKey(const ValueKey('p-menu-sheet-group'));
            expect(groups, findsNWidgets(2));
            final g1 = tester.getRect(groups.at(0));
            final g2 = tester.getRect(groups.at(1));
            expect(g1.left - sheet.left, gutter);
            expect(sheet.right - g1.right, gutter);
            expect(g1.top - desc.bottom, want['header.paddingBottom']);
            expect(g2.top - g1.bottom, want['group.gap']);
            expect(sheet.bottom - g2.bottom, want['root.paddingBottom']);
            final gd =
                tester.widget<DecoratedBox>(groups.first).decoration
                    as BoxDecoration;
            expect(want['group.radius'], 16);
            expect(gd.borderRadius, BorderRadius.circular(16));
            _expectColor(want['group.background'], mode, gd.color!, 'group');

            // ── 줄 — 첫 줄이 시험 대상 ──
            final item = tester.getRect(find.byKey(_item).first);
            final second = tester.getRect(find.byKey(_item).at(1));
            final paddingX = (want['item.paddingX'] as num).toDouble();
            final paddingY = (want['item.paddingY'] as num).toDouble();
            final minHeight = (want['item.minHeight'] as num).toDouble();
            expect(item.left, g1.left);
            expect(item.width, g1.width);
            // 설명이 있으면 이름 22 + 설명 18 + 사이 2 에 위아래 14, 없으면 이름 22 + 28 = 50 → 최소 52
            final label = tester.getRect(
              find.byKey(const ValueKey('p-menu-sheet-item-label')).first,
            );
            final labelStyle = tester
                .widget<Text>(
                  find.byKey(const ValueKey('p-menu-sheet-item-label')).first,
                )
                .style!;
            _expectType(
              want['itemLabel.typography'] as Map<String, dynamic>,
              labelStyle,
              weight: FontWeight.w400,
            );
            expect(
              item.height,
              textOnly ? minHeight : paddingY * 2 + 22 + 2 + 18,
            );
            expect(second.height, minHeight);
            expect(minHeight, 52);
            if (textOnly) {
              // 글만 — 가운데 정렬 · 아이콘 · 설명 없음
              expect(label.center.dx, closeTo(item.center.dx, 0.01));
              expect(
                find.byKey(const ValueKey('p-menu-sheet-item-icon')),
                findsNothing,
              );
              expect(
                find.byKey(const ValueKey('p-menu-sheet-item-description')),
                findsNothing,
              );
              expect(want['itemLabel.textAlign'], 'center');
              expect(want['item.justifyContent'], 'center');
            } else {
              final icon = tester.getRect(
                find.byKey(const ValueKey('p-menu-sheet-item-icon')).first,
              );
              final scale = tester
                  .widget<AnimatedScale>(
                    find.byKey(const ValueKey('p-menu-sheet-item-scale')).first,
                  )
                  .scale;
              // 눌렀을 때만 줄어든다 — 가운데 기준이라 왼쪽 자리가 안으로 들어온다
              final pressedScale = state == 'pressed' ? _basisScale(item) : 1.0;
              expect(scale, closeTo(pressedScale, 1e-9));
              final shrink = (1 - pressedScale) * item.width / 2;
              expect(icon.width, closeTo(22 * pressedScale, 0.01));
              expect(want['itemIcon.size'], 22);
              expect(
                icon.left - item.left,
                closeTo(paddingX + shrink + 0, 1.0),
              );
              // 아이콘 ↔ 이름 14
              expect(
                label.left - icon.right,
                closeTo(
                  (want['item.gap'] as num).toDouble() * pressedScale,
                  0.5,
                ),
              );
              expect(label.top - item.top, closeTo(paddingY, 1.5));
              final d = tester.getRect(
                find
                    .byKey(const ValueKey('p-menu-sheet-item-description'))
                    .first,
              );
              expect(
                d.top - label.bottom,
                closeTo((want['itemDescription.gap'] as num).toDouble(), 0.5),
              );
              final ds = tester
                  .widget<Text>(
                    find
                        .byKey(const ValueKey('p-menu-sheet-item-description'))
                        .first,
                  )
                  .style!;
              _expectType(
                want['itemDescription.typography'] as Map<String, dynamic>,
                ds,
                weight: FontWeight.w500,
              );
              _expectColor(
                want['itemDescription.foreground'],
                mode,
                ds.color!,
                'description',
              );
              final iconWidget = tester.widget<Icon>(
                find.byKey(const ValueKey('p-menu-sheet-item-icon')).first,
              );
              _expectColor(
                want['itemIcon.color'],
                mode,
                iconWidget.color!,
                'icon',
              );
            }
            _expectColor(
              want['itemLabel.foreground'],
              mode,
              labelStyle.color!,
              'label',
            );

            // 바탕 — 호버 · 누름은 누름 바탕, 막힌 줄은 그대로
            final bg =
                tester
                        .widget<AnimatedContainer>(find.byKey(_item).first)
                        .decoration
                    as BoxDecoration?;
            if (state == 'hovered' || state == 'pressed') {
              _expectColor(
                want['item.background'],
                mode,
                bg!.color!,
                'item bg',
              );
              expect(bg.color, colors.bgNeutralWeakPressed);
            } else {
              expect(bg?.color?.a ?? 0, 0);
            }
            if (state == 'hovered' || state == 'pressed') {
              if (critical) {
                expect(
                  tester
                      .widget<Text>(
                        find
                            .byKey(const ValueKey('p-menu-sheet-item-label'))
                            .first,
                      )
                      .style!
                      .color,
                  colors.fgCriticalContrast,
                );
              }
            }
            if (state == 'disabled') {
              expect(labelStyle.color, colors.fgDisabled);
            }

            // 줄 사이 선 — 안쪽 아래 1px, 묶음의 마지막 줄에는 없다
            final dividers = find.byKey(const ValueKey('p-menu-sheet-divider'));
            expect(dividers, findsNWidgets(1));
            final line = tester.getRect(dividers);
            expect(line.height, 1);
            expect(line.bottom, item.bottom);
            expect(line.left, item.left);
            expect(line.right, item.right);
            _expectColor(
              want['divider.color'],
              mode,
              tester.widget<ColoredBox>(dividers).color,
              'divider',
            );

            if (state == 'pressed') await gesture?.up();
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }

  // 누름 축소 — 기준 길이 max(높이, 폭 ÷ 4, 24), 배율 (기준 − 2) ÷ 기준
  group('누름', () {
    testWidgets('모션 줄이기면 줄지 않고 색만 바뀐다', (tester) async {
      _viewport(tester, const Size(600, 900));
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _app(Brightness.light, _view(_content())),
        ),
      );
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(_item).first),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey('p-menu-sheet-item-scale')).first,
            )
            .scale,
        1,
      );
      await g.up();
    });

    testWidgets('막힌 줄은 눌러도 누름 바탕 · 축소가 없다', (tester) async {
      _viewport(tester, const Size(600, 900));
      await tester.pumpWidget(
        _app(Brightness.light, _view(_content(enabled: false))),
      );
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(_item).first),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey('p-menu-sheet-item-scale')).first,
            )
            .scale,
        1,
      );
      await g.up();
    });
  });

  group('모양 — 폰 폭', () {
    testWidgets('360 폭에서도 좌우 24 · 안전 영역을 아래에 더한다', (tester) async {
      _viewport(tester, const Size(360, 800), safeBottom: 34);
      await tester.pumpWidget(_app(Brightness.light, _view(_content())));
      await tester.pumpAndSettle();
      final sheet = _rect(tester, _root);
      expect(sheet.width, 360);
      final last = tester.getRect(
        find.byKey(const ValueKey('p-menu-sheet-group')).last,
      );
      // 아래 16 + 안전 영역 34
      expect(sheet.bottom - last.bottom, 16 + 34);
      expect(last.left - sheet.left, 24);
    });

    testWidgets('머리가 없으면 위 24 에서 바로 첫 묶음이 선다', (tester) async {
      _viewport(tester, const Size(600, 900));
      await tester.pumpWidget(
        _app(Brightness.light, _view(_content(header: false))),
      );
      await tester.pumpAndSettle();
      final sheet = _rect(tester, _root);
      final g1 = tester.getRect(
        find.byKey(const ValueKey('p-menu-sheet-group')).first,
      );
      expect(g1.top - sheet.top, 24);
    });

    testWidgets('화면의 90% 를 넘는 목록은 목록만 스크롤한다(머리는 그대로)', (tester) async {
      _viewport(tester, const Size(390, 600));
      final many = PMenuSheetContent(
        title: '긴 목록',
        groups: [
          PMenuSheetGroup([
            for (var i = 0; i < 30; i++)
              PMenuSheetItem(label: '줄 $i', icon: LucideIcons.copy),
          ]),
        ],
      );
      await tester.pumpWidget(_app(Brightness.light, _view(many)));
      await tester.pumpAndSettle();
      final sheet = _rect(tester, _root);
      expect(sheet.height, closeTo(600 * 0.9, 0.01));
      final title = _rect(tester, const ValueKey('p-menu-sheet-title'));
      expect(title.top - sheet.top, 24);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      // 머리는 그대로
      expect(
        _rect(tester, const ValueKey('p-menu-sheet-title')).top - sheet.top,
        24,
      );
    });
  });

  group('동작', () {
    List<PMenuSheetGroup> groups({
      required List<String> log,
      bool secondEnabled = true,
    }) => [
      PMenuSheetGroup([
        PMenuSheetItem(
          label: '내보내기',
          icon: LucideIcons.folderOutput,
          onSelect: () => log.add('내보내기'),
        ),
        PMenuSheetItem(
          label: '정렬 바꾸기',
          icon: LucideIcons.arrowDownUp,
          enabled: secondEnabled,
          onSelect: () => log.add('정렬'),
        ),
      ]),
    ];

    testWidgets('줄을 누르면 시트가 먼저 닫히고 다 닫힌 뒤 동작이 불린다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final log = <String>[];
      final sheetAtCall = <bool>[];
      PMenuSheetItem? picked;
      final g = [
        PMenuSheetGroup([
          PMenuSheetItem(
            label: '내보내기',
            icon: LucideIcons.folderOutput,
            onSelect: () {
              log.add('내보내기');
              sheetAtCall.add(
                find
                    .byKey(const ValueKey('p-menu-sheet-list'))
                    .evaluate()
                    .isNotEmpty,
              );
            },
          ),
        ]),
      ];
      await tester.pumpWidget(
        _app(Brightness.light, _Host(groups: g, picked: (v) => picked = v)),
      );
      await _open(tester);
      expect(find.byKey(const ValueKey('p-menu-sheet-list')), findsOneWidget);
      await tester.tap(_label('내보내기'));
      // 닫히는 중 — 아직 동작은 불리지 않는다
      await tester.pump(const Duration(milliseconds: 50));
      expect(log, isEmpty);
      await tester.pumpAndSettle();
      expect(log, ['내보내기']);
      // 불린 때에는 시트가 이미 없다
      expect(sheetAtCall, [false]);
      expect(picked?.label, '내보내기');
      expect(find.byKey(const ValueKey('p-menu-sheet-list')), findsNothing);
    });

    testWidgets('막힌 줄은 실행하지 않고 닫히지 않는다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final log = <String>[];
      await tester.pumpWidget(
        _app(
          Brightness.light,
          _Host(groups: groups(log: log, secondEnabled: false)),
        ),
      );
      await _open(tester);
      await tester.tap(_label('정렬 바꾸기'));
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(find.byKey(const ValueKey('p-menu-sheet-list')), findsOneWidget);
    });

    testWidgets('바깥(딤) 누르기 · 손잡이 · Esc 로 닫힌다 — 동작은 불리지 않는다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final log = <String>[];
      PMenuSheetItem? picked = const PMenuSheetItem(label: '지켜보는 값');
      await tester.pumpWidget(
        _app(
          Brightness.light,
          _Host(
            groups: groups(log: log),
            picked: (v) => picked = v,
          ),
        ),
      );
      // 딤
      await _open(tester);
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('p-menu-sheet-list')), findsNothing);
      expect(picked, isNull);
      // 손잡이
      await _open(tester);
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-handle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('p-menu-sheet-list')), findsNothing);
      // Esc
      await _open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('p-menu-sheet-list')), findsNothing);
      expect(log, isEmpty);
    });

    testWidgets('뒤로 가기로 닫힌다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final log = <String>[];
      await tester.pumpWidget(
        _app(Brightness.light, _Host(groups: groups(log: log))),
      );
      await _open(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('p-menu-sheet-list')), findsNothing);
      expect(log, isEmpty);
    });

    testWidgets('줄을 누른 채 10px 넘게 끌면 실행하지 않는다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final log = <String>[];
      await tester.pumpWidget(
        _app(Brightness.light, _Host(groups: groups(log: log))),
      );
      await _open(tester);
      // 열린 뒤 0.5초는 끌리지 않는다
      await tester.pump(const Duration(milliseconds: 600));
      final g = await tester.startGesture(tester.getCenter(_label('내보내기')));
      await g.moveBy(const Offset(0, 14));
      await tester.pump(const Duration(milliseconds: 50));
      await g.moveBy(const Offset(0, 6));
      await tester.pump(const Duration(milliseconds: 50));
      // 천천히 짧게 — 놓아도 닫히지 않고 제자리로 돌아온다
      await g.up();
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(find.byKey(const ValueKey('p-menu-sheet-list')), findsOneWidget);
    });

    testWidgets('줄 밖에서 떼면 실행하지 않는다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final log = <String>[];
      await tester.pumpWidget(
        _app(Brightness.light, _Host(groups: groups(log: log))),
      );
      await _open(tester);
      await tester.pump(const Duration(milliseconds: 600));
      final g = await tester.startGesture(tester.getCenter(_label('내보내기')));
      await g.moveTo(const Offset(195, 20));
      await g.up();
      await tester.pumpAndSettle();
      expect(log, isEmpty);
    });

    testWidgets('키보드 — Tab 으로 줄에 닿으면 안쪽 링이 서고 Enter 로 실행한다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final log = <String>[];
      await tester.pumpWidget(
        _app(Brightness.light, _Host(groups: groups(log: log))),
      );
      await _open(tester);
      expect(
        find.byKey(const ValueKey('p-menu-sheet-focus-ring')),
        findsNothing,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final ring = find.byKey(const ValueKey('p-menu-sheet-focus-ring'));
      expect(ring, findsOneWidget);
      // 줄 안쪽 2px — 링이 줄 상자를 넘지 않는다
      expect(tester.getRect(ring), tester.getRect(find.byKey(_item).first));
      final rd = tester.widget<DecoratedBox>(ring).decoration as BoxDecoration;
      expect((rd.border! as Border).top.width, 2);
      expect((rd.border! as Border).top.color, PColors.light.strokeFocusRing);
      expect(_spec.resolve({}, 'focused')['focusRing.width'], 2);
      expect(_spec.resolve({}, 'focused')['focusRing.offset'], -2);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(log, ['내보내기']);
    });

    testWidgets('막힌 줄에는 Tab 이 서지 않는다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final log = <String>[];
      await tester.pumpWidget(
        _app(
          Brightness.light,
          _Host(groups: groups(log: log, secondEnabled: false)),
        ),
      );
      await _open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // 첫 줄
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // 막힌 줄을 건너뛰고 보조 기술용 닫기
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('p-menu-sheet-focus-ring')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('p-menu-sheet-close')), findsOneWidget);
    });

    testWidgets('보조 기술용 닫기 — 평소엔 보이지 않고 Tab 이 닿으면 보인다, Enter 로 닫는다', (
      tester,
    ) async {
      _viewport(tester, const Size(390, 800));
      final log = <String>[];
      await tester.pumpWidget(
        _app(Brightness.light, _Host(groups: groups(log: log))),
      );
      await _open(tester);
      // 평소 — 크기 0
      expect(
        tester.getSize(find.byKey(const ValueKey('p-menu-sheet-close'))).height,
        0,
      );
      // 읽는다
      expect(find.bySemanticsLabel('닫기'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final close = tester.getRect(
        find.byKey(const ValueKey('p-menu-sheet-close')),
      );
      final want = _spec.resolve({}, 'enabled');
      expect(close.height, greaterThanOrEqualTo(52));
      expect(want['closeButton.minHeight'], 52);
      expect(want['closeButton.paddingX'], 20);
      expect(want['closeButton.radius'], 12);
      // 폭 전체(좌우 화면 여백 24)
      expect(close.width, 390 - 48);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('p-menu-sheet-list')), findsNothing);
      expect(log, isEmpty);
    });

    testWidgets('읽기 — 시트는 제목이 이름인 dialog, 줄은 이름 · 설명 · 막힘을 읽는다', (
      tester,
    ) async {
      _viewport(tester, const Size(390, 800));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Brightness.light,
          _Host(
            groups: [
              const PMenuSheetGroup([
                PMenuSheetItem(
                  label: '내보내기',
                  description: '파일로 저장해요.',
                  icon: LucideIcons.folderOutput,
                ),
                PMenuSheetItem(label: '정렬 바꾸기', enabled: false),
              ]),
            ],
          ),
        ),
      );
      await _open(tester);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('p-menu-sheet-list'))),
        isNotNull,
      );
      expect(find.bySemanticsLabel('주간 회의 메모'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(_item).first),
        matchesSemantics(
          label: '내보내기',
          hint: '파일로 저장해요.',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(_item).at(1)),
        matchesSemantics(
          label: '정렬 바꾸기',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('제목이 없으면 semanticLabel 이 시트의 이름이다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Brightness.light,
          _Host(
            title: null,
            semanticLabel: '주간 회의 메모 더보기',
            groups: groups(log: <String>[]),
          ),
        ),
      );
      await _open(tester);
      expect(find.bySemanticsLabel('주간 회의 메모 더보기'), findsOneWidget);
      expect(find.byKey(const ValueKey('p-menu-sheet-title')), findsNothing);
      handle.dispose();
    });

    testWidgets('글만 시트도 라우트로 뜨고 줄을 누르면 닫힌다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final log = <String>[];
      await tester.pumpWidget(
        _app(
          Brightness.light,
          _Host(
            layout: PMenuSheetLayout.textOnly,
            groups: [
              PMenuSheetGroup([
                PMenuSheetItem(label: '사진 찍기', onSelect: () => log.add('찍기')),
              ]),
            ],
          ),
        ),
      );
      await _open(tester);
      final label = tester.getRect(_label('사진 찍기'));
      expect(label.center.dx, closeTo(195, 0.01));
      await tester.tap(_label('사진 찍기'));
      await tester.pumpAndSettle();
      expect(log, ['찍기']);
    });

    testWidgets('스펙이 정한 동작 값 — 끌기 · 줄 · 닫기 · 모션', (tester) async {
      // 문장으로 된 스펙 값이 바뀌면 여기서 알아챈다
      final base = _spec.resolve({}, 'enabled');
      expect(base['root.maxHeight'], '화면 높이의 90%');
      expect(base['overlay.zIndex'], 100);
      expect(base['root.zIndex'], 101);
      expect(base['item.transitionDuration'], '150ms');
      expect(PDuration.colorTransition, const Duration(milliseconds: 150));
      expect(base['root.paddingTop'], PSpacing.x6);
      expect(base['root.paddingBottom'], PSpacing.x4);
      expect(base['root.paddingX'], PSpacing.globalGutter);
      expect(base['group.gap'], PSpacing.x2_5);
      expect(base['item.gap'], PSpacing.x3_5);
      expect(base['itemDescription.gap'], PSpacing.x0_5);
      final motion = _spec.json['motion'] as Map<String, dynamic>;
      expect((motion['열림 — 시트'] as Map<String, dynamic>)['duration'], '300ms');
      expect((motion['닫힘 — 시트'] as Map<String, dynamic>)['duration'], '200ms');
    });
  });
}

/// 눌림 배율 — 기준 길이 max(높이, 폭 ÷ 4, 24), (기준 − 2) ÷ 기준.
double _basisScale(Rect item) {
  final basis = [
    item.height,
    item.width / 4,
    24.0,
  ].reduce((a, b) => a > b ? a : b);
  return (basis - 2) / basis;
}
