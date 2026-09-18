// 청구 예정액이 **한도 사용(=잔액)과 다른 이유**를 그 자리에서 밝힌다 (2026-09-18 제보).
//
// 사용자가 같은 카드에서 두 숫자가 다르다고 알렸다 — 자산 목록·한도 사용은 466,800,
// 카드 상세 청구 예정은 527,100. 둘은 서로 다른 양이다.
//
//   · 잔액은 `effective_at <= 지금` 인 이력만 센다 → **아직 안 온 거래를 안 센다**
//   · 청구 예정은 회차 기간 전체를 센다 → 반복 거래가 미리 만들어 둔 것까지 센다
//
// 서버가 그 차이(`upcomingScheduledAmount`)를 내려주므로, 화면이 숫자 밑에서 말해 준다.
// 아무 말도 없으면 사용자는 어느 쪽이 맞는지 알 수 없다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/card_billing.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

const _card = Asset(
  rowId: 42,
  assetName: '네이버 현대카드',
  assetType: 'CREDIT_CARD',
  balance: -466800,
  institution: '현대카드',
  creditLimit: 21000000,
  paymentDay: 12,
  isIncludedInTotal: 'Y',
);

CardBilling _billing({int? scheduled}) => CardBilling(
  cardAssetRowId: 42,
  upcomingAmount: 527100,
  upcomingLumpSumAmount: 527100,
  upcomingScheduledAmount: scheduled,
  upcomingPeriodStart: '2026-09-01',
  upcomingPeriodEnd: '2026-09-30',
  nextPaymentDate: '2026-10-12',
  paymentDay: 12,
);

Future<void> _open(WidgetTester tester, CardBilling billing) async {
  // 테스트 폰트는 글자마다 정사각형이라 한글이 실제보다 훨씬 넓게 잰다 — 폰 폭
  // (390)으로 두면 카드 상세의 가로 행들이 넘쳐 레이아웃 예외가 뜬다. 넉넉히 준다.
  tester.view.physicalSize = const Size(760 * 3, 2400 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => [_card]),
        cardBillingProvider.overrideWith((ref, id) async => billing),
        assetTransfersProvider.overrideWith((ref, key) async => const []),
        categoriesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showAssetDetailRich(ctx, _card),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // `pumpAndSettle` 은 여기서 안 끝난다 — 안 채운 provider 들의 스켈레톤이 계속
  // 반짝인다. 시트가 열리고 청구가 그려질 만큼만 프레임을 돌린다.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('예정분이 있으면 얼마가 아직 안 온 것인지 밝힌다', (tester) async {
    await _open(tester, _billing(scheduled: 60300));

    expect(
      find.text(l.assetBillingScheduledPortion('60,300원')),
      findsOneWidget,
      reason: '예정액과 한도 사용이 갈리는 이유를 화면이 말하지 않는다',
    );
  });

  testWidgets('예정분이 0 이면 아무 말도 안 한다 — 잔액과 어긋날 이유가 없다', (tester) async {
    await _open(tester, _billing(scheduled: 0));

    expect(find.textContaining('아직 안 온'), findsNothing);
    expect(find.text(l.assetMonthlyPaymentDay(12)), findsOneWidget);
  });

  // 옛 서버는 이 칸을 안 내려준다 — 그때도 화면이 깨지지 않아야 한다.
  testWidgets('칸이 없어도 아무 말 없이 지나간다', (tester) async {
    await _open(tester, _billing());

    expect(find.textContaining('아직 안 온'), findsNothing);
    // 시트가 실제로 그려졌는지 — 안 그려졌으면 위 findsNothing 이 빈 통과가 된다.
    expect(find.text(l.assetMonthlyPaymentDay(12)), findsOneWidget);
  });

  test('문구가 ko·en 양쪽에 있다', () {
    expect(l.assetBillingScheduledPortion('1원'), contains('1원'));
  });
}
