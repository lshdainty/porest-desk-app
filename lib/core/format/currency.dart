import 'package:intl/intl.dart';

import 'package:porest_desk_app/core/format/krw.dart';

/// 지원 통화 — 외화통장·해외 결제에서 쓴다.
///
/// 통화명은 다국어 대상이 아니다. ISO 코드(USD)와 기호($)는 로케일과 무관한 국제
/// 표기라 화면에도 `$ USD` 처럼 코드로 보여 준다(브랜드 고유명과 같은 취급).
class CurrencyOption {
  const CurrencyOption(this.code, this.symbol);

  final String code;
  final String symbol;
}

const String kDefaultCurrency = 'KRW';

const List<CurrencyOption> kCurrencies = [
  CurrencyOption('KRW', '₩'),
  CurrencyOption('USD', r'$'),
  CurrencyOption('JPY', '¥'),
  CurrencyOption('EUR', '€'),
  CurrencyOption('CNY', '¥'),
  CurrencyOption('GBP', '£'),
  CurrencyOption('AUD', r'A$'),
  CurrencyOption('CAD', r'C$'),
  CurrencyOption('HKD', r'HK$'),
  CurrencyOption('SGD', r'S$'),
  CurrencyOption('THB', '฿'),
  CurrencyOption('VND', '₫'),
  CurrencyOption('TWD', r'NT$'),
  CurrencyOption('CHF', 'CHF'),
];

String currencySymbol(String? code) {
  if (code == null) return '';
  for (final c in kCurrencies) {
    if (c.code == code) return c.symbol;
  }
  return code;
}

bool isForeignCurrency(String? code) =>
    code != null && code.isNotEmpty && code != kDefaultCurrency;

/// 라벨 괄호 안에 붙는 통화 단위 — `잔액 (원)` · `잔액 ($)` 의 그 자리.
///
/// 잔액·한도 라벨이 `(원)` 으로 박혀 있어 USD 를 골라도 원화처럼 보였다(QA 12차).
/// 단위는 **고른 통화**를 따라야 한다.
///
/// 기호는 새로 세지 않고 위 [kCurrencies] 한 벌을 그대로 쓴다 — 두 벌이 되면 통화를
/// 하나 늘릴 때 한쪽만 늘어나고, 그 어긋남은 화면에서만 보인다.
///
/// **원화만 로케일을 탄다.** 한국어 화면은 `₩` 를 안 쓰고 `원` 을 접미로 붙이고
/// (`krwSigned` · [wonUnit] 이 이미 그 규칙이다), 영어 화면은 `₩10,000` 처럼 앞에
/// 붙인다. 그래서 여기서도 ko `원` / en `₩` 로 갈린다 — `잔액 (₩)` 도 `Balance (원)`
/// 도 그 화면에서는 남의 글자다. 나머지 통화는 로케일과 무관한 국제 표기라 기호 그대로다.
///
/// 통화를 모르면(`null`·빈 문자열) 원화로 본다 — 안 적힌 자산은 원화라는 게
/// [kDefaultCurrency] 다. 모르는 코드는 코드를 그대로 낸다(빈 괄호보다 낫다).
///
/// **웹도 같은 규칙을 쓴다** — `shared/lib/porest/currency.ts` 의 `currencyUnit`
/// (desk-front #369). 갈리면 같은 자산을 웹과 앱에서 다른 단위로 읽는다.
String currencyUnit(String? code) =>
    (code == null || code.isEmpty || code == kDefaultCurrency)
    ? wonUnit()
    : currencySymbol(code);

/// 원 통화 금액 표기 — `$5.50` / `¥1,280`.
///
/// 소수 자리는 통화별로 다르다(엔·원·동은 0). 기호는 우리가 붙이므로 숫자만 뽑는다.
String formatOriginalAmount(double amount, String code, String locale) {
  final digits = (code == 'JPY' || code == 'KRW' || code == 'VND') ? 0 : 2;
  final f = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: digits,
  );
  return '${currencySymbol(code)}${f.format(amount)}';
}

/// 자산 잔액의 원화 환산 — 화면에서 자산을 다시 더하는 곳은 이 함수를 거친다.
///
/// 서버는 순자산·요약을 이미 환산해서 준다. raw balance 를 그대로 더하면
/// USD 1,000 이 1,000원으로 잡혀 서버 값과 어긋난다.
int balanceInKrw(int balance, String? currency, double? exchangeRate) {
  if (!isForeignCurrency(currency) ||
      exchangeRate == null ||
      exchangeRate <= 0) {
    return balance;
  }
  return (balance * exchangeRate).round();
}
