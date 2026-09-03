/// 저장 부호를 정하는 한 자리.
///
/// 사용자는 잔액·사용액을 **늘 절대값으로** 입력하고 부호는 종류가 정한다
/// (QA #19, 사용자 결정). 자산군은 `+`, 부채군은 `−` 다.
///
/// 화면마다 따로 뒤집으면 한 곳을 빠뜨렸을 때 홈 '총 부채' 가 조용히 뒤집힌다 —
/// 계좌 폼은 부호를 아예 안 씌우고(음수가 그대로 저장됐다) 카드 폼만 씌우고 있었다.
/// 서버도 같은 정규화를 하지만 앱에서 맞춰 보내야 편집 화면이 되읽는 값도 맞는다.
library;

/// 부채군 — 잔액이 '빚' 인 유형. 마이너스통장은 `BANK_ACCOUNT` 라 여기 없다.
const _debtTypes = {'CREDIT_CARD', 'LOAN'};

/// [assetType] 이 부채군인가. 체크카드는 사용액을 연결 계좌가 이미 뺐으므로 아니다.
bool isDebtAssetType(String assetType) => _debtTypes.contains(assetType);

/// 사용자가 친 절대값 [amount] 에 종류가 정한 부호를 씌운다.
///
/// [isOverdraft] 는 마이너스통장 — `BANK_ACCOUNT` 인데 잔액이 빚이다.
/// 별도 `AssetType` 을 만들지 않기로 했으므로(QA #17) 부호가 유일한 표시다.
///
/// 여러 번 적용해도 결과가 같다(멱등) — 이미 음수인 값을 넣어도 안전하다.
int signedBalance(String assetType, int amount, {bool isOverdraft = false}) {
  final abs = amount.abs();
  return (isOverdraft || isDebtAssetType(assetType)) ? -abs : abs;
}
