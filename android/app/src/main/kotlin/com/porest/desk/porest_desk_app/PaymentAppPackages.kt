package com.porest.desk.porest_desk_app

/**
 * 결제 알림을 읽어올 앱 목록 — 카드사와 은행.
 *
 * <p>알림 접근 권한은 <b>기기의 모든 알림</b>을 볼 수 있다. 그래서 여기 적힌 앱이 보낸
 * 알림만 들여다보고 나머지는 즉시 버린다 — 메신저 내용이 우리 코드에 잠깐이라도
 * 머무르지 않게 하는 게 목적이다.
 *
 * <p><b>은행 앱을 따로 나눈 이유</b> — 체크카드는 발급 주체가 은행이라 결제 알림도
 * 은행 앱에서 온다(토스·카카오뱅크·케이뱅크 체크카드가 대표적이다). 그런데 은행 앱은
 * 결제 말고도 입금·이체·잔액·공지 알림을 훨씬 많이 보낸다. 카드사 앱과 같은 잣대로
 * 걸렀다간 계좌이체가 지출로 둔갑한다. 소스를 구분해 두고 은행 쪽은 더 엄격하게 본다
 * ({@link SmsPaymentFilter#looksLikeCardPaymentFromBank}).
 *
 * <p>패키지명은 Play 스토어 기준(2026-08). 앱이 갈아엎히면 여기 한 줄 추가로 대응한다.
 */
object PaymentAppPackages {

    /** 이 알림이 어디서 왔는가 — 필터 강도를 가른다. */
    enum class Source { CARD_APP, BANK_APP }

    /** 카드사 앱 — 오는 알림이 대체로 결제라 기본 필터로 충분하다. */
    val CARD_APPS: Map<String, String> = mapOf(
        "com.kbcard.cxh.appcard" to "KB국민카드",      // KB Pay
        "com.kbcard.kbbusinesscard" to "KB국민카드",   // KB국민기업카드
        "com.shcard.smartpay" to "신한카드",           // 신한 SOL페이
        "com.shinhancard.wallet" to "신한카드",        // (구) 신한카드 올댓
        "com.hyundaicard.appcard" to "현대카드",
        "kr.co.samsungcard.mpocket" to "삼성카드",
        "net.ib.android.smcard" to "삼성카드",         // 모니모 (삼성금융 통합)
        "com.lcacApp" to "롯데카드",                   // 디지로카
        "com.wooricard.smartapp" to "우리카드",        // 우리WON카드
        "com.hanaskcard.paycla" to "하나카드",         // 하나Pay
        "nh.smart.card" to "NH농협카드",
        "nh.smart.nhallonepay" to "NH농협카드",        // NH페이
        "com.bccard.bcsmartapp" to "BC카드",
    )

    /**
     * 은행 앱 — 체크카드 결제가 여기로 온다. 대신 결제와 무관한 알림도 쏟아진다.
     *
     * <p>표시명은 자산의 institution 과 맞물려 카드를 찾는 단서가 되므로
     * 사람들이 흔히 쓰는 이름으로 적는다("케이뱅크" 등).
     */
    val BANK_APPS: Map<String, String> = mapOf(
        "viva.republica.toss" to "토스",
        "com.kakaobank.channel" to "카카오뱅크",
        "com.kbankwith.smartbank" to "케이뱅크",
        "com.kbstar.kbbank" to "국민은행",             // KB스타뱅킹
        "com.shinhan.sbanking" to "신한은행",          // 신한 슈퍼SOL
        "com.wooribank.smart.npib" to "우리은행",      // 우리WON뱅킹
        "com.hanabank.oqf" to "하나은행",              // 하나원큐
        "com.kebhana.hanapush" to "하나은행",          // (구) 하나원큐
        "com.nonghyup.nhallonebank" to "농협은행",     // NH올원뱅크
        "nh.smart.nhcok" to "농협은행",                // NH콕뱅크
        "com.ibk.android.ionebank" to "기업은행",      // i-ONE Bank
        "com.IBK.SmartPush.app" to "기업은행",         // i-ONE 알림
    )

    fun sourceOf(packageName: String?): Source? = when {
        packageName == null -> null
        CARD_APPS.containsKey(packageName) -> Source.CARD_APP
        BANK_APPS.containsKey(packageName) -> Source.BANK_APP
        else -> null
    }

    /** 어느 카드사·은행인가 — 알림 본문에 이름이 없을 때 붙여 준다. */
    fun issuerOf(packageName: String?): String? =
        CARD_APPS[packageName] ?: BANK_APPS[packageName]
}
