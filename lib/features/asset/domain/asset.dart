import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:porest_desk_app/core/format/decimal_string.dart';

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
    /// 예수금·현금 잔액 (투자 계좌의 매수 대기 자금). balance = cashBalance + holdingBalance.
    int? cashBalance,
    /// 보유 종목 평가금액. 보유가 없으면 0.
    int? holdingBalance,
    String? currency,
    /// 원화 환산율 (통화 1단위당 원화). KRW 는 1 — 순자산은 balance × 이 값으로 환산된다.
    double? exchangeRate,
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
    // 이번 달(1일~말일) 사용 합계 — CHECK_CARD 전용, 서버 계산(예정 제외·환불 상계).
    // 연결계좌 즉시 차감으로 잔액이 늘 0 이라, 행·상세는 잔액 대신 이 값을 보여준다.
    int? monthlyUsedAmount,
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
    // 서버 계약은 BigDecimal(decimal(28,8)) — double 로 담으면 십진 소수가 깎이므로
    // 클라이언트는 문자열로 들고 다닌다. 전송도 문자열 그대로(Jackson 이 BigDecimal 로 받는다).
    @JsonKey(fromJson: decimalStringFromJson) String? quantity,
    String? holdingName,
    int? holdingValue,
    /// 총 매수원가 (원화, 수수료 포함). 평가액과의 차이가 평가손익이다.
    int? totalCost,
    /// 평단가 — 총원가 / 수량. 서버 파생값이라 읽기 전용, 정밀도 때문에 문자열.
    /// 서버 계약이 BigDecimal 이라 JSON 숫자로 온다 — 컨버터 없이 캐스트하면 터진다.
    @JsonKey(fromJson: decimalStringFromJson) String? avgPrice,
    int? sortOrder,
  }) = _AssetHolding;

  factory AssetHolding.fromJson(Map<String, dynamic> json) =>
      _$AssetHoldingFromJson(json);
}

/// 표시·미리보기 계산용 수치. 저장·전송에는 절대 쓰지 않는다 — 그 경로는 문자열 그대로다.
/// (토스 `TossHolding.quantityValue` 와 같은 패턴)
extension AssetHoldingQuantity on AssetHolding {
  double get quantityValue => double.tryParse(quantity ?? '') ?? 0;
}
