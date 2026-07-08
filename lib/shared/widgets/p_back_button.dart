import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// 공통 뒤로가기 버튼 — AppBar leading 표준.
///
/// chevron-left(`<`, size 22) + 좌측 8 inset + 버튼 padding 6.
/// 글리프가 화면 좌측에서 14px(8+6), 타이틀과 10px 간격이 되도록 web 설정 섹션
/// 헤더(계좌·카드 관리)와 px 단위로 통일.
///
/// AppBar 에서는 `leadingWidth: PBackButton.leadingWidth(46), titleSpacing: 0`
/// 과 함께 쓴다 — titleSpacing 0 이라 타이틀은 leadingWidth(46)에서 시작,
/// 글리프 오른쪽(36)과 10px 간격.
class PBackButton extends StatelessWidget {
  const PBackButton({super.key, this.onPressed, this.tooltip});

  /// AppBar leading 표준 폭 — 이 버튼과 함께 AppBar 에 지정.
  /// 46 = 좌측 inset 8 + 버튼 34(22+pad12) + 타이틀 간격용 여백 4.
  static const double leadingWidth = 46;

  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final btn = Padding(
      // 좌측 8 inset — 글리프가 화면 좌측에서 14px(8 + 버튼 padding 6) 떨어지게 (web 헤더 정합).
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        borderRadius: PRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(LucideIcons.chevronLeft, size: 22, color: t.fgPrimary),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: tooltip ?? l.actionBack,
      child: tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn,
    );
  }
}
