// 금액 숨김을 **푸는** 저장은 본인 확인을 거친다 (QA 22차 #2).
//
// 앱은 자산 상세에 이 토글이 없어(사용자 결정) 수정 폼이 **유일한 해제 경로**다.
// 확인이 없으면 "풀 때는 본인 확인" 규칙 자체가 없는 것과 같다 — 스위치를 끄고
// 저장만 누르면 그냥 풀렸다.
//
// 확인창 **속**(비밀번호 검증)은 여기서 안 본다. 여기서 잠그는 건 하나다 —
// 확인이 끝나기 전에는 저장 요청이 **나가지 않는다.**
//
// 폼이 이 값을 싣는지도 함께 잠근다. 서버 PUT 은 "키가 없으면 유지" 라 폼이 칸을
// 빼먹어도 겉으론 아무 일도 안 나지만, **껐는데 안 꺼지는** 쪽은 조용히 실패한다.
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
import 'package:porest_desk_app/features/asset/presentation/include_in_total_card.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';

const _hidden = Asset(
  rowId: 8,
  assetName: 'QA 비상금',
  assetType: 'BANK_ACCOUNT',
  balance: 470000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
  isAmountHidden: 'Y',
);

const _shown = Asset(
  rowId: 9,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
  isAmountHidden: 'N',
);

class _CapturingRepo extends AssetRepository {
  _CapturingRepo() : super(Dio());

  String? updatedHidden;
  bool updateCalled = false;

  Asset _fake() => const Asset(rowId: 1, assetName: 'x', assetType: 'CASH');

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
    String? isAmountHidden,
    int? cardCatalogRowId,
    Patch<int> creditLimit = const Patch.keep(),
    Patch<int> paymentDay = const Patch.keep(),
    Patch<int> paymentAssetRowId = const Patch.keep(),
    bool? isOverdraft,
    List<AssetHolding>? holdings,
    int? carryoverAmount,
  }) async {
    updateCalled = true;
    updatedHidden = isAmountHidden;
    return _fake();
  }
}

Future<_CapturingRepo> _open(WidgetTester tester, Asset edit) async {
  final repo = _CapturingRepo();
  // 폼 본문은 ListView 다 — 기본 800x600 에서는 토글 카드가 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => [edit]),
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
              onPressed: () => showAccountEditDialog(ctx, edit),
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

Finder _hideSwitch() => find.descendant(
  of: find.byType(HideAmountCard),
  matching: find.byType(PSwitch),
);

Future<void> _toggleHide(WidgetTester tester) async {
  await tester.tap(_hideSwitch());
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester, String label) async {
  await tester.tap(
    find.ancestor(of: find.text(label), matching: find.byType(PButton)).last,
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('끄고 저장하면 확인창이 뜨고 저장 요청은 안 나간다', (tester) async {
    final repo = await _open(tester, _hidden);
    await _toggleHide(tester);
    await _tapSave(tester, l.actionSave);

    expect(find.text(l.unlockTitle), findsOneWidget);
    expect(repo.updateCalled, isFalse);
  });

  testWidgets('확인을 취소하면 저장도 안 된다 — 서버 값은 숨김 그대로', (tester) async {
    final repo = await _open(tester, _hidden);
    await _toggleHide(tester);
    await _tapSave(tester, l.actionSave);

    await tester.tap(
      find
          .ancestor(
            of: find.text(l.actionCancel),
            matching: find.byType(PButton),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(find.text(l.unlockTitle), findsNothing);
    expect(repo.updateCalled, isFalse);
  });

  testWidgets('켜는 쪽은 확인 없이 Y 로 저장된다', (tester) async {
    final repo = await _open(tester, _shown);
    await _toggleHide(tester);
    await _tapSave(tester, l.actionSave);

    expect(find.text(l.unlockTitle), findsNothing);
    expect(repo.updatedHidden, 'Y');
  });

  testWidgets('숨김을 안 건드린 저장은 묻지 않고 Y 를 그대로 싣는다', (tester) async {
    final repo = await _open(tester, _hidden);
    await _tapSave(tester, l.actionSave);

    expect(find.text(l.unlockTitle), findsNothing);
    expect(repo.updatedHidden, 'Y');
  });
}
