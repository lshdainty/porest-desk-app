import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// Snackbar severity — color/icon 분기 (success/info/warning/error/neutral).
enum PSnackSeverity { neutral, success, info, warning, error }

/// 표준 SnackBar — specs/components/sonner.md 미러.
///
/// 사용:
/// ```dart
/// showPSnackBar(context, '저장되었습니다');                              // neutral
/// showPSnackBar(context, '완료', severity: PSnackSeverity.success);
/// showPSnackBar(context, '실패: $msg', severity: PSnackSeverity.error);
/// ```
///
/// Material `ScaffoldMessenger.showSnackBar` 직접 호출 산재(~110건)를
/// 정리하기 위한 단일 진입점.
///
/// 예전엔 severity 색으로 <b>배경 전체</b>를 칠했다. 그래서 저장 한 번에 화면 하단이
/// 통째로 초록 막대가 됐고, 같은 성공 알림인데도 웹보다 훨씬 크게 보였다. 스펙은
/// 그렇게 정의한 적이 없다 — 표면은 중립으로 두고 <b>왼쪽 아이콘만</b> semantic 색을
/// 쓴다(`surface-default` + `border-default` 1px + `radius-md` + `shadow-lg`).
/// 웹 sonner 와 같은 톤이라 두 클라이언트가 같은 무게로 말한다.
void showPSnackBar(
  BuildContext context,
  String message, {
  PSnackSeverity severity = PSnackSeverity.neutral,
  Duration duration = const Duration(seconds: 4),
  SnackBarAction? action,

  /// 직접 넘기는 messenger — 전역 키로 띄울 때 쓴다. ScaffoldMessenger.of 는
  /// 자기 자신의 context 에서는 못 찾으므로(위로만 탐색) 그 경우 필수다.
  ScaffoldMessengerState? messenger,
}) {
  final t = context.tokens;
  // 아이콘 색만 severity 를 탄다. neutral 은 아이콘 자체가 없다(스펙: default kind).
  final (Color? iconColor, IconData? icon) = switch (severity) {
    PSnackSeverity.neutral => (null, null),
    PSnackSeverity.success => (t.statusSuccess, LucideIcons.circleCheck),
    PSnackSeverity.info => (t.statusInfo, LucideIcons.info),
    PSnackSeverity.warning => (t.statusWarning, LucideIcons.triangleAlert),
    PSnackSeverity.error => (t.statusDanger, LucideIcons.circleAlert),
  };

  (messenger ?? ScaffoldMessenger.of(context)).showSnackBar(
    SnackBar(
      // 색을 직접 그리므로 Material 기본 배경·여백을 걷어낸다.
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x16,
          vertical: PSpace.x12,
        ),
        decoration: BoxDecoration(
          // 다크에서 surface(#242938)는 bg-page(#1A1F2E)와 차이가 작고, 분리를
          // 맡던 그림자는 검은색이라 검은 배경 위에서 효과가 없다. 면을 한 단계
          // 올려야 실제로 뜬다(sonner.md 2026-08-21). 라이트에선 raised 가
          // surface 와 같은 값이라 변화 없다.
          color: t.bgSurfaceRaised,
          // 테두리 없음 — 면과 그림자만으로 분리한다(sonner.md 2026-08-21).
          borderRadius: PRadius.brMd,
          // 다크에서 lg·xl 은 부드러운 번짐이 아니라 한 겹 더 어두운 띠로 읽힌다
          // (그림자 색이 50~60% 검정인데 배경이 이미 거의 검정이라 경계가 안 뭉개진다).
          // md 는 띠가 안 생기고, 분리는 위의 surfaceRaised 면 차이가 해 준다.
          boxShadow: t.shadowMd,
        ),
        // 최소 높이 52(sonner.md). 패딩 12+12 와 아이콘 22 만으로는 46 이라
        // 모바일에서 눈에 안 들어왔다. 내용이 길면 자연히 늘어난다.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52 - PSpace.x12 * 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: PSpace.x12),
              ],
              Expanded(
                child: Text(
                  message,
                  // 이 메시지는 스펙의 title 자리다 — title-sm(16/600).
                  // 웹도 sonner title 에 text-title-sm + font-semibold 를 준다.
                  // 예전 bodySm(13/500)은 앱 토큰 이름이 스케일과 어긋나 한 단계
                  // 작은 값(spec 의 label-sm)을 쓰고 있던 것이다.
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: PFontSize.titleSm,
                    fontWeight: PFontWeight.semi,
                    height: 1.4,
                    color: t.fgPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      action: action,
    ),
  );
}
