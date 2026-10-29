// 별자리 그리는 식 — 웹 ConstellationSVG 와 앱 ConstellationPainter(uniformScale)가 같은 기대값 파일로 시험한다(I-11 검수).
// 기대값 원본: /home/lshdainty/qa/design-work/impl-audit/instructions/I-11-1-star-geometry.json (독립 공식 scale = min(W,H)/100 ·
// 중앙 offset, 허용 0.5px) · star_map 원본: .../I-11-1-star-map-fixture.json(groo-sql desk/data/27 의 실제 데이터).
// test/fixtures/i11_1_star_geometry.json · i11_1_star_map.json 은 그 사본이다 — 한쪽을 바꾸면 웹과 같이 바꿀 것.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_painter.dart';

class _Rec implements Canvas {
  final lines = <List<double>>[];
  final circles = <(Offset, double, Paint)>[];
  final linePaints = <Paint>[];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    lines.add([p1.dx, p1.dy, p2.dx, p2.dy]);
    linePaints.add(paint);
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      circles.add((c, radius, paint));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final geo =
      jsonDecode(
            File('test/fixtures/i11_1_star_geometry.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final maps = {
    for (final c
        in (jsonDecode(
              File('test/fixtures/i11_1_star_map.json').readAsStringSync(),
            )['constellations']
            as List))
      (c as Map<String, dynamic>)['key'] as String: jsonEncode(c['star_map']),
  };
  final tol = (geo['tolerancePx'] as num).toDouble();
  final ratios = geo['sizeRatios'] as Map<String, dynamic>;
  List<double> r(String k) =>
      (ratios[k] as List).map((e) => (e as num).toDouble()).toList();

  for (final c in (geo['cases'] as List).cast<Map<String, dynamic>>()) {
    final name = '${c['key']} · ${c['panel']} ${c['w']}x${c['h']}';
    test(name, () {
      final map = StarMapData.parse(maps[c['key']]!);
      final size = Size((c['w'] as num).toDouble(), (c['h'] as num).toDouble());
      final rec = _Rec();
      ConstellationPainter(map: map, color: Colors.white).paint(rec, size);
      final centers = (c['centers'] as List).cast<List>();
      final lines = (c['lines'] as List).cast<List>();
      expect(rec.circles.length, centers.length, reason: '별 수');
      for (var i = 0; i < centers.length; i++) {
        expect(
          rec.circles[i].$1.dx,
          closeTo((centers[i][0] as num).toDouble(), tol),
          reason: '별 $i x',
        );
        expect(
          rec.circles[i].$1.dy,
          closeTo((centers[i][1] as num).toDouble(), tol),
          reason: '별 $i y',
        );
      }
      expect(rec.lines.length, lines.length, reason: '선 수');
      for (var i = 0; i < lines.length; i++) {
        for (var k = 0; k < 4; k++) {
          expect(
            rec.lines[i][k],
            closeTo((lines[i][k] as num).toDouble(), tol),
            reason: '선 $i [$k]',
          );
        }
      }
      // 별 크기 · 선 굵기 = min(W,H) × 비율(별 수 구간)
      final n = map.pts.length;
      final band = n <= 8 ? 0 : (n <= 15 ? 1 : 2);
      final sh = size.shortestSide;
      expect(
        rec.circles.first.$2,
        closeTo(sh * r('litRadius')[band], 0.01),
        reason: '켠 별 반지름',
      );
      expect(
        rec.linePaints.first.strokeWidth,
        closeTo(sh * r('lineWidth')[band], 0.01),
        reason: '선 굵기',
      );
    });
  }
}
