import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// specs/components/alert.md 미러.
///
/// 페이지 안 고정 inline 메시지 — toast([showPSnackBar])는 floating, AlertDialog
/// 는 modal confirm. Alert은 컨텍스트 메시지(약관 변경 안내·결제 실패 등).
///
/// 5 variants — default/info/success/warning/error. semantic variants 는
/// border-left 4px + 8% color-mix bg + variant icon.
enum PAlertVariant { defaultPlain, info, success, warning, error }

class PAlert extends StatelessWidget {
  const PAlert({
    super.key,
    required this.title,
    this.description,
    this.variant = PAlertVariant.info,
    this.icon,
    this.onDismiss,
    this.action,
  });

  final String title;
  final String? description;
  final PAlertVariant variant;

  /// 미지정 시 variant 기본 아이콘 자동 선택. default variant는 아이콘 없음.
  final IconData? icon;

  /// dismissable — 우측 close button 노출 + 콜백.
  final VoidCallback? onDismiss;

  /// 우측 우선순위 액션 (선택). dismiss와 동시 사용 시 액션 우측 + close 더 우측.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final (Color accent, Color bg, IconData defaultIcon) = switch (variant) {
      PAlertVariant.defaultPlain =>
        (t.borderDefault, t.bgSurface, LucideIcons.info),
      PAlertVariant.info => (t.statusInfo, t.statusInfoSubtle, LucideIcons.info),
      PAlertVariant.success =>
        (t.statusSuccess, t.statusSuccessSubtle, LucideIcons.checkCircle2),
      PAlertVariant.warning => (
          t.statusWarning,
          t.statusWarningSubtle,
          LucideIcons.alertTriangle
        ),
      PAlertVariant.error =>
        (t.statusDanger, t.statusDangerSubtle, LucideIcons.alertOctagon),
    };
    final hasAccent = variant != PAlertVariant.defaultPlain;
    final iconData = icon ?? defaultIcon;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PRadius.brSm,
        border: hasAccent
            ? Border(left: BorderSide(color: accent, width: 4))
            : Border.all(color: t.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAccent || icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(iconData, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: PFontSize.bodyMd,
                    fontWeight: PFontWeight.semi,
                    color: t.fgPrimary,
                    height: PLineHeight.snug,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: PFontSize.bodySm,
                      fontWeight: PFontWeight.regular,
                      color: t.fgSecondary,
                      height: PLineHeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                splashRadius: 16,
                tooltip: l.actionClose,
                icon: Icon(LucideIcons.x, color: t.fgTertiary),
                onPressed: onDismiss,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
