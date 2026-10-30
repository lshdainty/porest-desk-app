// I-09b 09b-1 앱 — 그날 시트 안 한 단계(줄 5 · 6 · 7 · 8 · 9): 목록 → 상세 → 수정 폼이 시트 하나 안에서 바뀐다.
// 단계마다 닫힘 규칙이 다르다(목록 · 상세 = 조회, 수정 폼 = 입력). ← · 뒤로 가기 · Esc 는 한 단계 뒤, 닫기 원 · 바깥은 시트 전체.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/data/calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_clock.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/event_label.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

import '../../support/plain_text.dart';
import 'support/event_form_support.dart' show rowTitle;

class _Me extends AuthNotifier {
  @override
  Future<User?> build() async => const User(
    rowId: 1,
    userId: 'me',
    userName: '나',
    userEmail: 'me@example.com',
  );
}

class _Repo extends CalendarRepository {
  _Repo(this.world) : super(Dio());
  final _World world;

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
    world.updates++;
    world.titles[id] = title;
    if (world.moveOnSave) world.starts[id] = '2026-10-23T10:00:00';
    return world.events(2026, 10).first;
  }

  @override
  Future<void> deleteEvent(int id) async {
    world.deleted.add(id);
  }
}

/// 서버 역할 — 저장 · 삭제가 다음 조회에 비친다.
class _World {
  final deleted = <int>{};
  final titles = <int, String>{};
  final starts = <int, String>{};
  final builds = <MonthYM, int>{};
  int updates = 0;
  bool moveOnSave = false;

  /// 목록이 길어 스크롤되는 날 — 열두 줄을 더한다.
  bool many = false;

  CalendarEvent _e(
    int id,
    String title,
    String start, {
    int? user = 1,
    int calendar = 1,
    String? rrule,
  }) => CalendarEvent(
    rowId: id,
    userRowId: user,
    title: titles[id] ?? title,
    startDate: starts[id] ?? start,
    endDate: (starts[id] ?? start).replaceFirst('T10', 'T11'),
    isAllDay: 'N',
    calendarRowId: calendar,
    calendarColor: '#2c70bf',
    rrule: rrule,
  );

  List<CalendarEvent> events(int y, int m) => [
    if (y == 2026 && m == 10) ...[
      _e(1, '내 일정', '2026-10-22T10:00:00'),
      _e(2, '남의 일정', '2026-10-22T12:00:00', user: 9, calendar: 2),
      _e(3, '반복 일정', '2026-10-22T14:00:00', rrule: 'FREQ=WEEKLY'),
      _e(4, '편집권한 일정', '2026-10-22T16:00:00', user: 9, calendar: 3),
      if (many)
        for (var i = 0; i < 12; i++)
          _e(
            10 + i,
            '일정 ${10 + i}',
            '2026-10-22T${(17 + i % 6).toString().padLeft(2, '0')}:${i < 6 ? '00' : '30'}:00',
          ),
    ],
  ].where((e) => !deleted.contains(e.rowId)).toList();
}

const _cals = [
  UserCalendar(rowId: 1, calendarName: '개인', color: '#2c70bf', isDefault: true),
  UserCalendar(
    rowId: 2,
    calendarName: '회사',
    color: '#c73838',
    isOwner: false,
    myRole: 'READ',
  ),
  UserCalendar(
    rowId: 3,
    calendarName: '운동',
    color: '#2d8060',
    isOwner: false,
    myRole: 'EDIT',
  ),
];

void main() {
  late AppLocalizations l;
  setUpAll(
    () async => l = await AppLocalizations.delegate.load(const Locale('ko')),
  );

  Finder root() => find.byKey(const ValueKey('p-bottom-sheet-root'));
  Finder back() => find.byKey(const ValueKey('p-bottom-sheet-back-slot'));
  Finder close() => find.byKey(const ValueKey('p-bottom-sheet-close'));
  Finder button(String label) =>
      find.byWidgetPredicate((w) => w is PButton && w.label == label);
  Finder detailTitle() => find.byKey(const ValueKey('calendar-detail-title'));

  Future<_World> pump(
    WidgetTester tester, {
    bool moveOnSave = false,
    bool many = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final saved = calendarNow;
    calendarNow = () => DateTime(2026, 10, 29, 13);
    addTearDown(() => calendarNow = saved);
    final world = _World()
      ..moveOnSave = moveOnSave
      ..many = many;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_Me.new),
          calendarRepositoryProvider.overrideWith((ref) async => _Repo(world)),
          userCalendarListProvider.overrideWith((ref) async => _cals),
          eventLabelsProvider.overrideWith((ref) async => const <EventLabel>[]),
          holidayListProvider.overrideWith((ref, k) async => <Holiday>[]),
          monthEventsProvider.overrideWith((ref, k) async {
            world.builds[k] = (world.builds[k] ?? 0) + 1;
            return world.events(k.year, k.month);
          }),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Column(
              children: [
                // 이미 받아 둔 다음 달 — 반복 일정을 지우면 이 달도 다시 받아야 한다
                Consumer(
                  builder: (context, ref, _) {
                    ref.watch(monthEventsProvider((year: 2026, month: 11)));
                    return const SizedBox.shrink();
                  },
                ),
                const Expanded(child: CalendarScreen()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(CalendarScreen),
            matching: find.text('22'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    return world;
  }

  Future<void> tapEvent(WidgetTester tester, String title) async {
    await tester.tap(rowTitle(title).last);
    await tester.pumpAndSettle();
  }

  group('5 — 시트 안 한 단계', () {
    testWidgets('일정 줄을 누르면 같은 시트가 상세로 바뀐다 — 시트 1 · 머리 ← · "일정 상세" · 닫기', (
      tester,
    ) async {
      await pump(tester);
      expect(root(), findsOneWidget);
      expect(back(), findsNothing, reason: '목록 단계에는 ← 가 없다');
      await tapEvent(tester, '내 일정');
      expect(root(), findsOneWidget, reason: '시트를 닫고 새로 열지 않는다');
      expect(findPlain(l.calEventDetailTitle), findsOneWidget);
      expect(back(), findsOneWidget);
      expect(close(), findsOneWidget);
      expect(plainOf((tester.widget<Text>(detailTitle())).data!), '내 일정');
    });

    testWidgets('← 는 그날 목록으로, 닫기는 시트 전체를 닫는다', (tester) async {
      await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.tap(back());
      await tester.pumpAndSettle();
      expect(root(), findsOneWidget);
      expect(detailTitle(), findsNothing);
      expect(rowTitle('남의 일정'), findsWidgets, reason: '목록 단계');
      await tapEvent(tester, '내 일정');
      await tester.tap(close());
      await tester.pumpAndSettle();
      expect(root(), findsNothing, reason: '닫기 원은 단계를 건너뛰고 시트 전체');
    });

    testWidgets('Esc · 시스템 뒤로 가기는 한 단계씩 — 상세 → 목록 → 닫힘', (tester) async {
      await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(detailTitle(), findsNothing);
      expect(root(), findsOneWidget);
      await tapEvent(tester, '내 일정');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(detailTitle(), findsNothing);
      expect(root(), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(root(), findsNothing);
    });

    testWidgets('목록 · 상세는 조회라 바깥을 누르면 시트 전체가 닫힌다', (tester) async {
      await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(root(), findsNothing);
    });

    testWidgets('긴 목록에서 스크롤해 연 상세는 맨 위부터 보이고, ← 뒤 목록은 보던 스크롤 그대로다', (
      tester,
    ) async {
      await pump(tester, many: true);
      double offset() => tester
          .state<ScrollableState>(
            find
                .descendant(of: root(), matching: find.byType(Scrollable))
                .first,
          )
          .position
          .pixels;
      await tester.ensureVisible(rowTitle('일정 21').last);
      await tester.pumpAndSettle();
      final listOffset = offset();
      expect(listOffset, greaterThan(0), reason: '목록이 스크롤됐다');
      await tester.tap(rowTitle('일정 21').last);
      await tester.pumpAndSettle();
      expect(detailTitle(), findsOneWidget);
      expect(offset(), 0, reason: '상세는 맨 위부터 — 목록의 스크롤 위치가 따라오지 않는다');
      await tester.tap(back());
      await tester.pumpAndSettle();
      expect(offset(), closeTo(listOffset, 1), reason: '목록은 보던 스크롤 그대로');
    });

    testWidgets('목록에서 보던 스크롤 · 초점이 ← 뒤에도 그대로다(초점 = 연 줄)', (tester) async {
      await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.tap(back());
      await tester.pumpAndSettle();
      final focused = FocusManager.instance.primaryFocus;
      expect(focused, isNotNull);
      // 연 줄의 PListButtonItem 이 초점을 받는다 — 줄 제목 글이 그 초점 아래에 있다
      expect(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is Focus && w.focusNode == focused,
          ),
          matching: rowTitle('내 일정'),
        ),
        findsWidgets,
      );
    });
  });

  group('7 — [수정][삭제] 는 서버가 허락하는 사람에게만', () {
    testWidgets('내가 만든 일정 · 편집 권한 캘린더의 일정은 [삭제][수정] 이 있다', (tester) async {
      await pump(tester);
      await tapEvent(tester, '내 일정');
      expect(button(l.actionDelete), findsOneWidget);
      expect(button(l.actionEdit), findsOneWidget);
      await tester.tap(back());
      await tester.pumpAndSettle();
      await tapEvent(tester, '편집권한 일정');
      expect(
        button(l.actionEdit),
        findsOneWidget,
        reason: '남이 만들었지만 캘린더 권한이 EDIT',
      );
    });

    testWidgets('남이 만든 읽기 전용 캘린더 일정은 바닥 자체가 없다', (tester) async {
      await pump(tester);
      await tapEvent(tester, '남의 일정');
      expect(detailTitle(), findsOneWidget);
      expect(button(l.actionDelete), findsNothing);
      expect(button(l.actionEdit), findsNothing);
      expect(find.byKey(const ValueKey('p-bottom-sheet-footer')), findsNothing);
    });
  });

  group('9 — [수정] 은 같은 시트가 수정 폼으로', () {
    testWidgets('시트 1 · 폼 머리 ← 와 "일정 수정" · 바깥을 눌러도 닫히지 않는다 · ← 는 상세로', (
      tester,
    ) async {
      await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.tap(button(l.actionEdit));
      await tester.pumpAndSettle();
      expect(root(), findsOneWidget, reason: '새 시트를 띄우지 않는다');
      expect(findPlain(l.calEventEdit), findsOneWidget);
      expect(back(), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(root(), findsOneWidget, reason: '입력 폼 단계는 바깥 누르기로 닫히지 않는다');
      // 바꾸지 않았으면 ← 가 바로 상세로
      await tester.tap(back());
      await tester.pumpAndSettle();
      expect(detailTitle(), findsOneWidget);
      expect(find.byType(PAlertDialogView), findsNothing);
    });

    testWidgets('바꾼 채 ← · Esc → "작성한 내용이 사라져요" — 계속 작성은 폼 유지, 나가기는 상세', (
      tester,
    ) async {
      await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.tap(button(l.actionEdit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '바꾼 제목');
      await tester.pumpAndSettle();
      await tester.tap(back());
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
      await tester.tap(find.text(l.sheetLeaveStay));
      await tester.pumpAndSettle();
      expect(findPlain(l.calEventEdit), findsOneWidget, reason: '계속 작성');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        find.byType(PAlertDialogView),
        findsOneWidget,
        reason: 'Esc 도 같은 물음',
      );
      await tester.tap(find.text(l.sheetLeaveLeave));
      await tester.pumpAndSettle();
      expect(detailTitle(), findsOneWidget);
      expect(
        plainOf(tester.widget<Text>(detailTitle()).data!),
        '내 일정',
        reason: '버린 값',
      );
    });

    testWidgets('바꾼 채 닫기 원 → 같은 물음(시트 전체 닫기)', (tester) async {
      await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.tap(button(l.actionEdit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '바꾼 제목');
      await tester.pumpAndSettle();
      await tester.tap(close());
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
      await tester.tap(find.text(l.sheetLeaveLeave));
      await tester.pumpAndSettle();
      expect(root(), findsNothing);
    });

    testWidgets('저장하면 상세로 돌아와 새 값이 보인다', (tester) async {
      final world = await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.tap(button(l.actionEdit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '새 제목');
      await tester.pumpAndSettle();
      await tester.tap(button(l.actionSave));
      await tester.pumpAndSettle();
      expect(world.updates, 1);
      expect(root(), findsOneWidget);
      expect(plainOf(tester.widget<Text>(detailTitle()).data!), '새 제목');
    });

    testWidgets('날짜를 옮겨 저장해 그날에 없으면 그날 목록 단계로 간다', (tester) async {
      await pump(tester, moveOnSave: true);
      await tapEvent(tester, '내 일정');
      await tester.tap(button(l.actionEdit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '옮긴 일정');
      await tester.pumpAndSettle();
      await tester.tap(button(l.actionSave));
      await tester.pumpAndSettle();
      expect(root(), findsOneWidget);
      expect(detailTitle(), findsNothing);
      expect(rowTitle('남의 일정'), findsWidgets, reason: '그날 목록 단계');
      expect(rowTitle('옮긴 일정'), findsNothing);
    });
  });

  group('8 — 삭제 확인 글과 지운 뒤', () {
    testWidgets('반복 없음 글 → 확인하면 지운 일정이 빠진 그날 목록으로, 시트는 닫히지 않는다', (
      tester,
    ) async {
      final world = await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.tap(button(l.actionDelete));
      await tester.pumpAndSettle();
      expect(
        findPlainContaining("'내 일정' 일정을 지울까요? 지운 일정은 되돌릴 수 없어요."),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: find.text(l.actionDelete),
        ),
      );
      await tester.pumpAndSettle();
      expect(world.deleted, {1});
      expect(root(), findsOneWidget);
      expect(detailTitle(), findsNothing);
      expect(rowTitle('내 일정'), findsNothing, reason: '지운 일정은 목록에서 빠진다');
      expect(rowTitle('남의 일정'), findsWidgets);
    });

    testWidgets('반복 일정은 모든 회차가 함께 지워진다고 말하고, 받아 둔 다른 달도 다시 받는다', (
      tester,
    ) async {
      final world = await pump(tester);
      await tapEvent(tester, '반복 일정');
      await tester.tap(button(l.actionDelete));
      await tester.pumpAndSettle();
      expect(
        findPlainContaining(
          "'반복 일정' 은 반복 일정이라 모든 회차가 함께 지워져요. 지운 일정은 되돌릴 수 없어요.",
        ),
        findsOneWidget,
      );
      const nov = (year: 2026, month: 11);
      final before = world.builds[nov]!;
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: find.text(l.actionDelete),
        ),
      );
      await tester.pumpAndSettle();
      expect(world.builds[nov], before + 1, reason: '반복 일정은 보이는 달 모두 비운다');
    });

    testWidgets('반복이 아닌 일정은 그 달만 다시 받는다', (tester) async {
      final world = await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.tap(button(l.actionDelete));
      await tester.pumpAndSettle();
      const nov = (year: 2026, month: 11);
      const oct = (year: 2026, month: 10);
      final beforeNov = world.builds[nov]!;
      final beforeOct = world.builds[oct]!;
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: find.text(l.actionDelete),
        ),
      );
      await tester.pumpAndSettle();
      expect(world.builds[oct], beforeOct + 1);
      expect(world.builds[nov], beforeNov);
    });

    // 타이밍에 민감할 수 있다 — 확인창(PAlertDialog)은 자기 PopupRoute 라 맨 위 라우트로서 뒤로 가기를 먼저 받아야 한다.
    // 확인창의 닫힘 모션(pumpAndSettle)이 끝나기 전에 단언하면 흔들린다. 첫 실행에서 어긋나면 모션 끝까지 더 기다릴 것.
    testWidgets('확인창이 뜬 채 시스템 뒤로 가기는 확인창만 닫고 시트 · 상세 단계는 그대로다', (tester) async {
      final world = await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.tap(button(l.actionDelete));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsNothing, reason: '확인창만 닫힌다');
      expect(root(), findsOneWidget, reason: '시트는 그대로');
      expect(detailTitle(), findsOneWidget, reason: '상세 단계도 목록으로 물러나지 않는다');
      expect(world.deleted, isEmpty, reason: '취소와 같다 — 지우지 않는다');

      // 그다음 뒤로 가기가 비로소 한 단계(상세 → 목록)다
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(detailTitle(), findsNothing);
      expect(root(), findsOneWidget);
    });

    testWidgets('수정 폼 바닥 [삭제] 도 같은 확인창 · 지운 뒤 그날 목록', (tester) async {
      final world = await pump(tester);
      await tapEvent(tester, '내 일정');
      await tester.tap(button(l.actionEdit));
      await tester.pumpAndSettle();
      await tester.tap(button(l.actionDelete));
      await tester.pumpAndSettle();
      expect(findPlainContaining("'내 일정' 일정을 지울까요?"), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: find.text(l.actionDelete),
        ),
      );
      await tester.pumpAndSettle();
      expect(world.deleted, {1});
      expect(root(), findsOneWidget);
      expect(rowTitle('내 일정'), findsNothing);
    });
  });
}
