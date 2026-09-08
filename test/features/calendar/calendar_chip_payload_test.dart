// 캘린더 반복·알림 칩이 저장에 실린다 (감사 2026-09-08 A2).
//
// 두 칩 다 화면에는 있는데 저장 본문에 없었다.
//   · 반복 — 골라도 아무 일이 안 일어났다. 서버가 "안 보내면 유지" 로 바뀌기 전에는
//     웹에서 만든 반복이 앱 저장 한 번에 사라지기까지 했다.
//   · 알림 — 보내지도 읽지도 않았다. 앱 도메인에 필드 자체가 없었다.
//
// **읽기가 먼저다.** 서버는 `reminderMinutes` 를 "null=무변경 / 리스트=전체 교체" 로
// 읽으므로(`CalendarEventServiceImpl.updateEvent`), 기존 알림을 칩에 채우지 않고 저장만
// 실으면 웹에서 건 알림이 앱 저장 때마다 전부 지워진다. 그래서 여는 순간 채워지는지와
// 저장에 되실리는지를 같이 잠근다.
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) "무엇을 보내는가" 를 위젯 테스트로 잠근다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/network/patch.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/calendar/data/calendar_repository.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';
import 'package:porest_desk_app/features/calendar/domain/event_label.dart';
import 'package:porest_desk_app/features/calendar/domain/user_calendar.dart';
import 'package:porest_desk_app/features/calendar/presentation/calendar_event_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

const _defaultCalendar = UserCalendar(
  rowId: 1,
  calendarName: '개인',
  isDefault: true,
);

/// 서버 목록 응답 그대로 — 반복은 웹이 만든 세부 규칙까지 들고 있고, 알림 둘 중
/// 하나(10분)는 앱 칩에 없는 값이다.
const _webMadeEventJson = <String, dynamic>{
  'rowId': 42,
  'title': '주간 회의',
  'eventType': 'WORK',
  'startDate': '2026-09-10T09:00:00',
  'endDate': '2026-09-10T10:00:00',
  'isAllDay': 'N',
  'calendarRowId': 1,
  'rrule': 'FREQ=WEEKLY;BYDAY=MO,WE',
  'reminders': [
    {'rowId': 1, 'eventRowId': 42, 'minutesBefore': 10, 'isSent': 'N'},
    {'rowId': 2, 'eventRowId': 42, 'minutesBefore': 30, 'isSent': 'N'},
  ],
};

/// 반복도 알림도 없는 일정.
const _plainEventJson = <String, dynamic>{
  'rowId': 43,
  'title': '점심',
  'eventType': 'PERSONAL',
  'startDate': '2026-09-10T12:00:00',
  'endDate': '2026-09-10T13:00:00',
  'isAllDay': 'N',
  'calendarRowId': 1,
};

/// 화면이 넘긴 인자를 그대로 잡아 둔다 — 값뿐 아니라 "키를 실었는가" 까지 본다.
class _CapturingRepo extends CalendarRepository {
  _CapturingRepo() : super(Dio());

  Map<String, Object?>? created;
  Map<String, Object?>? updated;

  CalendarEvent _fake() => CalendarEvent.fromJson(_plainEventJson);

  @override
  Future<CalendarEvent> createEvent({
    required String title,
    String? description,
    String? eventType,
    String? color,
    int? calendarRowId,
    required String startDate,
    required String endDate,
    bool isAllDay = false,
    int? labelRowId,
    String? location,
    String? rrule,
    List<int>? reminderMinutes,
  }) async {
    created = {'rrule': rrule, 'reminderMinutes': reminderMinutes};
    return _fake();
  }

  @override
  Future<CalendarEvent> updateEvent({
    required int id,
    required String title,
    Patch<String> description = const Patch.keep(),
    String? eventType,
    String? color,
    int? calendarRowId,
    required String startDate,
    required String endDate,
    bool isAllDay = false,
    Patch<int> labelRowId = const Patch.keep(),
    Patch<String> location = const Patch.keep(),
    Patch<String> rrule = const Patch.keep(),
    List<int>? reminderMinutes,
  }) async {
    updated = {
      'rrulePresent': rrule.present,
      'rrule': rrule.value,
      'reminderMinutes': reminderMinutes,
    };
    return _fake();
  }
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submit(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<_CapturingRepo> _open(WidgetTester tester, {CalendarEvent? edit}) async {
  final repo = _CapturingRepo();
  // 시트 본문은 ListView 다 — 좁은 화면에서는 아래쪽 칩이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calendarRepositoryProvider.overrideWith((ref) async => repo),
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
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  group('응답 읽기', () {
    test('알림 사전분을 목록으로 읽는다', () {
      final e = CalendarEvent.fromJson(_webMadeEventJson);
      expect(e.reminderMinutes, [10, 30]);
    });

    test('알림 키가 없으면 빈 목록이다 — null 로 터지지 않는다', () {
      expect(CalendarEvent.fromJson(_plainEventJson).reminderMinutes, isEmpty);
    });
  });

  group('신규 일정', () {
    testWidgets('고른 반복과 알림이 저장에 실린다', (tester) async {
      final repo = await _open(tester);
      await tester.enterText(_field(l.calTitlePlaceholder), '스탠드업');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.calRepeatDaily));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.calReminderMinutesBefore(15)));
      await tester.pumpAndSettle();
      await tester.tap(_submit(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.created, isNotNull, reason: '생성이 안 불렸다 — 테스트가 아무것도 안 본다');
      expect(repo.created!['rrule'], 'FREQ=DAILY');
      expect(repo.created!['reminderMinutes'], [15]);
    });

    testWidgets('아무것도 안 고르면 반복은 안 실린다', (tester) async {
      final repo = await _open(tester);
      await tester.enterText(_field(l.calTitlePlaceholder), '메모');
      await tester.pumpAndSettle();
      await tester.tap(_submit(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.created!['rrule'], isNull);
      expect(repo.created!['reminderMinutes'], isEmpty);
    });
  });

  group('일정 수정', () {
    testWidgets('칩을 안 건드리면 웹이 만든 반복·알림이 그대로 되돌아간다', (tester) async {
      final repo = await _open(
        tester,
        edit: CalendarEvent.fromJson(_webMadeEventJson),
      );
      await tester.tap(_submit(l.actionEdit));
      await tester.pumpAndSettle();

      expect(repo.updated, isNotNull, reason: '수정이 안 불렸다');
      // 칩 다섯 개는 FREQ 하나만 표현한다 — 되돌릴 때 BYDAY 를 뭉개면 안 된다.
      expect(
        repo.updated!['rrule'],
        'FREQ=WEEKLY;BYDAY=MO,WE',
        reason: '칩을 안 바꿨는데 세부 규칙이 사라지면 웹에서 만든 반복이 뭉개진다',
      );
      // 10분은 앱 칩에 없는 값이다 — 화면에 안 보인다고 지우면 안 된다.
      expect(
        repo.updated!['reminderMinutes'],
        [10, 30],
        reason: '기존 알림을 안 읽고 저장하면 웹에서 건 알림이 통째로 지워진다',
      );
    });

    testWidgets('반복을 바꾸면 그 값이 나간다', (tester) async {
      final repo = await _open(
        tester,
        edit: CalendarEvent.fromJson(_webMadeEventJson),
      );
      await tester.tap(find.text(l.calRepeatMonthly));
      await tester.pumpAndSettle();
      await tester.tap(_submit(l.actionEdit));
      await tester.pumpAndSettle();

      expect(repo.updated!['rrule'], 'FREQ=MONTHLY');
    });

    testWidgets("'반복 없음' 을 고르면 명시적 null 로 지워진다", (tester) async {
      final repo = await _open(
        tester,
        edit: CalendarEvent.fromJson(_webMadeEventJson),
      );
      await tester.tap(find.text(l.calRecurrenceNone));
      await tester.pumpAndSettle();
      await tester.tap(_submit(l.actionEdit));
      await tester.pumpAndSettle();

      // 키를 빼면 서버가 지금 값을 지킨다 — 그러면 칩이 여전히 아무 일도 안 한다.
      expect(repo.updated!['rrulePresent'], isTrue);
      expect(repo.updated!['rrule'], isNull);
    });

    testWidgets('켜져 있던 알림 칩을 끄면 그 값만 빠진다', (tester) async {
      final repo = await _open(
        tester,
        edit: CalendarEvent.fromJson(_webMadeEventJson),
      );
      await tester.tap(find.text(l.calReminderMinutesBefore(30)));
      await tester.pumpAndSettle();
      await tester.tap(_submit(l.actionEdit));
      await tester.pumpAndSettle();

      expect(repo.updated!['reminderMinutes'], [10]);
    });
  });
}
