package com.porest.desk.porest_desk_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 결제 문자 수신 기능의 안드로이드 창구.
 *
 * 문자 수신·알림은 [SmsReceiver] 가 앱과 무관하게 처리하고(앱이 꺼져 있어도 온다),
 * 여기서는 Flutter 가 필요로 하는 것만 넘긴다 — 권한 상태·보관함·알림으로 들어온 문자.
 */
class MainActivity : FlutterActivity() {

    /** 알림을 눌러 들어왔을 때의 문자. Flutter 가 가져가면 비운다. */
    private var pendingSmsText: String? = null
    private var pendingSmsId: Long? = null

    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        capturePending(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // singleTop 이라 앱이 이미 떠 있으면 여기로 들어온다.
        setIntent(intent)
        capturePending(intent)
    }

    /**
     * 알림에서 들어온 문자를 붙잡아 둔다.
     *
     * Flutter 가 아직 붙기 전에 도착할 수 있어 바로 넘기지 못한다 —
     * 들고 있다가 Dart 가 물어볼 때 건넨다.
     */
    private fun capturePending(intent: Intent?) {
        val text = intent?.getStringExtra(EXTRA_SMS_TEXT) ?: return
        pendingSmsText = text
        pendingSmsId = intent.getLongExtra(EXTRA_SMS_ID, -1L).takeIf { it >= 0 }
        // 화면 회전 등으로 같은 인텐트가 다시 오면 이미 처리한 문자가 되살아난다.
        intent.removeExtra(EXTRA_SMS_TEXT)
        intent.removeExtra(EXTRA_SMS_ID)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermissions" -> result.success(hasPermissions())
            "requestPermissions" -> requestPermissions(result)
            "inbox" -> result.success(SmsInboxStore.all(this))
            "removeFromInbox" -> {
                val id = (call.argument<Number>("id"))?.toLong()
                if (id == null) {
                    result.error("bad_args", "id is required", null)
                } else {
                    SmsInboxStore.remove(this, id)
                    result.success(null)
                }
            }
            "clearInbox" -> {
                SmsInboxStore.clear(this)
                result.success(null)
            }
            "consumePendingSms" -> {
                val text = pendingSmsText
                val id = pendingSmsId
                pendingSmsText = null
                pendingSmsId = null
                result.success(
                    if (text == null) null else mapOf("text" to text, "id" to id)
                )
            }
            else -> result.notImplemented()
        }
    }

    private fun hasPermissions(): Boolean {
        val sms = ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS)
        if (sms != PackageManager.PERMISSION_GRANTED) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        if (hasPermissions()) {
            result.success(true)
            return
        }
        // 앞선 요청이 아직 안 끝났으면 그것부터 끝내게 둔다 — 대화상자를 겹쳐 띄우지 않는다.
        if (permissionResult != null) {
            result.success(false)
            return
        }
        permissionResult = result

        val wanted = mutableListOf(Manifest.permission.RECEIVE_SMS)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            wanted += Manifest.permission.POST_NOTIFICATIONS
        }
        ActivityCompat.requestPermissions(this, wanted.toTypedArray(), REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_CODE) return
        val pending = permissionResult ?: return
        permissionResult = null
        // 알림 권한은 거절돼도 수신 자체는 된다 — 보관함에는 쌓인다.
        // 그래서 "문자 수신이 되는가" 만 결과로 본다.
        val smsIndex = permissions.indexOf(Manifest.permission.RECEIVE_SMS)
        val granted = smsIndex >= 0 &&
            grantResults.getOrNull(smsIndex) == PackageManager.PERMISSION_GRANTED
        pending.success(granted)
    }

    companion object {
        private const val CHANNEL = "porest/sms_android"
        private const val REQUEST_CODE = 6301

        const val EXTRA_SMS_TEXT = "porest.sms.text"
        const val EXTRA_SMS_ID = "porest.sms.id"
    }
}
