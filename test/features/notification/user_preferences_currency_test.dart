// `/me/preferences` 의 `defaultCurrency` 디코딩 (D7 · desk-back #328).
//
// 이 칸은 서버보다 앱이 먼저 나갈 수 있다 — 컬럼·API 가 아직 없는 서버에 붙으면
// 응답에 키가 없다. 그때 죽거나 빈 값으로 떨어지면 새 자산·거래의 통화가 사라진다.
// **없으면 원화**가 이 칸의 계약이고, 종전 동작(늘 원화)과 같다.
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/core/format/currency.dart';
import 'package:porest_desk_app/features/notification/data/user_preferences_repository.dart';

void main() {
  test('서버가 준 값을 그대로 읽는다', () {
    final p = UserPreferences.fromJson(const {'defaultCurrency': 'USD'});
    expect(p.defaultCurrency, 'USD');
  });

  test('서버가 아직 이 칸을 안 실어 주면 원화다', () {
    // 옛 서버에 붙은 새 앱 — 나머지 칸도 종전처럼 기본값으로 채워진다.
    final p = UserPreferences.fromJson(const {'timezone': 'Asia/Seoul'});
    expect(p.defaultCurrency, kDefaultCurrency);
    expect(p.timezone, 'Asia/Seoul');
  });

  test('copyWith 는 통화만 갈아 끼운다', () {
    final p = UserPreferences.fromJson(const {
      'defaultCurrency': 'KRW',
      'timezone': 'Asia/Tokyo',
    });
    final next = p.copyWith(defaultCurrency: 'JPY');
    expect(next.defaultCurrency, 'JPY');
    expect(next.timezone, 'Asia/Tokyo');
  });
}
