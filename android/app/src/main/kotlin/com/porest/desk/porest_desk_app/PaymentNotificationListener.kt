package com.porest.desk.porest_desk_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * 카드사 앱이 띄운 결제 알림을 읽어 기록 대상으로 삼는다.
 *
 * <p><b>왜 필요한가</b> — 카드사들이 승인 내역을 문자 대신 자사 앱 푸시로 보내는 쪽으로
 * 옮겨 갔다. 문자만 보면 카드에 따라 아무것도 안 잡힌다.
 *
 * <p><b>권한의 무게</b> — 알림 접근은 기기의 <b>모든 알림</b>을 볼 수 있는 특수 권한이다
 * (사용자가 설정에서 직접 켜야 하고, 런타임 팝업으로는 받을 수 없다). 그래서
 * {@link CardAppPackages} 에 적힌 카드사 앱이 보낸 것만 들여다보고 나머지는 즉시 버린다 —
 * 메신저 내용이 우리 코드에 잠깐이라도 머무르지 않게 한다.
 *
 * <p>여기서도 지출을 만들지 않는다. 문자 경로와 똑같이 수신함에 적어 두고, 사용자가
 * 확인 화면에서 저장한다.
 */
class PaymentNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val sbnSafe = sbn ?: return
        if (!CardAppPackages.isCardApp(sbnSafe.packageName)) return

        val body = mergeText(sbnSafe) ?: return
        if (!SmsPaymentFilter.looksLikePayment(body)) return

        val now = System.currentTimeMillis()
        // 같은 결제를 문자로도 받았을 수 있다 — 몇 분 안의 같은 금액이면 접는다.
        if (SmsInboxStore.hasRecentSameAmount(this, body, now, DEDUPE_WINDOW_MILLIS)) return

        SmsInboxStore.add(this, now, body, now)
        notifyQuietly(now, body)
    }

    /**
     * 알림에서 읽을 수 있는 텍스트를 한 덩어리로 모은다.
     *
     * <p>제목·본문·펼친 본문이 제각각이라(어떤 앱은 제목에 금액, 어떤 앱은 본문에 가맹점)
     * 전부 이어 붙여 서버 파서에 넘긴다. 파서가 필드별로 알아서 골라낸다.
     *
     * <p>카드사 이름이 본문에 없는 경우가 있어(앱 알림은 보낸 앱이 곧 카드사라 생략한다)
     * 앞에 붙여 준다 — 없으면 어느 카드인지 매칭할 단서가 사라진다.
     */
    private fun mergeText(sbn: StatusBarNotification): String? {
        val extras = sbn.notification?.extras ?: return null
        val parts = listOfNotNull(
            extras.getCharSequence(NotificationCompat.EXTRA_TITLE)?.toString(),
            extras.getCharSequence(NotificationCompat.EXTRA_TEXT)?.toString(),
            extras.getCharSequence(NotificationCompat.EXTRA_BIG_TEXT)?.toString(),
        ).map { it.trim() }.filter { it.isNotEmpty() }.distinct()

        if (parts.isEmpty()) return null
        val body = parts.joinToString(separator = "\n")

        val issuer = CardAppPackages.issuerOf(sbn.packageName)
        return if (issuer != null && !body.contains(issuer)) "$issuer\n$body" else body
    }

    /**
     * 조용한 알림 — 소리·진동 없이 목록에만 남긴다.
     *
     * <p>카드사 앱이 이미 소리를 냈다. 같은 결제로 한 번 더 울리면 성가시기만 하다.
     * 그래도 알림을 띄우는 건 탭 한 번으로 기록 화면까지 가기 위해서다.
     */
    private fun notifyQuietly(id: Long, body: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        ensureChannel()

        val launch = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_SMS_TEXT, body)
            putExtra(MainActivity.EXTRA_SMS_ID, id)
        }
        val pending = PendingIntent.getActivity(
            this,
            id.toInt(),
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_edit)
            .setContentTitle(getString(R.string.sms_notification_title))
            .setContentText(SmsPaymentFilter.summarize(body))
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .setAutoCancel(true)
            .setContentIntent(pending)
            .build()

        NotificationManagerCompat.from(this).notify(id.toInt(), notification)
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.card_noti_channel),
            // 카드사 앱이 이미 울렸다 — 우리는 목록에만 남긴다.
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.card_noti_channel_desc)
            setShowBadge(true)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "porest_card_app_payment"

        /** 문자와 앱 알림이 같은 결제를 물어오는 간격 — 넉넉히 잡아도 오탐이 적다. */
        private const val DEDUPE_WINDOW_MILLIS = 5 * 60 * 1000L
    }
}
