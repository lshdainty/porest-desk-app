import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// front `sonner` toast 의 모바일 등가 — ScaffoldMessenger 위에 한 겹 wrap.
///
/// 4개 톤: success / warning / danger / info / plain.
enum PToastTone { plain, success, warning, danger, info }

class PToast {
  static void show(
    BuildContext context, {
    required String message,
    PToastTone tone = PToastTone.plain,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final t = context.tokens;
    Color bg;
    Color fg;
    IconData icon;
    switch (tone) {
      case PToastTone.success:
        bg = t.statusSuccessSubtle;
        fg = t.statusSuccessFg;
        icon = LucideIcons.checkCircle;
        break;
      case PToastTone.warning:
        bg = t.statusWarningSubtle;
        fg = t.statusWarningFg;
        icon = LucideIcons.alertTriangle;
        break;
      case PToastTone.danger:
        bg = t.statusDangerSubtle;
        fg = t.statusDangerFg;
        icon = LucideIcons.xCircle;
        break;
      case PToastTone.info:
        bg = t.statusInfoSubtle;
        fg = t.statusInfoFg;
        icon = LucideIcons.info;
        break;
      case PToastTone.plain:
        bg = t.bgSurface;
        fg = t.fgPrimary;
        icon = LucideIcons.bell;
        break;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: PRadius.brMd,
            border: Border.all(color: t.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: PTypo.bodySm.copyWith(
                    color: fg,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  child: Text(
                    actionLabel,
                    style: PTypo.bodySm.copyWith(
                      color: fg,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, tone: PToastTone.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, tone: PToastTone.danger);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, tone: PToastTone.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message, tone: PToastTone.info);
}
