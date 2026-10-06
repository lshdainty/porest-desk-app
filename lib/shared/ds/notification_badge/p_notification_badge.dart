import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';

/// 크기 — small(점 6 — 새 것이 있는지만, 기본) · large(숫자 18 — 몇 개인지가 중요할 때).
enum PNotificationBadgeSize { small, large }

/// 붙는 자리 — icon(상단 바 · 탭 바의 아이콘, 기본) · text(탭 · Segmented 의 글 오른쪽 위).
enum PNotificationBadgeAttach { icon, text }

/// 숫자 글 — 100 이상이면 "99+". 0 이하면 배지가 없다(null).
@visibleForTesting
String? notificationBadgeLabel(int count) =>
    count <= 0 ? null : (count >= 100 ? '99+' : '$count');

/// Notification Badge — 안 읽은 알림이 있다는 점 · 숫자. 구조는 SEED Notification Badge(2026-10-03), 수치 원본은
/// porest-design `specs/components/notification-badge.yaml`(값은 `test/fixtures/design_spec/notification-badge.json`).
/// 웹(desk-front `src/shared/ds/notification-badge`)과 같은 값이다.
///
/// 붙을 대상([child] — 아이콘 · 글)을 감싸고 그 상자 위에 겹쳐 놓는다 — 자리를 차지하지 않는다(아이콘 크기 · 버튼
/// 높이 · 탭 폭을 바꾸지 않는다). 아이콘에 붙는 점은 아이콘 상자 안 위 1 · 오른쪽 1, 숫자는 왼쪽 아래 꼭짓점이
/// (아이콘 폭 − 8, 14) 라 위 · 오른쪽으로 튀어나와 숫자가 길수록 오른쪽으로 자란다. 글에 붙으면 글 끝 + 2 · 줄 위 끝.
///
/// 점은 브랜드 글자색(fg-brand — 다크에서 밝은 짝), 숫자 알약은 bg-brand-solid + 흰 숫자(t1 11/15 · 700 · 숫자 폭 같게 ·
/// 글자 크기 설정을 따르지 않는다 — 커지면 아이콘을 덮는다). 0 이면 없고 100 이상이면 "99+".
/// 읽지 않는다 — 알림은 붙은 버튼 · 탭의 이름에 직접 넣는다("알림, 새 알림 3개" — 줄이지 않은 수).
class PNotificationBadge extends StatelessWidget {
  const PNotificationBadge({
    super.key,
    required this.child,
    this.show = true,
    this.count,
    this.size = PNotificationBadgeSize.small,
    this.attach = PNotificationBadgeAttach.icon,
  }) : assert(
         size == PNotificationBadgeSize.small || count != null,
         '숫자(large)는 count 가 있다',
       );

  /// 붙을 대상 — 아이콘(24 · 20)이나 글. 그 상자에서 잰다.
  final Widget child;

  /// 점(small)을 보일지 — 새 것이 있을 때.
  final bool show;

  /// 숫자(large) — 0 이하면 배지가 없다.
  final int? count;
  final PNotificationBadgeSize size;
  final PNotificationBadgeAttach attach;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final large = size == PNotificationBadgeSize.large;
    final label = large ? notificationBadgeLabel(count ?? 0) : null;
    if (!show || (large && label == null)) return child;

    // 읽지 않는다 — 붙은 버튼 · 탭의 이름이 알린다
    final Widget pill = large
        ? Container(
            key: const ValueKey('notification-badge'),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.bgBrandSolid,
              borderRadius: BorderRadius.circular(PRounded.full),
            ),
            child: Text(
              label!,
              textScaler: TextScaler.noScaling,
              style: PTypography.t1.copyWith(
                color: c.staticWhite,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          )
        : Container(
            key: const ValueKey('notification-badge'),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: c.fgBrand,
              borderRadius: BorderRadius.circular(PRounded.full),
            ),
          );
    final Widget badge = ExcludeSemantics(child: pill);

    final Widget positioned = switch ((attach, size)) {
      // 아이콘 상자 안 — 위 1 · 오른쪽 1
      (PNotificationBadgeAttach.icon, PNotificationBadgeSize.small) =>
        Positioned(top: 1, right: 1, child: badge),
      // 왼쪽 아래 꼭짓점 = (아이콘 폭 − 8, 14) — 오른쪽 8 에서 제 폭만큼 오른쪽, 14 에서 제 높이만큼 위로
      (PNotificationBadgeAttach.icon, PNotificationBadgeSize.large) =>
        Positioned(
          top: 14,
          right: 8,
          child: FractionalTranslation(
            translation: const Offset(1, -1),
            child: badge,
          ),
        ),
      // 글 끝 + 2 · 줄 상자 위 끝
      (PNotificationBadgeAttach.text, _) => Positioned(
        top: 0,
        right: -2,
        child: FractionalTranslation(
          translation: const Offset(1, 0),
          child: badge,
        ),
      ),
    };

    return Stack(clipBehavior: Clip.none, children: [child, positioned]);
  }
}
