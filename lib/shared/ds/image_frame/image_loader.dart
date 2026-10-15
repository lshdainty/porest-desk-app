import 'dart:async';

import 'package:flutter/widgets.dart';

/// 그림 한 장을 받는 상태.
enum PImageStatus { loading, loaded, error }

/// 그림 받기 — [image] 를 받아 loading → loaded · error 로 알린다. Image Frame · Logo Tile 이 같이 쓴다.
///
/// - 다 받으면 원래 크기로 세로 그림인지([portrait]: 폭 < 높이) 안다 — 세로 카드 그림을 돌릴 때 쓴다.
/// - 붙을 때 이미 받아 둔 그림(캐시)은 바로 loaded 이고 [reveal] 이 false 다(나타나는 움직임 없이 그대로 보인다).
/// - [timeout] 이 있으면 **틀이 화면에 들어온 때부터** 잰다 — 목록 아래쪽 그림이 보기도 전에 실패로 바뀌지 않게.
///   지나면 실패와 같다. 실패(오류 · 시간)로 바뀐 뒤에 그림이 와도 다시 바꾸지 않는다.
/// - [image] 가 바뀌면 처음부터 다시 받는다.
class PImageLoader extends StatefulWidget {
  const PImageLoader({
    super.key,
    required this.image,
    required this.builder,
    this.timeout,
  });

  final ImageProvider image;
  final Duration? timeout;
  final Widget Function(
    BuildContext context,
    PImageStatus status,
    bool portrait,
    bool reveal,
  )
  builder;

  @override
  State<PImageLoader> createState() => _PImageLoaderState();
}

class _PImageLoaderState extends State<PImageLoader> {
  ImageStream? _stream;
  late ImageStreamListener _listener;
  PImageStatus _status = PImageStatus.loading;
  bool _portrait = false;
  bool _reveal = false;
  bool _resolving = false;

  Timer? _timer;
  ScrollPosition? _position;
  bool _visibilityPending = false;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(_onImage, onError: _onError);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
    _watchScroll();
  }

  @override
  void didUpdateWidget(PImageLoader old) {
    super.didUpdateWidget(old);
    if (old.image != widget.image) {
      _status = PImageStatus.loading;
      _portrait = false;
      _reveal = false;
      _timer?.cancel();
      _timer = null;
      _resolve();
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _timer?.cancel();
    _position?.removeListener(_checkVisible);
    super.dispose();
  }

  void _resolve() {
    final next = widget.image.resolve(createLocalImageConfiguration(context));
    if (_stream?.key == next.key) return;
    _stream?.removeListener(_listener);
    _stream = next;
    _resolving = true;
    next.addListener(_listener);
    _resolving = false;
    _armTimeout();
  }

  void _onImage(ImageInfo info, bool sync) {
    final portrait = info.image.width < info.image.height;
    info.dispose();
    // 받는 중일 때만 바꾼다 — 실패 뒤에 온 그림 · 같은 그림의 두 번째 알림은 무시한다
    if (_status != PImageStatus.loading) return;
    void apply() {
      _status = PImageStatus.loaded;
      _portrait = portrait;
      _reveal = !sync;
    }

    if (_resolving) {
      apply();
    } else if (mounted) {
      setState(apply);
    }
    _timer?.cancel();
    _timer = null;
  }

  void _onError(Object error, StackTrace? stack) {
    if (_status != PImageStatus.loading) return;
    void apply() => _status = PImageStatus.error;
    if (_resolving) {
      apply();
    } else if (mounted) {
      setState(apply);
    }
    _timer?.cancel();
    _timer = null;
  }

  // ── 10초 — 틀이 화면에 들어온 때부터 ─────────────────────────

  void _armTimeout() {
    if (widget.timeout == null || _status != PImageStatus.loading) return;
    if (_timer != null || _visibilityPending) return;
    _visibilityPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityPending = false;
      if (mounted) _checkVisible();
    });
  }

  void _watchScroll() {
    if (widget.timeout == null) return;
    final next = Scrollable.maybeOf(context)?.position;
    if (identical(next, _position)) return;
    _position?.removeListener(_checkVisible);
    _position = next?..addListener(_checkVisible);
  }

  void _checkVisible() {
    if (_timer != null || _status != PImageStatus.loading) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    final frame = box.localToGlobal(Offset.zero) & box.size;
    if (!frame.overlaps(screen)) return;
    _position?.removeListener(_checkVisible);
    _position = null;
    _timer = Timer(widget.timeout!, () {
      if (!mounted || _status != PImageStatus.loading) return;
      setState(() => _status = PImageStatus.error);
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _status, _portrait, _reveal);
}
