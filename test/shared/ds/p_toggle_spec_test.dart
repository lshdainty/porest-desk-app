// Toggle 이 스펙 값(test/fixtures/design_spec/toggle.json)대로인지 — 끔 · 켬 × 톤 × 상태(기본 · 누름 · 비활성) × 라이트 ·
// 다크의 상자 · 아이콘(크기 · 선 굵기 · 색) · 바탕 · 누름 축소와, 눌림 · 키보드 · 읽는 말. 웹은 같은 JSON 을 크로미움에서 잰다.
//
// 앱에 없는 상태(웹의 hovered · focused — 올림 · 포커스 링)는 재지 않는다. 선 굵기(2 · 2.5)는 lucide 글꼴의 굵기 짝으로 본다
// (Lucide = 2, Lucide500 = 2.5). 누르는 영역("44 × 44")은 누른 자리로, 누름 축소("단추 전체 2px")는 그려진 배율로 잰다.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/toggle/p_toggle.dart';
import 'package:groo_damda_app/shared/ds/toggle/toggle_demo.dart';

import '../../support/design_spec.dart';

final _spec = DesignSpec.load('toggle');

/// 앱의 상태 — 웹의 hovered(올림) · focused(키보드 포커스 링)는 앱에 없다.
final _appStates = _spec.states
    .where((s) => s != 'hovered' && s != 'focused')
    .toList();

Widget _host(
  Brightness mode,
  Widget child, {
  bool reduceMotion = false,
  Alignment alignment = Alignment.topLeft,
}) {
  final app = MaterialApp(
    theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(
      body: Align(alignment: alignment, child: child),
    ),
  );
  return reduceMotion
      ? MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: app,
        )
      : app;
}

PToggle _toggle({
  bool pressed = false,
  ValueChanged<bool>? onChanged,
  PToggleTone tone = PToggleTone.defaultTone,
  String label = '금액 가리기',
}) => PToggle(
  semanticLabel: label,
  pressed: pressed,
  onChanged: onChanged,
  icon: LucideIcons.eye,
  pressedIcon: LucideIcons.eyeOff500,
  tone: tone,
);

Finder get _box => find.byKey(const ValueKey('toggle-box'));
Finder get _icon => find.byKey(const ValueKey('toggle-icon'));

/// 그려지는 배율 — 그 상자에서 화면까지 겹친 변환의 확대.
double _paintedScale(WidgetTester tester, Finder finder) =>
    tester.renderObject(finder).getTransformTo(null).entry(0, 0);

/// 실패를 모으는 도우미.
class _Check {
  _Check(this.mode, this.want, this.where);

  final Brightness mode;
  final Map<String, Object?> want;
  final String where;
  final failures = <String>[];

  void fail(String message) => failures.add('$where — $message');

  void color(String key, Color actual) {
    final w = pickMode(want[key], mode);
    if (w == null) return;
    if (!sameColor(specColor(w), actual)) {
      fail('$key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    final w = want[key];
    if (w is num && (w - actual).abs() > 0.5) {
      fail('$key: 스펙 $w · 실제 $actual');
    }
  }

  void cursor(String key, MouseCursor actual) {
    final expected = switch (want[key]) {
      'pointer' => SystemMouseCursors.click,
      'not-allowed' => SystemMouseCursors.forbidden,
      _ => null,
    };
    if (expected != null && actual != expected) {
      fail('$key: 스펙 ${want[key]} · 실제 $actual');
    }
  }

  void motion(String durationKey, String easingKey, Duration d, Curve curve) {
    if (want[durationKey] != null && specMs(want[durationKey]) != d) {
      fail('$durationKey: 스펙 ${want[durationKey]} · 실제 $d');
    }
    if (want[easingKey] != null) {
      final cubic = specCubic(want[easingKey]);
      if (curve is! Cubic ||
          [curve.a, curve.b, curve.c, curve.d].join(',') != cubic.join(',')) {
        fail('$easingKey: 스펙 ${want[easingKey]} · 실제 $curve');
      }
    }
  }

  void coverage(Set<String> measured, Set<String> elsewhere) {
    for (final key in want.keys) {
      if (!measured.contains(key) && !elsewhere.contains(key)) {
        fail('$key: 스펙에 있는데 이 테스트가 재지 않는다 — 재는 곳을 더한다');
      }
    }
  }
}

/// 앱에 없는 값 — 포커스 링은 웹 상태다.
const _webOnly = {'focusRing.width', 'focusRing.offset', 'focusRing.color'};

/// 동작 테스트가 보는 값 — 누르는 영역 · 고정 이름 · 전환이 무엇을 바꾸는지.
const _behavior = {'root.touchTarget', 'root.name', 'root.transitionProperty'};

void main() {
  for (final mode in Brightness.values) {
    for (final combo in _spec.combos(['toggled', 'tone'])) {
      for (final state in _appStates) {
        final title =
            '${mode.name} ${combo['toggled']} ${combo['tone']} $state';
        testWidgets('$title — 스펙 값이다', (tester) async {
          final on = combo['toggled'] == 'on';
          final inverted = combo['tone'] == 'inverted';
          final disabled = state == 'disabled';
          await tester.pumpWidget(
            _host(
              mode,
              _toggle(
                pressed: on,
                onChanged: disabled ? null : (_) {},
                tone: inverted ? PToggleTone.inverted : PToggleTone.defaultTone,
              ),
            ),
          );
          // 놓인 자리는 누르기 전에 잰다 — 누르면 단추 전체가 줄어 그려진 사각형이 작아진다
          final rect = tester.getRect(_box);
          TestGesture? gesture;
          if (state == 'pressed') {
            gesture = await tester.startGesture(rect.center);
            await tester.pump();
          }
          await tester.pump(const Duration(milliseconds: 400));
          final k = _Check(mode, _spec.resolve(combo, state), title);
          final measured = <String>{};

          // 상자 — 40 · 모서리 8 · 바탕(켬 · 끔과 상관없이 투명, 누름에만 칠한다)
          final deco =
              tester.widget<DecoratedBox>(_box).decoration as BoxDecoration;
          k.px('root.size', rect.width);
          k.px('root.size', rect.height);
          k.px('root.radius', (deco.borderRadius! as BorderRadius).topLeft.x);
          k.color('root.background', deco.color ?? Colors.transparent);
          measured.addAll(['root.size', 'root.radius', 'root.background']);

          // 커서 · 전환(바탕만 150ms)
          k.cursor(
            'root.cursor',
            tester
                .widget<MouseRegion>(
                  find
                      .ancestor(of: _box, matching: find.byType(MouseRegion))
                      .first,
                )
                .cursor,
          );
          final fade = tester.widget<TweenAnimationBuilder<Color?>>(
            find.ancestor(
              of: _box,
              matching: find.byType(TweenAnimationBuilder<Color?>),
            ),
          );
          k.motion(
            'root.transitionDuration',
            'root.transitionEasing',
            fade.duration,
            fade.curve,
          );
          measured.addAll([
            'root.cursor',
            'root.transitionDuration',
            'root.transitionEasing',
          ]);

          // 아이콘 — 20 · 가운데 · 켬 2.5(Lucide500) · 끔 2(Lucide) · 색
          final icon = tester.widget<Icon>(_icon);
          k.px('icon.size', icon.size!);
          final iconRect = tester.getRect(_icon);
          if ((iconRect.center - rect.center).distance > 0.5) {
            k.fail('icon: 단추 가운데가 아니다 $iconRect · $rect');
          }
          final wantFont = (k.want['icon.strokeWidth'] as num) == 2.5
              ? toggleOnFont
              : 'Lucide';
          if (icon.icon!.fontFamily != wantFont) {
            k.fail(
              'icon.strokeWidth: 스펙 ${k.want['icon.strokeWidth']}(글꼴 $wantFont) · 실제 ${icon.icon!.fontFamily}',
            );
          }
          k.color('icon.color', icon.color!);
          measured.addAll(['icon.size', 'icon.strokeWidth', 'icon.color']);

          // 누름 축소 — 단추 전체(기준 40)
          final scale = tester.widget<AnimatedScale>(
            find.ancestor(of: _box, matching: find.byType(AnimatedScale)).first,
          );
          final wantScale = k.want['root.scale'] != null ? 38 / 40 : 1.0;
          if ((scale.scale - wantScale).abs() > 1e-3) {
            k.fail('root.scale: 스펙 $wantScale · 실제 ${scale.scale}');
          }
          k.motion(
            'root.scaleDuration',
            'root.scaleEasing',
            scale.duration,
            scale.curve,
          );
          measured.addAll([
            'root.scale',
            'root.scaleDuration',
            'root.scaleEasing',
          ]);

          k.coverage(measured, {..._webOnly, ..._behavior});
          await gesture?.up();
          await tester.pump(const Duration(milliseconds: 400));
          if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
        });
      }
    }
  }

  group('동작', () {
    testWidgets('누르는 영역은 보이는 40 둘레로 2 씩 넓은 44 × 44 다 — 놓인 자리는 그대로다', (
      tester,
    ) async {
      var changes = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          Center(child: _toggle(onChanged: (_) => changes++)),
          alignment: Alignment.center,
        ),
      );
      final r = tester.getRect(_box);
      expect(r.size, const Size.square(40));
      expect(PTouch.min, 44);
      await tester.tapAt(r.center + const Offset(21, 0));
      await tester.tapAt(r.center + const Offset(0, -21));
      expect(changes, 2);
      await tester.tapAt(r.center + const Offset(23, 0));
      expect(changes, 2);
    });

    testWidgets('손을 뗄 때 켬 · 끔이 바뀌고 부른다 — 누르는 동안은 바꾸지 않는다 · 끌어 나가면 바꾸지 않는다', (
      tester,
    ) async {
      final calls = <bool>[];
      var on = false;
      late StateSetter set;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return _toggle(
                pressed: on,
                onChanged: (v) {
                  calls.add(v);
                  set(() => on = v);
                },
              );
            },
          ),
        ),
      );
      final g = await tester.startGesture(tester.getCenter(_box));
      await tester.pump();
      expect(calls, isEmpty);
      await g.up();
      await tester.pump();
      expect(calls, [true]);
      await tester.tap(_box);
      expect(calls, [true, false]);
      // 손가락을 단추 밖으로 끌어 나가 떼면 바꾸지 않는다
      final out = await tester.startGesture(tester.getCenter(_box));
      await out.moveBy(const Offset(120, 0));
      await out.up();
      await tester.pump();
      expect(calls, [true, false]);
    });

    testWidgets('막히면 누를 수 없다 · Tab 에서 빠진다 · 키로도 바뀌지 않는다', (tester) async {
      var changes = 0;
      await tester.pumpWidget(_host(Brightness.light, _toggle()));
      await tester.tap(_box, warnIfMissed: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(changes, 0);
      // 켜 둔 채 막혀도 켬 그대로(고른 모양을 지우지 않는다)
      await tester.pumpWidget(_host(Brightness.light, _toggle(pressed: true)));
      expect(tester.widget<Icon>(_icon).icon!.fontFamily, toggleOnFont);
    });

    testWidgets('Space · Enter 로 켜고 끈다(키보드 포커스를 받는다)', (tester) async {
      final calls = <bool>[];
      await tester.pumpWidget(
        _host(Brightness.light, _toggle(onChanged: calls.add)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, [true, true]);
    });

    testWidgets(
      '아이콘은 지금 상태를 그린다 — 끔은 eye, 켬은 eye-off(선 2.5) · 모으기 단추는 같은 아이콘이다',
      (tester) async {
        await tester.pumpWidget(_host(Brightness.light, _toggle()));
        expect(tester.widget<Icon>(_icon).icon, LucideIcons.eye);
        await tester.pumpWidget(
          _host(Brightness.light, _toggle(pressed: true)),
        );
        expect(tester.widget<Icon>(_icon).icon, LucideIcons.eyeOff500);
        // 모으기 단추 — 사선 없이 같은 모양(코드 포인트가 같고 굵기만 다르다)
        expect(LucideIcons.star.codePoint, LucideIcons.star500.codePoint);
        expect(LucideIcons.pin.codePoint, LucideIcons.pin500.codePoint);
      },
    );

    test('켬의 아이콘은 선 2.5 짝을 줘야 한다 — 굵기를 단추가 정한다', () {
      expect(LucideIcons.eyeOff500.fontFamily, toggleOnFont);
      expect(toggleOffFonts, contains(LucideIcons.eye.fontFamily));
    });
  });

  group('움직임', () {
    testWidgets('누르면 단추 전체가 2px 거리 준다(기준 40) — 자리는 그대로, 모션 줄이기면 줄지 않는다', (
      tester,
    ) async {
      for (final reduce in [false, true]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            _toggle(onChanged: (_) {}),
            reduceMotion: reduce,
          ),
        );
        final rect = tester.getRect(_box);
        final before = _paintedScale(tester, _box);
        final g = await tester.startGesture(rect.center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          (tester.getRect(_box).center - rect.center).distance,
          lessThan(0.01),
        );
        expect(
          _paintedScale(tester, _box) / before,
          closeTo(reduce ? 1 : 38 / 40, 1e-3),
          reason: 'reduce=$reduce',
        );
        await g.up();
        await tester.pump(const Duration(milliseconds: 400));
      }
    });

    testWidgets('아이콘 · 굵기 · 색은 바로 바뀐다 — 전환이 없다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, _toggle(onChanged: (_) {})),
      );
      final c = GrooTheme.light().extension<PColors>()!;
      expect(tester.widget<Icon>(_icon).color, c.fgNeutralMuted);
      await tester.pumpWidget(
        _host(Brightness.light, _toggle(pressed: true, onChanged: (_) {})),
      );
      // 한 프레임 만에 켬의 색 · 아이콘
      expect(tester.widget<Icon>(_icon).color, c.fgNeutral);
      expect(tester.widget<Icon>(_icon).icon, LucideIcons.eyeOff500);
    });

    testWidgets('누름 바탕은 150ms 에 나타나고 손을 떼면 사라진다 — 브랜드 채움 위에는 없다', (
      tester,
    ) async {
      final c = GrooTheme.light().extension<PColors>()!;
      for (final tone in PToggleTone.values) {
        await tester.pumpWidget(
          _host(Brightness.light, _toggle(onChanged: (_) {}, tone: tone)),
        );
        final g = await tester.startGesture(tester.getCenter(_box));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final bg =
            (tester.widget<DecoratedBox>(_box).decoration as BoxDecoration)
                .color!;
        if (tone == PToggleTone.inverted) {
          expect(bg.a, 0, reason: '브랜드 채움 위 — 누름 색 짝이 없다');
        } else {
          expect(sameColor(c.bgLayerDefaultPressed, bg), isTrue);
        }
        await g.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          (tester.widget<DecoratedBox>(_box).decoration as BoxDecoration)
              .color!
              .a,
          0,
        );
      }
    });
  });

  group('읽는 말', () {
    testWidgets('이름은 고정이고 켬은 toggled 가 알린다 — 켜도 이름이 바뀌지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      Widget on(bool v) =>
          _host(Brightness.light, _toggle(pressed: v, onChanged: (_) {}));
      await tester.pumpWidget(on(false));
      final off = tester.getSemantics(find.bySemanticsLabel('금액 가리기'));
      expect(
        off,
        isSemantics(
          label: '금액 가리기',
          isButton: true,
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      await tester.pumpWidget(on(true));
      expect(
        tester.getSemantics(find.bySemanticsLabel('금액 가리기')),
        isSemantics(
          label: '금액 가리기',
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      // 막힘
      await tester.pumpWidget(_host(Brightness.light, _toggle(pressed: true)));
      expect(
        tester.getSemantics(find.bySemanticsLabel('금액 가리기')),
        isSemantics(
          hasEnabledState: true,
          isEnabled: false,
          hasToggledState: true,
          isToggled: true,
        ),
      );
      semantics.dispose();
    });
  });

  testWidgets('견본이 폰 폭 312 에서 넘침 없이 그려진다', (tester) async {
    for (final mode in Brightness.values) {
      await tester.pumpWidget(
        _host(
          mode,
          const SizedBox(
            width: 312,
            child: SingleChildScrollView(child: ToggleDemo()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: mode.name);
    }
  });
}
