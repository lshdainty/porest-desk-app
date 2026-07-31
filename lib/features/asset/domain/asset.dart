import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset.freezed.dart';
part 'asset.g.dart';

/// 백엔드 `AssetApiDto.AssetResponse` 1:1 매핑.
/// `cardCatalog` 같은 nested 필드는 v0.1 에선 사용 안 하므로 제외.
@freezed
abstract class Asset with _$Asset {
  const factory Asset({
    required int rowId,
    int? userRowId,
    required String assetName,
    required String assetType, // 'CASH' | 'BANK_ACCOUNT' | 'CARD' | 'INVESTMENT' | ...
    int? balance,
    String? currency,
    String? color,
    String? institution,
    String? memo,
    int? sortOrder,
    String? isIncludedInTotal, // 'Y' | 'N'
    // 신용카드 청구 사이클 (CREDIT_CARD 전용, nullable).
    int? creditLimit, // 신용 한도
    int? paymentDay, // 결제일 (1~31)
    int? paymentAssetRowId, // 결제 출금계좌 자산 rowId
    // 토스 연동 (INVESTMENT 전용, nullable). 토스 현재가 × 보유수량으로 평가액 실시간 계산.
    // deprecated — holdings(다건)로 대체. 서버 필드 잔존으로 파싱만 유지.
    String? tossSymbol, // 토스 연동 종목코드
    int? tossQuantity, // 토스 연동 보유수량
    // 보유 종목 (INVESTMENT 전용, design tossapi5) — linked(현재가×수량 연동) | manual(평가액 직접).
    // 구버전 서버 응답엔 없으므로 기본 빈 리스트로 안전 파싱.
    @Default(<AssetHolding>[]) List<AssetHolding> holdings,
  }) = _Asset;

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
}

/// 투자 보유 종목 1건 — 백엔드 `holdings[]` 계약 미러.
/// linked=true → tossSymbol+quantity(현재가 연동), false → holdingName+holdingValue(직접 입력).
@freezed
abstract class AssetHolding with _$AssetHolding {
  const factory AssetHolding({
    int? rowId,
    @Default(false) bool linked,
    String? tossSymbol,
    int? quantity,
    String? holdingName,
    int? holdingValue,
    int? sortOrder,
  }) = _AssetHolding;

  factory AssetHolding.fromJson(Map<String, dynamic> json) =>
      _$AssetHoldingFromJson(json);
}
