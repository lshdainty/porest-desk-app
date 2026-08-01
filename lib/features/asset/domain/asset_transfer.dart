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
