// 예산 경고 임계값을 바꾸면 게이지 경고선이 **곧바로** 새 값이 된다.
//
// 알림 설정의 임계값 슬라이더는 `/users/me/preferences` 로 PATCH 하고
// `userPreferences` 만 갱신했다. 그런데 홈·예산의 게이지 경고선은 같은 엔드포인트를
// **따로 GET 하는** `budgetAlertThresholdProvider` 에서 온다. 이 provider 는
// autoDispose 가 아니고 홈은 셸(IndexedStack)에 상주해 dispose 되지도 않으므로,
// 저장 뒤 비우지 않으면 방금 내가 민 눈금이 60초 신선도 규칙이 돌 때까지 게이지에
// 안 선다 — **무효화는 내가 한 것, 시계는 남이 한 것**.
//
// 화면 색으로 잰다. 78% 쓴 예산의 게이지는 임계값 85 에서 info(일반), 70 으로
//내리면 warning(경고)이다. 색이 안 바뀌면 경고선이 옛 값에 굳어 있다는 뜻이다.
//
// 설정 화면과 홈을 한 트리에 함께 띄우는 건 실제 상황 그대로다 — 설정은 홈 위로
// push 되고, 홈은 셸에 mount 된 채 남는다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/auth/user.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/budget/application/budget_providers.dart';
import 'package:porest_desk_app/features/budget/domain/budget.dart';
import 'package:porest_desk_app/features/dashboard/application/dashboard_providers.dart';
import 'package:porest_desk_app/features/dashboard/domain/dashboard_summary.dart';
import 'package:porest_desk_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/notification/application/user_preferences_providers.dart';
import 'package:porest_desk_app/features/notification/data/user_preferences_repository.dart';
import 'package:porest_desk_app/features/notification/presentation/notification_settings_screen.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_slider.dart';

/// 이번 달 1일 (`_DashboardScreenState._ymdStart` 와 같은 규칙).
String _monthStart() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-01';
}

/// 로그인 조회를 네트워크로 내보내지 않는다 — 설정 화면이 이메일을 본다.
class _NoAuth extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

UserPreferences _prefs(int threshold) => UserPreferences(
  pushEnabled: true,
  notifyPayment: true,
  notifyBudget: true,
  notifyAutoRecord: true,
  notifyDutchPay: true,
  notifyCalendar: true,
  notifyWeeklyReport: false,
  notifyMonthlyReport: false,
  budgetAlertThreshold: threshold,
  quietHoursEnabled: false,
  quietHoursStart: '22:00',
  quietHoursEnd: '07:00',
  notificationSound: NotificationSound.defaultSound,
  vibrationEnabled: true,
  emailEnabled: false,
  emailFrequency: EmailFrequency.weekly,
  timezone: 'Asia/Seoul',
  defaultCurrency: 'KRW',
);

/// 서버 대신 값을 들고 있는 가짜. `serverThreshold` 는 게이지가 **따로** 물어보는
/// 그 자리다 — PATCH 가 성공해야만 바뀐다.
class _FakePrefsRepo extends UserPreferencesRepository {
  _FakePrefsRepo() : super(Dio());

  int serverThreshold = 85;

  /// PATCH 본문들 — 몇 번, 무엇이 나갔는지.
  final List<Map<String, dynamic>> patches = [];

  /// true 면 저장이 실패한다(낙관적 반영은 롤백된다).
  bool failNext = false;

  @override
  Future<UserPreferences> get() async => _prefs(serverThreshold);

  @override
  Future<UserPreferences> update(Map<String, dynamic> fields) async {
    patches.add(fields);
    if (failNext) throw Exception('저장 실패');
    serverThreshold = fields['budgetAlertThreshold'] as int? ?? serverThreshold;
    return _prefs(serverThreshold);
  }
}

/// 게이지 채움 색 — `_BudgetRow` 의 `stateColor`.
/// 홈 화면에서 `FractionallySizedBox` 는 이 막대 하나뿐이다.
Color _gaugeFill(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(FractionallySizedBox),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (box.decoration as BoxDecoration).color!;
}

PorestTokens _tokens(WidgetTester tester) =>
    tester.element(find.byType(DashboardScreen)).tokens;

void main() {
  /// 임계값 provider 가 실제로 **다시 조회된 횟수**.
  late int thresholdReads;
  late _FakePrefsRepo repo;

  Future<void> pump(WidgetTester tester) async {
    // 홈 리스트의 예산 카드와 설정의 슬라이더가 둘 다 만들어질 만큼 길게.
    tester.view.physicalSize = const Size(430, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    thresholdReads = 0;
    repo = _FakePrefsRepo();
    final start = _monthStart();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesRepositoryProvider.overrideWith((ref) async => repo),
          authProvider.overrideWith(_NoAuth.new),
          // 게이지가 읽는 별개 조회 — 비울 때마다 서버 값을 다시 본다.
          budgetAlertThresholdProvider.overrideWith((ref) async {
            thresholdReads++;
            return repo.serverThreshold;
          }),
          // 이번 달: 상한 10만 중 7만 8천을 썼다 → 78%.
          monthBudgetsProvider.overrideWith(
            (ref, key) async => [
              Budget(
                rowId: 1,
                budgetAmount: 100000,
                budgetYear: key.year,
                budgetMonth: key.month,
              ),
            ],
          ),
          rangeSummaryProvider.overrideWith(
            (ref, range) async => RangeSummary(
              startDate: range.startDate,
              endDate: range.endDate,
              totalExpense: range.startDate == start ? 78000 : 0,
            ),
          ),
          assetSummaryProvider.overrideWith(
            (ref, key) async => const AssetSummary(),
          ),
          monthExpensesProvider.overrideWith((ref, key) async => const []),
          categoriesProvider.overrideWith((ref) async => const []),
          dashboardSummaryProvider.overrideWith(
            (ref) async => DashboardSummary.fromJson(const <String, dynamic>{}),
          ),
        ],
        child: MaterialApp(
          theme: PorestTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const Scaffold(
            body: Column(
              children: [
                // 셸에 상주하는 홈.
                Expanded(child: DashboardScreen()),
                // 그 위로 push 된 설정 화면.
                Expanded(child: NotificationSettingsScreen()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 슬라이더를 [v] 로 민다 — `_ThresholdCard` 가 건 콜백 그대로 탄다.
  Future<void> slideTo(WidgetTester tester, double v) async {
    tester.widget<PSlider>(find.byType(PSlider)).onChanged!(v);
    await tester.pumpAndSettle();
  }

  testWidgets('임계값을 내리면 홈 게이지 경고선이 60초를 안 기다리고 새 값이 된다', (tester) async {
    await pump(tester);
    final t = _tokens(tester);

    // 78% < 85% — 아직 경고선 아래다.
    expect(
      _gaugeFill(tester),
      t.statusInfoFg,
      reason: '시작 상태가 이미 경고면 이 테스트는 아무것도 안 본다',
    );
    expect(thresholdReads, 1);

    await slideTo(tester, 70);

    // 그 키 하나만 나간다(부분 수정).
    expect(repo.patches, [
      {'budgetAlertThreshold': 70},
    ]);
    expect(
      _gaugeFill(tester),
      t.statusWarningFg,
      reason:
          '78% 는 70% 경고선을 넘었는데 게이지가 옛 경고선(85%)에 굳어 있다 — '
          '저장 뒤 budgetAlertThresholdProvider 를 안 비웠다',
    );
    // 색이 바뀐 이유가 **다시 조회했기 때문**임을 못 박는다.
    expect(thresholdReads, 2);
  });

  testWidgets('저장이 실패하면 비우지 않는다 — 서버 값은 그대로다', (tester) async {
    await pump(tester);
    expect(thresholdReads, 1);

    repo.failNext = true;
    await slideTo(tester, 70);

    expect(repo.patches, hasLength(1), reason: 'PATCH 는 나갔다');
    expect(thresholdReads, 1, reason: '롤백된 저장까지 비우면 바뀌지도 않은 값을 헛되이 다시 물어본다');
    expect(_gaugeFill(tester), _tokens(tester).statusInfoFg);
  });
}
