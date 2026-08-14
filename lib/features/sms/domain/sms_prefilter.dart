/// 결제 문자로 보이는가 — 서버로 보내기 전의 로컬 게이트.
///
/// 서버 `SmsParser.looksLikePayment` 와 같은 규칙이다. 여기서 한 번 거르는 이유는
/// 정확도가 아니라 **프라이버시**다 — 클립보드나 수신함의 아무 텍스트가 서버로
/// 흘러가면 안 된다. 판정이 애매하면 통과시키고 서버가 다시 판단한다.
///
/// 규칙: 금액(`5,500원`) + 결제 키워드가 함께 있어야 한다.
bool looksLikePaymentSms(String? text) {
  if (text == null || text.trim().isEmpty) return false;
  if (!_amountPattern.hasMatch(text)) return false;
  return _paymentKeywords.any(text.contains);
}

final RegExp _amountPattern = RegExp(r'[0-9][0-9,]{0,15}\s*원');

const List<String> _paymentKeywords = ['승인', '취소', '결제', '출금', '사용'];
