// 해지 뒤 **유예 기간** — 돈 낸 기간이 남은 사람을 Free 취급하지 않는다.
//
// 서버(desk-back #332)는 해지해도 만료일을 앞당기지 않는다. 응답은
// `status=CANCELLED` · `autoRenew=false` · `currentPeriodEnd=<미래>` 로 남고
// `features` 에도 `SECURITIES` 가 그대로 있어 증권 기능은 열려 있다.
// 앱이 `status == 'ACTIVE'` 만 보던 동안 시트는 그 사람에게 "Free 플랜 이용 중" 과
// "Pro 시작하기" 를 내밀었다 — 이미 구독 중이라 서버가 거절하는 버튼이다.
//
// 문구도 같이 갈린다. 해지한 구독에 **다음 결제는 없다** — 그 날짜는 결제일이
// 아니라 이용이 끝나는 날이다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/features/subscription/data/subscription_repository.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/subscription/presentation/subscription_sheet.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations_ko.dart';

/// 서버가 주는 모양 — `LocalDateTime` 직렬화라 **시간대 표시가 없다**(UTC 벽시계).
/// 여기서 `Z` 를 붙여 두면 정작 고쳐야 할 경로(무표시 → UTC 로 읽기)를 안 지난다.
String _serverUtc(Duration offset) {
  final iso = DateTime.now().toUtc().add(offset).toIso8601String();
  return iso.endsWith('Z') ? iso.substring(0, iso.length - 1) : iso;
}

SubscriptionInfo _sub({
  required String status,
  String? currentPeriodEnd,
  bool autoRenew = true,
}) => SubscriptionInfo(
  planCode: 'SECURITIES',
  planName: 'Porest Pro',
  status: status,
  currentPeriodEnd: currentPeriodEnd,
  autoRenew: autoRenew,
);

Widget _app(SubscriptionInfo? sub) => ProviderScope(
  overrides: [mySubscriptionProvider.overrideWith((ref) async => sub)],
  child: MaterialApp(
    theme: PorestTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Builder(
      builder: (ctx) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showSubscriptionSheet(ctx),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _openSheet(WidgetTester tester, SubscriptionInfo? sub) async {
  // 시트(0.92)가 배너·footer 를 한 번에 담도록 세로를 넉넉히. 폭은 폰 폭 고정 —
  // 640 을 넘기면 Material 이 시트를 640 으로 잘라 가운데 정렬한다.
  //
  // 430(iPhone Pro Max 급)인 이유: Pro 플랜 카드의 `Pro | 현재 플랜` 행이 390 폭에서
  // 3.9px 넘친다. **이 변경과 무관한 기존 레이아웃 문제**로 origin/main 에서도 같은
  // 폭에 ACTIVE 구독을 물리면 똑같이 넘친다 — 여기서 붙잡을 일이 아니라 폭을 피한다.
  tester.view.physicalSize = const Size(430 * 3, 1600 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(sub));
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  final l = AppLocalizationsKo();

  group('SubscriptionInfo.isActive', () {
    test('ACTIVE 는 종전대로 활성이다', () {
      expect(_sub(status: 'ACTIVE').isActive, isTrue);
      expect(
        _sub(
          status: 'ACTIVE',
          currentPeriodEnd: _serverUtc(const Duration(days: 30)),
        ).isActive,
        isTrue,
      );
    });

    test('CANCELLED + 남은 기간 = 활성 — 돈 낸 기간은 끝까지 Pro 다', () {
      expect(
        _sub(
          status: 'CANCELLED',
          currentPeriodEnd: _serverUtc(const Duration(days: 30)),
          autoRenew: false,
        ).isActive,
        isTrue,
      );
    });

    test('CANCELLED + 지난 기간 = 비활성', () {
      expect(
        _sub(
          status: 'CANCELLED',
          currentPeriodEnd: _serverUtc(const Duration(days: -1)),
          autoRenew: false,
        ).isActive,
        isFalse,
      );
    });

    test('날짜를 못 읽으면 종전 동작 — 보수적으로 비활성', () {
      // 만료일 없는(무제한) 해지까지 유예로 봐 주면 되돌아올 날이 없어 영영 안 막힌다.
      expect(_sub(status: 'CANCELLED').isActive, isFalse);
      expect(_sub(status: 'CANCELLED', currentPeriodEnd: '').isActive, isFalse);
      expect(
        _sub(status: 'CANCELLED', currentPeriodEnd: '언젠가').isActive,
        isFalse,
      );
      // 날짜만 있는 값(LocalDate)은 시간대가 없어 [parseServerUtc] 가 거부한다.
      expect(
        _sub(status: 'CANCELLED', currentPeriodEnd: '2099-01-01').isActive,
        isFalse,
      );
    });

    test('EXPIRED 등 다른 상태는 기간이 남아도 비활성이다', () {
      expect(
        _sub(
          status: 'EXPIRED',
          currentPeriodEnd: _serverUtc(const Duration(days: 30)),
        ).isActive,
        isFalse,
      );
    });
  });

  testWidgets('유예 기간 — Pro 로 보이고 "구독하기" 가 없다', (tester) async {
    final end = _serverUtc(const Duration(days: 30));
    await _openSheet(
      tester,
      _sub(status: 'CANCELLED', currentPeriodEnd: end, autoRenew: false),
    );

    expect(find.text(l.subUsingPro), findsOneWidget);
    expect(find.text(l.subUsingFree), findsNothing);

    // 이미 구독 중이고 서버가 재구독을 막는다 — 누를 수 없는 버튼을 내밀지 않는다.
    expect(find.text(l.subStartPro), findsNothing);
    expect(find.text(l.subCancel), findsOneWidget);
  });

  testWidgets('자동갱신이 꺼지면 날짜 라벨이 "다음 결제" 가 아니다', (tester) async {
    final end = _serverUtc(const Duration(days: 30));
    final date = localDateKey(end)!;
    await _openSheet(
      tester,
      _sub(status: 'CANCELLED', currentPeriodEnd: end, autoRenew: false),
    );

    expect(find.text(l.subProUntil(date)), findsOneWidget);
    expect(
      find.text(l.subNextBilling(date, krwSigned(9900, false, unit: true))),
      findsNothing,
      reason: '해지한 구독에 다음 결제는 없다 — 없는 청구를 예고하면 안 된다',
    );
  });

  testWidgets('기간이 지난 해지는 Free 로 보인다', (tester) async {
    await _openSheet(
      tester,
      _sub(
        status: 'CANCELLED',
        currentPeriodEnd: _serverUtc(const Duration(days: -1)),
        autoRenew: false,
      ),
    );

    expect(find.text(l.subUsingFree), findsOneWidget);
    expect(find.text(l.subUsingPro), findsNothing);
    expect(find.text(l.subStartPro), findsOneWidget);
  });

  testWidgets('자동갱신 중인 구독은 종전 문구 그대로다', (tester) async {
    final end = _serverUtc(const Duration(days: 30));
    final date = localDateKey(end)!;
    await _openSheet(tester, _sub(status: 'ACTIVE', currentPeriodEnd: end));

    expect(find.text(l.subUsingPro), findsOneWidget);
    expect(
      find.text(l.subNextBilling(date, krwSigned(9900, false, unit: true))),
      findsOneWidget,
    );
    expect(find.text(l.subProUntil(date)), findsNothing);
  });

  testWidgets('만료일이 없는 해지는 Free — 터지지 않는다', (tester) async {
    await _openSheet(tester, _sub(status: 'CANCELLED', autoRenew: false));

    expect(find.text(l.subUsingFree), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('날짜를 못 읽으면 문구도 종전 그대로다', (tester) async {
    await _openSheet(
      tester,
      _sub(status: 'ACTIVE', currentPeriodEnd: '언젠가', autoRenew: false),
    );

    // 자리 표시자만 있는 날짜에 "…까지 이용" 을 끼우면 더 이상해진다 — 종전 문구.
    expect(find.text(l.subUsingPro), findsOneWidget);
    expect(
      find.text(
        l.subNextBilling(
          l.subNextBillingDate,
          krwSigned(9900, false, unit: true),
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
