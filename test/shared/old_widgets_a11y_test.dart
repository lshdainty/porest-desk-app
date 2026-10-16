// 옛 부품(lib/shared/widgets)의 공용 접근성 — 01A-062 · 071 · 082 · 090 · 091.
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_checkbox.dart';
import 'package:groo_damda_app/shared/widgets/p_chip.dart';
import 'package:groo_damda_app/shared/widgets/p_progress.dart';
import 'package:groo_damda_app/shared/widgets/p_tabs.dart';

Widget _host(Widget child, {Brightness mode = Brightness.light}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

Iterable<SemanticsData> _nodes(WidgetTester tester) {
  final out = <SemanticsData>[];
  void walk(SemanticsNode n) {
    out.add(n.getSemanticsData());
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return out;
}

void main() {
  testWidgets('동작 줄이기를 켜면 로딩 원이 돌지 않는다', (tester) async {
    for (final reduce in [true, false]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: _host(const PCircularProgressIndicator()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, !reduce, reason: 'reduce=$reduce');
    }
  });

  for (final mode in Brightness.values) {
    testWidgets('PButton ${mode.name} — 막힘은 전용 색(불투명도 없음), 버튼 역할, 누르는 영역 44', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PButton(label: '저장', onPressed: null),
              PButton(label: '삭제', onPressed: () {}, size: PButtonSize.sm),
            ],
          ),
          mode: mode,
        ),
      );
      final t = mode == Brightness.dark
          ? GrooTokens.dark
          : GrooTokens.light;
      expect(find.byType(Opacity), findsNothing, reason: '불투명도로 흐리게 하지 않는다');
      final disabledText = tester.widget<Text>(find.text('저장'));
      expect(disabledText.style!.color, t.fgDisabled);
      final saveNode = _nodes(tester).firstWhere((n) => n.label.contains('저장'));
      expect(saveNode.flagsCollection.isButton, isTrue);
      // 보이는 sm 은 32 — 위 6 에서도 눌린다(44)
      var taps = 0;
      await tester.pumpWidget(
        _host(
          PButton(label: '삭제', onPressed: () => taps++, size: PButtonSize.sm),
          mode: mode,
        ),
      );
      final r = tester.getRect(find.byType(PButton));
      await tester.tapAt(Offset(r.center.dx, r.top - 5));
      expect(taps, 1);
      handle.dispose();
    });
  }

  testWidgets('PChip · PTabs · PCheckbox — 고른 상태를 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PChip(label: '식비', selected: true, onTap: () {}),
            PTabs<int>(
              value: 1,
              onChanged: (_) {},
              items: const [
                PTabItem(value: 1, label: '지출'),
                PTabItem(value: 2, label: '수입'),
              ],
            ),
            PCheckbox(value: true, onChanged: (_) {}, label: '동의'),
          ],
        ),
      ),
    );
    final nodes = _nodes(tester).toList();
    bool has(String label, bool Function(SemanticsData) test) =>
        nodes.any((n) => n.label.contains(label) && test(n));
    expect(
      has('식비', (n) => n.flagsCollection.isSelected == Tristate.isTrue),
      isTrue,
    );
    expect(
      has('지출', (n) => n.flagsCollection.isSelected == Tristate.isTrue),
      isTrue,
    );
    expect(
      has('수입', (n) => n.flagsCollection.isSelected == Tristate.isFalse),
      isTrue,
    );
    expect(
      has('동의', (n) => n.flagsCollection.isChecked == CheckedState.isTrue),
      isTrue,
    );
    handle.dispose();
  });
}
