// 일정 시트에서 **칸을 비우면 실제로 지워진다** (회귀 마무리 P3).
//
// 서버가 캘린더 수정 본문을 `Optional` 로 읽기 시작하면서(desk-back #325) 뜻이 셋으로
// 갈렸다 — 키가 없으면 유지, `"key": null` 이면 지움, 값이 오면 교체. 앱은 본문을
// Dart 의 널 인지 맵 엔트리(`'key': ?value`)로 만들어 **null 인 칸을 키째 뺐다.**
// 그래서 설명·장소를 지우거나 '라벨 없음' 을 고르고 저장해도 다시 열면 옛 값이 있었다.
//
// 반복(`rrule`)은 #327 이 먼저 [Patch] 로 옮겼다 — 이 파일은 그 위에 셋을 더 얹는
// 것뿐이라, 반복·알림은 `calendar_chip_payload_test.dart` 가 계속 잠근다.
//
// 안 건드리는 쪽도 같이 잠근다. 소속 캘린더는 "뗀다" 가 없는 칸이다 — 서버
// `UpdateRequest.calendarRowId` 는 `Optional` 이 아닌 맨 `Long` 이고 서비스가
// `if (calendarRowId != null)` 로만 읽어 옮기기만 한다. 시트 선택기에도 '선택 안 함' 이
// 없다. 종류(`eventType`)·색(`color`)도 화면이 늘 값을 들고 있어 비는 상태가 없다.
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
import 'package:porest_desk_app/shared/widgets/p_select.dart';

const _defaultCalendar = UserCalendar(
  rowId: 1,
  calendarName: '개인',
  isDefault: true,
);

const _label = EventLabel(rowId: 4, labelName: '업무', color: '#2c70bf');

/// 설명·장소·라벨이 다 채워진 일정 — 여기서 하나씩 비운다.
const _filledEventJson = <String, dynamic>{
  'rowId': 42,
  'title': '주간 회의',
  'description': '주간 정례',
  'eventType': 'WORK',
  'color': '#2c70bf',
  'startDate': '2026-09-10T09:00:00',
  'endDate': '2026-09-10T10:00:00',
  'isAllDay': 'N',
  'labelRowId': 4,
  'location': '3층 회의실',
  'calendarRowId': 1,
};

/// 화면이 넘긴 인자를 그대로 잡아 둔다 — 값뿐 아니라 "키를 실었는가" 까지 본다.
class _CapturingRepo extends CalendarRepository {
  _CapturingRepo() : super(Dio());

  bool called = false;
  Patch<String> description = const Patch.keep();
  Patch<String> location = const Patch.keep();
  Patch<int> labelRowId = const Patch.keep();
  Patch<String> rrule = const Patch.keep();
  String? color;
  String? eventType;
  int? calendarRowId;

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
    called = true;
    this.description = description;
    this.location = location;
    this.labelRowId = labelRowId;
    this.rrule = rrule;
    this.color = color;
    this.eventType = eventType;
    this.calendarRowId = calendarRowId;
    return CalendarEvent.fromJson(_filledEventJson);
  }
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submit(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

/// 라벨 select — 시트에는 `PSelect<int>` 가 둘(캘린더 → 라벨) 있고 라벨이 뒤다.
Finder get _labelSelect => find.byType(PSelect<int>).at(1);

Future<_CapturingRepo> _open(
  WidgetTester tester, {
  bool labelsFail = false,
}) async {
  final repo = _CapturingRepo();
  // 시트 본문은 ListView 다 — 좁은 화면에서는 아래쪽 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calendarRepositoryProvider.overrideWith((ref) async => repo),
        eventLabelsProvider.overrideWith(
          (ref) async => labelsFail ? throw Exception('boom') : const [_label],
        ),
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
              onPressed: () => showCalendarEventDialog(
                ctx,
                edit: CalendarEvent.fromJson(_filledEventJson),
              ),
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

  testWidgets('설명을 지우면 description 이 명시적 null 로 실린다', (tester) async {
    final repo = await _open(tester);
    await tester.enterText(_field(l.calDescriptionPlaceholder), '');
    await tester.pumpAndSettle();
    await tester.tap(_submit(l.actionEdit));
    await tester.pumpAndSettle();

    expect(repo.called, isTrue, reason: '수정이 안 불렸다 — 테스트가 아무것도 안 본다');
    expect(
      repo.description.present,
      isTrue,
      reason: 'description 키가 빠지면 서버가 옛 설명을 지킨다 — 비운 게 안 지워진다',
    );
    expect(repo.description.value, isNull);
  });

  testWidgets('장소를 지우면 location 이 명시적 null 로 실린다', (tester) async {
    final repo = await _open(tester);
    await tester.enterText(_field(l.calLocationPlaceholder), '');
    await tester.pumpAndSettle();
    await tester.tap(_submit(l.actionEdit));
    await tester.pumpAndSettle();

    expect(
      repo.location.present,
      isTrue,
      reason: 'location 키가 빠지면 옛 장소가 그대로 남는다',
    );
    expect(repo.location.value, isNull);
  });

  testWidgets("'라벨 없음' 을 고르면 labelRowId 가 명시적 null 로 실린다", (tester) async {
    final repo = await _open(tester);
    await tester.tap(_labelSelect);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.calNoLabel).last);
    await tester.pumpAndSettle();
    await tester.tap(_submit(l.actionEdit));
    await tester.pumpAndSettle();

    expect(
      repo.labelRowId.present,
      isTrue,
      reason: 'labelRowId 키가 빠지면 서버가 옛 라벨을 지킨다 — 앱에서 라벨을 못 뗀다',
    );
    expect(repo.labelRowId.value, isNull);
  });

  testWidgets('안 건드린 칸은 지금 값이 그대로 실린다', (tester) async {
    final repo = await _open(tester);
    await tester.tap(_submit(l.actionEdit));
    await tester.pumpAndSettle();

    expect(repo.description.value, '주간 정례');
    expect(repo.location.value, '3층 회의실');
    expect(repo.labelRowId.value, 4);
    // #327 이 세운 자리 — 되돌리면 안 된다.
    expect(repo.rrule.present, isTrue);
  });

  // 라벨 목록 조회가 실패하면 select 자리에 에러 문구가 뜬다 — 고를 자리가 없는데
  // 화면이 "라벨을 비웠다" 로 읽으면 저장 한 번에 붙어 있던 라벨이 떨어진다.
  testWidgets('라벨 조회가 실패해도 지금 라벨이 그대로 실린다', (tester) async {
    final repo = await _open(tester, labelsFail: true);
    expect(tester.takeException(), isNull);

    await tester.tap(_submit(l.actionEdit));
    await tester.pumpAndSettle();

    expect(repo.labelRowId.value, 4, reason: '고를 자리가 없는 저장이 라벨을 떼면 안 된다');
  });

  // 화면에 "비움" 이 없는 칸들. 여기에 null 이 실리면 남의 값이 지워지거나
  // (캘린더) 저장 자체가 깨진다(종류).
  testWidgets('소속 캘린더·종류·색은 늘 값이 실린다', (tester) async {
    final repo = await _open(tester);
    await tester.enterText(_field(l.calDescriptionPlaceholder), '');
    await tester.pumpAndSettle();
    await tester.tap(_submit(l.actionEdit));
    await tester.pumpAndSettle();

    expect(
      repo.calendarRowId,
      1,
      reason: '서버는 캘린더를 뗄 수 없다 — null 을 실으면 뜻이 없는 키가 된다',
    );
    expect(repo.eventType, 'WORK', reason: '종류를 안 되돌리면 저장 한 번에 기본값으로 바뀐다');
    expect(repo.color, '#2c70bf');
  });
}
