import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// specs/components/checkbox.md 미러.
///
/// 다중 선택 또는 단일 confirm — 즉시 효과 on/off 는 [PSwitch], 그룹 단일 선택은
/// [PRadio]. sm/md/lg 3 sizes × 6 states (default · checked · indeterminate ·
/// focused · disabled · error). control 자체는 16/18/20 — 모바일 hit area는
/// label까지 wrap 해 row clickable로 만들어 44+ 확보.
enum PCheckboxSize { sm, md, lg }

class PCheckbox extends StatelessWidget {
  const PCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = PCheckboxSize.md,
    this.dense = false,
    this.tristate = false,
    this.error = false,
    this.label,
    this.helperText,
    this.semanticLabel,
  });

  /// `null`이면 indeterminate (tristate=true 필요).
  final bool? value;

  /// `null`이면 disabled.
  final ValueChanged<bool?>? onChanged;

  final PCheckboxSize size;

  /// 행 전체가 탭 영역(InkWell 리스트 행 등)일 때 자체 44 히트박스 생략 —
  /// control 크기만 차지. spec "row clickable로 44+ 확보" 패턴의 행 안 배치용.
  final bool dense;

  /// indeterminate 상태 허용 (parent-child 그룹).
  final bool tristate;

  /// `aria-invalid` — borderDanger 1px + danger ring.
  final bool error;

  /// 우측 외부 라벨. 없으면 control 단독 (semanticLabel 필수).
  final String? label;

  /// 옵션 helper / error text — control 아래.
  final String? helperText;

  /// label 없을 때 스크린리더용.
  final String? semanticLabel;

  double get _boxSize => switch (size) {
    PCheckboxSize.sm => 16,
    PCheckboxSize.md => 18,
    PCheckboxSize.lg => 20,
  };

  double get _iconSize => switch (size) {
    PCheckboxSize.sm => 10,
    PCheckboxSize.md => 12,
    PCheckboxSize.lg => 14,
  };

  double get _dashHeight => 2;

  double get _dashWidth => switch (size) {
    PCheckboxSize.sm => 8,
    PCheckboxSize.md => 10,
    PCheckboxSize.lg => 12,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disabled = onChanged == null;
    final indeterminate = tristate && value == null;
    final checked = value == true;
    final filled = checked || indeterminate;

    final (Color bg, Color border) = switch ((disabled, error, filled)) {
      (true, _, true) => (
        t.bgBrandSolid.withValues(alpha: 0.5),
        t.bgBrandSolid.withValues(alpha: 0.5),
      ),
      (true, _, false) => (t.bgMuted, t.borderDefault),
      (_, true, _) => (t.bgSurface, t.statusDanger),
      // 채움·테두리는 다크에서도 primary 고정(bgBrandSolid) — web checkbox bg-primary 정합.
      (false, false, true) => (t.bgBrandSolid, t.bgBrandSolid),
      (false, false, false) => (t.bgSurface, t.borderStrong),
    };

    Widget control = AnimatedContainer(
      duration: PMotion.fast,
      curve: PMotion.standard,
      width: _boxSize,
      height: _boxSize,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PRadius.brSm,
        border: Border.all(color: border),
      ),
      child: Center(
        child: indeterminate
            ? Container(
                width: _dashWidth,
                height: _dashHeight,
                color: t.fgOnBrand.withValues(alpha: disabled ? 0.5 : 1),
              )
            : (checked
                  ? Icon(
                      Icons.check_rounded,
                      size: _iconSize,
                      weight: 700,
                      color: t.fgOnBrand.withValues(alpha: disabled ? 0.5 : 1),
                    )
                  : const SizedBox.shrink()),
      ),
    );

    if (label == null) {
      // 단독 control — semanticLabel 필수.
      control = Semantics(
        label: semanticLabel,
        checked: checked,
        mixed: indeterminate,
        enabled: !disabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled
              ? null
              : () => onChanged!(indeterminate ? false : !checked),
          child: dense
              ? control
              : SizedBox(width: 44, height: 44, child: Center(child: control)),
        ),
      );
      return helperText == null
          ? control
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                control,
                _HelperText(helperText!, error: error),
              ],
            );
    }

    // label 포함 row — label까지 hit area로 묶어 44+ 확보.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled
                ? null
                : () => onChanged!(indeterminate ? false : !checked),
            borderRadius: PRadius.brSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  control,
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label!,
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.body,
                        fontWeight: PFontWeight.medium,
                        color: disabled ? t.fgDisabled : t.fgPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (helperText != null) _HelperText(helperText!, error: error),
      ],
    );
  }
}

class _HelperText extends StatelessWidget {
  const _HelperText(this.text, {required this.error});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 26),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: PTypo.sans,
          fontSize: PFontSize.caption,
          fontWeight: PFontWeight.regular,
          color: error ? t.statusDanger : t.fgTertiary,
        ),
      ),
    );
  }
}
