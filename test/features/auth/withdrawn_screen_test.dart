// 해지 완료 화면 — 웹 /withdrawn 과 같은 화면이 앱에도 있다(2026-09-22 사용자 결정).
//
// 두 길로 들어온다. ① 해지 직후(해지 시트가 보낸다) ② 해지한 계정의 로그인 시도
// (USER_021 — 라우터가 보낸다). 예전엔 ① 은 6초 토스트(폰에서 4줄, 재가입 안내 없음),
// ② 는 로그인 화면의 빨간 에러 글(데이터 안내 없음)이라 사라지거나 서로 다른 말을 했다.
//
// 이 파일이 붙잡는 것:
//  - 화면에 해지 끝 · 데이터 보관·파기 · 재가입 불가가 다 나온다
//  - 로그아웃 상태에서도 이 화면에 머문다(해지 직후 로그아웃이 로그인으로 튕기지 않는다)
//  - [로그인 화면으로] · 뒤로가기 는 로그인 화면으로 — 다시 튕기지도, 앱이 닫히지도 않는다
//  - 해지를 마치면 토스트가 아니라 이 화면이 뜨고 로그아웃한다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/app/router.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/auth/user.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/storage/prefs_provider.dart';
import 'package:porest_desk_app/core/update/app_update.dart';
import 'package:porest_desk_app/features/auth/presentation/withdrawn_screen.dart';
import 'package:porest_desk_app/features/settings/application/withdrawal_providers.dart';
import 'package:porest_desk_app/features/settings/data/withdrawal_repository.dart';
import 'package:porest_desk_app/features/settings/domain/withdrawal_check.dart';
import 'package:porest_desk_app/features/settings/presentation/withdrawal_sheet.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

const _user = User(
  rowId: 1,
  userId: 'tester',
  userName: 'Tester',
  userEmail: 'tester@example.com',
);

/// 인증 대역. 진짜 로그아웃은 서버·쿠키·SSO 를 물고 있어 상태 자리만 흉내 낸다.
class _FakeAuth extends AuthNotifier {
  _FakeAuth(this._initial);
  final User? _initial;
  int logouts = 0;

  @override
  Future<User?> build() async => _initial;

  @override
  Future<void> logout() async {
    logouts++;
    state = const AsyncData(null);
  }

  /// 딥링크 교환이 실패한 자리 — 진짜 [AuthNotifier.exchangeAndLoginWithCode] 처럼
  /// 에러를 상태에 싣는다.
  void failLogin(Object e) => state = AsyncError(e, StackTrace.current);
}

class _FakeRepo extends WithdrawalRepository {
  _FakeRepo() : super(Dio());

  @override
  Future<WithdrawalCheck> check() async => const WithdrawalCheck(
    blocked: [],
    subscriptionPeriodEnd: null,
    sharedCalendarsOwned: 0,
    calendarMemberships: 0,
    dutchPaysOwned: 0,
    dutchPayParticipations: 0,
  );

  @override
  Future<String> verifyPassword(String password) async => 'ticket';

  @override
  Future<void> withdraw({required String reauthToken, String? reason}) async {}
}

final _l = lookupAppLocalizations(const Locale('ko'));

MaterialApp _app(GoRouter router) => MaterialApp.router(
  theme: PorestTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: router,
);

/// 앱의 진짜 라우터(redirect 포함)로 띄운다. 업데이트 안내는 끈다.
Future<ProviderContainer> _pumpRealRouter(
  WidgetTester tester,
  _FakeAuth auth,
) async {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(() => auth),
      updateStatusProvider.overrideWith(
        (ref) async => const UpdateStatus(currentBuild: 1, latest: null),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _app(container.read(routerProvider)),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({PrefsKeys.locale: 'ko'});
  });

  final withdrawnError = ApiException(
    code: 'USER_021',
    message: '해지한 계정이에요',
    statusCode: 403,
  );

  testWidgets('해지한 계정으로 로그인하면 로그인 에러 글이 아니라 해지 완료 화면이다', (tester) async {
    final auth = _FakeAuth(null);
    await _pumpRealRouter(tester, auth);
    expect(find.text(_l.authSsoLogin), findsOneWidget, reason: '로그아웃 → 로그인 화면');

    auth.failLogin(withdrawnError);
    await tester.pumpAndSettle();

    expect(find.byType(WithdrawnScreen), findsOneWidget);
    expect(find.text(_l.withdrawnTitle), findsOneWidget);
    expect(find.text(_l.withdrawnBody), findsOneWidget);
    expect(find.textContaining('감사했습니다'), findsOneWidget);
    expect(find.text(_l.withdrawIrreversibleRejoin), findsOneWidget);
    expect(find.text(_l.withdrawnToLogin), findsOneWidget);
    expect(find.text(_l.authSsoLogin), findsNothing);
  });

  testWidgets('[로그인 화면으로] 는 에러를 걷고 로그인 화면으로 — 다시 튕기지 않는다', (tester) async {
    final auth = _FakeAuth(null);
    final container = await _pumpRealRouter(tester, auth);
    auth.failLogin(withdrawnError);
    await tester.pumpAndSettle();

    await tester.tap(find.text(_l.withdrawnToLogin));
    await tester.pumpAndSettle();

    expect(find.byType(WithdrawnScreen), findsNothing);
    expect(find.text(_l.authSsoLogin), findsOneWidget);
    expect(container.read(authProvider).hasError, isFalse);
  });

  testWidgets('뒤로가기도 로그인 화면으로 — 앱이 닫히지 않는다', (tester) async {
    final platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final auth = _FakeAuth(null);
    await _pumpRealRouter(tester, auth);
    auth.failLogin(withdrawnError);
    await tester.pumpAndSettle();

    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();

    expect(find.text(_l.authSsoLogin), findsOneWidget);
    expect(
      platformCalls.any((c) => c.method == 'SystemNavigator.pop'),
      isFalse,
      reason: '뒤로가기로 앱이 닫히면 해지 안내 뒤에 할 일을 못 찾는다',
    );
  });

  testWidgets('로그아웃 상태에서도 해지 완료 화면에 머문다 — 로그인으로 튕기지 않는다', (tester) async {
    final auth = _FakeAuth(null);
    final container = await _pumpRealRouter(tester, auth);

    container.read(routerProvider).go('/withdrawn');
    await tester.pumpAndSettle();
    expect(find.byType(WithdrawnScreen), findsOneWidget);

    // 해지 직후의 로그아웃과 같은 자리 — 인증 상태가 다시 실려 redirect 가 한 번 더 돈다.
    await auth.logout();
    await tester.pumpAndSettle();
    expect(find.byType(WithdrawnScreen), findsOneWidget);
    expect(find.text(_l.authSsoLogin), findsNothing);
  });

  testWidgets('해지를 마치면 토스트가 아니라 완료 화면이 뜨고 로그아웃한다', (tester) async {
    final auth = _FakeAuth(_user);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () => showWithdrawalSheet(c),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(path: '/withdrawn', builder: (_, _) => const WithdrawnScreen()),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('LOGIN')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => auth),
          withdrawalRepositoryProvider.overrideWith((ref) async => _FakeRepo()),
        ],
        child: _app(router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.withdrawNext));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'secret');
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l.withdrawConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(WithdrawnScreen), findsOneWidget);
    expect(find.textContaining('감사했습니다'), findsOneWidget);
    expect(auth.logouts, 1);
    expect(find.byType(SnackBar), findsNothing, reason: '예전 6초 토스트는 없다');
  });
}
