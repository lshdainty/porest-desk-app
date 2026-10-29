import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

import 'package:groo_damda_app/features/constellation/presentation/sky_colors.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 밤하늘 히어로 — 오늘의 목표 별자리가 별빛만큼 점등.
/// 하늘은 역할 색 그라디언트(01-033 C — 라이트는 짙은 하늘, 다크는 밝은 하늘), 글 · 아이콘은 `fg-neutral-inverted` 하나(웹 NightSkyHero 와 같다).
/// 글은 흐르는 차례로 쌓아 겹치지 않고, 장식(달빛 · 잔별 · 별자리 그림)만 투명도를 남긴다.
class NightSkyHero extends StatelessWidget {
  const NightSkyHero({
    super.key,
    required this.today,
    required this.doneToday,
    this.onOpen,
  });

  final ConstellationToday today;
  final int doneToday;

  /// 카드 전체 · 썸네일을 누르면 — 오늘의 목표 별자리 상세 시트(P2, 10-29 사용자 결정).
  final VoidCallback? onOpen;

  /// 오른쪽 위 별자리 썸네일 한 변.
  static const double thumbSize = 88;

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
      button: onOpen != null,
      onTap: onOpen,
      label: l.constHeroLabel(name, lit, today.goal),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
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
                    builder: (context, box) => _Decor(size: box.biggest),
                  ),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.constHeroTodayTarget,
                                    style: smallStyle,
                                  ),
                                  const SizedBox(height: PSpacing.x0_5),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: keepAll(
                                            done
                                                ? l.constHeroCollectedBang(name)
                                                : name,
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
                                ],
                              ),
                            ),
                            const SizedBox(width: PSpacing.x3),
                            // 별자리 썸네일 88 — 켠 별 밝게 · 남은 별 고리, 오른쪽 위(안 여백에서 −4). 보조 기술에는 숨긴다(카드 이름이 읽는다).
                            Transform.translate(
                              offset: const Offset(PSpacing.x1, -PSpacing.x1),
                              child: ExcludeSemantics(
                                child: SizedBox(
                                  key: const ValueKey('night-sky-thumb'),
                                  width: thumbSize,
                                  height: thumbSize,
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
                        ),
                        const Spacer(),
                        const SizedBox(height: PSpacing.x4),
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

/// 장식 층 — 달빛 · 잔별(보조 기술에 숨김, 투명도 남김). 별자리 그림은 배경이 아니라 오른쪽 위 썸네일이다.
class _Decor extends StatelessWidget {
  const _Decor({required this.size});
  final Size size;

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
      ],
    );
  }
}

/// 히어로 썸네일 figure — 점등 별(글로우)과 점선/실선 연결, 꺼진 별은 고리. 정비율.
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
    // 썸네일은 정비율 — 0~100 좌표를 짧은 변에 맞춰 가운데에 놓는다.
    final unit = size.shortestSide / 100;
    final ox = (size.width - 100 * unit) / 2;
    final oy = (size.height - 100 * unit) / 2;
    Offset at(List<double> p) => Offset(ox + p[0] * unit, oy + p[1] * unit);

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
    // 썸네일은 촘촘한 단계 하나 — 켠 별 r 2.5 · 고리 r 1.8
    const rOn = 2.5;
    const rOff = 1.8;
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
