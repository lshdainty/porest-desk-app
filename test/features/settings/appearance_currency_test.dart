// 표시 설정의 '기본 통화' 는 **계정에 저장한다** (D7 · QA #124).
//
// 종전엔 기기 `SharedPreferences` 에만 넣었고 **읽는 곳이 하나도 없었다**. 고르면
// 저장된 것처럼 보이는데 폰을 바꾸면 사라지고, 새 자산·거래 어디에서도 아무 일이
// 일어나지 않았다. 지역 설정과 같은 자리(`/me/preferences` 의 `defaultCurrency`,
// desk-back #328)로 옮겼다 — 웹도 같은 자리를 읽는다(desk-front #368).
//
// 여기서 잠그는 것 셋:
//   ① 고른 값이 **서버로 나간다** — 그 키 하나만(부분 수정이라 나머지는 무변경)
//   ② **서버가 준 값으로 그린다** — 웹에서 고른 값이 폰에서도 보여야 한다
//   ③ 아직 못 읽었으면 **원화로 그리되 못 누르게** 막는다. 넷 다 꺼 두면 고장으로
//      보이고, 열어 두면 도착 전에 누른 값이 조용히 사라진다
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/notification/application/user_preferences_providers.dart';
import 'package:porest_desk_app/features/notification/data/user_preferences_repository.dart';
import 'package:porest_desk_app/features/settings/presentation/appearance_section.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_radio_list.dart';

/// 서버 대신 값을 들고 있는 가짜 — 무엇이 나갔는지까지 잡는다.
class _FakePrefsRepo extends UserPreferencesRepository {
  _FakePrefsRepo(this._current) : super(Dio());

  UserPreferences _current;

  /// PATCH 본문들 — 몇 번, 무엇이 나갔는지.
  final List<Map<String, dynamic>> patches = [];

  /// GET 을 영영 안 끝내고 싶을 때(아직 못 읽은 상태) 쓴다.
  bool hang = false;

  @override
  Future<UserPreferences> get() async {
    if (hang) return Completer<UserPreferences>().future;
    return _current;
  }

  @override
  Future<UserPreferences> update(Map<String, dynamic> fields) async {
    patches.add(fields);
    _current = _current.copyWith(
      defaultCurrency: fields['defaultCurrency'] as String?,
    );
    return _current;
  }
}

UserPreferences _prefs({String defaultCurrency = 'KRW'}) => UserPreferences(
  pushEnabled: true,
  notifyPayment: true,
  notifyBudget: true,
  notifyAutoRecord: true,
  notifyDutchPay: true,
  notifyCalendar: true,
  notifyWeeklyReport: false,
  notifyMonthlyReport: false,
  budgetAlertThreshold: 85,
  quietHoursEnabled: false,
  quietHoursStart: '22:00',
  quietHoursEnd: '07:00',
  notificationSound: NotificationSound.defaultSound,
  vibrationEnabled: true,
  emailEnabled: false,
  emailFrequency: EmailFrequency.weekly,
  timezone: 'Asia/Seoul',
  defaultCurrency: defaultCurrency,
);

Future<_FakePrefsRepo> _pump(
  WidgetTester tester, {
  String serverCurrency = 'KRW',
  bool hang = false,
}) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final repo = _FakePrefsRepo(_prefs(defaultCurrency: serverCurrency))
    ..hang = hang;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userPreferencesRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const Scaffold(
          body: SingleChildScrollView(child: AppearanceSection()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// 지금 켜져 있는 통화 — 통화 리스트는 이 화면의 유일한 `PRadioList<String>` 이다.
PRadioList<String> _currencyList(WidgetTester tester) =>
    tester.widget<PRadioList<String>>(find.byType(PRadioList<String>));

void main() {
  testWidgets('고른 통화가 서버로 나간다 — 그 키 하나만', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();

    expect(repo.patches, [
      {'defaultCurrency': 'USD'},
    ], reason: '기기에만 넣으면 폰을 바꾸는 순간 사라지고 새 자산·거래도 못 읽는다');
    expect(_currencyList(tester).value, 'USD');
  });

  testWidgets('서버가 준 값으로 그린다', (tester) async {
    // 웹에서 EUR 를 골라 뒀다면 폰에서도 EUR 로 보여야 한다.
    await _pump(tester, serverCurrency: 'EUR');

    expect(_currencyList(tester).value, 'EUR');
  });

  testWidgets('같은 값을 다시 누르면 아무것도 안 보낸다', (tester) async {
    final repo = await _pump(tester, serverCurrency: 'USD');

    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();

    expect(repo.patches, isEmpty);
  });

  testWidgets('아직 못 읽었으면 원화로 그리되 못 누른다', (tester) async {
    final repo = await _pump(tester, hang: true);

    // 넷 다 꺼 두면 고장으로 보인다 — 원화로 떨어뜨린다.
    expect(_currencyList(tester).value, 'KRW');
    // 도착 전에 누르면 그 값이 조용히 사라진다 — 아예 못 누르게 막는다.
    expect(_currencyList(tester).onChanged, isNull);

    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();
    expect(repo.patches, isEmpty);
  });

  testWidgets('기기에는 아무것도 안 남긴다', (tester) async {
    // 값이 두 벌이 되면 어느 쪽이 참인지 모르게 된다 — 계정 값 하나만 둔다.
    // 웹도 `pd-currency`(localStorage) 를 옮겨 오지 않았다(desk-front #368).
    await _pump(tester);

    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('pd-currency'),
      isNull,
      reason: '기기에도 쓰면 계정 값과 갈려 어느 쪽이 참인지 모르게 된다',
    );
  });
}
