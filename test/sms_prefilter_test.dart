import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/features/sms/domain/sms_prefilter.dart';

/// 로컬 프리필터 — 서버로 보낼지 말지의 게이트.
///
/// 이 판정이 느슨하면 클립보드의 사적인 텍스트가 서버로 흘러간다.
/// 반대로 너무 빡빡하면 진짜 결제 문자를 놓친다 — 서버가 한 번 더 보므로
/// 애매한 건 통과시키는 쪽이 맞다.
void main() {
  group('looksLikePaymentSms', () {
    test('카드사 결제 문자는 통과한다', () {
      expect(
        looksLikePaymentSms(
          '[Web발신]\nKB국민카드1234승인\n5,500원 일시불\n08/13 13:22\n스타벅스강남',
        ),
        isTrue,
      );
      expect(
        looksLikePaymentSms('신한카드(1234)승인 12,000원 일시불 08/13 19:05 김밥천국'),
        isTrue,
      );
    });

    test('취소 문자도 통과한다 — 막는 건 서버가 판단한다', () {
      expect(
        looksLikePaymentSms('KB국민카드1234승인취소 5,500원 08/13 14:00 스타벅스'),
        isTrue,
      );
    });

    test('결제와 무관한 텍스트는 서버로 보내지 않는다', () {
      expect(looksLikePaymentSms('오늘 저녁에 만나자'), isFalse);
      expect(looksLikePaymentSms('회의 자료 공유드립니다'), isFalse);
    });

    test('금액만 있고 결제 키워드가 없으면 거른다', () {
      expect(looksLikePaymentSms('회비 30,000원 보내주세요'), isFalse);
    });

    test('빈 입력·null 은 조용히 거른다', () {
      expect(looksLikePaymentSms(null), isFalse);
      expect(looksLikePaymentSms(''), isFalse);
      expect(looksLikePaymentSms('   '), isFalse);
    });
  });
}
