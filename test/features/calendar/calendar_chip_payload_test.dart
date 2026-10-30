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
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/calendar/data/calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale;

import 'support/event_form_support.dart';

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
    String? occurrenceStartDate,
  }) async {
    updated = {
      'rrulePresent': rrule.present,
      'rrule': rrule.value,
      'reminderMinutes': reminderMinutes,
      'occurrenceStartDate': occurrenceStartDate,
    };
    return _fake();
  }
}

Future<_CapturingRepo> _open(WidgetTester tester, {CalendarEvent? edit}) async {
  final repo = _CapturingRepo();
  await openEventForm(tester, repo: repo, edit: edit);
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  /// 반복 · 알림 고르기 시트에서 고른다 — 반복은 누르면 바로 닫히고 알림은 체크 뒤 "완료".
  Future<void> pickRepeat(WidgetTester tester, String label) async {
    await tapRow(tester, l.calRepeat);
    await tapRow(tester, label);
  }

  Future<void> pickReminders(WidgetTester tester, List<String> labels) async {
    await tapRow(tester, l.calFieldReminder);
    for (final label in labels) {
      await tapRow(tester, label);
    }
    await tapButton(tester, l.actionDone);
  }

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
      await enterTitle(tester, '스탠드업');
      await pickRepeat(tester, l.calRepeatDaily);
      await pickReminders(tester, [l.calReminderMinutesBefore(15)]);
      await tapButton(tester, l.actionSave);

      expect(repo.created, isNotNull, reason: '생성이 안 불렸다 — 테스트가 아무것도 안 본다');
      expect(repo.created!['rrule'], 'FREQ=DAILY');
      expect(repo.created!['reminderMinutes'], [15]);
    });

    testWidgets('아무것도 안 고르면 반복은 안 실린다', (tester) async {
      final repo = await _open(tester);
      await enterTitle(tester, '메모');
      await tapButton(tester, l.actionSave);

      expect(repo.created!['rrule'], isNull);
      expect(repo.created!['reminderMinutes'], isEmpty);
    });

    testWidgets('알림은 고른 차례가 아니라 짧은 차례로 실리고 줄 값도 그 차례다', (tester) async {
      final repo = await _open(tester);
      await enterTitle(tester, '메모');
      await pickReminders(tester, [
        l.calReminderDayBefore,
        l.calReminderMinutesBefore(5),
      ]);
      expect(
        valueText(
          '${l.calReminderMinutesBefore(5)}, ${l.calReminderDayBefore}',
        ),
        findsOneWidget,
      );
      await tapButton(tester, l.actionSave);

      expect(repo.created!['reminderMinutes'], [5, 1440]);
    });
  });

  group('일정 수정', () {
    testWidgets('고르기를 안 건드리면 웹이 만든 반복·알림이 그대로 되돌아간다', (tester) async {
      final repo = await _open(
        tester,
        edit: CalendarEvent.fromJson(_webMadeEventJson),
      );
      await tapButton(tester, l.actionSave);

      expect(repo.updated, isNotNull, reason: '수정이 안 불렸다');
      // 고르기는 FREQ 하나만 표현한다 — 되돌릴 때 BYDAY 를 뭉개면 안 된다.
      expect(
        repo.updated!['rrule'],
        'FREQ=WEEKLY;BYDAY=MO,WE',
        reason: '안 바꿨는데 세부 규칙이 사라지면 웹에서 만든 반복이 뭉개진다',
      );
      // 10분은 선택지에 없는 값이다 — 화면에 안 보인다고 지우면 안 된다.
      expect(
        repo.updated!['reminderMinutes'],
        [10, 30],
        reason: '기존 알림을 안 읽고 저장하면 웹에서 건 알림이 통째로 지워진다',
      );
    });

    testWidgets('알림을 고쳐도 선택지에 없는 10분은 그대로 이어진다', (tester) async {
      final repo = await _open(
        tester,
        edit: CalendarEvent.fromJson(_webMadeEventJson),
      );
      await tapRow(tester, l.calFieldReminder);
      await tapRow(tester, l.calReminderDayBefore);
      await tapButton(tester, l.actionDone);
      await tapButton(tester, l.actionSave);

      expect(repo.updated!['reminderMinutes'], [10, 30, 1440]);
    });

    testWidgets('반복을 바꾸면 그 값이 나간다', (tester) async {
      final repo = await _open(
        tester,
        edit: CalendarEvent.fromJson(_webMadeEventJson),
      );
      await pickRepeat(tester, l.calRepeatMonthly);
      await tapButton(tester, l.actionSave);

      expect(repo.updated!['rrule'], 'FREQ=MONTHLY');
    });

    testWidgets("'반복 안 함' 을 고르면 명시적 null 로 지워진다", (tester) async {
      final repo = await _open(
        tester,
        edit: CalendarEvent.fromJson(_webMadeEventJson),
      );
      await pickRepeat(tester, l.calRecurrenceNone);
      await tapButton(tester, l.actionSave);

      // 키를 빼면 서버가 지금 값을 지킨다 — 그러면 고르기가 여전히 아무 일도 안 한다.
      expect(repo.updated!['rrulePresent'], isTrue);
      expect(repo.updated!['rrule'], isNull);
    });

    testWidgets('알림을 전부 해제하면 빈 목록이 실린다', (tester) async {
      final repo = await _open(
        tester,
        edit: CalendarEvent.fromJson(_webMadeEventJson),
      );
      await tapRow(tester, l.calFieldReminder);
      // 10 · 30 중 선택지에 있는 30 만 끌 수 있다 — 10 은 화면에 줄이 없다
      await tapRow(tester, l.calReminderMinutesBefore(30));
      await tapButton(tester, l.actionDone);
      await tapButton(tester, l.actionSave);

      expect(repo.updated!['reminderMinutes'], [10]);
    });
  });
}
