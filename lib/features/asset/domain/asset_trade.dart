import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset_trade.freezed.dart';
part 'asset_trade.g.dart';

/// 투자 자산의 매수·매도 거래 — 백엔드 `AssetTradeApiDto.TradeResponse` 미러.
///
/// 예수금이 줄고 느는 진짜 사건이다. 이게 없으면 평가액 갱신을 보고 예수금을
/// 추측해야 하는데, 시세 변동·추가 매수·재등록이 전부 같은 갱신으로 들어와 구분되지 않는다.
///
/// `OPENING` 은 앱을 쓰기 전부터 갖고 있던 보유라 돈이 오가지 않는다.
@freezed
abstract class AssetTrade with _$AssetTrade {
  const factory AssetTrade({
    required int rowId,
    required int assetRowId,
    required String tradeType, // 'OPENING' | 'BUY' | 'SELL'
    String? holdingType, // 'STOCK' | 'GOLD' | 'CRYPTO'
    /// 종목 식별자 — 연동은 토스 종목코드, 미연동은 항목명.
    required String holdingKey,
    @Default(false) bool linked,
    /// 소수 허용이라 문자열로 주고받는다(AssetHolding.quantity 와 같은 이유).
    String? quantity,
    /// 거래대금 — 수수료 제외.
    int? amount,
    int? fee,
    /// 실현손익 (매도 전용). 이익 양수 / 손실 음수.
    int? realizedPl,
    String? tradeDate,
    String? description,
  }) = _AssetTrade;

  factory AssetTrade.fromJson(Map<String, dynamic> json) =>
      _$AssetTradeFromJson(json);
}
