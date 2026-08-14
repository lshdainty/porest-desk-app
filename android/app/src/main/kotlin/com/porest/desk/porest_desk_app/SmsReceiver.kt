package com.porest.desk.porest_desk_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Telephony
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * 결제 문자 수신 → 알림 + 보관함.
 *
 * <p>여기서 지출을 만들지 않는다. 문자만 보고 자동으로 기록하면 카드 매핑이나
 * 카테고리가 틀렸을 때 사용자가 모르는 사이 장부가 어긋난다. 알림을 눌러 앱에
 * 들어와 확인·수정한 뒤 저장하는 흐름을 그대로 탄다.
 *
 * <p>서버 파서도 부르지 않는다. 문자가 올 때마다 네트워크를 타면 배터리를 먹고,
 * 서버가 잠깐 죽어 있으면 알림 자체가 안 뜬다. 여기서는 로컬 정규식으로
 * "결제 문자인가" 만 보고, 해석은 앱에 들어온 뒤에 한다.
 *
 * <p>SMS 는 70자(한글)를 넘으면 여러 조각으로 쪼개져 온다. 조각별로 알림을 띄우면
 * 한 결제에 알림이 서너 개 뜨므로 반드시 이어 붙여서 판단한다.
 */
class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val body = mergeMessageBody(intent) ?: return
        if (!SmsPaymentFilter.looksLikePayment(body)) return

        val receivedAt = System.currentTimeMillis()
        // 알림 id 겸 보관함 키 — 같은 문자를 두 번 담지 않게 수신 시각을 쓴다.
        val id = receivedAt
        SmsInboxStore.add(context, id, body, receivedAt)
        notify(context, id, body)
    }

    /** 멀티파트 조각을 원래 한 통으로 되돌린다. */
    private fun mergeMessageBody(intent: Intent): String? {
        val parts = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return null
        if (parts.isEmpty()) return null
        val body = parts.joinToString(separator = "") { it.displayMessageBody.orEmpty() }
        return body.ifBlank { null }
    }

    private fun notify(context: Context, id: Long, body: String) {
        // Android 13+ 는 알림도 권한이다. 없으면 조용히 지나간다 —
        // 보관함에는 이미 담겼으니 앱에서 목록으로 확인할 수 있다.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, android.Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        ensureChannel(context)

        // 알림을 누르면 앱이 열리면서 문자를 함께 들고 간다.
        // singleTop 이라 이미 떠 있으면 onNewIntent 로 들어온다.
        val launch = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_SMS_TEXT, body)
            putExtra(MainActivity.EXTRA_SMS_ID, id)
        }
        val pending = PendingIntent.getActivity(
            context,
            id.toInt(),
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_edit)
            .setContentTitle(context.getString(R.string.sms_notification_title))
            .setContentText(SmsPaymentFilter.summarize(body))
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(pending)
            .build()

        NotificationManagerCompat.from(context).notify(id.toInt(), notification)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.sms_notification_channel),
            // 소리까지 울리면 문자 알림과 겹쳐 두 번 울린다 — 조용히 목록에만 남긴다.
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = context.getString(R.string.sms_notification_channel_desc)
            setShowBadge(true)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_ID = "porest_sms_payment"
    }
}
