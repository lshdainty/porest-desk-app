import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/painting.dart';

/// Image Frame · Card Art · Logo Tile 견본 · 테스트에 쓰는 그림 대역 — 실제 사진 · 카드사 그림이 아니라 칠한 그림이다
/// (밖으로 요청을 보내지 않는다). 화면에서 쓰지 않는다. 가로 · 세로 · 흰 그림 · 어두운 그림 · 못 받는 그림 · 안 오는 그림이 있다.
enum PSampleKind {
  /// 가로 사진 600 × 450 — 하늘 · 산 · 해(가운데를 남겨 자르면 해가 남는다)
  photo(600, 450),

  /// 세로 사진 480 × 600(4:5)
  photoTall(480, 600),

  /// 흰 그림 — 흰 바탕의 흰 카드(투명 윤곽이 없으면 틀이 묻힌다). 아주 옅은 글자만 있다
  white(600, 450),

  /// 어두운 그림 — 짙은 남색 한 색(투명 윤곽이 테를 만들지 않아야 한다)
  dark(600, 450),

  /// 가로 카드 그림 856 × 540(1.585) — 모서리까지 칠한 카드
  cardWide(856, 540),

  /// 세로 카드 그림 540 × 856(0.63) — 시계 방향으로 90° 돌리면 cardWide 와 같은 모습(글자가 오른쪽으로 눕는다)
  cardTall(540, 856),

  /// 로고 그림 — 투명 바탕 · 검은 마크(흰 판 위에서만 보인다)
  logo(200, 120);

  const PSampleKind(this.width, this.height);
  final int width;
  final int height;
}

/// 칠한 그림 — 같은 [kind] 는 같은 그림이다(이미지 캐시가 하나로 본다).
class PSampleImage extends ImageProvider<PSampleImage> {
  const PSampleImage(this.kind);

  final PSampleKind kind;

  @override
  Future<PSampleImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<PSampleImage>(this);

  @override
  ImageStreamCompleter loadImage(
    PSampleImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    _paint(kind).then((image) => ImageInfo(image: image)),
  );

  @override
  bool operator ==(Object other) => other is PSampleImage && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;
}

/// 못 받는 그림 — 받기가 바로 실패한다.
class PBrokenImage extends ImageProvider<PBrokenImage> {
  const PBrokenImage();

  @override
  Future<PBrokenImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<PBrokenImage>(this);

  @override
  ImageStreamCompleter loadImage(
    PBrokenImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(Exception('못 받는 그림(견본)')),
  );

  @override
  bool operator ==(Object other) => other is PBrokenImage;

  @override
  int get hashCode => 0;
}

/// 안 오는 그림 — 받는 중 상태를 붙잡아 둔다(견본이 스켈레톤을 보이려고). 실제 화면에서 쓰지 않는다.
class PNeverImage extends ImageProvider<PNeverImage> {
  const PNeverImage();

  @override
  Future<PNeverImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<PNeverImage>(this);

  @override
  ImageStreamCompleter loadImage(
    PNeverImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Completer<ImageInfo>().future);

  @override
  bool operator ==(Object other) => other is PNeverImage;

  @override
  int get hashCode => 1;
}

Future<ui.Image> _paint(PSampleKind kind) {
  final w = kind.width.toDouble();
  final h = kind.height.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
  final full = Rect.fromLTWH(0, 0, w, h);
  final fill = Paint();
  switch (kind) {
    case PSampleKind.photo:
      canvas.drawRect(
        full,
        fill
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9EC5E6), Color(0xFFF3DCC0)],
          ).createShader(full),
      );
      canvas.drawCircle(
        const Offset(300, 170),
        46,
        Paint()..color = const Color(0xFFFFF3C4),
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, 450)
          ..lineTo(0, 300)
          ..lineTo(130, 210)
          ..lineTo(250, 290)
          ..lineTo(360, 170)
          ..lineTo(600, 320)
          ..lineTo(600, 450)
          ..close(),
        Paint()..color = const Color(0xFF6F8F72),
      );
      canvas.drawPath(
        Path()
          ..moveTo(0, 450)
          ..lineTo(0, 360)
          ..lineTo(160, 310)
          ..lineTo(340, 370)
          ..lineTo(600, 330)
          ..lineTo(600, 450)
          ..close(),
        Paint()..color = const Color(0xFF4B6B52),
      );
    case PSampleKind.photoTall:
      canvas.drawRect(
        full,
        fill
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8C9D4), Color(0xFF8C9FC4)],
          ).createShader(full),
      );
      canvas.drawCircle(
        const Offset(240, 230),
        80,
        Paint()..color = const Color(0xFFFFFFFF),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(120, 360, 240, 40),
          const Radius.circular(20),
        ),
        Paint()..color = const Color(0xCCFFFFFF),
      );
    case PSampleKind.white:
      canvas.drawRect(full, Paint()..color = const Color(0xFFFFFFFF));
      _text(
        canvas,
        'SELECT',
        const Offset(300, 195),
        56,
        const Color(0xFFF1F1F1),
      );
    case PSampleKind.dark:
      canvas.drawRect(full, Paint()..color = const Color(0xFF10153A));
      canvas.drawCircle(
        const Offset(470, 110),
        60,
        Paint()..color = const Color(0xFF1B2260),
      );
    case PSampleKind.cardWide:
      canvas.drawRect(
        full,
        fill
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B3A67), Color(0xFF6B7FD7)],
          ).createShader(full),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(60, 120, 96, 72),
          const Radius.circular(12),
        ),
        Paint()..color = const Color(0xFFF3D27A),
      );
      _text(
        canvas,
        'PORTRAIT TEST',
        const Offset(60, 400),
        56,
        const Color(0xFFFFFFFF),
        left: true,
      );
    case PSampleKind.cardTall:
      canvas.drawRect(
        full,
        fill
          ..shader = const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF7A2B3F), Color(0xFFE08A6A)],
          ).createShader(full),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(348, 60, 72, 96),
          const Radius.circular(12),
        ),
        Paint()..color = const Color(0xFFF3D27A),
      );
      canvas.save();
      canvas.translate(60, 796);
      canvas.rotate(-1.5707963267948966);
      _text(
        canvas,
        'TALL CARD',
        Offset.zero,
        48,
        const Color(0xFFFFFFFF),
        left: true,
      );
      canvas.restore();
    case PSampleKind.logo:
      canvas.drawCircle(
        const Offset(60, 60),
        44,
        Paint()..color = const Color(0xFF111111),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(116, 30, 72, 60),
          const Radius.circular(10),
        ),
        Paint()..color = const Color(0xFF111111),
      );
  }
  return recorder.endRecording().toImage(kind.width, kind.height);
}

void _text(
  Canvas canvas,
  String text,
  Offset at,
  double size,
  Color color, {
  bool left = false,
}) {
  final p = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  p.paint(canvas, left ? at : Offset(at.dx - p.width / 2, at.dy));
}
