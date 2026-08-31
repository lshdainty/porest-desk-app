// 입력칸은 입력칸대로 — 키보드로 고칠 수 있고, 반쪽짜리 문자열은 안 올린다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';

Widget _app(Widget child) => MaterialApp(
  theme: PorestTheme.dark(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('날짜를 타이핑해서 고친다', (tester) async {
    DateTime? changed;
    await tester.pumpWidget(
      _app(
        PDateInput(
          value: DateTime(2026, 3, 5),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030, 12, 31),
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '2026-07-08');
    await tester.pump();

    expect(changed, DateTime(2026, 7, 8));
  });

  testWidgets('완성되기 전에는 값을 올리지 않는다', (tester) async {
    DateTime? changed;
    await tester.pumpWidget(
      _app(
        PDateInput(value: DateTime(2026, 3, 5), onChanged: (v) => changed = v),
      ),
    );

    for (final partial in ['2', '20', '2026', '2026-0', '2026-07-']) {
      await tester.enterText(find.byType(TextField), partial);
      await tester.pump();
      expect(changed, isNull, reason: '"$partial" 는 아직 날짜가 아니다');
    }
  });

  testWidgets('없는 날짜와 범위 밖은 거른다', (tester) async {
    DateTime? changed;
    await tester.pumpWidget(
      _app(
        PDateInput(
          value: DateTime(2026, 3, 5),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030, 12, 31),
          onChanged: (v) => changed = v,
        ),
      ),
    );

    // 2월 31일 — DateTime 이 3월로 굴려 버리는 값
    await tester.enterText(find.byType(TextField), '2026-02-31');
    await tester.pump();
    expect(changed, isNull);

    // lastDate 밖
    await tester.enterText(find.byType(TextField), '2031-01-01');
    await tester.pump();
    expect(changed, isNull);
  });

  testWidgets('시각도 타이핑해서 고치고, 잘못된 값은 거른다', (tester) async {
    TimeOfDay? changed;
    await tester.pumpWidget(
      _app(
        PTimeInput(
          value: const TimeOfDay(hour: 9, minute: 0),
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '25:00');
    await tester.pump();
    expect(changed, isNull, reason: '25시는 없다');

    await tester.enterText(find.byType(TextField), '18:30');
    await tester.pump();
    expect(changed, const TimeOfDay(hour: 18, minute: 30));
  });
}
