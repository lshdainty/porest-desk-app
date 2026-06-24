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
    String? tossSymbol, // 토스 연동 종목코드
    int? tossQuantity, // 토스 연동 보유수량
  }) = _Asset;

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
}
