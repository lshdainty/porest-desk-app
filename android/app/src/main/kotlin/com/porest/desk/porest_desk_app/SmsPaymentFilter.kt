package com.porest.desk.porest_desk_app

/**
 * 결제 문자로 보이는가 — 수신함 전체가 서버로 흘러가지 않게 막는 게이트.
 *
 * 서버 `SmsParser.looksLikePayment`·Flutter `looksLikePaymentSms` 와 같은 규칙이다.
 * 정확도가 아니라 **프라이버시**가 목적이라 여기서 통과한 것만 알림·인박스로 간다.
 * 판정이 애매하면 통과시키고 서버가 다시 판단한다.
 *
 * 금액과 결제 키워드가 함께 있어야 한다 — 인증번호 문자에는 숫자만 있고,
 * 안내 문자에는 키워드만 있다.
 */
object SmsPaymentFilter {
    private val AMOUNT = Regex("""[0-9][0-9,]{0,15}\s*원""")
    private val KEYWORDS = listOf("승인", "취소", "결제", "출금", "사용")

    fun looksLikePayment(text: String?): Boolean {
        if (text.isNullOrBlank()) return false
        if (!AMOUNT.containsMatchIn(text)) return false
        return KEYWORDS.any { text.contains(it) }
    }

    /**
     * 은행 앱 알림이 <b>카드 결제</b>인가 — 기본 필터보다 엄격하다.
     *
     * <p>은행 앱은 결제 말고도 입금·이체·잔액·공지를 훨씬 많이 보낸다. 기본 필터는
     * "출금" 한 단어만 있어도 통과시키는데, 계좌이체 출금이 그렇게 들어오면 지출로
     * 둔갑한다 — 이체는 자산 사이의 이동이지 쓴 돈이 아니다.
     *
     * <p>그래서 카드로 긁었다는 신호를 <b>명시적으로 요구</b>하고, 이체·입금이 분명한
     * 알림은 버린다. "출금" 자체는 배제하지 않는다 — 체크카드 결제를 그렇게 적는
     * 은행이 있는데, 어차피 카드 신호가 없으면 위에서 걸린다.
     */
    fun looksLikeCardPaymentFromBank(text: String?): Boolean {
        if (text.isNullOrBlank()) return false
        if (!AMOUNT.containsMatchIn(text)) return false
        if (BANK_EXCLUDE.any { text.contains(it) }) return false
        return BANK_CARD_MARKERS.any { text.contains(it) }
    }

    /** 은행 앱 알림에서 "카드로 긁었다" 를 알리는 말. 하나는 있어야 결제로 본다. */
    private val BANK_CARD_MARKERS =
        listOf("승인", "체크카드", "카드결제", "카드 결제", "일시불", "결제")

    /** 명백히 결제가 아닌 알림 — 있으면 버린다. */
    private val BANK_EXCLUDE = listOf("입금", "이체", "송금", "자동납부")

    /**
     * 결제 금액만 뽑는다 — 중복 억제 키로 쓴다. 못 읽으면 null.
     *
     * <p>정확한 해석은 서버가 한다. 여기서는 "같은 결제가 문자와 앱 알림으로 두 번
     * 들어왔는가" 를 가리기 위한 대략의 지문만 있으면 된다.
     */
    fun amountOf(text: String?): String? {
        if (text.isNullOrBlank()) return null
        return AMOUNT.find(text)?.groupValues?.getOrNull(0)?.replace(" ", "")
    }

    /**
     * 알림 한 줄로 보여 줄 요약 — "스타벅스강남 5,500원".
     *
     * 서버 파서를 부르지 않는다. 문자가 올 때마다 네트워크를 타면 배터리도 먹고,
     * 서버가 죽어 있으면 알림 자체가 안 뜬다. 여기서는 눈에 띄는 금액 하나만 뽑고,
     * 정확한 해석은 사용자가 알림을 눌러 앱에 들어온 뒤에 한다.
     */
    fun summarize(text: String): String {
        val amount = AMOUNT.find(text)?.value?.replace(" ", "")
        return amount ?: text.lineSequence().firstOrNull { it.isNotBlank() }?.take(40).orEmpty()
    }
}
