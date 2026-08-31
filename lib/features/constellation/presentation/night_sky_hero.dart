import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/features/constellation/domain/constellation.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// 밤하늘 히어로 — 오늘의 목표 별자리가 별빛만큼 점등.
/// 밤 장면이라 라이트/다크 공통 고정 다크 팔레트(웹 NightSkyHero 미러, 커스텀 hero 영역).
class NightSkyHero extends StatelessWidget {
  const NightSkyHero({super.key, required this.today, required this.doneToday});

  final ConstellationToday today;
  final int doneToday;

  static const _dimStars = <(double, double)>[
    (5, 18), (11, 72), (17, 30), (22, 84), (28, 12), (33, 52), (38, 88),
    (45, 8), (55, 90), (62, 10), (68, 86), (75, 20), (83, 78), (90, 14),
    (95, 52), (8, 48), (92, 82), (60, 30), (20, 58), (86, 44),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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

    return Container(
      height: 168,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: PRadius.brLg,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1430), Color(0xFF17224A), Color(0xFF1F2C5E)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: LayoutBuilder(builder: (context, box) {
        return Stack(
          children: [
            // 은은한 달빛
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x299AB0FF), Colors.transparent],
                    stops: [0, 0.65],
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 14,
              right: 16,
              child: Icon(LucideIcons.moon, size: 15, color: Color(0x8CD2DCFF)),
            ),
            // 배경 잔별
            for (var i = 0; i < _dimStars.length; i++)
              Positioned(
                left: box.maxWidth * _dimStars[i].$1 / 100,
                top: box.maxHeight * _dimStars[i].$2 / 100,
                child: Container(
                  width: i % 3 == 0 ? 2.5 : 1.5,
                  height: i % 3 == 0 ? 2.5 : 1.5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x52C8D4FF),
                  ),
                ),
              ),
            // 별자리 figure — 중앙 비율 박스 (웹 aspectRatio 1.45 정합)
            Positioned(
              top: box.maxHeight * 0.10,
              bottom: box.maxHeight * 0.24,
              left: 0,
              right: 0,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.45,
                  child: CustomPaint(
                    painter: _HeroFigurePainter(
                      map: today.constellation.starMap,
                      lit: lit,
                      done: done,
                    ),
                  ),
                ),
              ),
            ),
            // 좌상단: 오늘의 목표
            Positioned(
              top: 12,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.constHeroTodayTarget,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: 11,
                      fontWeight: PFontWeight.semi,
                      letterSpacing: 0.33,
                      color: const Color(0x9ECDD8FF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        done ? l.constHeroCollectedBang(name) : name,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.32,
                          color: const Color(0xFFF2F5FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.constHeroStarlightCount(lit, today.goal),
                        style: TextStyle(
                          fontFamily: PTypo.mono,
                          fontSize: 12.5,
                          fontWeight: PFontWeight.bold,
                          color: const Color(0xD9BECDFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 좌하단: 진행 캡션
            Positioned(
              left: 16,
              bottom: 13,
              child: Text(
                caption,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 11,
                  color: const Color(0x8CC6D1FA),
                ),
              ),
            ),
            // 우하단: 스트릭 + 보호
            Positioned(
              right: 14,
              bottom: 13,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x17FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.sparkles, size: 12, color: Color(0xFFE6ECFF)),
                        const SizedBox(width: 6),
                        Text(
                          l.constHeroStreak(today.streak),
                          style: TextStyle(
                            fontFamily: PTypo.sans,
                            fontSize: 11.5,
                            fontWeight: PFontWeight.bold,
                            color: const Color(0xFFE6ECFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.cloud, size: 11, color: Color(0xB2BECDFF)),
                      const SizedBox(width: 4),
                      Text(
                        l.constHeroGuardInfo(today.guardCount),
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: 10.5,
                          fontWeight: PFontWeight.semi,
                          color: const Color(0xB2BECDFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// 히어로 중앙 figure — 점등 별(글로우)과 점선/실선 연결. 박스에 늘림(preserveAspectRatio none 정합).
class _HeroFigurePainter extends CustomPainter {
  _HeroFigurePainter({required this.map, required this.lit, required this.done});

  final StarMapData map;
  final int lit;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 100;
    Offset at(List<double> p) => Offset(p[0] * sx, p[1] * sy);

    final lineColor = done ? const Color(0xD9B2C5FF) : const Color(0x8094A8EB);
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
      ..color = Color.fromRGBO(176, 196, 255, done ? 0.8 : 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, done ? 7 : 4.5);
    final onPaint = Paint()..color = const Color(0xFFE8EEFF);
    final offPaint = Paint()
      ..color = const Color(0x73BECDFF)
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
      old.map != map || old.lit != lit || old.done != done;
}
