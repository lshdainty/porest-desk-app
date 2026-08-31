import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_trade.dart';

/// 서버 `BigDecimal` 은 JSON **숫자**로 온다. 앱은 정밀도 때문에 문자열로 들고 다니므로
/// 컨버터 없이 캐스트하면 그 값이 실제로 채워지는 순간 화면이 통째로 죽는다.
///
///     type 'double' is not a subtype of type 'String?' in type cast
///
/// 보유가 하나도 없을 땐 전부 null 이라 안 터지고, 매수를 하는 순간 터졌다.
/// 그래서 "숫자로 와도 파싱되는가" 를 필드마다 못 박아 둔다.
void main() {
  group('AssetHolding — 서버가 숫자로 주는 십진 필드', () {
    test('quantity·avgPrice 가 숫자로 와도 문자열로 받는다', () {
      final h = AssetHolding.fromJson(const {
        'rowId': 1,
        'quantity': 3.75000000,
        'avgPrice': 71500.00000000,
      });

      expect(h.quantity, '3.75');
      expect(h.avgPrice, '71500');
    });

    test('문자열로 와도 그대로 받는다 — 꼬리 0 만 떨어진다', () {
      final h = AssetHolding.fromJson(const {
        'rowId': 1,
        'quantity': '0.05000000',
        'avgPrice': '95123456.50000000',
      });

      expect(h.quantity, '0.05');
      expect(h.avgPrice, '95123456.5');
    });

    test('정수로 와도 받는다', () {
      final h = AssetHolding.fromJson(const {
        'rowId': 1,
        'quantity': 10,
        'avgPrice': 71500,
      });

      expect(h.quantity, '10');
      expect(h.avgPrice, '71500');
    });

    test('없으면 null — 보유가 비어 있을 때 터지지 않는다', () {
      final h = AssetHolding.fromJson(const {'rowId': 1});

      expect(h.quantity, isNull);
      expect(h.avgPrice, isNull);
    });

    test('아주 작은 수량도 지수 표기가 되지 않는다', () {
      // 1e-8 로 표기되면 서버로 되돌려 보낼 때 BigDecimal 파싱이 깨진다.
      final h = AssetHolding.fromJson(const {
        'rowId': 1,
        'quantity': 0.00000001,
      });

      expect(h.quantity, '0.00000001');
      expect(h.quantity, isNot(contains('e')));
    });
  });

  group('AssetTrade — 거래 수량', () {
    test('숫자로 와도 문자열로 받는다', () {
      final t = AssetTrade.fromJson(const {
        'rowId': 1,
        'assetRowId': 2,
        'tradeType': 'BUY',
        'holdingKey': '005930',
        'quantity': 10.00000000,
      });

      expect(t.quantity, '10');
    });

    test('소수 수량(코인)도 깎이지 않는다', () {
      final t = AssetTrade.fromJson(const {
        'rowId': 1,
        'assetRowId': 2,
        'tradeType': 'BUY',
        'holdingKey': 'BTC',
        'quantity': 0.05,
      });

      expect(t.quantity, '0.05');
    });
  });
}
