package com.porest.desk.porest_desk_app

/**
 * 결제 알림을 읽어올 카드사 앱 목록.
 *
 * <p>알림 접근 권한은 <b>기기의 모든 알림</b>을 볼 수 있는 강한 권한이다. 그래서 여기
 * 적힌 앱이 보낸 알림만 들여다보고 나머지는 즉시 버린다 — 카톡·메신저 내용이
 * 우리 코드에 잠깐이라도 머무르지 않게 하는 게 목적이다.
 *
 * <p>패키지명은 Play 스토어 기준(2026-08). 카드사가 앱을 갈아엎으면 바뀔 수 있어
 * 새 앱이 나오면 여기 한 줄 추가하는 것으로 대응한다.
 */
object CardAppPackages {

    /** 패키지명 → 표시용 이름. 알림에 카드사가 안 적혀 있을 때 이 이름을 단서로 쓴다. */
    val ALLOWED: Map<String, String> = mapOf(
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

    fun isCardApp(packageName: String?): Boolean =
        packageName != null && ALLOWED.containsKey(packageName)

    /** 그 앱이 어느 카드사인가 — 알림 본문에 카드사명이 없을 때 붙여 준다. */
    fun issuerOf(packageName: String?): String? = ALLOWED[packageName]
}
