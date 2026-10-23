import 'dart:io';
import 'dart:typed_data';

/// 시험용 최소 PNG 해독기 — 8비트 RGB · RGBA, 비인터레이스만(자산 검사용).
class PngImage {
  PngImage(this.width, this.height, this.channels, this.data);
  final int width;
  final int height;
  final int channels;
  final Uint8List data;

  bool get hasAlpha => channels == 4;

  /// [r, g, b, a]
  List<int> px(int x, int y) {
    final i = (y * width + x) * channels;
    return [data[i], data[i + 1], data[i + 2], hasAlpha ? data[i + 3] : 255];
  }

  /// 바탕(흰 불투명 또는 투명)과 다른 픽셀의 경계 상자 (x0, y0, x1, y1 — 끝 포함).
  List<int>? bbox({required bool Function(List<int>) isInk}) {
    var x0 = width, y0 = height, x1 = -1, y1 = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (isInk(px(x, y))) {
          if (x < x0) x0 = x;
          if (y < y0) y0 = y;
          if (x > x1) x1 = x;
          if (y > y1) y1 = y;
        }
      }
    }
    return x1 < 0 ? null : [x0, y0, x1, y1];
  }

  static PngImage read(String path) {
    final b = File(path).readAsBytesSync();
    final bd = ByteData.sublistView(b);
    var o = 8;
    var w = 0, h = 0, ct = 0, depth = 0, il = 0;
    final idat = BytesBuilder();
    while (o < b.length) {
      final len = bd.getUint32(o);
      final type = String.fromCharCodes(b.sublist(o + 4, o + 8));
      final body = b.sublist(o + 8, o + 8 + len);
      if (type == 'IHDR') {
        final d = ByteData.sublistView(Uint8List.fromList(body));
        w = d.getUint32(0);
        h = d.getUint32(4);
        depth = body[8];
        ct = body[9];
        il = body[12];
      } else if (type == 'IDAT') {
        idat.add(body);
      }
      o += 12 + len;
    }
    if (depth != 8 || il != 0 || (ct != 2 && ct != 6)) {
      throw UnsupportedError('depth=$depth ct=$ct il=$il');
    }
    final ch = ct == 6 ? 4 : 3;
    final raw = zlib.decode(idat.toBytes());
    final stride = w * ch;
    final out = Uint8List(h * stride);
    for (var y = 0; y < h; y++) {
      final f = raw[y * (stride + 1)];
      final src = y * (stride + 1) + 1;
      for (var i = 0; i < stride; i++) {
        final x = raw[src + i];
        final a = i >= ch ? out[y * stride + i - ch] : 0;
        final u = y > 0 ? out[(y - 1) * stride + i] : 0;
        final c = (y > 0 && i >= ch) ? out[(y - 1) * stride + i - ch] : 0;
        int v;
        switch (f) {
          case 0:
            v = x;
          case 1:
            v = x + a;
          case 2:
            v = x + u;
          case 3:
            v = x + ((a + u) >> 1);
          default:
            final p = a + u - c;
            final pa = (p - a).abs(), pb = (p - u).abs(), pc = (p - c).abs();
            v = x + (pa <= pb && pa <= pc ? a : (pb <= pc ? u : c));
        }
        out[y * stride + i] = v & 255;
      }
    }
    return PngImage(w, h, ch, out);
  }
}
