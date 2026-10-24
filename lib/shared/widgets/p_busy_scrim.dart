import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

/// 뒤를 만지면 안 되는 처리 — 화면 전체 딤 + 흰 원 40 (progress-circle.md "뒤를 만지면 안 되는 처리").
///
/// 가져오기 확정 · 이용 해지처럼 **끝나기 전에 뒤 화면을 쓰면 안 되는** 처리에만 쓴다. 뒤를 써도 되는 기다림은
/// 작은 원(제목 옆 24)이고 이 덮개가 아니다. 웹 `BusyScrim` 과 같은 값이다(I-05 37 · 49).
///
/// - 딤 `overlay-dim`(라이트 50% · 다크 65%), 원 `staticWhite` 40 · 값 없음. **1초에 보인다** — 1초 안에 끝나면
///   덮개는 보이지 않는다([PLoadingTiming.showAfter]). 다만 손은 처음부터 막는다(그 사이 눌러 겹치지 않게).
/// - 덮는 동안 뒤 화면은 의미 트리에서 빠진다([BlockSemantics]) — 모달처럼. 원의 이름("가져오는 중" · "해지하는 중")이
///   그 자리에서 읽힌다.
/// - 딤 위에는 안내 글을 두지 않는다(글자색 짝이 없다 — 열린 일).
///
/// 루트 오버레이에 올라가 **시트까지 덮는다**. 부른 쪽 화면이 사라져도(시트를 내려도) 덮개는 [PBusyScrimHandle.hide]
/// 가 불릴 때까지 남는다 — 해지는 시트가 내려가도 끝까지 가기 때문이다.
///
/// ```dart
/// final scrim = PBusyScrim.show(context, label: l.importBusy);
/// try {
///   await work();
/// } finally {
///   scrim.hide();
/// }
/// ```
abstract final class PBusyScrim {
  /// 덮개를 올린다. [label] 은 원의 이름이다(읽는 글 — 화면에는 그리지 않는다).
  static PBusyScrimHandle show(BuildContext context, {required String label}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => PBusyScrimLayer(label: label),
      // 아래 화면을 다시 그리지 않아도 된다 — 덮개가 불투명이 아니어도 뒤는 그대로다
      opaque: false,
    );
    overlay.insert(entry);
    return PBusyScrimHandle._(entry);
  }
}

/// [PBusyScrim.show] 가 돌려주는 끄는 손잡이.
class PBusyScrimHandle {
  PBusyScrimHandle._(this._entry);

  OverlayEntry? _entry;

  /// 덮개가 올라가 있는가.
  bool get isShown => _entry != null;

  /// 덮개를 걷는다. 두 번 불러도 괜찮다.
  void hide() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry.remove();
    entry.dispose();
  }
}

/// 덮개 한 장 — 손 막기 + (1초 뒤) 딤 · 흰 원 · 뒤 화면 의미 트리 숨김. 오버레이 밖에서 바로 놓아도 된다(시험 · 카탈로그).
class PBusyScrimLayer extends StatefulWidget {
  const PBusyScrimLayer({
    super.key,
    required this.label,
    this.showAfter = PLoadingTiming.showAfter,
  });

  /// 원의 이름 — "가져오는 중" · "해지하는 중".
  final String label;

  /// 딤 · 원이 나타나기까지.
  final Duration showAfter;

  @override
  State<PBusyScrimLayer> createState() => _PBusyScrimLayerState();
}

class _PBusyScrimLayerState extends State<PBusyScrimLayer> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.showAfter == Duration.zero) {
      _visible = true;
    } else {
      _timer = Timer(widget.showAfter, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 손은 처음부터 막고, 보이는 덮개는 1초 뒤에
    final layer = SizedBox.expand(
      child: AbsorbPointer(
        child: ColoredBox(
          key: const ValueKey('busy-scrim-dim'),
          color: _visible ? c.overlayDim : const Color(0x00000000),
          child: _visible
              ? Center(
                  child: PProgressCircle(
                    key: const ValueKey('busy-scrim-circle'),
                    size: PProgressCircleSize.s40,
                    tone: PProgressCircleTone.staticWhite,
                    semanticsLabel: widget.label,
                  ),
                )
              : null,
        ),
      ),
    );
    return _visible ? BlockSemantics(child: layer) : layer;
  }
}
