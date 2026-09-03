// 마이너스통장 표시 — BANK_ACCOUNT + 음수 잔액(QA #17).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_type_meta.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

Asset _asset(String type, int balance) =>
    Asset(rowId: 1, assetName: 'x', assetType: type, balance: balance);

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  test('음수 잔액 입출금은 마이너스통장으로 보인다', () {
    expect(assetTypeLabelOf(l, _asset('BANK_ACCOUNT', -50000)), '마이너스통장');
    expect(isOverdraftAsset(_asset('BANK_ACCOUNT', -1)), isTrue);
  });

  test('0·양수 입출금은 그대로 입출금', () {
    expect(
      assetTypeLabelOf(l, _asset('BANK_ACCOUNT', 0)),
      l.assetTypeBankAccount,
    );
    expect(
      assetTypeLabelOf(l, _asset('BANK_ACCOUNT', 100)),
      l.assetTypeBankAccount,
    );
    expect(isOverdraftAsset(_asset('BANK_ACCOUNT', 0)), isFalse);
  });

  test('다른 유형은 음수여도 유형 라벨 그대로 — 대출은 대출이다', () {
    expect(assetTypeLabelOf(l, _asset('LOAN', -3000000)), l.assetTypeLoan);
    expect(
      assetTypeLabelOf(l, _asset('CREDIT_CARD', -500000)),
      l.assetTypeCreditCard,
    );
    expect(isOverdraftAsset(_asset('LOAN', -1)), isFalse);
  });
}
