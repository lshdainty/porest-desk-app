import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset.freezed.dart';
part 'asset.g.dart';

/// 백엔드 `AssetApiDto.AssetResponse` 1:1 매핑.
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
    // 연결된 카드 상품 (카드 자산 전용, nullable) — 편집 진입 시 선택 상태 복원용.
    AssetCardCatalog? cardCatalog,
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

/// 자산에 연결된 카드 상품 요약 — 백엔드 `CardCatalogBriefResponse` 미러.
/// 카드 편집 화면에서 기존 상품을 고른 상태로 되살리는 데 쓴다.
@freezed
abstract class AssetCardCatalog with _$AssetCardCatalog {
  const factory AssetCardCatalog({
    required int rowId,
    required String cardName,
    String? imgUrl,
    String? companyName,
    String? companyLogoUrl,
  }) = _AssetCardCatalog;

  factory AssetCardCatalog.fromJson(Map<String, dynamic> json) =>
      _$AssetCardCatalogFromJson(json);
}

/// 보유 유형 — 수량 단위가 다르다(주식 주 / 금 g / 코인 개).
/// 토스 시세 연동(linked)은 STOCK 만 가능 — 금·코인은 시세를 못 받는다.
enum AssetHoldingType {
  @JsonValue('STOCK')
  stock,
  @JsonValue('GOLD')
  gold,
  @JsonValue('CRYPTO')
  crypto;

  /// 서버 계약 값 — 요청 바디 직렬화용.
  String get wire => switch (this) {
        AssetHoldingType.stock => 'STOCK',
        AssetHoldingType.gold => 'GOLD',
        AssetHoldingType.crypto => 'CRYPTO',
      };
}

/// 투자 보유 종목 1건 — 백엔드 `holdings[]` 계약 미러.
/// linked=true → tossSymbol+quantity(현재가 연동), false → holdingName+holdingValue(직접 입력).
@freezed
abstract class AssetHolding with _$AssetHolding {
  const factory AssetHolding({
    int? rowId,
    // 구버전 응답엔 없음 — 없거나 모르는 값이면 주식으로 본다(하위호환).
    @JsonKey(unknownEnumValue: AssetHoldingType.stock)
    @Default(AssetHoldingType.stock)
    AssetHoldingType holdingType,
    @Default(false) bool linked,
    String? tossSymbol,
    // 코인 0.05·금 3.75g 등 소수 허용. 미연동도 기록 가능(선택).
    double? quantity,
    String? holdingName,
    int? holdingValue,
    int? sortOrder,
  }) = _AssetHolding;

  factory AssetHolding.fromJson(Map<String, dynamic> json) =>
      _$AssetHoldingFromJson(json);
}
