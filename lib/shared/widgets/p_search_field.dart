import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// 공용 검색바 — web `Input search` 변형(.top__search) 1:1 canonical.
///
/// 스펙(전 검색바 통일 SoT):
/// - rounded radius-md, filled `bg-muted`, resting 테두리 없음(transparent)
/// - focus 시: 테두리 = border-focus(코발트, 1.5px) + bg = surface (ring 없음)
/// - prefix search 아이콘(16, fg-tertiary), hint = label-sm(13) fg-tertiary
/// - height ≈ web h-9(36) — isDense + compact padding
///
/// header 검색바 / 전체 메뉴 검색 / 화면 내 검색 등 앱의 모든 검색 input 은
/// 반드시 이 위젯을 사용(테두리 렌더 통일).
class PSearchField extends StatefulWidget {
  const PSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.trailing,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;

  /// 우측 위젯(clear 버튼 등) — 선택.
  final Widget? trailing;

  @override
  State<PSearchField> createState() => _PSearchFieldState();
}

class _PSearchFieldState extends State<PSearchField> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    // focus 시 bg muted→surface + 코발트 테두리 swap — rebuild 필요.
    _node.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final focused = _node.hasFocus;
    // web Input h-9(36px) 고정 — TextField 자체 최소높이로 두꺼워지지 않게 강제
    return SizedBox(
      height: 36,
      child: TextField(
      controller: widget.controller,
      focusNode: _node,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(
        fontFamily: PTypo.sans,
        fontSize: PFontSize.bodySm,
        color: t.fgPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        hintStyle: TextStyle(
          fontFamily: PTypo.sans,
          fontSize: PFontSize.bodySm,
          color: t.fgTertiary,
        ),
        prefixIcon: Icon(LucideIcons.search, size: 16, color: t.fgTertiary),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        suffixIcon: widget.trailing,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        filled: true,
        // resting = bg-muted, focus = bg-surface (web 정합)
        fillColor: focused ? t.bgSurface : t.bgMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        // resting = 테두리 없음, focus = 코발트(border-focus) — web .top__search 정합
        border: OutlineInputBorder(
          borderRadius: PRadius.brMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PRadius.brMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PRadius.brMd,
          borderSide: BorderSide(color: t.borderFocus, width: 1.5),
        ),
      ),
      ),
    );
  }
}
