import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// specs/components/switch.md 미러.
///
/// **즉시 반영** 되는 binary 토글 (알림 ON/OFF, 다크모드 등). form submit 필요한
/// binary 입력은 [PCheckbox], 3+ 옵션은 [PRadio]/SegmentedControl.
///
/// iOS 스타일 — Track 44×24 + Thumb 20×20 흰색. unchecked=borderStrong /
/// checked=bgBrandSolid(web on=primary 솔리드, 다크 동일). thumb은 다크모드에서도 흰색 유지(`fgOnBrand` 고정).
class PSwitch extends StatelessWidget {
  const PSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;

  /// `null`이면 disabled.
  final ValueChanged<bool>? onChanged;

  final String? semanticLabel;

  static const double _trackW = 44;
  static const double _trackH = 24;
  static const double _thumbSize = 20;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disabled = onChanged == null;
    // web switch on=primary 솔리드(다크 동일) 정합 — bgBrand(다크=light)가 아닌 solid.
    final trackBg = value ? t.bgBrandSolid : t.borderStrong;

    final track = AnimatedContainer(
      duration: PMotion.fast,
      curve: PMotion.standard,
      width: _trackW,
      height: _trackH,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: disabled ? trackBg.withValues(alpha: 0.5) : trackBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedAlign(
        duration: PMotion.fast,
        curve: PMotion.standard,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: _thumbSize,
          height: _thumbSize,
          decoration: BoxDecoration(
            color: t.fgOnBrand,
            shape: BoxShape.circle,
            boxShadow: t.shadowMd,
          ),
        ),
      ),
    );

    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: !disabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => onChanged!(!value),
        child: SizedBox(height: 44, width: 56, child: Center(child: track)),
      ),
    );
  }
}

/// label-우 / switch-좌(우) row — 모바일 설정 페이지 표준 패턴.
///
/// `<label htmlFor>` 패턴 — row 전체 클릭으로 toggle. helper 텍스트는 label 아래.
class PSwitchTile extends StatelessWidget {
  const PSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disabled = onChanged == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : () => onChanged!(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.body,
                        fontWeight: PFontWeight.medium,
                        color: disabled ? t.fgDisabled : t.fgPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.caption,
                          fontWeight: PFontWeight.regular,
                          color: t.fgTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PSwitch(value: value, onChanged: onChanged, semanticLabel: title),
            ],
          ),
        ),
      ),
    );
  }
}
