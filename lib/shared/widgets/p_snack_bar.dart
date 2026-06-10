import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// Snackbar severity — color/icon 분기 (success/info/warning/error/neutral).
enum PSnackSeverity { neutral, success, info, warning, error }

/// 표준 SnackBar — 자동 contrast 배경/전경 + 선택적 아이콘.
///
/// 사용:
/// ```dart
/// showPSnackBar(context, '저장되었습니다');                              // neutral
/// showPSnackBar(context, '완료', severity: PSnackSeverity.success);
/// showPSnackBar(context, '실패: $msg', severity: PSnackSeverity.error);
/// ```
///
/// Material `ScaffoldMessenger.showSnackBar` 직접 호출 산재(~110건)를
/// 정리하기 위한 단일 진입점. severity 분기로 brand-tone 일관성 + 시맨틱 명확.
void showPSnackBar(
  BuildContext context,
  String message, {
  PSnackSeverity severity = PSnackSeverity.neutral,
  Duration duration = const Duration(seconds: 4),
  SnackBarAction? action,
}) {
  final t = context.tokens;
  final (bg, fg) = switch (severity) {
    PSnackSeverity.neutral => (null, null),
    PSnackSeverity.success => (t.statusSuccess, t.fgOnSuccess),
    PSnackSeverity.info => (t.statusInfo, t.fgOnSuccess),
    PSnackSeverity.warning => (t.statusWarning, t.fgOnSuccess),
    PSnackSeverity.error => (t.statusDanger, t.fgOnDanger),
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: fg != null
            ? PTypo.bodySm.copyWith(color: fg, fontWeight: PFontWeight.medium)
            : null,
      ),
      backgroundColor: bg,
      duration: duration,
      action: action,
    ),
  );
}
