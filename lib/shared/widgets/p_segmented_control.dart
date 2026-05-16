import 'package:flutter/material.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// Segmented control — 2~5개 mutually exclusive option 선택.
///
/// desk-app 7개 `_Seg`/`_PeriodSeg`/`_Segment` private 변종을 단일 인터페이스로
/// 통합. porest-design `specs/components/toggle-group.md` spec과 정합 의도이나,
/// preview/CSS는 web만 정의되어 있어 Flutter 위젯은 동일 시각을 구현.
///
/// 시각:
/// - 외곽: bgMuted + radius
/// - active item: bgSurface + 선택적 shadow + bold text
/// - inactive item: transparent + fgTertiary medium text
///
/// 사용:
/// ```dart
/// PSegmentedControl<_Period>(
///   value: _period,
///   items: const [
///     PSegmentItem(_Period.day, '일'),
///     PSegmentItem(_Period.week, '주'),
///     PSegmentItem(_Period.month, '월'),
///   ],
///   onChanged: (p) => setState(() => _period = p),
/// )
/// ```
///
/// 각 item이 자체 onTap을 가질 수 있음 — date picker 같은 "custom action"
/// 패턴 (예: stats `_PeriodSeg`의 사용자 지정 클릭 시 BottomSheet 오픈).
enum PSegmentActive { surface, brand }

enum PSegmentSize { sm, md }

class PSegmentItem<T> {
  const PSegmentItem(this.value, this.label, {this.onTap});
  final T value;
  final String label;

  /// null이면 [PSegmentedControl.onChanged]가 호출됨.
  /// 지정 시 active 여부에 무관하게 이 콜백이 우선.
  final VoidCallback? onTap;
}

class PSegmentedControl<T> extends StatelessWidget {
  const PSegmentedControl({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.expand = false,
    this.elevated = false,
    this.activeVariant = PSegmentActive.surface,
    this.size = PSegmentSize.md,
  });

  final T value;
  final List<PSegmentItem<T>> items;
  final ValueChanged<T> onChanged;

  /// true면 각 item이 Expanded로 가용 폭 균등 분할. false면 intrinsic.
  final bool expand;

  /// active item에 shadow를 추가해 elevation 강조.
  final bool elevated;

  /// active item 시각 — surface(기본, 흰 채움) / brand(brand 채움).
  final PSegmentActive activeVariant;

  final PSegmentSize size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (final item in items)
          if (expand)
            Expanded(child: _buildItem(t, item))
          else
            _buildItem(t, item),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.bgMuted,
        borderRadius: PRadius.brMd,
      ),
      child: row,
    );
  }

  Widget _buildItem(PorestTokens t, PSegmentItem<T> item) {
    final active = item.value == value;
    final (activeBg, activeFg) = switch (activeVariant) {
      PSegmentActive.surface => (t.bgSurface, t.fgPrimary),
      PSegmentActive.brand => (t.bgBrand, t.fgOnBrand),
    };
    final padding = switch (size) {
      PSegmentSize.sm => const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      PSegmentSize.md => const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    };
    final textStyle = switch (size) {
      PSegmentSize.sm => PTypo.micro,
      PSegmentSize.md => PTypo.bodySm,
    };
    return GestureDetector(
      onTap: item.onTap ?? () => onChanged(item.value),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.transparent,
          borderRadius: PRadius.brSm,
          boxShadow: active && elevated
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          item.label,
          textAlign: TextAlign.center,
          style: textStyle.copyWith(
            color: active ? activeFg : t.fgTertiary,
            fontWeight: active ? PFontWeight.bold : PFontWeight.medium,
          ),
        ),
      ),
    );
  }
}
