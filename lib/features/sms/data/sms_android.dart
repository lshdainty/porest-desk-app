import 'dart:io';

import 'package:flutter/services.dart';

/// 아직 기록하지 않은 수신 문자 한 건.
class SmsInboxEntry {
  const SmsInboxEntry({required this.id, required this.text, required this.receivedAt});

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

/// 안드로이드 결제 문자 수신 창구.
///
/// 수신·알림은 네이티브 `SmsReceiver` 가 앱과 무관하게 처리한다(앱이 꺼져 있어도 온다).
/// 여기서는 Flutter 가 필요한 것만 가져온다 — 권한 상태·보관함·알림으로 들어온 문자.
///
/// iOS 에서는 전부 빈 값을 돌려준다. 문자 접근이 OS 차원에서 막혀 있어
/// 클립보드 경로를 쓴다.
class SmsAndroid {
  const SmsAndroid._();

  static const MethodChannel _channel = MethodChannel('porest/sms_android');

  static bool get isSupported => Platform.isAndroid;

  /// 문자 수신 권한이 있는가 — 이 값이 곧 기능의 on/off 다(따로 저장하지 않는다).
  static Future<bool> hasPermissions() async {
    if (!isSupported) return false;
    return await _invoke<bool>('hasPermissions') ?? false;
  }

  /// 권한 요청 — 사용자가 설정에서 켤 때만 부른다.
  ///
  /// 알림 권한을 거절해도 수신 자체는 되므로(보관함에 쌓인다) 문자 권한만 결과로 본다.
  static Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    return await _invoke<bool>('requestPermissions') ?? false;
  }

  /// 카드사 앱 알림을 읽을 수 있는가(알림 접근 권한).
  ///
  /// 문자 권한과 별개다 — 카드사가 승인 내역을 문자로 보내면 문자 권한이,
  /// 자사 앱 푸시로 보내면 이쪽이 필요하다.
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

  /// 아직 기록하지 않은 문자 목록 — 최신순.
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
  static Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
