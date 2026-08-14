import 'dart:io';

import 'package:flutter/services.dart';

/// 클립보드 힌트 — 내용을 읽지 않고 얻은 단서.
class ClipboardHint {
  const ClipboardHint({required this.changeCount, required this.hasNumber});

  /// 클립보드가 바뀔 때마다 오르는 정수. 같은 복사본을 다시 권하지 않으려고 쓴다.
  final int changeCount;

  /// 숫자가 들어 있는가 — 결제 문자에는 금액이 반드시 있다.
  final bool hasNumber;
}

/// 클립보드에 결제 문자가 있을 법한지 — **내용은 읽지 않는다**.
///
/// iOS 는 클립보드를 읽을 때마다 "○○에서 붙여넣기" 배너를 띄운다. 홈에 들어올
/// 때마다 읽으면 그 배너가 계속 떠 사용자를 괴롭히므로, 배너를 띄울지 판단하는
/// 단계에서는 내용 접근이 없는 힌트만 본다(네이티브 `detectPatterns`).
/// 실제 읽기는 사용자가 배너를 눌렀을 때 한 번만 한다.
///
/// **iOS 전용이다.** 안드로이드에는 내용 접근 없이 클립보드를 엿볼 방법이 없고,
/// 애초에 문자를 직접 수신할 수 있어 클립보드를 우회로로 쓸 이유가 없다.
Future<ClipboardHint?> readClipboardHint() async {
  if (!Platform.isIOS) return null;
  try {
    final raw = await _channel.invokeMapMethod<String, dynamic>('hint');
    if (raw == null) return null;
    return ClipboardHint(
      changeCount: (raw['changeCount'] as num?)?.toInt() ?? 0,
      hasNumber: raw['hasNumber'] as bool? ?? false,
    );
  } on PlatformException {
    // 채널이 없는 빌드(구버전 앱 껍데기)에서도 앱은 그대로 돌아가야 한다.
    return null;
  } on MissingPluginException {
    return null;
  }
}

const MethodChannel _channel = MethodChannel('porest/clipboard_hint');
