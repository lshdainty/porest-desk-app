import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/accordion/p_disclosure_trigger.dart';
import 'package:porest_desk_app/shared/ds/accordion/p_expand_motion.dart';

/// 놓인 면 — standard(스펙 `default`, 기본 — 흰 면 · 시트 · 대화상자의 줄, 좌우 24) · card(Collapsible 이 Card 면을 그린다 —
/// 1px `stroke-neutral-weak` · 모서리 16 · `bg-layer-default`, 트리거가 카드 머리) · warning(경고 상자의 맨 아래 줄 — 좌우
/// 16 · 위 1px `stroke-warning-weak` · 누름 `bg-warning-weak-pressed`. 상자 — 바탕 · 테두리 · 모서리 12 · 경고 글 여백 — 는
/// 화면이 그리고 상자의 모서리 자르기가 누름 바탕을 자른다).
enum PCollapsibleSurface { standard, card, warning }

/// 펼친 내용의 모양 — text(기본 — 글 · 카드 · 칸, 아래 16) · rows(줄 목록 — 아래 8, 줄이 제 위아래 12 를 가진다).
enum PCollapsibleLayout { text, rows }

/// Collapsible — 내용 하나를 접고 편다(거래 상세의 분할 내역, 분할의 "빠르게 맞추기"). 트리거는 Accordion 항목 하나의
/// 모양이다([PDisclosureTrigger] — 54 · 74, 꺾쇠 20, 누름 바탕, 모션 모두 같다). 같은 모양의 상세가 여럿이면 [PAccordion]
/// 이다. 수치 원본은 porest-design `specs/components/collapsible.yaml`(값은 `test/fixtures/design_spec/collapsible.json`),
/// 웹은 desk-front `src/shared/ds/collapsible` 이다 — 같은 값이다.
///
/// [title] 은 무엇을 여닫는지 고정한 이름이다 — 상태마다 바꾸지 않는다. 펼침은 expanded 로 읽힌다. 설명([description] —
/// 합계 · 적용한 필터 수)은 이름 뒤에 함께 읽힌다. 펼친 내용([child])은 위 0 · 좌우는 트리거와 같고(24, 경고 상자 16) 아래는
/// 글 16 · 줄 목록 8 · 카드 24(줄 목록이어도 24). 안에서 스크롤하지 않는다. 접힌 내용은 트리에서 빠진다.
///
/// 원장 머리의 "소비 요약" · "월 달력" 은 이 부품이 아니라 화면의 단추다 — 하나를 열면 다른 하나를 닫는 것은 화면이 쥔다.
class PCollapsible extends StatefulWidget {
  const PCollapsible({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.open,
    this.defaultOpen = false,
    this.onOpenChange,
    this.disabled = false,
    this.surface = PCollapsibleSurface.standard,
    this.layout = PCollapsibleLayout.text,
    this.headingLevel = 3,
  });

  /// 이름 — 무엇을 여닫는지(고정).
  final String title;

  /// 설명 — 접혀 있어도 알아야 할 값(합계 · 적용한 필터 수), 있을 때만(높이 74).
  final String? description;

  /// 펼침 — 쥐고 다룰 때. 주면 이 값을 따르고 [onOpenChange] 로 바꾸려는 값을 알린다.
  final bool? open;
  final bool defaultOpen;
  final ValueChanged<bool>? onOpenChange;
  final bool disabled;
  final PCollapsibleSurface surface;
  final PCollapsibleLayout layout;
  final int headingLevel;
  final Widget child;

  @override
  State<PCollapsible> createState() => _PCollapsibleState();
}

class _PCollapsibleState extends State<PCollapsible> {
  late bool _inner = widget.defaultOpen;
  final String _panelId = 'pcollapsible-panel-${UniqueKey()}';

  bool get _open => widget.open ?? _inner;

  void _toggle() {
    final next = !_open;
    if (widget.open == null) setState(() => _inner = next);
    widget.onOpenChange?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final surface = widget.surface;
    final open = _open;
    final padX = surface == PCollapsibleSurface.warning
        ? PSpacing.x4
        : PSpacing.x6;
    // 펼친 내용 아래 — 글 16 · 줄 목록 8 · 카드 24
    final bottom = surface == PCollapsibleSurface.card
        ? PSpacing.x6
        : widget.layout == PCollapsibleLayout.rows
        ? PSpacing.x2
        : PSpacing.x4;

    Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 경고 상자 아래 줄 — 트리거 위 1px 선(상자 폭 끝까지)
        if (surface == PCollapsibleSurface.warning)
          SizedBox(
            key: const ValueKey('pcollapsible-divider'),
            height: 1,
            child: ColoredBox(color: c.strokeWarningWeak),
          ),
        PDisclosureTrigger(
          title: widget.title,
          description: widget.description,
          open: open,
          disabled: widget.disabled,
          paddingX: padX,
          pressed: surface == PCollapsibleSurface.warning
              ? PDisclosurePressed.warning
              : PDisclosurePressed.layer,
          headingLevel: widget.headingLevel,
          controlsId: _panelId,
          onToggle: _toggle,
        ),
        PExpandMotion(
          open: open,
          keyPrefix: 'pcollapsible-panel',
          child: Padding(
            key: const ValueKey('pcollapsible-panel'),
            padding: EdgeInsets.fromLTRB(padX, 0, padX, bottom),
            child: Semantics(
              container: true,
              identifier: _panelId,
              child: widget.child,
            ),
          ),
        ),
      ],
    );

    if (surface == PCollapsibleSurface.card) {
      body = DecoratedBox(
        key: const ValueKey('pcollapsible-card'),
        decoration: BoxDecoration(
          color: c.bgLayerDefault,
          border: Border.all(color: c.strokeNeutralWeak),
          borderRadius: BorderRadius.circular(PRounded.r4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PRounded.r4 - 1),
          child: body,
        ),
      );
    }
    return body;
  }
}
