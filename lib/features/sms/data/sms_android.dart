import 'dart:io';

import 'package:flutter/services.dart';

/// 아직 기록하지 않은 수신 문자 한 건.
class SmsInboxEntry {
  const SmsInboxEntry({
    required this.id,
    required this.text,
    required this.receivedAt,
  });

  final int id;
  final String text;
  final DateTime receivedAt;
}

/// 알림을 눌러 앱에 들어왔을 때 딸려 온 문자.
class PendingSms {
  const PendingSms({required this.text, this.id});
  final String text;
  final int? id;
}

/// 안드로이드 결제 감지 창구.
///
/// 감지·알림은 네이티브 `PaymentNotificationListener` 가 앱과 무관하게 처리한다
/// (앱이 꺼져 있어도 온다). 카드사·은행 앱 푸시와 결제 문자를 **알림 하나로** 읽는다 —
/// 예전에는 문자만 `RECEIVE_SMS` 로 따로 받았는데, 그 권한이 붙은 앱은 브라우저·
/// 메신저 경유 설치가 Play Protect 에 차단돼 경로를 합쳤다.
///
/// 여기서는 Flutter 가 필요한 것만 가져온다 — 권한 상태·보관함·알림으로 들어온 문자.
///
/// iOS 에서는 전부 빈 값을 돌려준다. 알림 접근 API 가 없어 클립보드 경로를 쓴다.
class SmsAndroid {
  const SmsAndroid._();

  static const MethodChannel _channel = MethodChannel('porest/sms_android');

  static bool get isSupported => Platform.isAndroid;

  /// 알림을 띄울 수 있는가 (Android 13+ 의 알림 권한).
  ///
  /// 결제 감지 자체와는 별개다 — 이게 없어도 알림 접근만 켜져 있으면 수신함에는
  /// 쌓인다. 알림에서 바로 기록하러 가는 동선만 빠질 뿐이다.
  static Future<bool> hasPermissions() async {
    if (!isSupported) return false;
    return await _invoke<bool>('hasPermissions') ?? false;
  }

  /// 알림 권한 요청 — 거절해도 감지는 계속된다(수신함에 쌓인다).
  static Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    return await _invoke<bool>('requestPermissions') ?? false;
  }

  /// 결제 알림을 읽을 수 있는가(알림 접근 권한).
  ///
  /// **이 값 하나가 결제 감지의 on/off 다.** 카드사·은행 앱 푸시는 물론
  /// 결제 문자까지 전부 이 경로로 읽는다.
  static Future<bool> hasNotificationAccess() async {
    if (!isSupported) return false;
    return await _invoke<bool>('hasNotificationAccess') ?? false;
  }

  /// 설정의 알림 접근 화면을 연다.
  ///
  /// 이 권한은 런타임 팝업으로 받을 수 없어 사용자가 설정에서 직접 켜야 한다.
  /// 안드로이드 11+ 는 우리 앱 항목 상세로 바로 열려서 목록을 뒤질 필요가 없다.
  static Future<void> openNotificationAccessSettings() async {
    if (!isSupported) return;
    await _invoke<void>('openNotificationAccessSettings');
  }

  /// 아직 기록하지 않은 결제 알림 목록 — 최신순.
  static Future<List<SmsInboxEntry>> inbox() async {
    if (!isSupported) return const [];
    final raw = await _invoke<List<dynamic>>('inbox');
    if (raw == null) return const [];
    return raw.map((e) {
      final m = (e as Map).cast<String, dynamic>();
      return SmsInboxEntry(
        id: (m['id'] as num?)?.toInt() ?? 0,
        text: m['text'] as String? ?? '',
        receivedAt: DateTime.fromMillisecondsSinceEpoch(
          (m['receivedAt'] as num?)?.toInt() ?? 0,
        ),
      );
    }).toList();
  }

  /// 기록했거나 필요 없어진 문자를 보관함에서 뺀다.
  static Future<void> removeFromInbox(int id) async {
    if (!isSupported) return;
    await _invoke<void>('removeFromInbox', {'id': id});
  }

  static Future<void> clearInbox() async {
    if (!isSupported) return;
    await _invoke<void>('clearInbox');
  }

  /// 알림을 눌러 들어왔는지 확인하고, 있으면 가져오면서 비운다.
  ///
  /// 비우지 않으면 앱으로 돌아올 때마다 같은 문자가 다시 열린다.
  static Future<PendingSms?> consumePendingSms() async {
    if (!isSupported) return null;
    final raw = await _invoke<Map<dynamic, dynamic>>('consumePendingSms');
    if (raw == null) return null;
    final m = raw.cast<String, dynamic>();
    final text = m['text'] as String?;
    if (text == null || text.isEmpty) return null;
    return PendingSms(text: text, id: (m['id'] as num?)?.toInt());
  }

  /// 채널이 없는 빌드에서도 앱은 그대로 돌아야 한다 — 기능만 조용히 빠진다.
  static Future<T?> _invoke<T>(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
