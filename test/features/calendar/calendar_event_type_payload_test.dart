// 일정 저장이 운영에서 통째로 막혀 있었다 — 앱이 `eventType` 기본값으로 서버 enum
// (`PERSONAL`·`WORK`·`BIRTHDAY`·`HOLIDAY`)에 없는 'NORMAL' 을 항상 실어 보냈다.
// 서버는 본문을 읽는 단계에서 걸려 400 을 돌려주므로 저장이 절대 성립하지 않는다.
// 화면에는 종류를 고르는 자리가 없어 호출자가 값을 넘기지도 않으니, 생성·수정 모두
// 100% 실패였다.
//
// 여기서 고정하는 것은 셋이다.
//   ① 저장 요청 바디에 서버가 아는 값이 실린다 (기본값은 웹과 같은 'PERSONAL')
//   ② 수정은 원래 종류를 되돌려 준다 — 서버가 무조건 덮어쓰므로, 안 그러면 저장
//      한 번에 사용자가 고른 종류가 기본값으로 바뀐다
//   ③ 화면에서 저장을 눌렀을 때 실제로 그 바디가 나간다 (다이얼로그 → 리포지토리 전체)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/calendar/data/calendar_repository.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';
import 'package:porest_desk_app/features/calendar/domain/event_label.dart';
import 'package:porest_desk_app/features/calendar/domain/user_calendar.dart';
import 'package:porest_desk_app/features/calendar/presentation/calendar_event_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

/// 서버 `CalendarEventType` 이 받는 값 전부. 이 목록 밖이면 저장이 400 이다.
const _serverEventTypes = {'PERSONAL', 'WORK', 'BIRTHDAY', 'HOLIDAY'};

const _eventJson = <String, dynamic>{
  'rowId': 42,
  'title': '회의',
  'eventType': 'WORK',
  'startDate': '2026-09-10T09:00:00',
  'endDate': '2026-09-10T10:00:00',
  'isAllDay': 'N',
  'calendarRowId': 1,
};

const _defaultCalendar = UserCalendar(
  rowId: 1,
  calendarName: '개인',
  isDefault: true,
);

/// 요청 바디를 잡아 두고 성공 응답을 돌려주는 Dio.
(Dio, List<Map<String, dynamic>> captured) _capturingDio() {
  final captured = <Map<String, dynamic>>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final data = options.data;
        if (data is Map) captured.add(data.cast<String, dynamic>());
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: const {
              'success': true,
              'code': 'COMMON_200',
              'message': 'OK',
              'data': _eventJson,
            },
          ),
        );
      },
    ),
  );
  return (dio, captured);
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

/// 일정 시트를 띄운다. 리포지토리는 진짜를 쓰고 Dio 만 가짜다 — 화면이 넘긴 값이
/// 바디까지 어떻게 가는지가 이 테스트의 대상이다.
Future<(AppLocalizations, List<Map<String, dynamic>>)> _openDialog(
  WidgetTester tester, {
  CalendarEvent? edit,
}) async {
  final l = await AppLocalizations.delegate.load(const Locale('ko'));
  final (dio, captured) = _capturingDio();
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calendarRepositoryProvider.overrideWith(
          (ref) async => CalendarRepository(dio),
        ),
        eventLabelsProvider.overrideWith((ref) async => <EventLabel>[]),
        userCalendarListProvider.overrideWith(
          (ref) async => const [_defaultCalendar],
        ),
        monthEventsProvider.overrideWith((ref, key) async => <CalendarEvent>[]),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () =>
                  showCalendarEventDialog(ctx, edit: edit, defaultDate: null),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return (l, captured);
}

void main() {
  group('저장 요청 바디 — 화면에서 눌렀을 때', () {
    testWidgets('새 일정은 서버가 아는 종류로 나간다', (tester) async {
      final (l, captured) = await _openDialog(tester);
      await tester.enterText(_field(l.calTitlePlaceholder), '점심 약속');
      await tester.pumpAndSettle();
      await tester.tap(_button(l.actionSave));
      await tester.pumpAndSettle();

      final body = captured.single;
      expect(body['title'], '점심 약속');
      expect(body['eventType'], isIn(_serverEventTypes));
      expect(body['eventType'], 'PERSONAL'); // 웹 EventForm 과 같은 값
    });

    testWidgets('수정은 원래 종류를 그대로 되돌려 준다', (tester) async {
      final (l, captured) = await _openDialog(
        tester,
        edit: CalendarEvent.fromJson(_eventJson),
      );
      await tester.tap(_button(l.actionEdit));
      await tester.pumpAndSettle();

      final body = captured.single;
      expect(body['eventType'], isIn(_serverEventTypes));
      // 종류를 고르는 자리가 없다고 해서 'WORK' 가 'PERSONAL' 로 내려가면 안 된다.
      expect(body['eventType'], 'WORK');
    });
  });

  group('리포지토리 — 종류 값 결정', () {
    test('안 넘기면 기본값이 실린다 — 키를 빼면 서버가 저장하지 못한다', () async {
      final (dio, captured) = _capturingDio();

      await CalendarRepository(dio).createEvent(
        title: '회의',
        startDate: '2026-09-10T09:00:00',
        endDate: '2026-09-10T10:00:00',
      );

      final body = captured.single;
      expect(body.containsKey('eventType'), isTrue);
      expect(body['eventType'], isIn(_serverEventTypes));
      expect(body['eventType'], kDefaultCalendarEventType);
    });

    test('넘긴 값은 그대로 실린다 — 생성도 수정도', () async {
      final (dio, captured) = _capturingDio();
      final repo = CalendarRepository(dio);

      await repo.createEvent(
        title: '생일',
        eventType: 'BIRTHDAY',
        startDate: '2026-09-10T09:00:00',
        endDate: '2026-09-10T10:00:00',
      );
      await repo.updateEvent(
        id: 42,
        title: '생일',
        eventType: 'BIRTHDAY',
        startDate: '2026-09-10T09:00:00',
        endDate: '2026-09-10T10:00:00',
      );

      expect(captured.map((b) => b['eventType']), ['BIRTHDAY', 'BIRTHDAY']);
    });

    test('빈 문자열은 값이 아니다 — 기본값으로 채운다', () {
      expect(eventTypeOrDefault(null), kDefaultCalendarEventType);
      expect(eventTypeOrDefault(''), kDefaultCalendarEventType);
      expect(eventTypeOrDefault('   '), kDefaultCalendarEventType);
      expect(eventTypeOrDefault(' WORK '), 'WORK');
    });

    test('모르는 값을 걸러내지 않는다 — 서버가 종류를 늘려도 옛 앱이 되돌리면 안 된다', () {
      expect(eventTypeOrDefault('TRAVEL'), 'TRAVEL');
    });

    test('기본값은 서버 enum 안에 있다', () {
      expect(kDefaultCalendarEventType, isIn(_serverEventTypes));
    });
  });
}
