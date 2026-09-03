// 저장 부호는 종류가 정한다(QA #19) — 사용자는 늘 절대값을 넣는다.
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/features/asset/domain/asset_sign.dart';

void main() {
  test('부채군은 음수 — 대출·신용카드', () {
    expect(signedBalance('LOAN', 3000000), -3000000);
    expect(signedBalance('CREDIT_CARD', 500000), -500000);
  });

  test('자산군은 양수 — 음수를 쳐도 뒤집는다', () {
    expect(signedBalance('BANK_ACCOUNT', 50000), 50000);
    expect(signedBalance('SAVINGS', -100), 100);
    expect(signedBalance('CASH', -1), 1);
    // 체크카드 사용액은 연결 계좌가 이미 뺐다 — 부채군이 아니다.
    expect(signedBalance('CHECK_CARD', 10000), 10000);
    expect(signedBalance('INVESTMENT', 7000), 7000);
  });

  test('마이너스통장은 BANK_ACCOUNT 인데 음수 — 유형만으로는 못 가른다', () {
    expect(signedBalance('BANK_ACCOUNT', 50000, isOverdraft: true), -50000);
    expect(signedBalance('BANK_ACCOUNT', -50000, isOverdraft: true), -50000);
  });

  test('멱등 — 이미 정규화된 값을 다시 넣어도 같다', () {
    expect(signedBalance('LOAN', signedBalance('LOAN', 3000000)), -3000000);
    expect(
      signedBalance('BANK_ACCOUNT', signedBalance('BANK_ACCOUNT', 500)),
      500,
    );
  });

  test('isDebtAssetType — 체크카드는 부채가 아니다', () {
    expect(isDebtAssetType('LOAN'), isTrue);
    expect(isDebtAssetType('CREDIT_CARD'), isTrue);
    expect(isDebtAssetType('CHECK_CARD'), isFalse);
    expect(isDebtAssetType('BANK_ACCOUNT'), isFalse);
  });
}
