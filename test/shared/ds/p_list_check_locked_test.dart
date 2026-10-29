// List 체크 줄 locked — 끌 수 없는 켬(list.md "끌 수 없는 켬 — 칸만 막는다"): 칸은 켠 채 막히고 줄은 누르지 못하지만
// 제목 · 앞 붙이개 · 배지는 보통 색이다. 줄 전체를 막는 것(onChanged 없음)과 다르다.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

import '../../support/plain_text.dart';

Widget _host(Widget child) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 360, child: child),
    ),
  ),
);

const _dot = SizedBox.square(key: ValueKey('dot'), dimension: 10);

Widget _row({required bool locked, ValueChanged<bool>? onChanged}) =>
    PListCheckItem(
      title: '개인',
      titleSuffix: const [PBadge(label: '기본')],
      checked: true,
      locked: locked,
      onChanged: onChanged ?? (_) {},
      prefix: _dot,
    );

/// 제목 뒤에 배지가 이어 붙으면 Text.rich 라 줄바꿈 보호 글자를 뺀 글로 찾는다.
Finder _title() => find.byWidgetPredicate(
  (w) => w is RichText && plainOf(w.text.toPlainText()).contains('개인'),
  description: '제목 개인',
);

Color? _colorOf(WidgetTester tester) {
  final rich = tester.widget<RichText>(_title());
  Color? found;
  rich.text.visitChildren((span) {
    if (span is TextSpan && found == null && (span.text ?? '').isNotEmpty) {
      found = span.style?.color;
    }
    return true;
  });
  return found ?? (rich.text as TextSpan).style?.color;
}

void main() {
  testWidgets('locked — 눌러도 안 바뀌고 포커스에서 빠진다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(_row(locked: true, onChanged: (_) => calls++)),
    );
    await tester.tap(_title(), warnIfMissed: false);
    await tester.pump();
    expect(calls, 0);
    final focus = tester
        .widgetList<Focus>(
          find.descendant(
            of: find.byType(PListCheckItem),
            matching: find.byType(Focus),
          ),
        )
        .where((f) => f.canRequestFocus)
        .toList();
    expect(focus, isEmpty, reason: '막힌 줄은 포커스를 받지 않는다');
  });

  testWidgets('locked — 칸은 켠 채 막힘, 제목 · 배지는 보통 색(꺼진 것으로 읽히지 않는다)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_row(locked: true)));
    final c = GrooTheme.light().extension<PColors>()!;
    expect(_colorOf(tester), c.fgNeutral);
    expect(_colorOf(tester), isNot(c.fgDisabled));
    final mark = tester.widget<PCheckmark>(find.byType(PCheckmark));
    expect(mark.checked, isTrue);
    expect(mark.enabled, isFalse, reason: '칸만 막힌다');
  });

  testWidgets('막힌 줄(locked 아님)은 제목도 비활성 색 — 둘이 다르다', (tester) async {
    await tester.pumpWidget(
      PListCheckItem(title: '개인', checked: true, onChanged: null).wrapped(),
    );
    final c = GrooTheme.light().extension<PColors>()!;
    final title = tester.widget<Text>(findPlain('개인'));
    expect(title.style?.color, c.fgDisabled);
  });

  testWidgets('낭독 — 개인, 기본, 체크됨, 사용할 수 없음', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_row(locked: true)));
    final node = find.semantics
        .byPredicate((n) => plainOf(n.label).contains('개인'))
        .evaluate()
        .first;
    final data = node.getSemanticsData();
    expect(plainOf(data.label), contains('개인'));
    expect(plainOf(data.label), contains('기본'));
    expect(data.hasFlag(SemanticsFlag.isChecked), isTrue);
    expect(data.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
    expect(data.hasFlag(SemanticsFlag.isEnabled), isFalse);
    handle.dispose();
  });
}

extension on Widget {
  Widget wrapped() => _host(this);
}
