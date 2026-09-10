// 알림 폴러는 **로그인했고 + 앱이 앞에 있을 때만** 돈다.
//
// `start`/`stop` 을 부르는 자리는 로그인·로그아웃 하나뿐이었다. 로그아웃은 거의 안 하므로
// 사실상 깔아 둔 내내 30초마다 알림 20건을 통째로 받았다. 그런데 그 결과가 바꾸는 건
// 앱 안 배지뿐이다 — 폰 알림창에 뜨는 게 아니라(FCM 이 아직 없다), 앱이 안 보이는 동안의
// 폴링은 아무도 못 보는 값을 받아 배터리·데이터만 쓴다.
//
// 여기서 세는 건 "조건문이 있다" 가 아니라 **알림 조회가 실제로 몇 번 나갔는가** 다.
// 시간은 위젯 테스트의 가짜 시계로 민다 — 진짜 30초를 기다리지 않는다.
//
// 앱은 **진짜 `PorestDeskApp`** 을 띄운다. 폴러를 켜고 끄는 배선이 거기 있으므로,
// 배선을 흉내 내면 정작 그게 끊겨도 테스트는 통과한다.
// lifecycle 도 엔진이 보내는 것과 같은 플랫폼 메시지로 넣는다(#350 과 같은 방식).
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/app/app.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/auth/user.dart';
import 'package:porest_desk_app/core/storage/prefs_provider.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/notification/application/notification_providers.dart';
import 'package:porest_desk_app/features/notification/application/notification_stream_service.dart';
import 'package:porest_desk_app/features/notification/data/notification_repository.dart';
import 'package:porest_desk_app/features/notification/domain/notification.dart';

/// 폴링 주기 — `NotificationStreamService.start` 의 기본값과 같아야 한다.
const _tick = Duration(seconds: 30);

void main() {
  // ─── 백그라운드 ─────────────────────────────────────────────
  testWidgets('백그라운드로 가면 30초가 세 번 지나도 알림을 안 묻는다', (tester) async {
    final h = await _pumpApp(tester);
    expect(h.calls, 1, reason: '로그인 직후 한 번은 묻는다 — 첫 조회는 baseline 이라 그대로 둔다');

    await h.background();
    final atBackground = h.calls;

    for (var i = 0; i < 3; i++) {
      await h.advance(_tick);
    }

    expect(
      h.calls,
      atBackground,
      reason:
          '앱이 안 보이는데 30초마다 알림 20건을 받았다. 그 결과가 바꾸는 건 앱 안 배지뿐이라 '
          '아무도 못 보고 사라진다 — 앞에 있지 않으면 폴러를 멈춰야 한다',
    );
  });

  testWidgets('앞으로 돌아오면 즉시 한 번 묻고, 다시 30초마다 묻는다', (tester) async {
    final h = await _pumpApp(tester);

    await h.background();
    await h.advance(_tick);
    final atBackground = h.calls;

    await h.foreground();
    expect(
      h.calls,
      atBackground + 1,
      reason: '복귀 직후 한 번은 바로 물어야 한다 — 안 그러면 최대 30초 동안 배지가 떠나기 전 값이다',
    );

    await h.advance(_tick);
    expect(h.calls, atBackground + 2, reason: '복귀했는데 30초 주기가 다시 안 돈다');
  });

  // ─── 로그아웃 ───────────────────────────────────────────────
  testWidgets('로그아웃하면 앞에 있어도 안 묻는다 — 조건은 둘 다 성립해야 한다', (tester) async {
    // 로그아웃하면 라우터가 로그인 화면으로 되돌린다. 테스트 폰트는 글자마다 정사각형이라
    // 'Porest Desk' 한 줄이 진짜 폰트보다 두 배 넘게 재어져 390 폭에서 넘친다(테스트
    // 환경 산물이지 실기기 문제가 아니다) — 넘칠 자리를 주고 폴러 횟수만 본다.
    final h = await _pumpApp(tester, width: 520);

    await h.logout();
    final atLogout = h.calls;

    for (var i = 0; i < 3; i++) {
      await h.advance(_tick);
    }
    expect(h.calls, atLogout, reason: '로그아웃했는데 폴러가 계속 돈다');

    // 앞에 있다고 되살아나면 안 된다 — 포그라운드는 조건의 한쪽일 뿐이다.
    await h.background();
    await h.foreground();
    expect(h.calls, atLogout, reason: '포그라운드로 돌아왔다고 로그아웃 상태의 폴러까지 되살리면 안 된다');
  });

  // ─── 타이머는 하나뿐 ────────────────────────────────────────
  testWidgets('켜는 경로를 여러 번 밟아도 30초에 한 번만 묻는다 — 타이머가 겹치지 않는다', (tester) async {
    final h = await _pumpApp(tester);

    // 켜는 자리가 둘(인증·포그라운드)이라 **멈추는 일 없이 연달아** 켜지는 길이 있다.
    // 무음 재인증이 그 자리다 — 이미 돌고 있는데 새 타이머를 얹으면 요청이 배로 나가고,
    // 멈추는 쪽은 한 번뿐이라 겹친 하나는 앱을 끌 때까지 안 꺼진다.
    await h.background();
    await h.foreground();
    await h.reauthenticate();
    await h.reauthenticate();

    final before = h.calls;
    await h.advance(_tick);
    expect(
      h.calls,
      before + 1,
      reason: '30초에 한 번이어야 한다 — 여러 번 늘었으면 타이머가 겹쳐 돌고 있다',
    );

    await h.advance(_tick);
    expect(h.calls, before + 2, reason: '다음 30초도 한 번이어야 한다');
  });

  // ─── baseline ───────────────────────────────────────────────
  testWidgets('멈췄다 켜도 그동안 온 알림을 새 것으로 친다 — baseline 이 초기화되지 않는다', (
    tester,
  ) async {
    // 첫 조회는 "여기까지는 본 것" 을 적어 두는 baseline 이라 emit 하지 않는다.
    // 멈췄다 켤 때 그 기준이 초기화되면, 복귀 조회가 그동안 온 알림을 **또 baseline 으로**
    // 삼아 버려 아무것도 안 뜬다. 반대로 기준을 안 올리면 같은 알림이 두 번 뜬다.
    final h = await _pumpApp(tester, server: [_notify(1, '결제 알림')]);
    expect(h.emitted, isEmpty, reason: '첫 조회는 baseline 이라 emit 하지 않는다');

    await h.background();
    // 앱이 안 보이는 사이 새 알림 둘이 쌓인다.
    h.server
      ..add(_notify(2, '예산 초과'))
      ..add(_notify(3, '카드 결제일'));
    await h.advance(_tick);
    expect(h.emitted, isEmpty, reason: '백그라운드에서는 묻지도 않으므로 뜰 것도 없다');

    await h.foreground();
    expect(
      h.emitted.map((n) => n.rowId),
      [2, 3],
      reason:
          '멈춘 사이 온 알림 둘이 새 것으로 잡혀야 한다 — 복귀 조회가 baseline 부터 다시 잡으면 '
          '아무것도 안 뜨고, 그 알림들은 영영 안 뜬다',
    );

    await h.advance(_tick);
    expect(h.emitted.map((n) => n.rowId), [
      2,
      3,
    ], reason: '다음 조회에서 같은 알림이 또 떴다 — 기준을 안 올렸다');
  });
}

// ─── 하네스 ───────────────────────────────────────────────────

AppNotification _notify(int rowId, String title) =>
    AppNotification(rowId: rowId, title: title);

class _Harness {
  _Harness(this.tester, this.container, this._calls, this.emitted, this.server);
  final WidgetTester tester;
  final ProviderContainer container;
  final List<int> _calls;

  /// 새 알림으로 판정돼 stream 으로 나간 것들.
  final List<AppNotification> emitted;

  /// 서버가 들고 있는 알림 — 테스트가 도중에 늘릴 수 있다.
  final List<AppNotification> server;

  /// 폴러가 알림 목록을 물어본 횟수.
  int get calls => _calls.first;

  /// 가짜 시계를 [d] 만큼 민다 — 진짜로 기다리지 않는다.
  Future<void> advance(Duration d) async {
    await tester.pump(d);
    await _flush();
  }

  /// 앱을 백그라운드로 — 엔진이 보내는 순서 그대로.
  Future<void> background() => _lifecycle(const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]);

  /// 앱이 앞으로 돌아온다 — 역순.
  Future<void> foreground() => _lifecycle(const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]);

  Future<void> logout() async {
    (container.read(authProvider.notifier) as _FakeAuth).signOutForTest();
    await _flush();
  }

  /// 로그인한 채로 인증 상태가 한 번 더 실린다(무음 재인증).
  Future<void> reauthenticate() async {
    (container.read(authProvider.notifier) as _FakeAuth)
        .reauthenticateForTest();
    await _flush();
  }

  Future<void> _lifecycle(List<AppLifecycleState> states) async {
    for (final s in states) {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StringCodec().encodeMessage(s.toString()),
        (_) {},
      );
      await tester.pump();
    }
    await _flush();
  }

  /// 폴러의 한 번 조회는 `await` 를 두 단계 거친다 — 프레임을 몇 번 밀어 해소시킨다.
  /// `pumpAndSettle` 은 못 쓴다: 로딩 스켈레톤이 `..repeat()` 무한 애니메이션이라 안 끝난다.
  Future<void> _flush() async {
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
  }
}

class _FakeAuth extends AuthNotifier {
  static const _user = User(
    rowId: 1,
    userId: 'tester',
    userName: 'Tester',
    userEmail: 'tester@example.com',
  );

  int _reauths = 0;

  @override
  Future<User?> build() async => _user;

  /// 로그아웃. 진짜 [AuthNotifier.logout] 은 서버·쿠키·SSO 를 물고 있어 여기서는 못 쓴다 —
  /// 폴러를 켜고 끄는 리스너가 보는 것은 `AsyncData(null)` 하나뿐이라 그 자리만 흉내 낸다.
  void signOutForTest() => state = const AsyncData(null);

  /// 무음 재인증 — **로그인한 채로** 인증 상태가 한 번 더 실린다.
  /// 서버가 사용자 정보를 새로 실어 오는 자리라 값도 달라질 수 있다(표시 이름 변경 등).
  void reauthenticateForTest() {
    _reauths++;
    state = AsyncData(_user.copyWith(userName: 'Tester $_reauths'));
  }
}

/// 알림 조회 대역 — **몇 번 불렸는지**와 그때 서버가 뭘 들고 있었는지만 본다.
class _CountingNotificationRepo extends NotificationRepository {
  _CountingNotificationRepo(this._calls, this._items) : super(Dio());
  final List<int> _calls;
  final List<AppNotification> _items;

  @override
  Future<List<AppNotification>> list({bool? unread, int? limit}) async {
    _calls[0]++;
    return List.of(_items);
  }

  // 셸 헤더의 종 배지가 읽는다 — 네트워크를 태우지 않는다.
  @override
  Future<int> unreadCount() async => 0;
}

Future<_Harness> _pumpApp(
  WidgetTester tester, {
  List<AppNotification> server = const [],
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({PrefsKeys.locale: 'ko'});

  final items = <AppNotification>[...server];
  final calls = <int>[0];
  final repo = _CountingNotificationRepo(calls, items);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_FakeAuth.new),
        notificationRepositoryProvider.overrideWith((ref) async => repo),
        // 테스트는 백엔드를 띄우지 않으므로 셸이 읽는 데이터는 빈 값으로 채운다.
        categoriesProvider.overrideWith(
          (_) => Future.value(<ExpenseCategory>[]),
        ),
        assetsProvider.overrideWith((_) => Future.value(<Asset>[])),
        assetSummaryProvider.overrideWith(
          (_, _) => Future.value(const AssetSummary()),
        ),
        monthExpensesProvider.overrideWith((_, _) => Future.value(<Expense>[])),
      ],
      child: const PorestDeskApp(),
    ),
  );
  // pumpAndSettle 은 못 쓴다(무한 스켈레톤 애니메이션) — 인증 확인이 끝나 폴러가
  // 첫 조회를 마칠 때까지 프레임을 민다. 30초보다 훨씬 짧게 민다: 여기서 주기를
  // 넘겨 버리면 각 테스트가 세는 기준이 흔들린다.
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  final container = ProviderScope.containerOf(
    tester.element(find.byType(PorestDeskApp)),
    listen: false,
  );
  final emitted = <AppNotification>[];
  // 첫 조회(baseline)는 아무것도 emit 하지 않으므로 여기서 붙어도 놓치는 것이 없다.
  final sub = container
      .read(notificationStreamServiceProvider)
      .newNotifications
      .listen(emitted.add);
  addTearDown(sub.cancel);

  return _Harness(tester, container, calls, emitted, items);
}
