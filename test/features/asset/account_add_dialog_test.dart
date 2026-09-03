// 계좌 폼의 입력 정책 — 마이너스통장(QA #17) · 부호(QA #19) · 별칭(QA #16).
//
// 에뮬레이터를 쓸 수 없는 환경이라(QA #23) 탭·라벨·저장 페이로드를 전부
// 위젯 테스트로 고정한다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/data/asset_repository.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/presentation/account_add_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

const _existing = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

const _overdraft = Asset(
  rowId: 9,
  assetName: '마통',
  assetType: 'BANK_ACCOUNT',
  balance: -50000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

const _loan = Asset(
  rowId: 10,
  assetName: '주택담보',
  assetType: 'LOAN',
  balance: -3000000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);

/// create/update 로 넘어간 인자를 잡는 가짜 레포지토리.
/// (네트워크를 태우지 않으려고 Dio 는 쓰이지 않는 자리만 채운다)
class _CapturingRepo extends AssetRepository {
  _CapturingRepo() : super(Dio());

  Map<String, Object?>? captured;

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
    captured = {
      'assetName': assetName,
      'assetType': assetType,
      'balance': balance,
      'creditLimit': creditLimit,
      'isOverdraft': isOverdraft,
    };
    return _fake();
  }

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
    captured = {
      'assetName': assetName,
      'assetType': assetType,
      'balance': balance,
      'creditLimit': creditLimit,
      'isOverdraft': isOverdraft,
    };
    return _fake();
  }
}

Future<_CapturingRepo> _open(
  WidgetTester tester, {
  Asset? edit,
  List<Asset> assets = const [_existing],
}) async {
  final repo = _CapturingRepo();
  // 시트 본문은 ListView 다 — 기본 800x600 에서는 계좌 종류 아래가 아예 안
  // 만들어져 findsNothing 이 거짓으로 통과한다. 폼 전체를 한 화면에 올린다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => assets),
        assetRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => edit == null
                  ? showAccountAddDialog(ctx)
                  : showAccountEditDialog(ctx, edit),
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

/// placeholder 로 입력칸을 찾는다 — 값이 들어가도 안 바뀌는 유일한 표식이다.
Finder _field(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _submitButton(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last;

Future<void> _tapSubmit(WidgetTester tester, String label) async {
  await tester.tap(_submitButton(label));
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('계좌 종류에 마이너스통장이 있다', (tester) async {
    await _open(tester);
    expect(find.text(l.assetSubtypeOverdraft), findsOneWidget);
    // 자산군 다음, 대출 앞.
    expect(find.text(l.assetTypeLoan), findsOneWidget);
  });

  testWidgets('마이너스통장은 사용 중인 금액을 양수로 받아 음수로 저장한다', (tester) async {
    final repo = await _open(tester);
    await tester.tap(find.text(l.assetSubtypeOverdraft));
    await tester.pumpAndSettle();
    // 라벨이 '잔액' 이 아니라 '사용 중인 금액' 으로 바뀐다.
    expect(find.text(l.assetOverdraftUsedLabel), findsOneWidget);
    expect(find.text(l.assetBalanceLabel), findsNothing);

    await tester.enterText(_field('0'), '50000');
    await tester.pumpAndSettle();
    await _tapSubmit(tester, l.calAdd);

    expect(repo.captured?['assetType'], 'BANK_ACCOUNT');
    expect(repo.captured?['balance'], -50000);
    expect(repo.captured?['isOverdraft'], isTrue);
  });

  testWidgets('입출금은 같은 값을 양수로 저장한다', (tester) async {
    final repo = await _open(tester);
    await tester.enterText(_field('0'), '50000');
    await tester.pumpAndSettle();
    await _tapSubmit(tester, l.calAdd);

    expect(repo.captured?['balance'], 50000);
    expect(repo.captured?['isOverdraft'], isFalse);
  });

  testWidgets('대출은 남은 빚을 양수로 받아 음수로 저장한다', (tester) async {
    final repo = await _open(tester);
    await tester.tap(find.text(l.assetTypeLoan));
    await tester.pumpAndSettle();
    expect(find.text(l.assetLoanRemainingLabel), findsOneWidget);
    await tester.enterText(_field('0'), '3000000');
    await tester.pumpAndSettle();
    await _tapSubmit(tester, l.calAdd);

    expect(repo.captured?['assetType'], 'LOAN');
    expect(repo.captured?['balance'], -3000000);
  });

  testWidgets('잔액칸에 `-` 는 타이핑되지 않는다', (tester) async {
    await _open(tester);
    await tester.enterText(_field('0'), '-50000');
    await tester.pumpAndSettle();
    expect(find.text('-50000'), findsNothing);
    expect(find.text('50000'), findsOneWidget);
  });

  testWidgets('1,000억을 넘는 잔액은 입력이 막힌다', (tester) async {
    await _open(tester);
    // QA 가 저장했던 99조.
    await tester.enterText(_field('0'), '99999999999999');
    await tester.pumpAndSettle();
    expect(find.text('99999999999999'), findsNothing);
  });

  testWidgets('음수 잔액 입출금을 열면 마이너스통장 탭이고 금액이 양수로 보인다', (tester) async {
    await _open(tester, edit: _overdraft, assets: const [_overdraft]);
    expect(find.text(l.assetOverdraftUsedLabel), findsOneWidget);
    expect(find.text('50000'), findsOneWidget);
    expect(find.text('-50000'), findsNothing);
  });

  testWidgets('대출 편집도 남은 빚을 양수로 보여 준다', (tester) async {
    await _open(tester, edit: _loan, assets: const [_loan]);
    expect(find.text(l.assetLoanRemainingLabel), findsOneWidget);
    expect(find.text('3000000'), findsOneWidget);
  });

  testWidgets('별칭 30자 초과는 카운터가 빨개지고 저장이 막힌다', (tester) async {
    await _open(tester);
    await tester.enterText(_field(l.assetNicknamePlaceholder), 'ㄱ' * 31);
    await tester.pumpAndSettle();
    expect(find.text(l.nameTooLong(30)), findsOneWidget);
    expect(find.text('31/30'), findsNothing);
    expect(tester.widget<PButton>(_submitButton(l.calAdd)).onPressed, isNull);
  });

  testWidgets('이미 있는 별칭은 안내가 뜨고 저장이 막힌다', (tester) async {
    await _open(tester);
    await tester.enterText(_field(l.assetNicknamePlaceholder), 'QA 주거래');
    await tester.pumpAndSettle();
    expect(find.text(l.assetNicknameDuplicate), findsOneWidget);
    expect(tester.widget<PButton>(_submitButton(l.calAdd)).onPressed, isNull);
  });

  testWidgets('별칭을 비우면 중복 검사를 안 탄다 — 자동 이름 경로', (tester) async {
    final repo = await _open(tester);
    // 한 번 쳤다 지운다(touched 상태로 만든다).
    await tester.enterText(_field(l.assetNicknamePlaceholder), 'QA 주거래');
    await tester.pumpAndSettle();
    await tester.enterText(_field(l.assetNicknamePlaceholder), '');
    await tester.pumpAndSettle();
    expect(find.text(l.assetNicknameDuplicate), findsNothing);
    await _tapSubmit(tester, l.calAdd);
    // 비면 '브랜드 종류' 로 자동 생성된다.
    expect(repo.captured?['assetName'], isNot('QA 주거래'));
    expect((repo.captured?['assetName'] as String).isNotEmpty, isTrue);
  });

  testWidgets('편집에서 자기 별칭을 그대로 두면 중복이 아니다', (tester) async {
    final repo = await _open(tester, edit: _existing);
    await tester.enterText(_field(l.assetNicknamePlaceholder), 'QA 주거래');
    await tester.pumpAndSettle();
    expect(find.text(l.assetNicknameDuplicate), findsNothing);
    await _tapSubmit(tester, l.actionSave);
    expect(repo.captured?['assetName'], 'QA 주거래');
  });
}
