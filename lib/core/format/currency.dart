import 'package:intl/intl.dart';

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
  if (!isForeignCurrency(currency) || exchangeRate == null || exchangeRate <= 0) {
    return balance;
  }
  return (balance * exchangeRate).round();
}
