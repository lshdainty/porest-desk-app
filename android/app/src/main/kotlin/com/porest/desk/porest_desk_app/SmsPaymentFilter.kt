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
