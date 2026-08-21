// iOS 스타일 시각 휠 — 탭하면 휠이 뜨고, 확인/취소가 값에 반영되는지.
// 날짜는 달력 그리드 그대로 두고 등장만 시트로 — 월 전체가 보이는 쪽이 낫다.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_calendar.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';

Widget _app(Widget child) => MaterialApp(
      theme: PorestTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('날짜 입력을 탭하면 달력이 시트로 올라온다', (tester) async {
    await tester.pumpWidget(_app(
      PDateInput(value: DateTime(2026, 3, 5), onChanged: (_) {}),
    ));

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    // 달력 그리드는 유지하되(월 전체가 보이는 쪽이 낫다) 등장 방식만 시트로.
    expect(find.byType(PCalendar), findsOneWidget);
    expect(find.text('2026년 3월'), findsOneWidget);
    // Material 다이얼로그 피커로 돌아가지 않았는지.
    expect(find.byType(CalendarDatePicker), findsNothing);
    expect(find.byType(CupertinoDatePicker), findsNothing);
  });

  testWidgets('날짜를 누르면 시트가 닫히고 그 값이 올라온다', (tester) async {
    DateTime? changed;
    await tester.pumpWidget(_app(
      PDateInput(value: DateTime(2026, 3, 5), onChanged: (v) => changed = v),
    ));

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    await tester.tap(find.text('17'));
    await tester.pumpAndSettle();

    expect(find.byType(PCalendar), findsNothing, reason: '고르면 바로 닫힌다');
    expect(changed, DateTime(2026, 3, 17));
  });

  testWidgets('시각 입력을 탭하면 휠이 뜨고, 취소하면 값이 그대로다', (tester) async {
    TimeOfDay? changed;
    await tester.pumpWidget(_app(
      PTimeInput(
        value: const TimeOfDay(hour: 9, minute: 0),
        onChanged: (v) => changed = v,
      ),
    ));

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsNothing);
    expect(changed, isNull, reason: '취소는 호출부 값을 건드리지 않는다');
  });

  testWidgets('휠을 굴리고 확인을 누르면 바뀐 값이 올라온다', (tester) async {
    TimeOfDay? changed;
    await tester.pumpWidget(_app(
      PTimeInput(
        value: const TimeOfDay(hour: 9, minute: 0),
        onChanged: (v) => changed = v,
      ),
    ));

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    // 시 컬럼을 굴린다. 피커 전체를 잡으면 가운데(분 컬럼)를 미는 셈이라
    // 시가 안 움직인다 — '09' 가 그려진 시 컬럼을 직접 집는다.
    await tester.drag(find.text('09'), const Offset(0, -64));
    await tester.pumpAndSettle();

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(changed, isNotNull, reason: '확인은 고른 값을 올려보낸다');
    expect(changed!.hour, isNot(9), reason: '굴린 만큼 시가 움직였다');
  });
}
