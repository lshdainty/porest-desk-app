import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/radio/p_radio.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 놓이는 자리 — sheet(기본: Input Button 이 연 검색 시트, 고르면 닫힌다 · 열면 검색칸에 초점) · inline(화면 · 단계 안,
/// 라디오만 바뀌고 단계의 버튼이 반영한다).
enum PSearchableListPlacement { sheet, inline }

/// 불러오는 줄의 앞 자리 — none(기본) · logo(Logo Tile 40) · cardArt(카드 그림 56) · avatar(42 원).
enum PSearchableListSkeletonPrefix { none, logo, cardArt, avatar }

// searchable-list.yaml — 줄 · 검색칸의 나머지 값은 list.yaml · input.yaml 이다.
const double _gap = PSpacing.x2; // root.gap — 검색칸 ↔ 결과 목록
const double _highlightInsetX =
    PSpacing.x1_5; // highlight.insetX — 강조 · 누름 때 좌우 6 들어온 바탕(평소 0)
const double _highlightRadius =
    PRounded.r2_5; // highlight.radius — 강조 · 누름 때 10(평소 0). List 누름 바탕과 같다
const double _prefixGap = PSpacing.x3; // 앞 붙이개 ↔ 글 12
const double _bodyEndGap = PSpacing.x2_5; // 글 ↔ 오른쪽 라디오
const double _logoSize = 40; // prefix.logo
const double _cardArtWidth = 56; // prefix.cardArt — 카드 비율
const double _cardArtRatio = 1.586;
const double _avatarSize = 42; // 스켈레톤의 아바타 자리(두 줄 줄 — 36 은 한 줄)
const int _skeletonRows = 5; // skeleton.size — 줄 다섯

/// Searchable List — 위 검색칸에 치는 대로 아래 목록이 걸러지고, 그 목록에서 하나를 고르는 묶음. 구조는 groo 가 둔
/// 컴포넌트(SEED 에는 Combobox 가 없다 — 부품마다 SEED 를 따랐다), 수치 원본은 groo-design
/// `specs/components/searchable-list.yaml`(값은 `test/fixtures/design_spec/searchable-list.json`). 웹(desk-front
/// `src/shared/ds/searchable-list`)과 같은 값 · 동작이다. 앱은 늘 large(검색칸 40)이고 시트만 쓴다(팝오버 없음).
///
/// 구성 — 묶음 [PSearchableList] 의 [children] 에 [PSearchableListInput] 과 결과 자리(결과 [PSearchableListResults] ·
/// 0건 [PSearchableListEmpty] · 실패 [PSearchableListError] · 불러오는 줄 [PSearchableListSkeleton] 중 하나)를 놓는다.
/// 거르는 것은 쓰는 쪽이다 — 묶음은 목록을 들지 않는다. [onQueryChanged] 로 받은 검색어로 쓰는 쪽이 바로 거르고(분류 · 줄을
/// 다시 그린다), 서버 목록은 [onSearch](마지막 입력 뒤 [searchDelay], 기본 300ms 에 한 번)로 받아 그린다. 묶음이 하는 일은
/// 검색어 · 강조 · 고름 · 키보드 · 알림이다.
///
/// 값 · 검색어 — [value] · [query] 를 주면 제어(없음은 빈 글 ''), 안 주면 안에서 든다([defaultValue] · [defaultQuery]).
/// 고르면 [onValueChanged] — 시트는 여기서 닫는다.
///
/// 키보드(콤보박스 — 사용자 결정 12A) — 초점은 늘 검색칸에 있고 줄은 초점을 받지 않는다. 앱은 터치 위주라 하드웨어
/// 키보드가 있을 때만 쓰인다: 글자는 거르고 강조를 지운다 · ↓ ↑ 는 강조를 한 줄씩(강조가 없으면 ↓ 첫 줄 · ↑ 마지막 줄,
/// 끝에서 멈춘다 — 분류 머리는 건너뛴다) · Enter 는 강조한 줄을 고른다(없으면 아무것도 하지 않는다) · Esc 는 검색어가
/// 있으면 지운다(뒤로 가기는 시트를 닫는 것이고 검색어를 지우지 않는다). 글자를 조합하는 동안(한글)의 ↓ ↑ Enter Esc 는
/// 조합의 것이다. 강조한 줄은 보이게 스크롤한다.
///
/// 시트에서 열면 검색칸에 초점이 가고 지금 값이 가운데 오게 스크롤한다. 높이가 정해진 자리(시트의 고정 높이 · 화면의 남는
/// 자리)에서는 검색칸이 위에 붙고 결과만 스크롤한다 — 높이가 정해지지 않은 스크롤 안에서는 그 스크롤이 함께 움직인다.
class PSearchableList extends StatefulWidget {
  const PSearchableList({
    super.key,
    this.value,
    this.defaultValue,
    this.onValueChanged,
    this.query,
    this.defaultQuery = '',
    this.onQueryChanged,
    this.onSearch,
    this.searchDelay = const Duration(milliseconds: 300),
    this.placement = PSearchableListPlacement.sheet,
    this.focusNode,
    required this.children,
  });

  /// 검색칸의 초점 노드 — 시트가 첫 초점을 이리로 넘겨줄 때(`PBottomSheet.show(initialFocus: …)`) 같은 노드를 둘에 준다.
  /// 주면 검색칸은 열릴 때 스스로 초점을 잡지 않는다(시트가 정한다 — 웹 `focusSearchableList(event)` 와 같다). 노드의 주인은
  /// 쓰는 쪽이다(묶음이 지우지 않는다). 안 주면 묶음이 만들고, 시트 자리에서는 열릴 때 한 번 스스로 잡는다.
  final FocusNode? focusNode;

  /// 지금 고른 값 — 오른쪽 라디오가 켜진 줄. 주면 제어(없음은 '').
  final String? value;
  final String? defaultValue;

  /// 고르면 — 시트는 여기서 닫는다([PSearchableListPlacement.sheet]).
  final ValueChanged<String>? onValueChanged;

  /// 검색어 — 주면 제어.
  final String? query;
  final String defaultQuery;

  /// 치는 대로 — 들고 있는 목록은 여기서 바로 거른다.
  final ValueChanged<String>? onQueryChanged;

  /// 서버 검색 — 마지막 입력 뒤 [searchDelay] 에 한 번.
  final ValueChanged<String>? onSearch;
  final Duration searchDelay;
  final PSearchableListPlacement placement;

  /// 검색칸 · 결과 자리.
  final List<Widget> children;

  @override
  State<PSearchableList> createState() => _PSearchableListState();
}

class _PSearchableListState extends State<PSearchableList> {
  String? _valueInner;
  late String _queryInner = widget.defaultQuery;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _highlighted;
  _HighlightSource _source = _HighlightSource.keyboard;
  Timer? _timer;

  /// 지금 그려진 줄 — 값 → 줄의 문맥. 화살표 순서는 그려진 세로 자리로 정한다.
  final Map<String, BuildContext> _options = {};

  String? get _value => widget.value ?? _valueInner;
  String get _query => widget.query ?? _queryInner;

  @override
  void initState() {
    super.initState();
    _valueInner = widget.defaultValue;
    _controller = TextEditingController(text: _query);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.onKeyEvent = _onKey;
    if (widget.placement == PSearchableListPlacement.sheet) {
      // 열면 지금 값이 가운데 오게 — 줄이 그려진 뒤에
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealCurrent());
    }
  }

  @override
  void didUpdateWidget(PSearchableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 제어한 검색어가 밖에서 바뀌면 칸의 글도 따라간다
    final query = widget.query;
    if (query != null && query != _controller.text) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else if (_focusNode.onKeyEvent == _onKey) {
      _focusNode.onKeyEvent = null;
    }
    _controller.dispose();
    super.dispose();
  }

  void _select(String next) {
    if (widget.value == null) setState(() => _valueInner = next);
    widget.onValueChanged?.call(next);
  }

  /// 치기 · 지우기 · Esc — 강조는 지우고, 서버 검색은 마지막 입력 뒤 한 번.
  void _changeQuery(String next) {
    setState(() {
      _highlighted = null;
      if (widget.query == null) _queryInner = next;
    });
    widget.onQueryChanged?.call(next);
    if (widget.onSearch != null) {
      _timer?.cancel();
      _timer = Timer(widget.searchDelay, () => widget.onSearch?.call(next));
    }
  }

  void _highlight(String? id, _HighlightSource source) {
    if (_highlighted == id && _source == source) return;
    setState(() {
      _highlighted = id;
      _source = source;
    });
  }

  /// 마우스가 목록을 떠났다 — 마우스 강조만 지운다(화살표로 짚은 강조는 남긴다. Q-007-2).
  void _clearPointerHighlight() {
    if (_highlighted != null && _source == _HighlightSource.pointer) {
      setState(() => _highlighted = null);
    }
  }

  void _register(String value, BuildContext context) =>
      _options[value] = context;

  void _unregister(String value, BuildContext context) {
    if (_options[value] == context) _options.remove(value);
    // 강조한 줄이 걸러져 사라지면 강조도 지운다 — 없는 줄을 가리키지 않게(줄이 다시 그려지는 프레임은 건너뛴다)
    if (_highlighted == value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _highlighted == value && !_options.containsKey(value)) {
          setState(() => _highlighted = null);
        }
      });
    }
  }

  /// 그려진 줄을 위에서 아래로.
  List<MapEntry<String, BuildContext>> _ordered() {
    final entries = <(double, MapEntry<String, BuildContext>)>[];
    for (final e in _options.entries) {
      final box = e.value.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      entries.add((box.localToGlobal(Offset.zero).dy, e));
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final e in entries) e.$2];
  }

  void _revealCurrent() {
    if (!mounted) return;
    final current = _value;
    final ctx = current == null ? null : _options[current];
    if (ctx == null || !ctx.mounted) return;
    Scrollable.ensureVisible(ctx, alignment: 0.5, duration: Duration.zero);
  }

  void _move(int step) {
    final ordered = _ordered();
    if (ordered.isEmpty) return;
    final at = ordered.indexWhere((e) => e.key == _highlighted);
    final next = at < 0
        ? (step == 1 ? 0 : ordered.length - 1)
        : math.min(ordered.length - 1, math.max(0, at + step));
    final target = ordered[next];
    _highlight(target.key, _HighlightSource.keyboard);
    if (target.value.mounted) {
      Scrollable.ensureVisible(
        target.value,
        duration: Duration.zero,
        alignmentPolicy: step == 1
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }

  /// 검색칸의 키 — 글자를 조합하는 동안(한글)은 조합의 것이다.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final composing = _controller.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      _move(key == LogicalKeyboardKey.arrowDown ? 1 : -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      // 강조가 없으면 아무것도 하지 않는다
      if (event is KeyDownEvent) _selectHighlighted();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_query.isEmpty) return KeyEventResult.ignored;
      if (event is KeyDownEvent) {
        _controller.clear();
        _changeQuery('');
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _selectHighlighted() {
    final id = _highlighted;
    if (id != null && _options.containsKey(id)) _select(id);
  }

  @override
  Widget build(BuildContext context) {
    return _PSearchableListScope(
      state: this,
      value: _value,
      query: _query,
      highlighted: _highlighted,
      source: _source,
      placement: widget.placement,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 높이가 정해진 자리면 결과 자리가 남는 높이 안에서 스크롤한다(검색칸은 위에 붙는다)
          final bounded = constraints.hasBoundedHeight;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: _gap,
            children: [
              for (final child in widget.children)
                bounded && child is _PSearchableListBody
                    ? Flexible(child: child)
                    : child,
            ],
          );
        },
      ),
    );
  }
}

enum _HighlightSource { keyboard, pointer }

/// 결과 자리 — 높이가 정해진 자리에서 남는 높이를 받는 위젯(결과 · 0건 · 실패 · 불러오는 줄).
abstract interface class _PSearchableListBody {}

class _PSearchableListScope extends InheritedWidget {
  const _PSearchableListScope({
    required this.state,
    required this.value,
    required this.query,
    required this.highlighted,
    required this.source,
    required this.placement,
    required super.child,
  });

  final _PSearchableListState state;
  final String? value;
  final String query;
  final String? highlighted;
  final _HighlightSource source;
  final PSearchableListPlacement placement;

  static _PSearchableListScope of(BuildContext context, String widget) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_PSearchableListScope>();
    assert(scope != null, '$widget 은 PSearchableList 안에서 쓴다');
    return scope!;
  }

  @override
  bool updateShouldNotify(_PSearchableListScope old) =>
      value != old.value ||
      query != old.query ||
      highlighted != old.highlighted ||
      source != old.source ||
      placement != old.placement;
}

/// 카탈로그 전용 — [value] 줄을 강조한 모습으로 멈춰 그린다(견본이 강조를 한 장으로 보여 줄 때만 쓴다. 실제로는 화살표 ·
/// 마우스로 짚은 한 줄만 강조된다).
class PSearchableListHighlightPreview extends InheritedWidget {
  const PSearchableListHighlightPreview({
    super.key,
    required this.value,
    required super.child,
  });

  final String value;

  static String? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PSearchableListHighlightPreview>()
      ?.value;

  @override
  bool updateShouldNotify(PSearchableListHighlightPreview oldWidget) =>
      value != oldWidget.value;
}

// ── 검색칸 ───────────────────────────────────────────────────

/// 검색칸 — Input 밑줄형(앞 돋보기 · 지우기)을 스스로 건다. large 40 · 좌우 24 안에 두어 돋보기와 줄의 앞 붙이개가 한 줄에
/// 선다. [placeholder] 는 "{무엇} 검색"("은행 이름 검색"), [semanticLabel] 은 이름("검색" — 라벨이 없다).
/// [autofocus] 를 안 주면 시트(`sheet`)일 때만 열릴 때 초점이 간다.
class PSearchableListInput extends StatefulWidget {
  const PSearchableListInput({
    super.key,
    this.placeholder,
    required this.semanticLabel,
    this.autofocus,
  });

  final String? placeholder;
  final String semanticLabel;
  final bool? autofocus;

  @override
  State<PSearchableListInput> createState() => _PSearchableListInputState();
}

class _PSearchableListInputState extends State<PSearchableListInput> {
  @override
  void initState() {
    super.initState();
    final scope = context
        .getInheritedWidgetOfExactType<_PSearchableListScope>();
    final focusOnOpen =
        widget.autofocus ?? scope?.placement == PSearchableListPlacement.sheet;
    final node = scope?.state._focusNode;
    // 노드를 밖에서 받았으면 첫 초점은 시트가 넘겨준다(Q-007-3) — 여기서 한 프레임 뒤에 다시 잡지 않는다
    if (!focusOnOpen || node == null || scope!.state.widget.focusNode != null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && node.canRequestFocus && !node.hasPrimaryFocus) {
        node.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _PSearchableListScope.of(
      context,
      'PSearchableListInput',
    ).state;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
      child: PInput(
        variant: PInputVariant.underline,
        controller: state._controller,
        focusNode: state._focusNode,
        placeholder: widget.placeholder,
        semanticLabel: widget.semanticLabel,
        prefixIcon: LucideIcons.search,
        clearable: true,
        onChanged: state._changeQuery,
        // 소프트 키보드의 확인 — 하드웨어 Enter 와 같다(강조가 없으면 아무것도 하지 않는다)
        onSubmitted: (_) => state._selectHighlighted(),
      ),
    );
  }
}

// ── 결과 ─────────────────────────────────────────────────────

/// 결과 목록 — 이름은 그 목록의 대상("은행"). 높이가 정해진 자리면 이 안에서 스크롤한다.
class PSearchableListResults extends StatelessWidget
    implements _PSearchableListBody {
  const PSearchableListResults({
    super.key,
    required this.semanticLabel,
    required this.children,
  });

  final String semanticLabel;

  /// 줄 · 분류.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scope = _PSearchableListScope.of(context, 'PSearchableListResults');
    return MouseRegion(
      onExit: (_) => scope.state._clearPointerHighlight(),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.list,
        label: semanticLabel,
        // 줄을 눌러도 초점은 검색칸에 남는다(같은 탭 영역)
        child: TextFieldTapRegion(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final list = Column(
                key: const ValueKey('searchable-list-results'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              );
              return constraints.hasBoundedHeight
                  ? SingleChildScrollView(child: list)
                  : list;
            },
          ),
        ),
      ),
    );
  }
}

/// 분류 — 머리는 List Header mediumWeak(14 · 500 · fg-neutral-subtle). 걸러져 줄이 남지 않은 분류는 머리째 숨긴다.
class PSearchableListGroup extends StatelessWidget {
  const PSearchableListGroup({
    super.key,
    required this.label,
    required this.children,
  });

  /// 분류 이름 — "시중은행" · "증권사"(짧은 명사).
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PListHeader(title: label),
          ...children,
        ],
      ),
    );
  }
}

/// 결과 줄 — List 의 누르는 줄(위아래 12 · 좌우 24, 제목 16 / 22 · 400, 설명 13 / 18). 초점은 받지 않는다. 오른쪽 라디오(24)는
/// 스스로 그린다(보는 표시 — 고름은 줄이 알린다). 고른 줄의 바탕은 칠하지 않는다.
///
/// 강조(화살표 · 마우스로 짚음)와 누름은 같은 바탕이다 — 좌우 6 들어온 bg-layer-default-pressed · 모서리 10. 누르면 콘텐츠만
/// 2px 거리 줄어든다(기준 max(높이, 폭 ÷ 4, 24) — 모션 줄이기면 하지 않는다). 화살표로 옮길 때는 바로 바뀌고, 마우스로 올린
/// 바탕만 150ms 로 바뀐다.
///
/// 앞 붙이개([prefix] — Logo Tile 40 · 카드 그림 56 · Avatar)는 쓰는 쪽이 넣는다. 이름 옆이라 읽지 않는다.
class PSearchableListItem extends StatefulWidget {
  const PSearchableListItem({
    super.key,
    required this.value,
    required this.title,
    this.detail,
    this.detailChild,
    this.prefix,
  }) : assert(
         detail == null || detailChild == null,
         '설명은 글(detail)이나 위젯(detailChild) 하나만 준다',
       );

  /// 고르면 onValueChanged 로 가는 값.
  final String value;
  final String title;

  /// 설명 — 카드사 · 종류.
  final String? detail;

  /// 설명 자리에 글 대신 두는 위젯(글 + 배지) — 글자 모양은 설명(13 · 옅은 색)을 따른다.
  final Widget? detailChild;
  final Widget? prefix;

  @override
  State<PSearchableListItem> createState() => _PSearchableListItemState();
}

class _PSearchableListItemState extends State<PSearchableListItem> {
  _PSearchableListState? _list;
  bool _pressed = false;

  /// 누름 축소의 기준 길이 max(높이, 폭 ÷ 4, 24) — 누르는 순간 그려진 크기에서 잰다.
  double _basis = 24;

  @override
  void initState() {
    super.initState();
    _list = context
        .getInheritedWidgetOfExactType<_PSearchableListScope>()
        ?.state;
    _list?._register(widget.value, context);
  }

  @override
  void didUpdateWidget(PSearchableListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _list?._unregister(oldWidget.value, context);
      _list?._register(widget.value, context);
    }
  }

  @override
  void dispose() {
    _list?._unregister(widget.value, context);
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    if (value) {
      final size = context.size;
      if (size != null) {
        _basis = math.max(size.height, math.max(size.width / 4, 24));
      }
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scope = _PSearchableListScope.of(context, 'PSearchableListItem');
    final c = context.colors;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final selected = scope.value == widget.value;
    final previewed =
        PSearchableListHighlightPreview.maybeOf(context) == widget.value;
    final highlighted = scope.highlighted == widget.value || previewed;
    final on = highlighted || _pressed;
    final fromPointer =
        highlighted && !previewed && scope.source == _HighlightSource.pointer;

    final detailStyle = PTypography.t3.copyWith(color: c.fgNeutralSubtle);
    final body = Padding(
      padding: const EdgeInsetsDirectional.only(end: _bodyEndGap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: PSpacing.x0_5,
        children: [
          Text(
            keepAll(widget.title),
            key: const ValueKey('searchable-list-title'),
            semanticsLabel: widget.title,
            style: PTypography.t5.copyWith(
              color: c.fgNeutral,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (widget.detail != null)
            Text(
              keepAll(widget.detail!),
              key: const ValueKey('searchable-list-detail'),
              semanticsLabel: widget.detail,
              style: detailStyle,
            ),
          if (widget.detailChild != null)
            DefaultTextStyle(
              key: const ValueKey('searchable-list-detail'),
              style: detailStyle,
              child: widget.detailChild!,
            ),
        ],
      ),
    );

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpacing.globalGutter,
        vertical: PSpacing.x3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.prefix != null)
            Padding(
              key: const ValueKey('searchable-list-prefix'),
              padding: const EdgeInsetsDirectional.only(end: _prefixGap),
              child: ExcludeSemantics(child: widget.prefix),
            ),
          Expanded(child: body),
          // 지금 값 — 보는 표시. 고름은 줄이 알린다. 줄 전체가 줄어들므로 동그라미는 따로 줄지 않는다
          ExcludeSemantics(
            child: PRadiomark(
              key: const ValueKey('searchable-list-radio'),
              checked: selected,
              size: PRadioSize.large,
              pressed: _pressed,
              scaleOnPress: false,
            ),
          ),
        ],
      ),
    );

    final content = AnimatedScale(
      key: const ValueKey('searchable-list-content'),
      scale: _pressed && !reduceMotion ? (_basis - 2) / _basis : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: row,
    );

    // 바탕 층 — 줄지 않는다. 평소는 좌우 0 · 모서리 0 인 투명 바탕이고, 강조 · 누름이면 좌우 6 들어오며 모서리 10 으로 둥글어진다
    // (Menu 알약과 같은 움직임 — 색 · 들임 · 모서리 150ms). 마우스로 올린 때만 전환하고 화살표 · 누름은 바로 바뀐다
    final background = Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: on ? 1 : 0),
        duration: fromPointer && !reduceMotion
            ? PDuration.colorTransition
            : Duration.zero,
        curve: PEasing.easing,
        builder: (context, t, _) => Padding(
          padding: EdgeInsets.symmetric(horizontal: _highlightInsetX * t),
          child: DecoratedBox(
            key: const ValueKey('searchable-list-highlight'),
            decoration: BoxDecoration(
              color: _PremultipliedColorTween(
                end: c.bgLayerDefaultPressed,
              ).transform(t),
              borderRadius: BorderRadius.circular(_highlightRadius * t),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      selected: selected,
      onTap: () => scope.state._select(widget.value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (e) {
          // 마우스를 움직여 올린 줄만 강조한다 — 화살표로 스크롤해 줄이 마우스 밑으로 지나가도 강조가 튀지 않게
          if (e.kind == PointerDeviceKind.mouse && !highlighted) {
            scope.state._highlight(widget.value, _HighlightSource.pointer);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: () => scope.state._select(widget.value),
          child: Stack(
            fit: StackFit.passthrough,
            children: [background, content],
          ),
        ),
      ),
    );
  }
}

/// 색 사이 — 투명에서 나타날 때 그 색 그대로 진해진다(미리 곱한 알파로 섞는다 — 투명한 검정을 거치지 않는다).
class _PremultipliedColorTween extends Tween<Color> {
  _PremultipliedColorTween({super.end}) : super(begin: const Color(0x00000000));

  @override
  Color lerp(double t) {
    final a = begin!;
    final b = end!;
    final alpha = (a.a + (b.a - a.a) * t).clamp(0.0, 1.0);
    if (alpha <= 0) return b.withValues(alpha: 0);
    double channel(double from, double to) =>
        (((from * a.a) + ((to * b.a) - (from * a.a)) * t) / alpha).clamp(
          0.0,
          1.0,
        );
    return Color.from(
      alpha: alpha,
      red: channel(a.r, b.r),
      green: channel(a.g, b.g),
      blue: channel(a.b, b.b),
    );
  }
}

// ── 0건 · 실패 · 불러오는 동안 ────────────────────────────────

/// 0건 — 목록 자리의 Result Section medium. 제목은 검색어로 만든다("'{검색어}'에 대한 검색 결과가 없어요" — [titleBuilder],
/// 검색어가 공백뿐이면 빈 글이 온다). 바뀌면 보조 기술이 한 번 읽는다(live region). [description] 은 할 수 있는 일
/// ("카드사 이름으로도 찾아보세요.").
class PSearchableListEmpty extends StatelessWidget
    implements _PSearchableListBody {
  const PSearchableListEmpty({
    super.key,
    this.title,
    this.titleBuilder,
    this.description,
  }) : assert(
         title != null || titleBuilder != null,
         '제목(title) 또는 검색어로 만드는 제목(titleBuilder)이 필요하다',
       );

  /// 제목 — 검색어와 상관없는 글.
  final String? title;

  /// 검색어로 만드는 제목 — 앞뒤 공백을 뗀 검색어를 받는다.
  final String Function(String query)? titleBuilder;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final scope = _PSearchableListScope.of(context, 'PSearchableListEmpty');
    return PResultSection(
      kind: PResultKind.empty,
      size: PResultSize.medium,
      icon: LucideIcons.searchX,
      title: title ?? titleBuilder!(scope.query.trim()),
      description: description,
    );
  }
}

/// 실패 — 0건과 따로(Result Section failure + "다시 시도"). 실패를 "결과가 없어요" 로 보이지 않는다.
class PSearchableListError extends StatelessWidget
    implements _PSearchableListBody {
  const PSearchableListError({
    super.key,
    required this.title,
    required this.retryLabel,
    required this.onRetry,
    this.retrying = false,
    this.description,
  });

  /// 제목 — "검색 결과를 불러오지 못했어요".
  final String title;

  /// 다시 시도 버튼의 글.
  final String retryLabel;
  final VoidCallback onRetry;

  /// 다시 시도하는 동안 — 버튼 로딩.
  final bool retrying;
  final String? description;

  @override
  Widget build(BuildContext context) {
    _PSearchableListScope.of(context, 'PSearchableListError');
    return PResultSection(
      kind: PResultKind.failure,
      size: PResultSize.medium,
      title: title,
      description: description,
      primaryAction: PResultAction(
        label: retryLabel,
        onPressed: onRetry,
        loading: retrying,
      ),
    );
  }
}

/// 불러오는 줄 — 줄 높이 그대로(위아래 12 · 좌우 24, 제목 t5 22 · 40% + 설명 t3 18 · 60%). 기본 다섯 줄. 앞 자리는 [prefix]
/// (logo 40 · 모서리 12, cardArt 폭 56 · 모서리 8, avatar 42 원). 보조 기술에는 숨긴다.
class PSearchableListSkeleton extends StatelessWidget
    implements _PSearchableListBody {
  const PSearchableListSkeleton({
    super.key,
    this.rows = _skeletonRows,
    this.prefix = PSearchableListSkeletonPrefix.none,
  });

  final int rows;
  final PSearchableListSkeletonPrefix prefix;

  Widget _prefix() => switch (prefix) {
    PSearchableListSkeletonPrefix.none => const SizedBox.shrink(),
    PSearchableListSkeletonPrefix.logo => const PSkeleton(
      width: _logoSize,
      height: _logoSize,
      radius: PSkeletonRadius.r12,
    ),
    PSearchableListSkeletonPrefix.cardArt => const PSkeleton(
      width: _cardArtWidth,
      height: _cardArtWidth / _cardArtRatio,
      radius: PSkeletonRadius.r8,
    ),
    PSearchableListSkeletonPrefix.avatar => const PSkeleton(
      width: _avatarSize,
      height: _avatarSize,
      radius: PSkeletonRadius.full,
    ),
  };

  @override
  Widget build(BuildContext context) {
    _PSearchableListScope.of(context, 'PSearchableListSkeleton');
    return ExcludeSemantics(
      child: Column(
        key: const ValueKey('searchable-list-skeleton'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows; i++)
            Padding(
              key: ValueKey('searchable-list-skeleton-row-$i'),
              padding: const EdgeInsets.symmetric(
                horizontal: PSpacing.globalGutter,
                vertical: PSpacing.x3,
              ),
              child: Row(
                children: [
                  if (prefix != PSearchableListSkeletonPrefix.none)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: _prefixGap,
                      ),
                      child: _prefix(),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: PSpacing.x0_5,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.4,
                          child: PSkeleton.text(PTypography.t5),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.6,
                          child: PSkeleton.text(PTypography.t3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
