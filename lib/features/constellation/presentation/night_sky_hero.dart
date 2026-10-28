import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

import 'package:groo_damda_app/features/constellation/presentation/sky_colors.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 밤하늘 히어로 — 오늘의 목표 별자리가 별빛만큼 점등.
/// 밤 장면이라 라이트/다크 공통 고정 다크 팔레트(웹 NightSkyHero 미러, 커스텀 hero 영역).
class NightSkyHero extends StatelessWidget {
  const NightSkyHero({super.key, required this.today, required this.doneToday});

  final ConstellationToday today;
  final int doneToday;

  static const _dimStars = <(double, double)>[
    (5, 18),
    (11, 72),
    (17, 30),
    (22, 84),
    (28, 12),
    (33, 52),
    (38, 88),
    (45, 8),
    (55, 90),
    (62, 10),
    (68, 86),
    (75, 20),
    (83, 78),
    (90, 14),
    (95, 52),
    (8, 48),
    (92, 82),
    (60, 30),
    (20, 58),
    (86, 44),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final lit = today.points < today.goal ? today.points : today.goal;
    final done = today.collected;
    final name = constellationName(today.constellation);

    final caption = done
        ? l.constHeroCaptionDone
        : (doneToday > 0 || today.memoPoints > 0)
        ? [
            l.constHeroCaptionProgress(doneToday),
            if (today.memoPoints > 0) l.constHeroCaptionMemo(today.memoPoints),
            l.constHeroCaptionRemain(today.goal - lit),
          ].join(' · ')
        : l.constHeroCaptionEmpty;

    // 글 · 아이콘 색은 하나다 — 불투명도로 흐리지 않는다(I-11 8). 장식(달빛 · 잔별 · 별자리 그림)만 투명도를 남긴다.
    final ink = c.fgNeutralInverted;
    final nameStyle = PTypography.t8.copyWith(
      color: ink,
      fontWeight: FontWeight.w700,
    );
    final countStyle = PTypography.t4.copyWith(
      color: ink,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final smallStyle = PTypography.t3.copyWith(color: ink);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l.constHeroLabel(name, lit, today.goal),
      child: Container(
        key: const ValueKey('night-sky-hero'),
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(minHeight: 168),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PRounded.r4),
          gradient: skyGradient(c, three: true),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, box) => _Decor(
                    size: box.biggest,
                    today: today,
                    lit: lit,
                    done: done,
                  ),
                ),
              ),
            ),
            Positioned(
              top: PSpacing.x4,
              right: PSpacing.x4,
              child: ExcludeSemantics(
                child: Icon(LucideIcons.moon, size: PSpacing.x5, color: ink),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(PSpacing.x5),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 168 - 2 * PSpacing.x5,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.constHeroTodayTarget, style: smallStyle),
                      const SizedBox(height: PSpacing.x0_5),
                      Padding(
                        padding: const EdgeInsets.only(right: PSpacing.x6),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: keepAll(
                                  done ? l.constHeroCollectedBang(name) : name,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' ${l.constHeroStarlightCount(lit, today.goal).replaceAll(' ', '\u00A0')}',
                                style: countStyle,
                              ),
                            ],
                          ),
                          style: nameStyle,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: PSpacing.x6),
                      Text(keepAll(caption), style: smallStyle),
                      const SizedBox(height: PSpacing.x2),
                      Wrap(
                        spacing: PSpacing.x3,
                        runSpacing: PSpacing.x1_5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Meta(
                            icon: LucideIcons.sparkles,
                            text: l.constHeroStreak(today.streak),
                            style: smallStyle.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _Meta(
                            icon: LucideIcons.cloud,
                            text: l.constHeroGuardInfo(today.guardCount),
                            style: smallStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 아이콘 14 + 사이 4 + 글 — 연속 관측 · 보호 한 조각.
class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.style});
  final IconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // 글이 두 줄이 되어도 아이콘은 첫 줄에 맞춘다(줄 높이 18 − 아이콘 14 의 절반 2).
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: PSpacing.x0_5),
          child: Icon(icon, size: PSpacing.x3_5, color: style.color),
        ),
        const SizedBox(width: PSpacing.x1),
        Flexible(child: Text(keepAll(text), style: style)),
      ],
    );
  }
}

/// 장식 층 — 달빛 · 잔별 · 별자리 그림(보조 기술에 숨김, 투명도 남김). 별자리 그림은 글 아래 배경이다.
class _Decor extends StatelessWidget {
  const _Decor({
    required this.size,
    required this.today,
    required this.lit,
    required this.done,
  });
  final Size size;
  final ConstellationToday today;
  final int lit;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          top: -40,
          right: -20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [skyInk(c, 0x29), Colors.transparent],
                stops: const [0, 0.65],
              ),
            ),
          ),
        ),
        for (var i = 0; i < NightSkyHero._dimStars.length; i++)
          Positioned(
            left: size.width * NightSkyHero._dimStars[i].$1 / 100,
            top: size.height * NightSkyHero._dimStars[i].$2 / 100,
            child: Container(
              width: i % 3 == 0 ? 2.5 : 1.5,
              height: i % 3 == 0 ? 2.5 : 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: skyInk(c, 0x52),
              ),
            ),
          ),
        Positioned(
          top: size.height * 0.10,
          bottom: size.height * 0.24,
          left: 0,
          right: 0,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.45,
              child: CustomPaint(
                painter: _HeroFigurePainter(
                  colors: c,
                  map: today.constellation.starMap,
                  lit: lit,
                  done: done,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 히어로 중앙 figure — 점등 별(글로우)과 점선/실선 연결. 박스에 늘림(preserveAspectRatio none 정합).
class _HeroFigurePainter extends CustomPainter {
  _HeroFigurePainter({
    required this.map,
    required this.lit,
    required this.done,
    required this.colors,
  });

  final PColors colors;

  final StarMapData map;
  final int lit;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 100;
    Offset at(List<double> p) => Offset(p[0] * sx, p[1] * sy);

    final lineColor = done ? skyInk(colors, 0xD9) : skyInk(colors, 0x80);
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (final e in map.edges) {
      if (e.length < 2) continue;
      final a = e[0];
      final b = e[1];
      if (a >= lit || b >= lit || a >= map.pts.length || b >= map.pts.length) {
        continue;
      }
      if (done) {
        canvas.drawLine(at(map.pts[a]), at(map.pts[b]), linePaint);
      } else {
        _drawDashedLine(canvas, at(map.pts[a]), at(map.pts[b]), linePaint);
      }
    }

    final glowPaint = Paint()
      ..color = skyInk(colors, done ? 0xCC : 0x8C)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, done ? 7 : 4.5);
    final onPaint = Paint()..color = skyInk(colors, 0xFF);
    final offPaint = Paint()
      ..color = skyInk(colors, 0x73)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 별 수 적응형 점 크기 — 밀집 별자리(15별 초과) 겹침 방지
    final dense = map.pts.length > 15;
    final rOn = dense ? 2.5 : 3.5;
    final rOff = dense ? 1.8 : 2.5;
    for (var i = 0; i < map.pts.length; i++) {
      final c = at(map.pts[i]);
      if (i < lit) {
        canvas.drawCircle(c, rOn * 1.7, glowPaint);
        canvas.drawCircle(c, rOn, onPaint);
      } else {
        canvas.drawCircle(c, rOff, offPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 3.0;
    const gap = 4.0;
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final end = (d + dash) < total ? d + dash : total;
      canvas.drawLine(a + dir * d, a + dir * end, paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_HeroFigurePainter old) =>
      old.map != map ||
      old.lit != lit ||
      old.done != done ||
      old.colors != colors;
}
