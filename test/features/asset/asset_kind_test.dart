// 폼 종류 아홉(I-17 6) — 저장 종류 매핑 · 자산에서 종류 재기 · 같은 묶음 · 1단계 묶음 차례. 웹 `asset-kind.test` 와 같은 값이다.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_kind.dart';

Asset _a(String type, [int? balance]) =>
    Asset(rowId: 1, assetName: 'x', assetType: type, balance: balance);

void main() {
  test('저장 종류 — 예금 · 적금은 둘 다 SAVINGS, 마이너스 통장은 입출금(음수 잔액)', () {
    expect(
      {for (final k in AssetKind.values) k: k.assetType},
      {
        AssetKind.checking: 'BANK_ACCOUNT',
        AssetKind.deposit: 'SAVINGS',
        AssetKind.installment: 'SAVINGS',
        AssetKind.overdraft: 'BANK_ACCOUNT',
        AssetKind.cash: 'CASH',
        AssetKind.loan: 'LOAN',
        AssetKind.credit: 'CREDIT_CARD',
        AssetKind.check: 'CHECK_CARD',
        AssetKind.investment: 'INVESTMENT',
      },
    );
  });

  test('자산에서 종류를 잰다 — 음수 잔액 입출금은 마이너스 통장, 예금 · 적금은 늘 적금', () {
    expect(AssetKindX.of(_a('BANK_ACCOUNT', 100)), AssetKind.checking);
    expect(AssetKindX.of(_a('BANK_ACCOUNT', -100)), AssetKind.overdraft);
    expect(AssetKindX.of(_a('SAVINGS', 100)), AssetKind.installment);
    expect(AssetKindX.of(_a('CASH')), AssetKind.cash);
    expect(AssetKindX.of(_a('LOAN', -1)), AssetKind.loan);
    expect(AssetKindX.of(_a('CREDIT_CARD')), AssetKind.credit);
    expect(AssetKindX.of(_a('CHECK_CARD')), AssetKind.check);
    expect(AssetKindX.of(_a('INVESTMENT')), AssetKind.investment);
  });

  test('빚인 종류는 마이너스 통장 · 대출뿐이다', () {
    expect(
      [
        for (final k in AssetKind.values)
          if (k.isDebt) k,
      ],
      [AssetKind.overdraft, AssetKind.loan],
    );
  });

  test('같은 묶음 — 계좌 여섯 · 카드 둘 · 투자 하나', () {
    expect(AssetKind.checking.siblings.length, 6);
    expect(AssetKind.credit.siblings, [AssetKind.credit, AssetKind.check]);
    expect(AssetKind.investment.siblings, [AssetKind.investment]);
  });

  test('1단계 묶음 차례 — 계좌 · 카드 · 투자, 아홉이 한 번씩', () {
    expect(
      [for (final g in assetKindGroups) g.$1],
      [AssetKindGroup.account, AssetKindGroup.card, AssetKindGroup.investment],
    );
    final all = [for (final g in assetKindGroups) ...g.$2];
    expect(all.toSet(), AssetKind.values.toSet());
    expect(all.length, 9);
    expect(all.first, AssetKind.checking);
  });

  test('카드 종류 코드 — 카탈로그 검색이 쓴다', () {
    expect(AssetKind.credit.cardApiCode, 'CREDIT');
    expect(AssetKind.check.cardApiCode, 'CHECK');
    expect(AssetKind.checking.cardApiCode, isNull);
  });
}
