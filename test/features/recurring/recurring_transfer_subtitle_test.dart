// 반복 목록의 이체 행 부제 — 출금 계좌만 적으면 돈이 어디로 갔는지가 행에서 사라진다.
//
// 어제(#366) 이체를 넣으면서 금액 색·부호만 고치고 부제는 그대로 뒀다. 프리셋 목록은
// 맞게 "출금 → 입금" 을 적는데 반복 목록 두 행(목록·"다가오는 7일")은 출금 계좌만
// 보였다(2026-09-15). 셋이 같은 helper 를 쓰게 하고 그걸 여기서 잠근다.
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/features/asset/domain/transfer_rules.dart';

void main() {
  group('transferPartiesLabel', () {
    test('출금 → 입금', () {
      expect(transferPartiesLabel('QA예금', 'QA적금'), 'QA예금 → QA적금');
    });

    test('이름이 없으면 - 로 채운다 — 화살표가 사라지면 이체로 안 보인다', () {
      expect(transferPartiesLabel(null, 'QA적금'), '- → QA적금');
      expect(transferPartiesLabel('QA예금', null), 'QA예금 → -');
    });
  });
}
