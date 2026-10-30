import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/features/sms/data/clipboard_hint.dart';

/// 클립보드 힌트를 읽는 함수 — 시험 · 캡처 하네스가 아이폰 경로(힌트가 있는 상태)를 재현하려고 바꿔 끼운다.
/// 실제 앱은 [readClipboardHint] 그대로다(안드로이드 · 힌트 없음 = null).
final clipboardHintReaderProvider = Provider<Future<ClipboardHint?> Function()>(
  (ref) => readClipboardHint,
);
