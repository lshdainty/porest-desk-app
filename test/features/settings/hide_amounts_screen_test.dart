import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/lock/app_lock.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/core/storage/prefs_provider.dart';
import 'package:porest_desk_app/features/settings/presentation/hide_amounts_screen.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required _FakeAuth auth,
    Set<String> hidden = const {},
    bool appLock = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.appLock: appLock,
      PrefsKeys.hideCards: hidden.toList(),
    });
    final container = ProviderContainer(
      overrides: [appLockAuthProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    container.listen(appLockedProvider, (_, _) {});
    await container.read(settingsProvider.future);

    // 실제 진입과 같게 push 로 쌓는다 — 저장 후 pop 할 자리가 있어야 한다.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('보안'))),
        GoRoute(path: '/hide', builder: (_, _) => const HideAmountsScreen()),
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
    await tester.pumpAndSettle();
    router.push('/hide');
    await tester.pumpAndSettle();
    return container;
  }

  group('금액 가리기 화면', () {
    testWidgets('카드를 골라도 저장 전에는 설정이 그대로다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final container = await pumpScreen(tester, auth: auth);

      await tester.tap(find.text('순자산').first);
      await tester.pumpAndSettle();

      // 화면에서만 골라 둔 상태 — 인증도 저장도 아직 없다.
      expect(auth.calls, 0);
      expect(container.read(settingsProvider).value?.hideCards, isEmpty);
    });

    testWidgets('가리기만 늘리는 저장은 인증 없이 통과한다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final container = await pumpScreen(tester, auth: auth);

      await tester.tap(find.text('순자산').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(auth.calls, 0);
      expect(
        container.read(settingsProvider).value?.hideCards,
        {'home.netWorth'},
      );
    });

    testWidgets('푸는 게 섞이면 저장할 때 인증을 한 번만 받는다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final container = await pumpScreen(
        tester,
        auth: auth,
        hidden: {'home.netWorth', 'home.budget', 'home.todaySpend'},
      );

      // 세 장을 한꺼번에 푼다 — 예전엔 스위치마다 인증이 떴다.
      for (final label in ['순자산', '예산 진행', '오늘 지출']) {
        await tester.tap(find.text(label).first);
        await tester.pumpAndSettle();
      }
      expect(auth.calls, 0);

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(auth.calls, 1);
      expect(container.read(settingsProvider).value?.hideCards, isEmpty);
    });

    testWidgets('인증을 취소하면 아무것도 저장되지 않는다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.failure);
      final container = await pumpScreen(
        tester,
        auth: auth,
        hidden: {'home.netWorth'},
        // 생체 실패 후 비밀번호 다이얼로그로 물러선다 — 거기서 취소한다.
      );

      await tester.tap(find.text('순자산').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      // 저장 버튼이 로딩 스피너(무한 애니메이션)로 바뀌어 settle 이 끝나지 않는다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('금액 보기 인증'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        container.read(settingsProvider).value?.hideCards,
        {'home.netWorth'},
      );
    });

    testWidgets('저장 버튼은 바꾼 게 있어야 눌린다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      await pumpScreen(tester, auth: auth);

      final button = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('저장'),
          matching: find.byType(InkWell),
        ).first,
      );
      expect(button.onTap, isNull);

      await tester.tap(find.text('순자산').first);
      await tester.pumpAndSettle();

      final enabled = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('저장'),
          matching: find.byType(InkWell),
        ).first,
      );
      expect(enabled.onTap, isNotNull);
    });

    testWidgets('모두 선택은 지금 탭의 카드만 고른다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final container = await pumpScreen(tester, auth: auth);

      // '홈' 탭으로 옮겨 그 탭만 전부 고른다.
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('모두 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(
        container.read(settingsProvider).value?.hideCards,
        cardsOfPage(HidePage.home).toSet(),
      );
    });

    testWidgets('탭 라벨에 고른 개수가 붙는다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      await pumpScreen(tester, auth: auth, hidden: {'home.netWorth'});

      // 전체 1 / 홈 1 — 나머지 탭은 개수 없이 이름만.
      expect(find.text('전체 1'), findsOneWidget);
      expect(find.text('홈 1'), findsOneWidget);
      expect(find.text('자산'), findsOneWidget);
    });
  });
}
