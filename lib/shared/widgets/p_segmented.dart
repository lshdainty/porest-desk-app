import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// front shadcn `<ToggleGroup variant="segmented">` 미러.
///
/// 기간 선택, 거래종류 등 — track(`bgSunken`) + active(`bgBrandSolid`) 패턴.
/// 사용 예:
/// ```dart
/// PSegmented<FilterPeriod>(
///   value: _period,
///   onChanged: (v) => setState(() => _period = v),
///   options: const [
///     PSegmentOption(value: FilterPeriod.week, label: '이번 주'),
///     ...
///   ],
/// )
/// ```
/// 활성 아이템 톤 — 웹 ToggleGroup variant 정합.
/// - [solid]: primary 채움 + on-brand 글씨(강조. 구독 월/연 등)
/// - [subtle]: surface-input 채움 + primary 글씨(절제. 데이터 내보내기/가져오기 등)
enum PSegmentedVariant { solid, subtle }

class PSegmentOption<T> {
  const PSegmentOption({required this.value, required this.label});
  final T value;
  final String label;
}

class PSegmented<T> extends StatelessWidget {
  const PSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.variant = PSegmentedVariant.solid,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<PSegmentOption<T>> options;

  /// 활성 톤 — 기본 solid(primary 채움). subtle 은 웹 segmented-subtle 미러.
  final PSegmentedVariant variant;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // ToggleGroup variant="segmented" spec (desk-front .p-seg):
    // wrapper: bg-sunken + border-default + radius-md + p-0.5 (2px)
    // item: h-7 (28) + caption(12/600) + active=bg-brand
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.bgSunken,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderDefault),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.value),
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    // active 채움은 bgBrandSolid(다크에서도 primary 고정) — bgBrand 는 다크에서
                    // primary-light 로 밝아짐. 웹 ToggleGroup segmented(active=primary) 정합.
                    color: o.value == value
                        ? (variant == PSegmentedVariant.subtle
                            ? t.bgMuted
                            : t.bgBrandSolid)
                        : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  alignment: Alignment.center,
                  child: Text(o.label,
                      style: PTypo.caption.copyWith(
                          color: o.value == value
                              ? (variant == PSegmentedVariant.subtle
                                  ? t.fgPrimary
                                  : t.fgOnBrand)
                              : t.fgSecondary,
                          fontWeight: PFontWeight.semi)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
