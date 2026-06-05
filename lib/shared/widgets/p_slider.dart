import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// specs/components/slider.md 미러.
///
/// 연속/단계적 숫자 값 선택 — 볼륨/밝기/가격 범위. Track 4px `bgMuted` +
/// fill `bgBrandSolid`(web fill=primary 솔리드, 다크 동일) + thumb 16×16 흰색(`fgOnBrand` 고정) + 2px primary 외곽선.
/// 다크 모드에서도 thumb은 흰색 유지.
class PSlider extends StatelessWidget {
  const PSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.semanticLabel,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: t.bgBrandSolid,
        inactiveTrackColor: t.bgMuted,
        thumbColor: t.fgOnBrand,
        overlayColor: t.bgBrandSolid.withValues(alpha: 0.12),
        thumbShape: _PrimaryRingThumb(borderColor: t.bgBrandSolid),
        // 좌우 인셋 없는 full-width 트랙 — web slider(컨테이너 전체 폭) 정합.
        // 기본 RoundedRect 는 thumb 반경만큼 양옆을 비워 눈금 라벨과 어긋난다.
        trackShape: const _FullWidthTrackShape(),
      ),
      child: Slider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        label: semanticLabel,
      ),
    );
  }
}

/// 좌우 인셋 없이 위젯 전체 폭을 쓰는 트랙 — web slider 정합.
class _FullWidthTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }
}

class _PrimaryRingThumb extends SliderComponentShape {
  const _PrimaryRingThumb({required this.borderColor});
  final Color borderColor;

  static const double _radius = 8; // 16 / 2

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final fillPaint = Paint()
      ..color = sliderTheme.thumbColor ?? const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, _radius, fillPaint);
    canvas.drawCircle(center, _radius - 1, ringPaint);
  }
}

/// range mode — two-thumb. Flutter `RangeSlider` 래퍼.
class PRangeSlider extends StatelessWidget {
  const PRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
  });

  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;
  final double min;
  final double max;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: t.bgBrandSolid,
        inactiveTrackColor: t.bgMuted,
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 8,
        ),
        thumbColor: t.fgOnBrand,
        overlayColor: t.bgBrandSolid.withValues(alpha: 0.12),
      ),
      child: RangeSlider(
        values: values,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
      ),
    );
  }
}
