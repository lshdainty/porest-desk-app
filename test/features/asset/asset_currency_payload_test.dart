// 통화는 **고르는 칸이 있는 화면만** 보낸다 (감사 2026-09-08 A1-①).
//
// 카드·투자 다이얼로그엔 통화를 고르는 칸이 없는데 'KRW' 를 실어 보냈다. 웹에서 USD 로
// 만든 해외 카드·증권계좌를 앱에서 한 번 편집하면 원화가 되고, 서버가 환산율까지 1 로
// 정규화해(`Asset.normalizeRate`) 총자산이 환산 없이 합쳐진다. 되돌릴 입력칸이 앱에는
// 없다 — 화면에 고르는 칸이 없으면 보낼 자격도 없다.
//
// 생성도 안 보낸다. 서버가 안 오면 KRW 로 채우므로(`AssetServiceImpl.createAsset`)
// 결과는 같고, 기본값을 정하는 자리가 하나로 남는다.
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) "무엇을 보내는가" 를 위젯 테스트로 잠근다.
// 통화 칸이 **있는** 계좌 화면은 계속 실어야 한다 — 그것도 같이 잠근다. 이게 없으면
// "통화는 안 보내는 것" 이라는 잘못된 교훈이 옆 화면으로 번진다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/network/patch.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/data/asset_repository.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/account_add_dialog.dart';
import 'package:porest_desk_app/features/asset/presentation/card_add_dialog.dart';
import 'package:porest_desk_app/features/asset/presentation/investment_add_dialog.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog_page.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/subscription/data/subscription_repository.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

/// 웹에서 USD 로 만든 해외 카드 — 앱엔 통화 칸이 없다.
const _usdCard = Asset(
  rowId: 7,
  assetName: 'Chase Sapphire',
  assetType: 'CREDIT_CARD',
  balance: -1200,
  currency: 'USD',
  exchangeRate: 1380,
  institution: '신한카드',
  isIncludedInTotal: 'Y',
  creditLimit: 5000000,
  paymentDay: 14,
);

/// 웹에서 USD 로 만든 해외 증권계좌.
const _usdInvest = Asset(
  rowId: 12,
  assetName: 'IBKR',
  assetType: 'INVESTMENT',
  balance: 5000,
  currency: 'USD',
  exchangeRate: 1380,
  institution: '키움증권',
  isIncludedInTotal: 'Y',
);

const _krwAccount = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

/// 카드 신규는 카탈로그에서 상품을 골라야 저장이 열린다 — 한 장만 둔다.
const _catalog = CardCatalogPage(
  content: [
    CardCatalogSummary(
      rowId: 101,
      cardName: 'QA 체크카드',
      cardType: 'CHECK',
      company: CardCompany(rowId: 1, name: '국민카드'),
    ),
  ],
  totalElements: 1,
  totalPages: 1,
  number: 0,
  size: 40,
  first: true,
  last: true,
  empty: false,
);

/// 화면이 넘긴 인자를 그대로 잡아 둔다 — 값뿐 아니라 "넘겼는가" 까지 본다.
class _CapturingRepo extends AssetRepository {
  _CapturingRepo() : super(Dio());

  Map<String, Object?>? created;
  Map<String, Object?>? updated;

  Asset _fake() => const Asset(rowId: 1, assetName: 'x', assetType: 'CASH');

  @override
  Future<Asset> create({
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    double? exchangeRate,
    String? color,
    String? institution,
    String? memo,
    String? isIncludedInTotal,
    int? sortOrder,
    int? cardCatalogRowId,
    int? creditLimit,
    int? paymentDay,
    int? paymentAssetRowId,
    bool? isOverdraft,
    List<AssetHolding>? holdings,
  }) async {
    created = {'currency': currency, 'exchangeRate': exchangeRate};
    return _fake();
  }

  @override
  Future<Asset> update({
    required int id,
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    Patch<double> exchangeRate = const Patch.keep(),
    String? color,
    String? institution,
    Patch<String> memo = const Patch.keep(),
    String? isIncludedInTotal,
    int? cardCatalogRowId,
    Patch<int> creditLimit = const Patch.keep(),
    Patch<int> paymentDay = const Patch.keep(),
    Patch<int> paymentAssetRowId = const Patch.keep(),
    bool? isOverdraft,
    List<AssetHolding>? holdings,
  }) async {
    updated = {
      'currency': currency,
      'exchangeRatePresent': exchangeRate.present,
    };
    return _fake();
  }
}

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<_CapturingRepo> _host(
  WidgetTester tester,
  void Function(BuildContext ctx) open, {
  List<Asset> assets = const [_krwAccount],
}) async {
  final repo = _CapturingRepo();
  // 시트 본문은 ListView 다 — 좁은 화면에서는 아래쪽 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => assets),
        assetRepositoryProvider.overrideWith((ref) async => repo),
        cardCatalogPageProvider.overrideWith((ref, key) async => _catalog),
        myFeaturesProvider.overrideWith((ref) async => MyFeatures.empty),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => open(ctx),
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

  testWidgets('카드 편집은 통화를 안 넘긴다', (tester) async {
    final repo = await _host(
      tester,
      (ctx) => showCardEditDialog(ctx, _usdCard),
      assets: const [_usdCard, _krwAccount],
    );
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.updated, isNotNull, reason: '저장이 안 불렸다 — 테스트가 아무것도 안 본다');
    expect(
      repo.updated!['currency'],
      isNull,
      reason: 'KRW 를 실으면 USD 카드가 원화가 되고 환산율이 1 이 된다',
    );
    expect(
      repo.updated!['exchangeRatePresent'],
      isFalse,
      reason: '환산율 칸도 이 화면엔 없다 — 키를 실으면 웹에서 넣은 환율이 지워진다',
    );
  });

  testWidgets('카드 신규도 통화를 안 넘긴다 — 서버가 KRW 로 채운다', (tester) async {
    final repo = await _host(tester, showCardAddDialog);
    // 체크카드로 바꾸면 결제일 없이도 저장이 열린다(신용은 결제일이 필수).
    await tester.tap(find.text(l.assetTypeCheckCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('QA 체크카드').last);
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.calAdd));
    await tester.pumpAndSettle();

    expect(repo.created, isNotNull, reason: '생성이 안 불렸다');
    expect(repo.created!['currency'], isNull);
  });

  testWidgets('투자 편집은 통화를 안 넘긴다', (tester) async {
    final repo = await _host(
      tester,
      (ctx) => showInvestmentEditDialog(ctx, _usdInvest),
      assets: const [_usdInvest, _krwAccount],
    );
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.updated, isNotNull, reason: '저장이 안 불렸다');
    expect(
      repo.updated!['currency'],
      isNull,
      reason: 'KRW 를 실으면 USD 증권계좌가 원화가 되고 환산율이 1 이 된다',
    );
  });

  testWidgets('투자 신규도 통화를 안 넘긴다', (tester) async {
    final repo = await _host(tester, showInvestmentAddDialog);
    await tester.tap(_submitButton(l.calAdd));
    await tester.pumpAndSettle();

    expect(repo.created, isNotNull, reason: '생성이 안 불렸다');
    expect(repo.created!['currency'], isNull);
  });

  // 반대편 — 통화 칸이 **있는** 계좌 화면은 계속 실어야 한다.
  testWidgets('계좌 편집은 통화를 그대로 넘긴다', (tester) async {
    final repo = await _host(
      tester,
      (ctx) => showAccountEditDialog(ctx, _krwAccount),
    );
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();

    expect(repo.updated, isNotNull, reason: '저장이 안 불렸다');
    expect(repo.updated!['currency'], 'KRW');
  });
}
