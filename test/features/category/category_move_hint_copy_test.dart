// 하위 카테고리 편집의 상위 칸 안내는 웹·앱이 같은 문장을 쓰고, 서버 거절 문구(EXP_015
// "하위 카테고리는 최상위로 올릴 수 없어요. 새 최상위를 만들어 거래를 옮겨 주세요")와 같은
// 길을 말한다(2026-09-24 사용자 결정).
//
// 전에는 셋이 다 달랐다. 앱 "다른 상위로…", 웹 "다른 상위 카테고리로…" 였고, 둘 다 "연결된
// 거래를 옮긴 뒤 새로 만들어" 라고 순서를 거꾸로 말했다(거래를 옮길 새 최상위가 먼저 있어야
// 한다).
//
// `l.categoryParentMoveHint` 로만 비교하면 arb 가 무슨 말로 바뀌든 따라가서 아무것도 안
// 지킨다. 웹은 `tests/category-move-hint-copy.test.ts` 에서 같은 전문을 잠근다 — 한쪽만
// 바뀌면 그쪽 테스트가 깨진다(subscription_feature_table_test 와 같은 방식).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

const _ko = '다른 상위 카테고리로 이동할 수 있어요. 최상위로 올리려면 새 최상위를 만들어 거래를 옮겨 주세요.';
const _en =
    'You can move it under a different parent. To make it top-level, '
    'create a new top-level category and move the transactions.';

void main() {
  test('ko — 웹과 같은 전문', () async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(l.categoryParentMoveHint, _ko);
  });

  test('en — 웹과 같은 전문', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(l.categoryParentMoveHint, _en);
  });
}
