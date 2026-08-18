import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/auth/user.dart';
import 'package:porest_desk_app/core/lock/app_lock.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/core/storage/prefs_provider.dart';
import 'package:porest_desk_app/features/settings/presentation/account_screen.dart';
import 'package:porest_desk_app/features/settings/presentation/appearance_section.dart';
import 'package:porest_desk_app/features/settings/presentation/hide_amounts_screen.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';

/// OS 프롬프트 없이 정해진 결과만 돌려주는 가짜 인증.
class _FakeAuth extends AppLockAuth {
  _FakeAuth(this.result) : super(LocalAuthentication());

  final AppLockAuthResult result;
  int calls = 0;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<AppLockAuthResult> authenticate({
    required String reason,
    required String signInTitle,
    required String cancelLabel,
  }) async {
    calls++;
    return result;
  }
}

class _FakeAuthUser extends AuthNotifier {
  @override
  Future<User?> build() async => const User(
        rowId: 1,
        userId: 'tester',
        userName: 'Tester',
        userEmail: 'tester@example.com',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpAccount(
    WidgetTester tester, {
    required _FakeAuth auth,
  }) async {
    final container = ProviderContainer(
      overrides: [
        appLockAuthProvider.overrideWithValue(auth),
        authProvider.overrideWith(_FakeAuthUser.new),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
        GoRoute(
            path: '/settings/hide-amounts',
            builder: (_, _) => const HideAmountsScreen()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: PorestTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return container;
  }

  group('계정 > 보안', () {
    testWidgets('앱 잠금·금액 가리기 행이 보안 섹션에 있다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await pumpAccount(tester, auth: _FakeAuth(AppLockAuthResult.success));
      await container.read(settingsProvider.future);
      await tester.pump();

      expect(find.text('앱 잠금'), findsOneWidget);
      expect(find.text('금액 가리기'), findsOneWidget);
      // 가려진 카드 수 / 전체 — 들어가 보지 않아도 상태가 보여야 한다.
      expect(find.text('0 / ${kAllHideCards.length}'), findsOneWidget);
      // '준비중' 자리표시 행은 사라졌다.
      expect(find.text('준비중'), findsNothing);
    });

    testWidgets('앱 잠금 스위치는 인증을 통과해야 켜진다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final auth = _FakeAuth(AppLockAuthResult.failure);
      final container = await pumpAccount(tester, auth: auth);
      await container.read(settingsProvider.future);
      await tester.pump();

      // 보안 섹션의 스위치는 2FA·앱 잠금 둘뿐 — 앱 잠금이 두 번째다.
      final switches = find.byType(PSwitch);
      expect(switches, findsNWidgets(2));
      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();

      expect(auth.calls, 1);
      // 인증 실패 → 꺼진 채로 남는다.
      expect(container.read(appLockEnabledProvider), false);
    });

    testWidgets('금액 가리기 행을 누르면 전용 화면으로 간다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await pumpAccount(tester, auth: _FakeAuth(AppLockAuthResult.success));
      await container.read(settingsProvider.future);
      await tester.pump();

      await tester.tap(find.text('금액 가리기'));
      await tester.pumpAndSettle();

      // 전용 화면 — 아코디언을 펼치지 않아도 전체 목록이 바로 보인다.
      expect(find.text('전체 잠그기'), findsOneWidget);
      expect(find.text('순자산'), findsOneWidget);
    });
  });

  group('표시 설정', () {
    testWidgets('개인정보 보호 섹션이 빠지고 테마·언어만 남는다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWith((_) => SharedPreferences.getInstance())],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PorestTheme.light(),
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppearanceScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('테마'), findsOneWidget);
      expect(find.text('개인정보 보호'), findsNothing);
      expect(find.text('앱 잠금'), findsNothing);
      expect(find.text('금액 가리기'), findsNothing);
    });
  });
}
