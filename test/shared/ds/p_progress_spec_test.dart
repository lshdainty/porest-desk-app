// Progress 가 스펙 값(test/fixtures/design_spec/progress.json)대로인지 — 한도 · 목표 × 상태(기본 · 넘침 · 달성) ×
// 라이트 · 다크의 글 · 막대 · 채움, 채움이 따라 차는 움직임, 읽는 말. 웹은 같은 JSON 을 크로미움에서 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/ds/progress/p_progress.dart';

import '../../support/design_spec.dart';

final _spec = DesignSpec.load('progress');

Widget _host(Brightness mode, Widget child, {bool reduceMotion = false}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? PorestTheme.dark() : PorestTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(child: SizedBox(width: 300, child: child)),
        ),
      ),
    );

/// 상태마다의 견본 값 — 400,000 중 350,000(88%) · 450,000(20,000 초과) · 목표 400,000 달성
const _cases = {
  ('limit', 'enabled'): (350000.0, 400000.0),
  ('limit', 'over'): (420000.0, 400000.0),
  ('goal', 'enabled'): (350000.0, 400000.0),
  ('goal', 'reached'): (400000.0, 400000.0),
};

void main() {
  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 한도 · 목표 × 상태가 스펙 값이다', (tester) async {
      final failures = <String>[];
      for (final MapEntry(key: (meaning, state), value: (value, max))
          in _cases.entries) {
        await tester.pumpWidget(
          _host(
            mode,
            PProgress(
              key: UniqueKey(),
              label: '식비 예산',
              value: value,
              max: max,
              meaning: PProgressMeaning.values.byName(meaning),
            ),
          ),
        );
        final want = _spec.resolve({'meaning': meaning}, state);
        final where = '${mode.name} $meaning $state';
        void color(String key, Color actual) {
          final w = pickMode(want[key], mode);
          if (w != null && !sameColor(specColor(w), actual)) {
            failures.add('$where — $key: 스펙 $w · 실제 ${colorHex(actual)}');
          }
        }

        void typo(String key, TextStyle style) {
          final t = want[key] as Map;
          if (style.fontSize != t['fontSize'] ||
              (style.fontSize! * style.height! - (t['lineHeight'] as num))
                      .abs() >
                  0.01) {
            failures.add(
              '$where — $key: 스펙 $t · 실제 ${style.fontSize}/${style.height}',
            );
          }
        }

        final texts = tester.widgetList<Text>(find.byType(Text)).toList();
        // 이름 · 오른쪽 글 · 금액 줄 차례
        final label = texts[0].style!;
        final status = texts[1].style!;
        final amount = texts[2].style!;
        typo('label.typography', label);
        if (label.fontWeight?.value != want['label.fontWeight']) {
          failures.add('$where — label.fontWeight');
        }
        color('label.foreground', label.color!);
        typo('status.typography', status);
        color('status.foreground', status.color!);
        final statusWeight = want['status.fontWeight'] ?? 400;
        if (status.fontWeight?.value != statusWeight) {
          failures.add(
            '$where — status.fontWeight: 스펙 $statusWeight · 실제 ${status.fontWeight}',
          );
        }
        typo('amount.typography', amount);
        color('amount.foreground', amount.color!);
        if (!(amount.fontFeatures ?? []).contains(
          const FontFeature.tabularFigures(),
        )) {
          failures.add('$where — amount.numerals: 숫자 폭이 같지 않다');
        }

        // 묶음 사이
        final column = tester.widget<Column>(
          find.descendant(
            of: find.byType(PProgress),
            matching: find.byType(Column),
          ),
        );
        if (column.spacing != want['root.gap']) {
          failures.add(
            '$where — root.gap: 스펙 ${want['root.gap']} · 실제 ${column.spacing}',
          );
        }

        // 막대 — 트랙 · 채움
        final bar = find.byType(PProgressBar);
        final track = tester.widget<Container>(
          find.descendant(of: bar, matching: find.byType(Container)).first,
        );
        final trackDeco = track.decoration! as BoxDecoration;
        if (tester.getSize(bar).height != want['track.height']) {
          failures.add('$where — track.height');
        }
        if ((trackDeco.borderRadius! as BorderRadius).topLeft.x !=
            want['track.radius']) {
          failures.add('$where — track.radius');
        }
        color('track.background', trackDeco.color!);
        final fill = find.byKey(const ValueKey('progress-fill'));
        final fillDeco =
            tester.widget<Container>(fill).decoration! as BoxDecoration;
        color('fill.background', fillDeco.color!);
        if ((fillDeco.borderRadius! as BorderRadius).topLeft.x !=
            want['fill.radius']) {
          failures.add('$where — fill.radius');
        }
        final fillWidth = tester.getSize(fill).width;
        final full = want['fill.width'] == '100%';
        final expected = full ? 300.0 : 300 * value / max;
        if ((fillWidth - expected).abs() > 0.5) {
          failures.add('$where — fill.width: 기대 $expected · 실제 $fillWidth');
        }
      }
      if (failures.isNotEmpty) fail(failures.join('\n'));
    });
  }

  testWidgets('오른쪽 글 — 반올림한 비율 · "N원 초과" · "달성"', (tester) async {
    Future<String> status(double v, double max, PProgressMeaning m) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PProgress(
            key: UniqueKey(),
            label: '식비 예산',
            value: v,
            max: max,
            meaning: m,
          ),
        ),
      );
      return tester.widgetList<Text>(find.byType(Text)).elementAt(1).data!;
    }

    expect(await status(350000, 400000, PProgressMeaning.limit), '88%');
    expect(await status(420000, 400000, PProgressMeaning.limit), '20,000원 초과');
    expect(await status(400000, 400000, PProgressMeaning.goal), '달성');
    // 0 보다 작은 값은 0
    expect(await status(-5, 100, PProgressMeaning.limit), '0%');
  });

  testWidgets('값이 0 보다 크면 채움은 적어도 높이만큼(8) — 0 이면 없다', (tester) async {
    Future<double> fill(double v) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PProgressBar(
            key: UniqueKey(),
            value: v,
            max: 1000,
            semanticsLabel: '예산',
            semanticsValue: '',
          ),
        ),
      );
      return tester.getSize(find.byKey(const ValueKey('progress-fill'))).width;
    }

    expect(await fill(1), 8);
    expect(await fill(0), 0);
  });

  testWidgets('값이 바뀌면 채움이 300ms 로 따라 찬다 — 처음 그릴 때 · 모션 줄이기면 바로', (
    tester,
  ) async {
    final motion = (_spec.json['motion'] as Map)['채움'] as Map;
    Widget bar(double v, {bool reduce = false}) => _host(
      Brightness.light,
      PProgressBar(
        value: v,
        max: 100,
        semanticsLabel: '예산',
        semanticsValue: '',
      ),
      reduceMotion: reduce,
    );
    double width() =>
        tester.getSize(find.byKey(const ValueKey('progress-fill'))).width;

    await tester.pumpWidget(bar(20));
    expect(width(), 60);
    await tester.pumpWidget(bar(80));
    await tester.pump(specMs(motion['duration']) ~/ 2);
    expect(width(), inExclusiveRange(60, 240));
    await tester.pump(specMs(motion['duration']));
    expect(width(), 240);

    await tester.pumpWidget(bar(20, reduce: true));
    await tester.pump();
    expect(width(), 60);
  });

  testWidgets('막대가 "{이름} {목표} 중 {현재}" 와 오른쪽 글을 읽고, 보이는 글은 두 번 읽지 않는다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Brightness.light,
        const PProgress(label: '식비 예산', value: 350000, max: 400000),
      ),
    );
    expect(
      tester.getSemantics(find.byType(PProgressBar)),
      matchesSemantics(label: '식비 예산 400,000원 중 350,000원', value: '88%'),
    );
    expect(find.bySemanticsLabel('식비 예산'), findsNothing);
    semantics.dispose();
  });
}
