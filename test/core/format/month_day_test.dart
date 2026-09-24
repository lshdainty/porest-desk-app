// 결제일을 말하는 문장의 날짜는 웹처럼 연도를 안 붙인다(QA 28 4).
//
// 웹 `formatMonthDay` 는 연도를 붙이지 않는다(ko "1월 25일" / en "Jan 25"). 앱 `formatDay`
// 는 올해가 아니면 연도를 붙인다 — 반복 거래 목록에서 내년치를 가르려고 둔 규칙이다.
// 그 값을 문장에 넣으면 12월에 "2027년 1월 25일에 결제돼요" 가 되어 웹과 갈린다.
// 문장에는 [monthDay] 를 쓴다. 해가 바뀌는 날짜로 재야 차이가 보이므로 먼 해(2100)를 쓴다.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/expense/presentation/closed_cycle_notice.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

void main() {
  final farNextYear = DateTime(2100, 1, 25);

  // 앱은 main.dart 에서 부른다 — 테스트도 같은 상태로.
  setUpAll(() async => initializeDateFormatting());

  test('ko — 해가 달라도 "M월 D일"(formatDay 는 연도를 붙인다)', () {
    expect(monthDay(farNextYear), '1월 25일');
    expect(formatDay(farNextYear).md, '2100년 1월 25일', reason: '목록용 규칙은 그대로다');
  });

  test('en — "Jan 25"(웹 "MMM d")', () {
    final prev = Intl.defaultLocale;
    Intl.defaultLocale = 'en';
    addTearDown(() => Intl.defaultLocale = prev);
    expect(monthDay(farNextYear), 'Jan 25');
  });

  test('고쳐 쓰기 확인창 — 12월 거래의 결제일(다음 해 1월)에 연도가 없다', () async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    const card = Asset(
      rowId: 7,
      assetName: '신한',
      assetType: 'CREDIT_CARD',
      paymentDay: 12,
    );

    final message = rewriteConfirmMessage(
      l,
      newAsset: card,
      dateKey: '2099-12-20',
    );

    expect(message, contains('새 거래는 1월 12일 결제에 청구돼요.'));
    expect(message, isNot(contains('2100년')));
  });
}
