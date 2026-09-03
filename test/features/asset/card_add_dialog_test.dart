// 카드 폼의 입력 정책 — 사용액은 절대값 입력·음수 저장(QA #19), 별칭 상한(QA #16).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/data/asset_repository.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/card_add_dialog.dart';
import 'package:porest_desk_app/features/card/application/card_providers.dart';
import 'package:porest_desk_app/features/card/domain/card_catalog_page.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

const _credit = Asset(
  rowId: 7,
  assetName: '신한 Deep Dream',
  assetType: 'CREDIT_CARD',
  balance: -500000,
  institution: '신한카드',
  isIncludedInTotal: 'Y',
  creditLimit: 5000000,
  paymentDay: 14,
);

const _other = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 100,
);

const _emptyPage = CardCatalogPage(
  content: [],
  totalElements: 0,
  totalPages: 0,
  number: 0,
  size: 40,
  first: true,
  last: true,
  empty: true,
);

class _CapturingRepo extends AssetRepository {
  _CapturingRepo() : super(Dio());

  int? balance;

  @override
  Future<Asset> update({
    required int id,
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    double? exchangeRate,
    String? color,
    String? institution,
    String? memo,
    String? isIncludedInTotal,
    int? cardCatalogRowId,
    int? creditLimit,
    int? paymentDay,
    int? paymentAssetRowId,
    bool? isOverdraft,
    List<AssetHolding>? holdings,
  }) async {
    this.balance = balance;
    return _credit;
  }
}

Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<_CapturingRepo> _openEdit(
  WidgetTester tester,
  Asset asset, {
  List<Asset> assets = const [_credit, _other],
}) async {
  final repo = _CapturingRepo();
  // 시트 본문은 ListView 다 — 좁은 화면에서는 사용액 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => assets),
        assetRepositoryProvider.overrideWith((ref) async => repo),
        cardCatalogPageProvider.overrideWith((ref, key) async => _emptyPage),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showCardEditDialog(ctx, asset),
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

  testWidgets('신용카드 편집은 사용액을 양수로 보여 준다', (tester) async {
    await _openEdit(tester, _credit);
    // '현재 사용액' 이라는 라벨 아래 −500000 이 보이면 안 된다.
    expect(find.text('500000'), findsOneWidget);
    expect(find.text('-500000'), findsNothing);
  });

  testWidgets('저장하면 다시 음수로 정규화된다', (tester) async {
    final repo = await _openEdit(tester, _credit);
    await tester.enterText(_field('0'), '320000');
    await tester.pumpAndSettle();
    await tester.tap(_submitButton(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.balance, -320000);
  });

  testWidgets('사용액 칸에 `-` 는 타이핑되지 않는다', (tester) async {
    await _openEdit(tester, _credit);
    await tester.enterText(_field('0'), '-320000');
    await tester.pumpAndSettle();
    expect(find.text('-320000'), findsNothing);
    expect(find.text('320000'), findsOneWidget);
  });

  testWidgets('별칭 30자 초과·중복은 안내가 뜨고 저장이 막힌다', (tester) async {
    await _openEdit(tester, _credit);
    final nickname = _field(l.assetCardNicknamePlaceholder);
    await tester.enterText(nickname, 'ㄱ' * 31);
    await tester.pumpAndSettle();
    expect(find.text(l.nameTooLong(30)), findsOneWidget);
    expect(
      tester.widget<PButton>(_submitButton(l.actionSave)).onPressed,
      isNull,
    );

    await tester.enterText(nickname, 'QA 주거래');
    await tester.pumpAndSettle();
    expect(find.text(l.assetNicknameDuplicate), findsOneWidget);
    expect(
      tester.widget<PButton>(_submitButton(l.actionSave)).onPressed,
      isNull,
    );

    // 자기 이름은 중복이 아니다.
    await tester.enterText(nickname, '신한 Deep Dream');
    await tester.pumpAndSettle();
    expect(find.text(l.assetNicknameDuplicate), findsNothing);
    expect(
      tester.widget<PButton>(_submitButton(l.actionSave)).onPressed,
      isNotNull,
    );
  });
}
