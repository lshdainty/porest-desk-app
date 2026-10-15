// 그림 대역 — 받기를 테스트가 쥔다(받는 중 · 다 받음 · 실패 · 안 옴). 밖으로 요청을 보내지 않는다.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCompleter extends ImageStreamCompleter {
  void emit(ui.Image image) => setImage(ImageInfo(image: image.clone()));
  void fail() => reportError(exception: Exception('못 받음'), silent: true);
}

/// [ready] 가 있으면 붙자마자 다 받은 그림(캐시된 것처럼 동기), 없으면 [emit] · [fail] 을 부를 때까지 받는 중.
class FakeImage extends ImageProvider<FakeImage> {
  FakeImage([this.ready]) : _failing = false;

  /// 받기가 바로 실패하는 그림.
  FakeImage.failing() : ready = null, _failing = true;

  final ui.Image? ready;
  final bool _failing;
  final _completer = _FakeCompleter();

  /// 받는 중인 그림이 다 왔다.
  void emit(ui.Image image) => _completer.emit(image);

  /// 받는 중인 그림이 실패했다.
  void fail() => _completer.fail();

  @override
  Future<FakeImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<FakeImage>(this);

  @override
  ImageStreamCompleter loadImage(FakeImage key, ImageDecoderCallback decode) {
    if (ready != null) _completer.emit(ready!);
    // 듣는 쪽이 붙은 다음에 알린다
    if (_failing) scheduleMicrotask(_completer.fail);
    return _completer;
  }
}

/// 크기가 있는 그림 한 장(원래 크기 w × h).
Future<ui.Image> testPicture(WidgetTester tester, int w, int h) async =>
    (await tester.runAsync(() => createTestImage(width: w, height: h)))!;
