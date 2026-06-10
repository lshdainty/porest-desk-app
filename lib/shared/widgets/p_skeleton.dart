import 'package:flutter/material.dart';

import '../../app/theme/motion.dart';
import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';

/// specs/components/skeleton.md 미러.
///
/// 데이터 로딩 중 콘텐츠 자리를 보존하는 placeholder 박스. shape은 사용처가
/// `width`/`height`/`borderRadius`로 결정. animation은 [PSkeletonAnimation.pulse]
/// (opacity 깜빡임, 기본) 또는 [PSkeletonAnimation.shimmer](좌→우 sweep).
///
/// 같은 페이지엔 한 가지 animation 통일 — 섞으면 시각 noise.
enum PSkeletonAnimation { pulse, shimmer }

class PSkeleton extends StatefulWidget {
  const PSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = PRadius.brSm,
    this.animation = PSkeletonAnimation.pulse,
  });

  /// 라인 placeholder: `PSkeleton.line(width: 120)` — height 16 (text-body line).
  const PSkeleton.line({super.key, this.width, double this.height = 16})
      : borderRadius = PRadius.brSm,
        animation = PSkeletonAnimation.pulse;

  /// avatar placeholder: `PSkeleton.circle(size: 40)`.
  PSkeleton.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = BorderRadius.circular(size),
        animation = PSkeletonAnimation.pulse;

  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final PSkeletonAnimation animation;

  @override
  State<PSkeleton> createState() => _PSkeletonState();
}

class _PSkeletonState extends State<PSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animation == PSkeletonAnimation.pulse
          ? const Duration(milliseconds: 2000)
          : const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final t = context.tokens;
    if (reducedMotion) {
      return _box(t);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (widget.animation == PSkeletonAnimation.pulse) {
          final v = _controller.value;
          final opacity = 0.5 + 0.5 * (v < 0.5 ? 1 - v * 2 : (v - 0.5) * 2);
          return Opacity(opacity: opacity, child: _box(t));
        }
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            children: [
              _box(t),
              Positioned.fill(
                child: FractionalTranslation(
                  translation: Offset(-1 + _controller.value * 2, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          t.bgBrand.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _box(PorestTokens t) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: t.bgMuted,
          borderRadius: widget.borderRadius,
        ),
      );
}

/// 텍스트 line 여러 줄 placeholder — gap 사이 4px (line-height 친화).
class PSkeletonLines extends StatelessWidget {
  const PSkeletonLines({
    super.key,
    required this.lines,
    this.lineHeight = 12,
    this.lastLineWidth = 0.6,
  });

  final int lines;
  final double lineHeight;
  final double lastLineWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < lines; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: i == lines - 1 ? lastLineWidth : 1.0,
            child: PSkeleton.line(height: lineHeight),
          ),
        ],
      ],
    );
  }
}

/// 모션 토큰 - shimmer 가 fast 가 아닌 loop 사용을 위한 명시 인용 (분석기 hint).
// ignore: unused_element
const _kShimmerDuration = PMotion.base;

/// desk-front `skeleton-loaders.tsx` 미러 — list 행 placeholder.
/// avatar(40 round) + 2 line (3/4 + 1/2) 패턴.
class PListSkeleton extends StatelessWidget {
  const PListSkeleton({
    super.key,
    this.rows = 5,
    this.showAvatar = false,
    this.gap = 12,
  });

  final int rows;
  final bool showAvatar;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < rows; i++) ...[
          if (i > 0) SizedBox(height: gap),
          Row(
            children: [
              if (showAvatar) ...[
                PSkeleton.circle(size: 36),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.75,
                        child: PSkeleton.line(height: 14)),
                    const SizedBox(height: 6),
                    FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.5,
                        child: PSkeleton.line(height: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// desk-front `CardSkeleton` 미러 — card 콘텐츠 placeholder (title + N lines).
class PCardSkeleton extends StatelessWidget {
  const PCardSkeleton({
    super.key,
    this.lines = 3,
    this.padding = const EdgeInsets.all(16),
  });

  final int lines;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: padding,
      // 실제 PCard 는 shadow variant(border 없음) — 스켈레톤도 동일하게.
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        boxShadow: t.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.66,
              child: PSkeleton.line(height: 18)),
          for (int i = 0; i < lines; i++) ...[
            const SizedBox(height: 12),
            FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: i == lines - 1 ? 0.5 : 1.0,
                child: PSkeleton.line(height: 14)),
          ],
        ],
      ),
    );
  }
}

/// desk-front `ChartSkeleton` 미러 — header + N bars (랜덤 높이 30~100%).
class PChartSkeleton extends StatelessWidget {
  const PChartSkeleton({
    super.key,
    this.bars = 7,
    this.barHeights = const [50, 80, 65, 95, 45, 75, 60],
  });

  final int bars;

  /// 0~100 % 높이 percent. 기본은 결정적 시퀀스 (사용처 매번 다른 시각 피함).
  final List<double> barHeights;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      // 실제 PCard 는 shadow variant(border 없음) — 스켈레톤도 동일하게.
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        boxShadow: t.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PSkeleton.line(width: 128, height: 18),
              PSkeleton.line(width: 80, height: 14),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < bars; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor:
                          (barHeights[i % barHeights.length] / 100).clamp(0.1, 1.0),
                      child: PSkeleton(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
