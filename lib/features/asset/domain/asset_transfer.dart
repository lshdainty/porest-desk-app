/// 백엔드 `AssetApiDto.TransferResponse` 매핑.
class AssetTransfer {
  const AssetTransfer({
    required this.rowId,
    this.userRowId,
    required this.fromAssetRowId,
    this.fromAssetName,
    required this.toAssetRowId,
    this.toAssetName,
    required this.amount,
    this.fee,
    this.interestAmount,
    this.autoSource,
    this.principalAmount,
    this.description,
    this.transferDate,
    this.createAt,
  });

  final int rowId;
  final int? userRowId;
  final int fromAssetRowId;
  final String? fromAssetName;
  final int toAssetRowId;
  final String? toAssetName;
  final int amount;
  final int? fee;

  /// 이자 (대출 상환 시). amount 중 이 금액은 부채를 줄이지 않고 지출로 잡힌다.
  final int? interestAmount;

  /// 시스템이 만든 이체의 출처 — `TRADE_SETTLEMENT`(매수 예수금 충당) /
  /// `CARD_PAYMENT`(카드 자동결제) / `CARD_REFUND`(카드 과납금을 결제계좌로 환급).
  /// null 이면 사용자가 직접 만든 이체다.
  ///
  /// 값이 있으면 금액이 원본(매수·청구)과 묶여 있어 고칠 수 없다.
  final String? autoSource;

  /// 원금 = amount − interestAmount. 입금 자산(대출)에 실제로 반영된 금액.
  final int? principalAmount;
  final String? description;
  final String? transferDate; // ISO-LOCAL-DATETIME (YYYY-MM-DDTHH:mm:ss)
  final String? createAt;

  factory AssetTransfer.fromJson(Map<String, dynamic> json) {
    return AssetTransfer(
      rowId: (json['rowId'] as num).toInt(),
      userRowId: (json['userRowId'] as num?)?.toInt(),
      fromAssetRowId: (json['fromAssetRowId'] as num).toInt(),
      fromAssetName: json['fromAssetName'] as String?,
      toAssetRowId: (json['toAssetRowId'] as num).toInt(),
      toAssetName: json['toAssetName'] as String?,
      amount: (json['amount'] as num).toInt(),
      fee: (json['fee'] as num?)?.toInt(),
      interestAmount: (json['interestAmount'] as num?)?.toInt(),
      autoSource: json['autoSource'] as String?,
      principalAmount: (json['principalAmount'] as num?)?.toInt(),
      description: json['description'] as String?,
      transferDate: json['transferDate'] as String?,
      createAt: json['createAt'] as String?,
    );
  }
}

/// 자산 잔액 추이 1개 시점 — `AssetApiDto.AssetBalanceTrendResponse.points` 의 한 항목.
class AssetBalancePoint {
  const AssetBalancePoint({required this.weekStart, required this.balance});
  final String weekStart; // YYYY-MM-DD
  final int balance;

  factory AssetBalancePoint.fromJson(Map<String, dynamic> json) {
    return AssetBalancePoint(
      weekStart: (json['weekStart'] as String?) ?? '',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
    );
  }
}
