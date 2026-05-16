import 'package:flutter/material.dart';

import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// 빈 상태 표시 — 아이콘 + 메시지 (+ 보조 메시지).
///
/// 일관된 spacing/색상/타이포로 통일된 empty state UI.
/// `ListView` 등 스크롤 가능한 컨테이너 안에 넣어 RefreshIndicator 와 함께 사용.
///
/// 사용 예:
/// ```dart
/// PEmptyState(
///   icon: LucideIcons.bell,
///   message: '알림이 없습니다',
/// )
/// ```
class PEmptyState extends StatelessWidget {
  const PEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subMessage,
    this.action,
    this.padding = const EdgeInsets.all(PSpace.x32),
    this.iconSize = 48,
  });

  final IconData icon;
  final String message;
  final String? subMessage;

  /// 보조 액션 버튼 (선택). [subMessage] 아래 12px gap 후 렌더.
  final Widget? action;
  final EdgeInsets padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: t.fgDisabled),
          const SizedBox(height: PSpace.x12),
          Text(
            message,
            style: PTypo.body.copyWith(color: t.fgTertiary),
            textAlign: TextAlign.center,
          ),
          if (subMessage != null) ...[
            const SizedBox(height: PSpace.x4),
            Text(
              subMessage!,
              style: PTypo.caption.copyWith(color: t.fgTertiary),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: PSpace.x12),
            action!,
          ],
        ],
      ),
    );
  }
}
