import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/button/p_button.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/notification_badge/p_notification_badge.dart';

/// 카탈로그(/dev/ds) — 점 · 숫자 × 아이콘 · 글, 숫자 1 · 12 · 99+(128), 0 이면 없다. 개수를 바꿔 본다.
class NotificationBadgeDemo extends StatefulWidget {
  const NotificationBadgeDemo({super.key});

  @override
  State<NotificationBadgeDemo> createState() => _NotificationBadgeDemoState();
}

class _NotificationBadgeDemoState extends State<NotificationBadgeDemo> {
  static const _steps = [0, 1, 3, 12, 99, 128];
  int _step = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget bell([double size = 24]) =>
        Icon(LucideIcons.bell, size: size, color: c.fgNeutral);
    Widget label(String text) =>
        Text(text, style: PTypography.t4.copyWith(color: c.fgNeutral));
    final count = _steps[_step];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: 'small — 점 6, 새 것이 있는지만(기본)',
          children: [
            DemoRow(
              label: '아이콘 24 · 20 — 아이콘 상자 안 위 1 · 오른쪽 1',
              children: [
                PNotificationBadge(child: bell()),
                PNotificationBadge(child: bell(20)),
              ],
            ),
            DemoRow(
              label: '글 — 글 끝 + 2 · 줄 위 끝',
              children: [
                PNotificationBadge(
                  attach: PNotificationBadgeAttach.text,
                  child: label('공지'),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: 'large — 숫자 18, 몇 개인지가 판단에 필요할 때',
          children: [
            DemoRow(
              label: '아이콘 — 왼쪽 아래 꼭짓점 (아이콘 폭 − 8, 14), 길수록 오른쪽으로',
              children: [
                for (final n in [1, 12, 128])
                  Padding(
                    // 위 · 오른쪽으로 튀어나온 만큼 띄운다 — 자리를 차지하지 않는다
                    padding: const EdgeInsets.only(right: PSpacing.x4),
                    child: PNotificationBadge(
                      size: PNotificationBadgeSize.large,
                      count: n,
                      child: bell(),
                    ),
                  ),
              ],
            ),
            DemoRow(
              label: '글',
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: PSpacing.x6),
                  child: PNotificationBadge(
                    size: PNotificationBadgeSize.large,
                    attach: PNotificationBadgeAttach.text,
                    count: 3,
                    child: label('승인 내역'),
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '개수 — 0 이면 사라지고 100 이상이면 "99+"',
          children: [
            DemoRow(
              label: 'count $count',
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: PSpacing.x4),
                  child: PNotificationBadge(
                    size: PNotificationBadgeSize.large,
                    count: count,
                    child: bell(),
                  ),
                ),
                PButton(
                  label: '개수 바꾸기',
                  variant: PButtonVariant.neutralWeak,
                  size: PButtonSize.small,
                  onPressed: () =>
                      setState(() => _step = (_step + 1) % _steps.length),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
