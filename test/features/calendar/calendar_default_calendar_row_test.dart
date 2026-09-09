// 기본 캘린더 행의 표시 스위치를 뺀다 — 항상 표시로 고정 (QA 결정 5).
//
// #338 이 "숨긴 캘린더는 일정 만들기 선택 목록에서 뺀다" 를 넣으면서 경계가 하나
// 생겼다. **기본 캘린더가 숨겨져 있으면** 서버가 자동 대입하는 캘린더가 곧 숨긴
// 캘린더라, 저장은 성공했는데 화면에는 아무것도 안 남는다. 되돌릴 스위치도 필터
// 시트 안이라 "일정이 사라졌다" 로만 보인다.
//
// 그래서 기본 캘린더를 못 숨기게 한다. 서버는 표시 토글을 400 으로 막고, 앱은
// **체크박스를 아예 안 그린다** — 눌리지 않는 회색 체크박스를 두면 "왜 안 되지"
// 만 남는다. 대신 캘린더 관리 화면·웹과 같은 '기본' 배지로 이유를 남긴다.
//
// 막는 것만으로는 부족하다. 막기 전에 이미 꺼 둔 사람의 응답은 여전히
// `isVisible: false` 로 온다. 스위치를 없앤 뒤라 되돌릴 방법이 화면에 없으므로,
// **읽는 자리에서** 기본 캘린더를 보임으로 고정해 그 상태 자체를 없앤다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/calendar/data/user_calendar_repository.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_visibility.dart';
import 'package:porest_desk_app/features/calendar/domain/holiday.dart';
import 'package:porest_desk_app/features/calendar/domain/user_calendar.dart';
import 'package:porest_desk_app/features/calendar/presentation/calendar_screen.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

const _default = UserCalendar(rowId: 1, calendarName: '기본캘린더', isDefault: true);
const _normal = UserCalendar(rowId: 2, calendarName: '회사캘린더');

/// 표시 토글을 막기 전에 꺼 둔 기본 캘린더 — 서버가 아직 이렇게 내려준다.
const _staleHiddenDefault = UserCalendar(
  rowId: 1,
  calendarName: '기본캘린더',
  isDefault: true,
  isVisible: false,
);

/// 토글이 실제로 나갔는지 잡아 둔다.
class _RecordingRepo extends UserCalendarRepository {
  _RecordingRepo() : super(Dio());

  final toggled = <int>[];

  @override
  Future<UserCalendar> toggleVisibility(int id) async {
    toggled.add(id);
    return _normal;
  }
}

CalendarEvent _event({
  required int rowId,
  required String title,
  required int calendarRowId,
  required DateTime day,
}) {
  String at(int h) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}T${h.toString().padLeft(2, '0')}:00:00';
  return CalendarEvent(
    rowId: rowId,
    title: title,
    calendarRowId: calendarRowId,
    startDate: at(9),
    endDate: at(10),
  );
}

/// 필터 시트의 체크박스 — 20×20 AnimatedContainer 하나가 한 행의 스위치다.
/// 색 점(8×8)·"오늘" 원과 크기로 갈린다.
Finder checkboxes() => find.byWidgetPredicate(
  (w) =>
      w is AnimatedContainer &&
      w.constraints == const BoxConstraints.tightFor(width: 20, height: 20),
);

void main() {
  late AppLocalizations l;

  /// 이번 달 15일 — 월 그리드에 늘 그려지고 이월 칸과 숫자가 겹치지 않는다.
  DateTime thisMonth15() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 15);
  }

  Future<_RecordingRepo> pump(
    WidgetTester tester, {
    required List<UserCalendar> calendars,
  }) async {
    final repo = _RecordingRepo();
    final d = thisMonth15();
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCalendarListProvider.overrideWith((ref) async => calendars),
          userCalendarRepositoryProvider.overrideWith((ref) async => repo),
          monthEventsProvider.overrideWith(
            (ref, key) async => [
              _event(rowId: 1, title: '기본일정', calendarRowId: 1, day: d),
              _event(rowId: 2, title: '회사일정', calendarRowId: 2, day: d),
            ],
          ),
          holidayListProvider.overrideWith((ref, key) async => <Holiday>[]),
        ],
        child: MaterialApp(
          theme: PorestTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Builder(
            builder: (context) {
              l = AppLocalizations.of(context);
              return const Scaffold(body: CalendarScreen());
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  /// 헤더 칩을 눌러 필터 시트를 연다. 칩 글자는 "N개" 라 개수를 알아야 한다.
  Future<void> openFilterSheet(
    WidgetTester tester, {
    required int count,
  }) async {
    await tester.tap(find.text(l.calCalendarChipCount(count)));
    await tester.pumpAndSettle();
  }

  group('필터 시트 — 기본 캘린더 행', () {
    testWidgets('기본 캘린더 행에는 체크박스가 없고 일반 캘린더 행에는 있다', (tester) async {
      await pump(tester, calendars: const [_default, _normal]);
      // 캘린더 2 + 공휴일 1.
      await openFilterSheet(tester, count: 3);

      expect(find.text('기본캘린더'), findsOneWidget);
      expect(find.text('회사캘린더'), findsOneWidget);

      // 세 행 중 스위치는 둘 — 기본 캘린더 행에만 없다.
      expect(checkboxes(), findsNWidgets(2), reason: '기본 캘린더 행에도 체크박스가 그려졌다');

      // 눌러도 아무 일 없는 행이라 탭(InkWell) 자체를 안 붙인다.
      expect(
        find.widgetWithText(InkWell, '기본캘린더'),
        findsNothing,
        reason: '기본 캘린더 행이 여전히 눌린다',
      );
      expect(find.widgetWithText(InkWell, '회사캘린더'), findsOneWidget);
    });

    testWidgets("기본 캘린더 행에는 '기본' 표식이 붙는다", (tester) async {
      await pump(tester, calendars: const [_default, _normal]);
      await openFilterSheet(tester, count: 3);

      // 관리 화면·웹이 쓰는 것과 같은 배지 — 스위치가 왜 없는지를 남긴다.
      expect(find.text(l.calDefault), findsOneWidget);
    });

    testWidgets('일반 캘린더 행은 그대로 토글된다', (tester) async {
      final repo = await pump(tester, calendars: const [_default, _normal]);
      await openFilterSheet(tester, count: 3);

      await tester.tap(find.text('회사캘린더'));
      await tester.pumpAndSettle();

      expect(repo.toggled, [2], reason: '일반 캘린더 토글까지 같이 죽었다');
    });

    testWidgets('기본 캘린더 행은 눌러도 토글이 안 나간다', (tester) async {
      final repo = await pump(tester, calendars: const [_default, _normal]);
      await openFilterSheet(tester, count: 3);

      await tester.tap(find.text('기본캘린더'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(repo.toggled, isEmpty, reason: '서버가 400 으로 막는 요청이 나갔다');
    });
  });

  group('기본 캘린더는 늘 보이는 것으로 취급된다', () {
    test('서버가 isVisible:false 로 내려도 보임이다', () {
      expect(_staleHiddenDefault.isVisible, isTrue);
      expect(isCalendarVisible(const [_staleHiddenDefault], 1), isTrue);
    });

    test('응답을 파싱해도 마찬가지다', () {
      final parsed = UserCalendar.fromJson(const {
        'rowId': 1,
        'calendarName': '기본캘린더',
        'isDefault': true,
        'isVisible': false,
      });

      expect(parsed.isVisible, isTrue);
    });

    test('기본이 아닌 캘린더의 숨김은 그대로 지켜진다', () {
      const hidden = UserCalendar(
        rowId: 2,
        calendarName: '회사캘린더',
        isVisible: false,
      );

      expect(hidden.isVisible, isFalse, reason: '숨기기 기능 자체가 죽었다');
      expect(isCalendarVisible(const [hidden], 2), isFalse);
    });

    testWidgets('숨김 값이 와도 그 일정이 월 그리드에 그려진다', (tester) async {
      await pump(tester, calendars: const [_staleHiddenDefault, _normal]);

      expect(
        find.text('기본일정'),
        findsWidgets,
        reason: '되돌릴 스위치가 없는데 기본 캘린더 일정이 사라졌다',
      );
    });

    testWidgets('숨김 값이 와도 헤더 개수와 색 점에 든다', (tester) async {
      await pump(tester, calendars: const [_staleHiddenDefault, _normal]);

      // 기본 + 회사 + 공휴일 = 3. 기본이 빠지면 2 가 된다.
      expect(find.text(l.calCalendarChipCount(3)), findsOneWidget);
    });

    testWidgets('숨김 값이 와도 필터 시트에서 켜진 것으로 보인다', (tester) async {
      await pump(tester, calendars: const [_staleHiddenDefault, _normal]);
      await openFilterSheet(tester, count: 3);

      // 꺼진 행은 이름이 fgTertiary 로 죽는다 — 기본 캘린더는 늘 켜진 색이다.
      final name = tester.widget<Text>(find.text('기본캘린더'));

      expect(name.style?.color, PorestTokens.light.fgPrimary);
      expect(name.style?.color, isNot(PorestTokens.light.fgTertiary));
    });
  });
}
