import 'package:flutter/material.dart' show Scrollbar;
import 'package:flutter/widgets.dart';

/// 넘치는 방향 — vertical(기본) · horizontal · both. 넘치는 방향만 스크롤한다.
enum PScrollAreaOrientation { vertical, horizontal, both }

/// 놓인 자리(스펙 `context`) — page(기본, 화면 · 카드 안의 높이를 정한 상자: 스크롤바 그대로) · overlay(시트 · 대화상자 안:
/// 끝에 닿아도 뒤 화면이 따라오지 않는다) · row(가로 줄 — 칩 줄 · 탭 · 가로 카드 줄: 스크롤바를 숨기고 끝은 Scroll Fog `row` 흐림이
/// 알린다).
enum PScrollAreaUse { page, overlay, row }

/// Scroll Area — 기본 스크롤 + 전역 스크롤바 한 벌. 수치 원본은 groo-design `specs/components/scroll-area.yaml`(값은
/// `test/fixtures/design_spec/scroll-area.json`), 웹은 desk-front `src/shared/ds/scroll-area` 다.
///
/// 스크롤은 플랫폼 그대로(끌기 · 관성)이고 막대의 모양은 이 위젯이 아니라 전역 [ScrollbarTheme](`GrooTheme` — 막대
/// `stroke-neutral-solid` · 6 · 알약, 바탕 투명, 눌러도 모양이 같다)다. 웹은 넘치면 막대가 늘 보이지만 앱은 스크롤할 때만 보이는
/// 플랫폼 스크롤바다(웹과 달라진 점). 세로 막대는 숨기지 않는다 — 숨기는 것은 가로 줄([PScrollAreaUse.row])뿐이다.
///
/// [label] 을 주면 상자가 이름을 받는다(안에 누르는 것이 없는 상자 — 글 · 표 · 일정 칸). 웹의 `region` + `tabindex` + 이름에
/// 해당하며, 안에 누르는 것이 있으면 주지 않는다. [PScrollAreaUse.overlay] 는 끝에서 튀지 않게 [ClampingScrollPhysics] 를 건다
/// (웹 `overscroll-behavior: contain` — Flutter 의 중첩 스크롤은 안쪽 끝에서 바깥을 끌지 않으므로 튕김만 막는다).
///
/// 높이 · 폭은 놓인 자리가 정한다. 끝을 흐리는 상자는 [PScrollFog] 가 곧 스크롤 상자다.
class PScrollArea extends StatefulWidget {
  const PScrollArea({
    super.key,
    required this.child,
    this.orientation = PScrollAreaOrientation.vertical,
    this.use = PScrollAreaUse.page,
    this.label,
    this.controller,
    this.padding,
    this.thumbVisibility = false,
  });

  final Widget child;
  final PScrollAreaOrientation orientation;
  final PScrollAreaUse use;

  /// 상자의 이름 — 안에 누르는 것이 없는 상자만.
  final String? label;

  /// 세로(both 는 세로) 스크롤 제어 — 없으면 이 위젯이 만든다.
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  /// 막대를 멈춰 보인다 — 카탈로그 · 테스트가 막대를 한 장으로 보일 때만(실제로는 스크롤할 때만 보인다).
  final bool thumbVisibility;

  @override
  State<PScrollArea> createState() => _PScrollAreaState();
}

class _PScrollAreaState extends State<PScrollArea> {
  ScrollController? _own;
  final ScrollController _horizontal = ScrollController();

  ScrollController get _vertical =>
      widget.controller ?? (_own ??= ScrollController());

  @override
  void dispose() {
    _own?.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final physics = widget.use == PScrollAreaUse.overlay
        ? const ClampingScrollPhysics()
        : null;
    final showBar = widget.use != PScrollAreaUse.row;
    final show = widget.thumbVisibility;

    Widget scroll;
    switch (widget.orientation) {
      case PScrollAreaOrientation.vertical:
        scroll = SingleChildScrollView(
          controller: _vertical,
          physics: physics,
          padding: widget.padding,
          child: widget.child,
        );
        if (showBar) {
          scroll = Scrollbar(
            controller: _vertical,
            thumbVisibility: show,
            child: scroll,
          );
        }
      case PScrollAreaOrientation.horizontal:
        final controller = widget.controller ?? _horizontal;
        scroll = SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          physics: physics,
          padding: widget.padding,
          child: widget.child,
        );
        if (showBar) {
          scroll = Scrollbar(
            controller: controller,
            thumbVisibility: show,
            child: scroll,
          );
        }
      case PScrollAreaOrientation.both:
        scroll = SingleChildScrollView(
          controller: _vertical,
          physics: physics,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            physics: physics,
            padding: widget.padding,
            child: widget.child,
          ),
        );
        if (showBar) {
          scroll = Scrollbar(
            controller: _vertical,
            thumbVisibility: show,
            child: Scrollbar(
              controller: _horizontal,
              thumbVisibility: show,
              notificationPredicate: (n) => n.depth == 1,
              child: scroll,
            ),
          );
        }
    }
    // 이 위젯이 만든 스크롤바만 쓴다 — 플랫폼 기본 스크롤바가 겹쳐 붙지 않게
    scroll = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: scroll,
    );
    if (widget.label != null) {
      scroll = Semantics(container: true, label: widget.label, child: scroll);
    }
    return scroll;
  }
}
