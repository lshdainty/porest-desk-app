// 자산 빈 상태 안내가 가리키는 메뉴 이름 — QA #15 의 앱판.
//
// 안내는 "설정 → 계좌·카드 관리에서 추가할 수 있어요" 인데 실제 설정 메뉴는
// "계좌·카드 관리" 였다. 안내만 '카드·계좌' 로 순서가 뒤집혀 있어, 그대로 읽고
// 찾아가면 그런 이름의 메뉴가 없다. 안내가 링크가 아니라 텍스트라 더 헤맨다.
//
// 여기서 잠그는 건 **문구 자체가 아니라 이름이 하나라는 것**이다 — 어느 한 곳을
// 고치면 나머지도 같이 움직여야 한다.
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/l10n/generated/app_localizations_en.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations_ko.dart';

void main() {
  test('ko — 메뉴 이름이 한 가지다', () {
    final l = AppLocalizationsKo();

    // 설정·더보기·금액 숨김 목록이 같은 화면을 같은 이름으로 부른다.
    expect(l.moreItemAccountCard, l.settingsMenuAccountCard);
    expect(l.hideCardAssetManage, l.settingsMenuAccountCard);
    // 그 화면의 제목도 같다.
    expect(l.assetManageTitle, l.settingsMenuAccountCard);

    // 빈 상태 안내는 사용자가 실제로 누를 메뉴 이름을 그대로 부른다.
    expect(l.assetEmptyHint, contains(l.settingsMenuAccountCard));
  });

  test('en — 설정에서 부르는 이름과 안내가 같다', () {
    final l = AppLocalizationsEn();

    expect(l.moreItemAccountCard, l.settingsMenuAccountCard);
    expect(l.assetEmptyHint, contains(l.settingsMenuAccountCard));
  });
}
