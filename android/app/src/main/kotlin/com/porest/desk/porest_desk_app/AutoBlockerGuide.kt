package com.porest.desk.porest_desk_app

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings

/**
 * 삼성 "자동 차단"(Auto Blocker) 설정으로 데려다준다.
 *
 * <p><b>왜 필요한가</b> — One UI 6.0(Android 14)부터 기본으로 켜져 있는 기능이고,
 * <b>스토어 밖에서 온 앱의 설치를 통째로 막는다</b>. 우리 앱이 위험해서가 아니라
 * 사이드로드라는 경로 자체를 막는 것이라, 이걸 끄기 전에는 설치도 업데이트도 안 된다.
 *
 * <p><b>공식 딥링크가 없다.</b> 알림 접근처럼 표준 {@code Settings.ACTION_*} 액션이
 * 주어지지 않아, 화면을 직접 여는 방법이 문서화돼 있지 않다. 그래서 아는 컴포넌트를
 * 순서대로 두드려 보고 안 되면 한 단계씩 물러선다 — 마지막은 설정 앱 자체다.
 * 어느 단계에 닿든 사용자는 화면 안내를 따라 몇 번만 더 누르면 된다.
 */
object AutoBlockerGuide {

    /** 자동 차단을 담당하는 시스템 앱. 이 앱이 없으면 그 기기엔 기능 자체가 없다. */
    private const val RAMPART_PACKAGE = "com.samsung.android.rampart"

    /**
     * 자동 차단 화면 후보.
     *
     * <p>제조사가 One UI 버전마다 옮길 수 있고 공개 API 도 아니라서, 열리면 좋고
     * 아니면 마는 값이다. 실패해도 아래 보안 설정으로 이어진다.
     */
    private val CANDIDATES = listOf(
        ComponentName(RAMPART_PACKAGE, "$RAMPART_PACKAGE.ui.AutoBlockerActivity"),
        ComponentName(RAMPART_PACKAGE, "$RAMPART_PACKAGE.AutoBlockerActivity"),
        ComponentName(
            "com.samsung.android.sm",
            "com.samsung.android.sm.security.ui.autoblocker.AutoBlockerActivity",
        ),
    )

    /**
     * 삼성 기기인가 — 이 안내를 보여 줄지 정한다.
     *
     * <p>자동 차단이 있는 One UI 6.0 은 Android 14 부터다. 그 아래 삼성 기기에는
     * 기능이 없어 안내가 오히려 혼란스럽다.
     */
    fun isSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return false
        val maker = Build.MANUFACTURER?.lowercase().orEmpty()
        return maker == "samsung"
    }

    /**
     * 자동 차단 화면을 연다 — 못 열면 보안 설정, 그것도 안 되면 설정 앱.
     *
     * @return 어디까지 갔는지. 화면 안내 문구를 그에 맞게 바꾸려고 돌려준다.
     */
    fun open(context: Context): String {
        for (component in CANDIDATES) {
            if (start(context, Intent().setComponent(component))) return "auto_blocker"
        }
        if (start(context, Intent(Settings.ACTION_SECURITY_SETTINGS))) return "security"
        if (start(context, Intent(Settings.ACTION_SETTINGS))) return "settings"
        return "none"
    }

    private fun start(context: Context, intent: Intent): Boolean =
        try {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (e: ActivityNotFoundException) {
            // 그 버전엔 없는 화면이다 — 다음 후보로.
            false
        } catch (e: SecurityException) {
            // 시스템 앱이 밖에서 여는 걸 막아 둔 경우(exported=false). 역시 다음 후보로.
            false
        }
}
