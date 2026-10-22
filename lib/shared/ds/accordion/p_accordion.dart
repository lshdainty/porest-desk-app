import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/accordion/p_disclosure_trigger.dart';
import 'package:groo_damda_app/shared/ds/accordion/p_expand_motion.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/header_row/p_header_row.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';

/// 변형 — inline(기본, 연속 목록 + 들인 사이 선 24) · separated(항목마다 Card 면 — 1px · 모서리 16 · 사이 8).
enum PAccordionVariant { inline, separated }

/// Accordion — 관련 상세를 세로로 묶고 항목마다 머리(트리거)를 눌러 펼친다(카드 혜택 · 유의사항). 구조는 SEED Accordion,
/// 수치 원본은 groo-design `specs/components/accordion.yaml`(값은 `test/fixtures/design_spec/accordion.json`), 웹은
/// desk-front `src/shared/ds/accordion` 이다 — 같은 값이다. 하나만 접고 펴는 자리는 [PCollapsible], 하위 줄을 접는 목록은
/// [PListParentItem] 이다(Tree View 는 HR 전용이라 앱에 없다).
///
///   [PAccordion]               아코디언 — [variant] · [values] · [defaultValues] · [onValuesChange]. 늘 여럿을 함께 열 수 있다
///                              (하나만 여는 모드는 없다). [children] 은 [PAccordionItem] · [PAccordionPlainItem] — 사이 선 ·
///                              간격은 이 위젯이 그린다. 처음에는 모두 접힘
///   [PAccordionItem]           항목 — [PAccordionItem.value](필수) · title · description · prefixIcon · child(펼친 내용)
///   [PAccordionPlainItem]      상세가 없는 항목 — 트리거가 아닌 그냥 줄(머리말 · 단추 · 꺾쇠 · 바탕 없음). 높이 · 글 시작은 트리거와 같다
///   [PAccordionHeader]         시트 · 대화상자의 목록 머리 — 제목(건수를 붙인다) + 오른쪽 자식(모두 펼치기)
///   [PAccordionExpandAll]      모두 펼치기 — 상세가 있는 항목만 열고 닫는다. 하나라도 접혀 있으면 "모두 펼치기", 전부 열렸으면
///                              "모두 접기"(글은 [expandLabel] · [collapseLabel] 로 부르는 쪽이 넘긴다)
///
/// 펼친 내용은 좌우 24 · 아래 16(위 0 — 트리거 아래 16 에 바로 잇는다), 글은 14 / 22 · `fg-neutral-muted`, 안에서 스크롤하지
/// 않는다. 펼쳐도 포커스는 트리거에 그대로고 화면을 저절로 스크롤하지 않는다. 펼친 내용에 region 을 두지 않는다. 접힌 내용은
/// 트리에서 빠져 읽지 않는다 — 웹과 달리 접히면 안의 상태도 사라진다([PExpandMotion]).
///
/// 키보드(웹 APG): 트리거에서 ↓ ↑ 는 다음 · 앞 트리거(끝에서 처음으로 돈다), Home · End 는 첫 · 끝 트리거 — 상세가 없는 줄 ·
/// 막힌 트리거는 건너뛴다.
class PAccordion extends StatefulWidget {
  const PAccordion({
    super.key,
    required this.children,
    this.variant = PAccordionVariant.inline,
    this.values,
    this.defaultValues = const [],
    this.onValuesChange,
    this.disabled = false,
  });

  final PAccordionVariant variant;

  /// 펼친 항목의 value 목록 — 쥐고 다룰 때. 주면 이 값을 따르고 [onValuesChange] 로 바꾸려는 값을 알린다.
  final List<String>? values;

  /// 처음 펼친 항목 — [values] 가 없을 때만. 없으면 모두 접힘.
  final List<String> defaultValues;
  final ValueChanged<List<String>>? onValuesChange;

  /// 전체 막힘.
  final bool disabled;
  final List<Widget> children;

  @override
  State<PAccordion> createState() => _PAccordionState();
}

class _PAccordionState extends State<PAccordion> {
  late List<String> _inner = List.of(widget.defaultValues);
  final List<FocusNode> _triggers = [];

  List<String> get _values => widget.values ?? _inner;

  void _toggle(String value) {
    final now = _values;
    final next = now.contains(value)
        ? [
            for (final v in now)
              if (v != value) v,
          ]
        : [...now, value];
    if (widget.values == null) setState(() => _inner = next);
    widget.onValuesChange?.call(next);
  }

  /// 포커스를 받을 수 있는 트리거를 화면 위에서 아래 차례로.
  List<FocusNode> _ordered() {
    double top(FocusNode n) {
      final box = n.context?.findRenderObject();
      return box is RenderBox && box.attached
          ? box.localToGlobal(Offset.zero).dy
          : 0;
    }

    final nodes = [
      for (final n in _triggers)
        if (n.canRequestFocus && n.context != null) n,
    ]..sort((a, b) => top(a).compareTo(top(b)));
    return nodes;
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.arrowDown &&
        key != LogicalKeyboardKey.arrowUp &&
        key != LogicalKeyboardKey.home &&
        key != LogicalKeyboardKey.end) {
      return KeyEventResult.ignored;
    }
    final keys = HardwareKeyboard.instance;
    if (keys.isAltPressed || keys.isControlPressed || keys.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    final nodes = _ordered();
    final i = nodes.indexWhere((n) => n.hasPrimaryFocus);
    if (i < 0) return KeyEventResult.ignored;
    final n = nodes.length;
    final next = key == LogicalKeyboardKey.arrowDown
        ? nodes[(i + 1) % n]
        : key == LogicalKeyboardKey.arrowUp
        ? nodes[(i - 1 + n) % n]
        : key == LogicalKeyboardKey.home
        ? nodes.first
        : nodes.last;
    next.requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final inline = widget.variant == PAccordionVariant.inline;
    final rows = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      // 항목 사이 선 — inline 만(1px · 좌우 24). 첫 항목 위 · 끝 항목 아래에는 긋지 않는다
      if (inline && i > 0) {
        rows.add(
          Padding(
            key: ValueKey('paccordion-divider-$i'),
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
            child: SizedBox(
              height: 1,
              child: ColoredBox(color: c.strokeNeutralSubtle),
            ),
          ),
        );
      }
      rows.add(widget.children[i]);
    }
    return _PAccordionScope(
      variant: widget.variant,
      values: _values,
      disabled: widget.disabled,
      toggle: _toggle,
      register: (n) => _triggers.add(n),
      unregister: (n) => _triggers.remove(n),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: Column(
          key: const ValueKey('paccordion'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: inline ? 0 : PSpacing.x2,
          children: rows,
        ),
      ),
    );
  }
}

class _PAccordionScope extends InheritedWidget {
  const _PAccordionScope({
    required this.variant,
    required this.values,
    required this.disabled,
    required this.toggle,
    required this.register,
    required this.unregister,
    required super.child,
  });

  final PAccordionVariant variant;
  final List<String> values;
  final bool disabled;
  final void Function(String value) toggle;
  final void Function(FocusNode node) register;
  final void Function(FocusNode node) unregister;

  static _PAccordionScope of(BuildContext context, String part) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_PAccordionScope>();
    assert(scope != null, '$part 는 PAccordion 안에 둔다.');
    return scope!;
  }

  @override
  bool updateShouldNotify(_PAccordionScope oldWidget) =>
      variant != oldWidget.variant ||
      disabled != oldWidget.disabled ||
      !_same(values, oldWidget.values);

  static bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 항목 면 — separated 는 Card 면(1px `stroke-neutral-weak` · 모서리 16 · 그림자 없음, 바탕은 놓인 면 그대로). 누름 바탕 ·
/// 펼친 내용을 모서리에서 자른다. inline 은 면이 없다.
class _PAccordionFace extends StatelessWidget {
  const _PAccordionFace({required this.variant, required this.child});

  final PAccordionVariant variant;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (variant == PAccordionVariant.inline) return child;
    return DecoratedBox(
      key: const ValueKey('paccordion-item-face'),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.strokeNeutralWeak),
        borderRadius: BorderRadius.circular(PRounded.r4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PRounded.r4 - 1),
        child: child,
      ),
    );
  }
}

/// 항목 — 트리거 + 펼친 내용([child]). [value] 가 [PAccordion.values] 에 든다.
class PAccordionItem extends StatefulWidget {
  const PAccordionItem({
    super.key,
    required this.value,
    required this.title,
    required this.child,
    this.description,
    this.prefixIcon,
    this.disabled = false,
    this.headingLevel = 3,
  });

  final String value;

  /// 제목 — 무엇의 상세인지(늘 줄을 바꾼다).
  final String title;

  /// 설명 — 제목 아래 한 줄 요약(있을 때만, 높이 74).
  final String? description;

  /// 앞 아이콘 — lucide 22(있을 때만).
  final IconData? prefixIcon;
  final bool disabled;

  /// 머리말 단계 — 놓인 자리를 따른다(기본 3).
  final int headingLevel;

  /// 펼친 내용 — 글이면 `DefaultTextStyle`(14 / 22 · `fg-neutral-muted`)을 받는다.
  final Widget child;

  @override
  State<PAccordionItem> createState() => _PAccordionItemState();
}

class _PAccordionItemState extends State<PAccordionItem> {
  final FocusNode _focus = FocusNode(debugLabel: 'PAccordionItem');
  final String _panelId = 'paccordion-panel-${UniqueKey()}';
  _PAccordionScope? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = _PAccordionScope.of(context, 'PAccordionItem');
    if (!identical(_scope, next) && _scope == null) next.register(_focus);
    _scope = next;
  }

  @override
  void dispose() {
    _scope?.unregister(_focus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _PAccordionScope.of(context, 'PAccordionItem');
    final open = scope.values.contains(widget.value);
    final disabled = scope.disabled || widget.disabled;
    return _PAccordionFace(
      variant: scope.variant,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PDisclosureTrigger(
            title: widget.title,
            description: widget.description,
            prefixIcon: widget.prefixIcon,
            open: open,
            disabled: disabled,
            headingLevel: widget.headingLevel,
            controlsId: _panelId,
            focusNode: _focus,
            onToggle: () => scope.toggle(widget.value),
          ),
          PExpandMotion(
            open: open,
            keyPrefix: 'paccordion-panel',
            child: Padding(
              key: const ValueKey('paccordion-panel'),
              padding: const EdgeInsets.fromLTRB(
                PSpacing.x6,
                0,
                PSpacing.x6,
                PSpacing.x4,
              ),
              child: Semantics(
                container: true,
                identifier: _panelId,
                child: DefaultTextStyle(
                  style: PTypography.articleNote.copyWith(
                    color: context.colors.fgNeutralMuted,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 상세가 없는 항목 — 트리거가 아닌 그냥 줄. 같은 위아래 16 · 좌우 24 · 글이라 높이(54 · 74)와 글 시작이 트리거와 같다. 누르는
/// 줄이 아니라 바탕이 없고 막힌 모양도 아니다.
class PAccordionPlainItem extends StatelessWidget {
  const PAccordionPlainItem({
    super.key,
    required this.title,
    this.description,
    this.prefixIcon,
  });

  final String title;
  final String? description;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scope = _PAccordionScope.of(context, 'PAccordionPlainItem');
    final tall = description != null;
    return _PAccordionFace(
      variant: scope.variant,
      child: ConstrainedBox(
        key: const ValueKey('paccordion-plain'),
        constraints: BoxConstraints(minHeight: tall ? 74 : 54),
        child: Semantics(
          container: true,
          label: tall ? '$title\n$description' : title,
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.x6,
              vertical: PSpacing.x4,
            ),
            child: Row(
              spacing: PSpacing.x3,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (prefixIcon != null)
                  SizedBox.square(
                    key: const ValueKey('pdisc-prefix'),
                    dimension: PDisclosureTrigger.prefixIconSize,
                    child: Icon(
                      prefixIcon,
                      size: PDisclosureTrigger.prefixIconSize,
                      color: c.fgNeutral,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: PSpacing.x0_5,
                    children: [
                      Text(
                        keepAll(title),
                        key: const ValueKey('pdisc-title'),
                        style: PTypography.t5.copyWith(
                          color: c.fgNeutral,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (description != null)
                        Text(
                          keepAll(description!),
                          key: const ValueKey('pdisc-description'),
                          style: PTypography.t3.copyWith(
                            color: c.fgNeutralSubtle,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 목록 머리 — 시트 · 대화상자에서 아코디언 위 한 줄. 높이 32 · 아래 8 · 제목 16 / 22 · 700(카드 머리와 같은 글) + 오른쪽
/// [trailing](모두 펼치기). 카드 안이면 [PCardHeader] 가 이 자리다.
class PAccordionHeader extends StatelessWidget {
  const PAccordionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.headingLevel = 3,
  });

  /// 제목 — 건수를 붙인다("혜택 상세 · 12건").
  final String title;
  final Widget? trailing;
  final int headingLevel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('paccordion-header'),
      padding: const EdgeInsets.only(bottom: PSpacing.x2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PSpacing.x8),
        // 오른쪽 동작이 머리 폭의 절반을 넘으면 제목 아래 줄 오른쪽 끝으로 간다(03-G 4A)
        child: PHeaderRow(
          gap: PSpacing.x2,
          actionBleed: kTextButtonPaddingX,
          title: Semantics(
            header: true,
            headingLevel: headingLevel,
            child: Text(
              keepAll(title),
              key: const ValueKey('paccordion-header-title'),
              semanticsLabel: title,
              style: PTypography.t5.copyWith(
                color: context.colors.fgNeutral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          action: trailing,
        ),
      ),
    );
  }
}

/// 모두 펼치기 — 목록 머리 오른쪽 글 버튼([PTextButton] — SEED Text Button: 보이는 36 · 14 · 700 · `fg-neutral-muted`, 아이콘 없음,
/// 누르는 영역 44).
///
/// 상세가 있는 항목([expandable])만 열고 닫는다. 하나라도 접혀 있으면 [expandLabel] 로 모두 열고, 모두 열려 있으면
/// [collapseLabel] 로 모두 접는다. 이름은 보이는 글 그대로, 펼침 상태를 따로 읽지 않는다.
class PAccordionExpandAll extends StatelessWidget {
  const PAccordionExpandAll({
    super.key,
    required this.values,
    required this.expandable,
    required this.onValuesChange,
    required this.expandLabel,
    required this.collapseLabel,
  });

  /// 아코디언과 같은 펼친 항목 목록.
  final List<String> values;

  /// 상세가 있는 항목의 value 목록 — 모두 펼치면 이것을 다 연다.
  final List<String> expandable;
  final ValueChanged<List<String>> onValuesChange;
  final String expandLabel;
  final String collapseLabel;

  bool get _allOpen =>
      expandable.isNotEmpty && expandable.every(values.contains);

  void _activate() {
    onValuesChange(
      _allOpen
          ? [
              for (final v in values)
                if (!expandable.contains(v)) v,
            ]
          : [...values, ...expandable.where((v) => !values.contains(v))],
    );
  }

  @override
  Widget build(BuildContext context) => PTextButton(
    label: _allOpen ? collapseLabel : expandLabel,
    onPressed: _activate,
    // 줄 끝에서 −14 — 글 끝이 부모 여백에 선다(레시피 EXPAND_ALL `-mr-x3_5`, D2)
    bleedEnd: true,
  );
}
