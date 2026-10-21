import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 목록 끝의 상태 — loading(다음 쪽이 있다: 받는 중 · 곧 받는다, 원) · error(못 불러옴, 글 + 다시 시도) · end(끝, 글).
enum PInfiniteListStatus { loading, error, end }

/// 다음 쪽을 부르는 거리 — 목록 끝이 화면 아래 끝에서 이만큼 안으로 오면 받는다(infinite-list.yaml sentinel.threshold,
/// 지금 Desk 앱 값). 목록이 게으른 [ListView] 면 이 자리가 그려져야 재므로 `cacheExtent` 도 이만큼 준다.
const double kPInfiniteListReach = 300;

/// Infinite List — 폰(768 미만) 긴 목록 끝의 한 자리. 쪽 넘김(Pagination)의 폰 짝이다. 수치 원본은 groo-design
/// `specs/components/infinite-list.yaml`(값은 `test/fixtures/design_spec/infinite-list.json`), 규칙은 `pagination.md` 의
/// "폰은 끝없이 불러오기". 웹(desk-front `src/shared/ds/infinite-list` 의 `InfiniteListEnd`)과 같은 값이다.
///
/// 목록 맨 아래에 둔다 — 위아래 24, 가운데. 상태 하나를 보인다.
///   loading  Progress Circle 24 · neutral. 1초가 지나야 보인다(그 전에 오면 깜빡이지 않게 높이만 지킨다).
///   error    "더 불러오지 못했어요."(t4 · 400 · fg-neutral-muted) + 12 아래 Button neutralWeak small "다시 시도".
///            이미 받은 줄은 그대로 둔다.
///   end      [endText](기본 "모두 봤어요." — t4 · 400 · fg-neutral-subtle). 한 쪽으로 끝나는 짧은 목록에는 두지 않는다.
///
/// [onReachEnd] — loading 일 때 이 자리가 가장 가까운 스크롤 상자 아래 끝에서 [kPInfiniteListReach] 안으로 오면 부른다.
/// 한 번 부르면 목록이 자라거나(이 자리가 다시 그려질 때 안 가깝다) 300 밖으로 나갔다 올 때까지 다시 부르지 않는다 —
/// 받는 동안 거듭 부르지 않게. 못 불러온 뒤 "다시 시도" 로 돌아온 loading 은 다시 시도가 받고 있으니 부르지 않는다.
/// "더 보기" 버튼은 두지 않는다. 첫 쪽을 못 불러오면 이 자리가 아니라 목록 자리가 Result Section 실패다.
///
/// 읽기 — 못 불러옴 · 끝 글은 상태 글(live region)로 한 번 읽힌다. 받는 동안 목록에 바쁨을 거는 것은 쓰는 쪽의 몫이다.
class PInfiniteListEnd extends StatefulWidget {
  const PInfiniteListEnd({
    super.key,
    required this.status,
    this.onRetry,
    this.endText,
    this.onReachEnd,
  });

  final PInfiniteListStatus status;

  /// "다시 시도" — 그 쪽을 다시 받는다.
  final VoidCallback? onRetry;

  /// 끝 글 — 기본 "모두 봤어요."(목록마다 "카드를 모두 봤어요." 처럼).
  final String? endText;

  /// 목록 끝이 화면 아래에서 300 안으로 오면 부른다 — loading 일 때만.
  final VoidCallback? onReachEnd;

  @override
  State<PInfiniteListEnd> createState() => _PInfiniteListEndState();
}

class _PInfiniteListEndState extends State<PInfiniteListEnd> {
  /// 1초가 지나 원이 보이는가.
  bool _spinnerShown = false;
  Timer? _showTimer;

  /// 지금 부를 수 있는가 — 한 번 부르면 내려놓고, 300 밖으로 나가면 다시 든다.
  bool _armed = true;
  ScrollPosition? _position;

  @override
  void initState() {
    super.initState();
    _restartWait();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (!identical(next, _position)) {
      _position?.removeListener(_schedule);
      _position = next?..addListener(_schedule);
    }
  }

  @override
  void didUpdateWidget(PInfiniteListEnd old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      _restartWait();
      // 다시 시도로 돌아온 loading 은 그 요청이 받고 있다 — 300 밖으로 나갔다 오거나 목록이 자랄 때까지 기다린다
      _armed = old.status != PInfiniteListStatus.error;
    }
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _position?.removeListener(_schedule);
    super.dispose();
  }

  void _restartWait() {
    _showTimer?.cancel();
    _spinnerShown = false;
    if (widget.status == PInfiniteListStatus.loading) {
      _showTimer = Timer(PLoadingTiming.showAfter, () {
        if (mounted) setState(() => _spinnerShown = true);
      });
    }
  }

  /// 이 자리의 위쪽 끝이 스크롤 상자 아래 끝에서 [kPInfiniteListReach] 안인가 — 그리고 목록 시작에서 이 자리까지의 거리
  /// (목록이 자랐는지 본다). 재지 못하면 null.
  ({bool inReach, double contentTop})? _measure() {
    final scrollable = Scrollable.maybeOf(context);
    final box = context.findRenderObject();
    final viewport = scrollable?.context.findRenderObject();
    if (scrollable == null ||
        box is! RenderBox ||
        viewport is! RenderBox ||
        !box.attached ||
        !viewport.attached ||
        !box.hasSize ||
        !viewport.hasSize ||
        scrollable.position.axis != Axis.vertical) {
      return null;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    return (
      inReach: top - viewport.size.height <= kPInfiniteListReach,
      contentTop: top + scrollable.position.pixels,
    );
  }

  double? _lastContentTop;
  bool _scheduled = false;

  /// 스크롤 알림은 이 자리가 새 위치로 놓이기 전에 오므로, 한 프레임 뒤(놓인 다음)에 잰다.
  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      _check();
    });
  }

  void _check() {
    if (!mounted || widget.status != PInfiniteListStatus.loading) return;
    final m = _measure();
    if (m == null) return;
    // 목록이 자랐다(이 자리가 아래로 밀렸다) — 새 쪽이 붙었으니 다시 부를 수 있다
    if (_lastContentTop != null &&
        (m.contentTop - _lastContentTop!).abs() > 0.5) {
      _armed = true;
    }
    _lastContentTop = m.contentTop;
    if (m.inReach) {
      if (!_armed) return;
      _armed = false;
      widget.onReachEnd?.call();
    } else {
      _armed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    // 목록이 자라 이 자리가 다시 그려질 때도 잰다 — 스크롤 알림은 길이가 바뀌어도 오지 않는다
    if (widget.status == PInfiniteListStatus.loading) _schedule();
    final status = widget.status;
    return Padding(
      key: const ValueKey('infinite-list-end'),
      padding: const EdgeInsets.symmetric(vertical: PSpacing.x6),
      child: Center(
        heightFactor: 1,
        child: switch (status) {
          PInfiniteListStatus.loading =>
            _spinnerShown
                ? const PProgressCircle(
                    key: ValueKey('infinite-list-progress'),
                    size: PProgressCircleSize.s24,
                  )
                // 1초 안에는 보이지 않는다 — 높이만 지킨다
                : const SizedBox.square(
                    key: ValueKey('infinite-list-quiet'),
                    dimension: 24,
                  ),
          PInfiniteListStatus.error => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  keepAll(l.dsInfiniteListError),
                  key: const ValueKey('infinite-list-message'),
                  semanticsLabel: l.dsInfiniteListError,
                  textAlign: TextAlign.center,
                  style: PTypography.t4.copyWith(
                    color: c.fgNeutralMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: PSpacing.x3),
              PButton(
                key: const ValueKey('infinite-list-retry'),
                label: l.dsCommonRetry,
                variant: PButtonVariant.neutralWeak,
                size: PButtonSize.small,
                onPressed: widget.onRetry,
              ),
            ],
          ),
          PInfiniteListStatus.end => Semantics(
            liveRegion: true,
            child: Text(
              keepAll(widget.endText ?? l.dsInfiniteListEnd),
              key: const ValueKey('infinite-list-message'),
              semanticsLabel: widget.endText ?? l.dsInfiniteListEnd,
              textAlign: TextAlign.center,
              style: PTypography.t4.copyWith(
                color: c.fgNeutralSubtle,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        },
      ),
    );
  }
}
