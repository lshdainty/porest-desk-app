import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:porest_desk_app/shared/ds/checkbox/selection_control.dart';
import 'package:porest_desk_app/shared/ds/icon_picker/category_icons.dart';
import 'package:porest_desk_app/shared/ds/input/p_input.dart';
import 'package:porest_desk_app/shared/ds/input_button/p_input_button.dart';
import 'package:porest_desk_app/shared/ds/result_section/p_result_section.dart';
import 'package:porest_desk_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import 'package:porest_desk_app/shared/ds/text/keep_all.dart';
import 'package:porest_desk_app/shared/ds/tooltip/p_tooltip.dart';

// icon-picker.yaml 의 값 — 토큰이 있는 값은 토큰으로 적는다.
const double _cell = PSpacing.x12; // cell.size 48
const double _cellRadius = PRounded.r3; // cell.radius 12
const double _icon = PSpacing.x6; // icon.size 24
const double _selectedBorder = 2; // cell.borderWidth(고른 칸)
const double _focusWidth = 2; // focusRing.width
const double _focusOffset = 2; // focusRing.offset
const double _columnGapMin = PSpacing.x1; // grid.columnGapMin 4
const double _rowGap = PSpacing.x1; // grid.rowGap 4
const double _searchGap = PSpacing.x3; // grid.searchGap 12 — 찾는 동안 찾기 칸 ↔ 격자
const double _headerPaddingTop = PSpacing.x3; // groupHeader.paddingTop 12
const double _headerPaddingBottom = PSpacing.x2; // groupHeader.paddingBottom 8
const double _paddingX = PSpacing.x6; // surface.paddingX 24
const double _fogStart = 20; // scroll-fog.yaml overlayBody — 위 20
const double _fogEnd = 80; // 아래 80
const int _sheetColumns = 6; // surface sheet · grid.columns

/// 결과 수를 알리기까지 — 치기를 멈춘 뒤 한 번(글자마다 읽지 않게).
const Duration kIconPickerAnnounceDelay = Duration(milliseconds: 500);

/// 격자의 열 수와 열 사이 — 칸 48 을 들어가는 만큼 두고(시트는 6열까지) 남는 폭은 칸 사이에 고르게 나눈다(사이 최소 4).
/// 본문이 308(48 × 6 + 4 × 5)보다 좁은 폰은 들어가는 만큼만 둔다.
@visibleForTesting
({int columns, double gap}) iconGridMetrics(double width) {
  final fit = ((width + _columnGapMin) / (_cell + _columnGapMin)).floor();
  final columns = math.max(1, math.min(_sheetColumns, fit));
  final gap = columns == 1 ? 0.0 : (width - columns * _cell) / (columns - 1);
  return (columns: columns, gap: gap);
}

/// 문구 — 부르는 쪽 말로 바꿀 때. 기본은 한국어다(Color Swatch 의 색 이름과 같은 자리).
@immutable
class PIconPickerTexts {
  const PIconPickerTexts({
    this.title = '아이콘',
    this.closeLabel = '닫기',
    this.listLabel = '아이콘',
    this.searchLabel = '아이콘 검색',
    this.searchPlaceholder = '아이콘 이름 검색',
    this.clearLabel = '지우기',
    this.currentIconName = '지금 아이콘',
    this.emptyDescription = '다른 말로 찾거나 묶음에서 골라주세요.',
    this.emptyTitle = _defaultEmptyTitle,
    this.countLabel = _defaultCountLabel,
  });

  /// 시트의 이름 — 트리거 라벨도 "아이콘"(Field).
  final String title;
  final String closeLabel;

  /// 격자(listbox)의 이름.
  final String listLabel;
  final String searchLabel;
  final String searchPlaceholder;
  final String clearLabel;

  /// 세트 밖에 저장된 아이콘의 트리거 값 글 — 지우지도 바꾸지도 않는다.
  final String currentIconName;
  final String emptyDescription;

  /// 0건 — "'유니콘'에 대한 아이콘이 없어요".
  final String Function(String query) emptyTitle;

  /// 결과 수 알림 — "검색 결과 2개".
  final String Function(int count) countLabel;
}

String _defaultEmptyTitle(String query) => "'$query'에 대한 아이콘이 없어요";
String _defaultCountLabel(int count) => '검색 결과 $count개';

/// 칸 하나 — 48 · 모서리 12 · 아이콘 24. 이름은 한국어 이름(listbox 의 선택지 · 고른 상태), 마우스는 같은 글의 툴팁.
/// 고른 칸은 안쪽 2px stroke-neutral-contrast(아이콘이 밀리지 않는다) + 선 2.5(w500 글꼴), 바탕은 칠하지 않는다. 눌리는 동안 바탕
/// bg-layer-floating-pressed + 2px 거리 축소(48 → 0.958, 모션 줄이기면 하지 않는다), 키보드 포커스에만 바깥 링 2px · 띄움 2px.
class PIconPickerCell extends StatefulWidget {
  const PIconPickerCell({
    super.key,
    required this.icon,
    required this.selected,
    required this.onSelect,
    this.focusNode,
    this.tabbable = true,
    this.onKey,
    this.onFocus,
  });

  final PCategoryIcon icon;

  /// 지금 값의 칸.
  final bool selected;

  /// 누르면 — 고른다.
  final ValueChanged<String> onSelect;
  final FocusNode? focusNode;

  /// 격자의 Tab 한 자리(고른 칸, 없으면 첫 칸).
  final bool tabbable;
  final KeyEventResult Function(String id, KeyEvent event)? onKey;
  final ValueChanged<String>? onFocus;

  @override
  State<PIconPickerCell> createState() => _PIconPickerCellState();
}

class _PIconPickerCellState extends State<PIconPickerCell> {
  FocusNode? _own;
  bool _pressed = false;
  bool _hovered = false;
  bool _focusVisible = false;

  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(PIconPickerCell old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _own)?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _own?.dispose();
    super.dispose();
  }

  void _onFocus() {
    // 키보드로 초점이 왔을 때만 링 — 손가락으로 눌러도 초점은 가지만 링은 없다
    final visible =
        _node.hasFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (visible != _focusVisible) setState(() => _focusVisible = visible);
    if (_node.hasFocus) widget.onFocus?.call(widget.icon.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selected = widget.selected;
    final glyph = categoryGlyph(widget.icon.id, bold: selected);
    const ring = _cell + (_focusOffset + _focusWidth) * 2;

    final face = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // 바탕 — 호버 · 누름만 칠한다(150ms)
        Positioned.fill(
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              end: (_pressed || _hovered)
                  ? c.bgLayerFloatingPressed
                  : const Color(0x00000000),
            ),
            duration: PDuration.colorTransition,
            curve: PEasing.easing,
            builder: (context, color, _) => DecoratedBox(
              key: const ValueKey('icon-cell-face'),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(_cellRadius),
              ),
            ),
          ),
        ),
        ExcludeSemantics(
          child: Icon(glyph, size: _icon, color: c.fgNeutral),
        ),
        // 고른 칸 — 안쪽 2px(아이콘이 밀리지 않는다)
        if (selected)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('icon-cell-selected'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_cellRadius),
                  border: Border.all(
                    color: c.strokeNeutralContrast,
                    width: _selectedBorder,
                  ),
                ),
              ),
            ),
          ),
        if (_focusVisible)
          Positioned(
            left: -(_focusOffset + _focusWidth),
            top: -(_focusOffset + _focusWidth),
            width: ring,
            height: ring,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('icon-cell-focus-ring'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    _cellRadius + _focusOffset + _focusWidth,
                  ),
                  border: Border.all(
                    color: c.strokeFocusRing,
                    width: _focusWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return PTooltip(
      message: widget.icon.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Semantics(
          container: true,
          label: widget.icon.name,
          selected: selected,
          focusable: true,
          focused: _node.hasFocus,
          onTap: () => widget.onSelect(widget.icon.id),
          child: ExcludeSemantics(
            child: Focus(
              focusNode: _node,
              skipTraversal: !widget.tabbable,
              onKeyEvent: (_, e) =>
                  widget.onKey?.call(widget.icon.id, e) ??
                  KeyEventResult.ignored,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) => setState(() => _pressed = false),
                onTap: () => widget.onSelect(widget.icon.id),
                child: SelectionPressScale(
                  pressed: _pressed,
                  size: const Size.square(_cell),
                  child: SizedBox.square(dimension: _cell, child: face),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 여는 자리 안 — 찾기 칸 + 묶음 격자(스크롤 · 끝 흐림) + 결과 수 알림. 시트 안에 넣거나 견본으로 그대로 그린다. 높이는 놓인
/// 자리가 정한다. 앱은 시트만 쓴다(6열 · 찾기 칸 40 — 팝오버 7열 · 34 는 1280 이상 웹 몫).
///
/// 찾기 — 위에 붙은 Input 밑줄형(앞 돋보기 · 지우기), 스크롤해도 그 자리다. 치는 대로 세트를 거른다(이름 · 찾는 말 · id — 소문자 ·
///   공백 없이 부분 일치). 결과는 세트 차례 그대로 묶음 머리 없이, 개수는 치기를 멈추면 한 번 알린다. 0건이면 격자 자리에 Result
///   Section medium. 한글을 조합하는 동안의 ↓ 는 조합의 것이다.
/// 격자 — 묶음은 머리(14 · 500 · fg-neutral-subtle, 위 12 · 아래 8)가 이름. 칸 48 을 6열(남는 폭은 칸 사이에 고르게, 사이 최소 4)로 두고
///   줄 사이 4. 스크롤 상자 맨 위(흐림 여백 20 아래)가 첫 묶음 머리이고, 찾는 동안은 머리 대신 격자 위 12.
/// 키보드 — 격자에 Tab 하나(고른 칸, 없으면 첫 칸). ← → 는 차례대로(줄 끝에서 다음 줄 · 다음 묶음으로, 끝에서 멈춘다 — RTL 은 반대),
///   ↑ ↓ 는 보이는 위아래 줄의 가장 가까운 칸(묶음 머리를 넘는다), Home · End 는 그 줄의 처음 · 끝, Enter · Space 로 고른다. 찾기
///   칸에서 ↓ 는 격자의 첫 칸으로. 열면 초점은 고른 칸(없으면 첫 칸)이고 고른 칸이 가운데에 오게 스크롤한다. Esc 는 찾는 말이
///   있으면 지우고(초점은 찾기 칸) 비었으면 그대로 둔다(시트가 닫는다).
class PIconPickerPanel extends StatefulWidget {
  const PIconPickerPanel({
    super.key,
    required this.selectedId,
    required this.onSelect,
    this.texts = const PIconPickerTexts(),
    this.autofocus = true,
    this.initialQuery = '',
  });

  /// 고른 칸의 id — 없으면(세트 밖 저장 값) null.
  final String? selectedId;

  /// 칸을 고르면.
  final ValueChanged<String> onSelect;
  final PIconPickerTexts texts;

  /// 열 때 초점을 고른 칸(없으면 첫 칸)에 두고 가운데로 스크롤한다.
  final bool autofocus;

  /// 처음 찾는 말 — 카탈로그의 찾는 중 · 0건 견본.
  final String initialQuery;

  @override
  State<PIconPickerPanel> createState() => _PIconPickerPanelState();
}

class _PIconPickerPanelState extends State<PIconPickerPanel> {
  late final TextEditingController _query = TextEditingController(
    text: widget.initialQuery,
  );
  final FocusNode _searchNode = FocusNode(debugLabel: 'icon-picker-search');
  final ScrollController _scroll = ScrollController();
  final Map<String, FocusNode> _nodes = {
    for (final icon in kCategoryIcons)
      icon.id: FocusNode(debugLabel: 'icon-${icon.id}'),
  };
  String? _activeId;
  Timer? _announceTimer;
  String? _announcedQuery;

  bool get _searching => _query.text.trim().isNotEmpty;
  List<PCategoryIcon> get _results => searchCategoryIcons(_query.text);
  List<PCategoryIcon> get _visible => _searching ? _results : kCategoryIcons;

  /// Tab 이 서는 칸 — 옮겨 다닌 칸, 없으면 고른 칸, 그것도 없으면 첫 칸.
  String? get _tabbableId {
    final visible = _visible;
    bool has(String? id) => id != null && visible.any((i) => i.id == id);
    if (has(_activeId)) return _activeId;
    if (has(widget.selectedId)) return widget.selectedId;
    return visible.isEmpty ? null : visible.first.id;
  }

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final id = kCategoryIcons.any((i) => i.id == widget.selectedId)
            ? widget.selectedId!
            : kCategoryIcons.first.id;
        final node = _nodes[id]!;
        _center(node);
        node.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _announceTimer?.cancel();
    _query.dispose();
    _searchNode.dispose();
    _scroll.dispose();
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _onQueryChanged(String _) {
    setState(() => _activeId = null);
    _announceTimer?.cancel();
    if (!_searching || _results.isEmpty) return;
    final query = _query.text;
    final count = _results.length;
    // 결과 수 — 치기를 멈추면 한 번. 0건은 Result Section 이 알린다
    _announceTimer = Timer(kIconPickerAnnounceDelay, () {
      if (!mounted || _announcedQuery == query) return;
      _announcedQuery = query;
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          widget.texts.countLabel(count),
          Directionality.of(context),
        ),
      );
    });
  }

  RenderObject? _renderOf(FocusNode node) => node.context?.findRenderObject();

  /// 고른 칸이 스크롤 상자 가운데에 오게 — 열 때 한 번.
  void _center(FocusNode node) {
    final object = _renderOf(node);
    if (object == null || !_scroll.hasClients) return;
    final viewport = RenderAbstractViewport.maybeOf(object);
    if (viewport == null) return;
    final target = viewport.getOffsetToReveal(object, 0.5).offset;
    _scroll.jumpTo(
      target.clamp(
        _scroll.position.minScrollExtent,
        _scroll.position.maxScrollExtent,
      ),
    );
  }

  /// 옮긴 칸이 흐림 밖에 보이게 — 위 20 · 아래 80(웹 scroll-padding 과 같다).
  void _reveal(FocusNode node) {
    final object = _renderOf(node);
    if (object == null || !_scroll.hasClients) return;
    final viewport = RenderAbstractViewport.maybeOf(object);
    if (viewport == null) return;
    final topEdge = viewport.getOffsetToReveal(object, 0).offset - _fogStart;
    final bottomEdge = viewport.getOffsetToReveal(object, 1).offset + _fogEnd;
    var offset = _scroll.offset;
    if (offset > topEdge) offset = topEdge;
    if (offset < bottomEdge) offset = math.min(bottomEdge, topEdge);
    _scroll.jumpTo(
      offset.clamp(
        _scroll.position.minScrollExtent,
        _scroll.position.maxScrollExtent,
      ),
    );
  }

  void _focusCell(String id) {
    final node = _nodes[id]!;
    setState(() => _activeId = id);
    node.requestFocus();
    _reveal(node);
  }

  Rect? _rectOf(String id) {
    final object = _renderOf(_nodes[id]!);
    if (object is! RenderBox || !object.attached) return null;
    return object.localToGlobal(Offset.zero) & object.size;
  }

  KeyEventResult _onCellKey(String id, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final ids = [for (final i in _visible) i.id];
    final i = ids.indexOf(id);
    if (i < 0) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = e.logicalKey;
    final r = _rectOf(id);
    bool sameRow(String other) {
      final q = _rectOf(other);
      return r != null && q != null && (q.top - r.top).abs() < 2;
    }

    String? target;
    if (key == LogicalKeyboardKey.arrowRight) {
      target = ids[math.min(ids.length - 1, math.max(0, i + (rtl ? -1 : 1)))];
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      target = ids[math.min(ids.length - 1, math.max(0, i + (rtl ? 1 : -1)))];
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      // 보이는 위아래 줄의 가장 가까운 칸 — 묶음 머리를 넘는다
      if (r == null) return KeyEventResult.handled;
      final down = key == LogicalKeyboardKey.arrowDown;
      double? rowTop;
      for (final other in ids) {
        final q = _rectOf(other);
        if (q == null) continue;
        if (down ? q.top > r.top + 2 : q.top < r.top - 2) {
          if (rowTop == null || (down ? q.top < rowTop : q.top > rowTop)) {
            rowTop = q.top;
          }
        }
      }
      if (rowTop != null) {
        var best = double.infinity;
        for (final other in ids) {
          final q = _rectOf(other);
          if (q == null || (q.top - rowTop).abs() > 2) continue;
          final d = (q.center.dx - r.center.dx).abs();
          if (d < best) {
            best = d;
            target = other;
          }
        }
      }
    } else if (key == LogicalKeyboardKey.home) {
      target = ids.firstWhere(sameRow, orElse: () => id);
    } else if (key == LogicalKeyboardKey.end) {
      target = ids.lastWhere(sameRow, orElse: () => id);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      widget.onSelect(id);
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }
    if (target != null && target != id) _focusCell(target);
    return KeyEventResult.handled;
  }

  KeyEventResult _onSearchKey(KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    if (e.logicalKey != LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.ignored;
    }
    // 글자를 조합하는 동안(한글)의 키는 조합의 것이다
    final composing = _query.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final visible = _visible;
    if (visible.isEmpty) return KeyEventResult.handled;
    _focusCell(visible.first.id);
    return KeyEventResult.handled;
  }

  /// Esc — 찾는 말이 있으면 지우고 찾기 칸으로(시트는 그대로), 비었으면 시트가 닫는다.
  KeyEventResult _onEscape(KeyEvent e) {
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    if (_query.text.isEmpty) return KeyEventResult.ignored;
    _query.clear();
    _onQueryChanged('');
    _searchNode.requestFocus();
    return KeyEventResult.handled;
  }

  Widget _gridOf(List<PCategoryIcon> icons, String? tabbable) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = iconGridMetrics(constraints.maxWidth);
        final rows = (icons.length / m.columns).ceil();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: _rowGap,
          children: [
            for (var r = 0; r < rows; r++)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var k = 0; k < m.columns; k++)
                    if (r * m.columns + k < icons.length)
                      PIconPickerCell(
                        key: ValueKey('icon-${icons[r * m.columns + k].id}'),
                        icon: icons[r * m.columns + k],
                        selected:
                            icons[r * m.columns + k].id == widget.selectedId,
                        focusNode: _nodes[icons[r * m.columns + k].id],
                        tabbable: icons[r * m.columns + k].id == tabbable,
                        onSelect: widget.onSelect,
                        onKey: _onCellKey,
                        onFocus: (id) => _activeId = id,
                      )
                    else
                      // 마지막 줄의 빈 자리 — 열은 늘 제자리다
                      const SizedBox(width: _cell, height: _cell),
                ],
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = widget.texts;
    final tabbable = _tabbableId;
    final searching = _searching;
    final results = _results;

    final search = Padding(
      padding: const EdgeInsets.symmetric(horizontal: _paddingX),
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, e) => _onSearchKey(e),
        child: PInput(
          variant: PInputVariant.underline,
          controller: _query,
          focusNode: _searchNode,
          prefixIcon: LucideIcons.search,
          clearable: true,
          placeholder: t.searchPlaceholder,
          semanticLabel: t.searchLabel,
          onChanged: _onQueryChanged,
        ),
      ),
    );

    Widget body;
    if (searching && results.isEmpty) {
      body = PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.medium,
        icon: LucideIcons.searchX,
        title: t.emptyTitle(_query.text.trim()),
        description: t.emptyDescription,
      );
    } else {
      body = Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.list, // Flutter 에 listbox 역할이 없다 — 가장 가까운 list
        label: t.listLabel,
        child: searching
            // 찾는 동안은 묶음 머리가 없다 — 찾기 칸 ↔ 격자 12(searchGap, 묶음 머리 위 여백과 같다)
            ? Padding(
                padding: const EdgeInsets.only(top: _searchGap),
                child: _gridOf(results, tabbable),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final section in kCategoryIconSections)
                    Semantics(
                      container: true,
                      explicitChildNodes: true,
                      label: section.group,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: _headerPaddingTop,
                              bottom: _headerPaddingBottom,
                            ),
                            child: ExcludeSemantics(
                              child: Text(
                                keepAll(section.group),
                                key: ValueKey('icon-group-${section.group}'),
                                style: PTypography.t4.copyWith(
                                  color: c.fgNeutralSubtle,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          _gridOf(section.icons, tabbable),
                        ],
                      ),
                    ),
                ],
              ),
      );
    }

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, e) => _onEscape(e),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          Expanded(
            // 끝 흐림 — 위 20 · 아래 80(본문 안 여백 그만큼). 찾기 칸은 스크롤 상자 밖이라 흐리지 않는다
            child: PScrollFog(
              use: PScrollFogUse.overlayBody,
              controller: _scroll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _paddingX),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon Picker — 카테고리 · 저축 목표에 붙일 아이콘을 고르는 칸. 세트는 porest-design `specs/components/category-icons.yaml`
/// (148개 · 13 묶음 — `category_icons.g.dart` 가 JSON 에서 만든다), 수치 원본은 `icon-picker.yaml`(값은
/// `test/fixtures/design_spec/icon-picker.json`). SEED 에는 아이콘 고르기 부품이 없다 — 세트 · 칸 · 고른 표시 · 키보드 · 한국어
/// 찾기는 porest 가 정했다. 웹(desk-front `src/shared/ds/icon-picker`)과 같은 값이다. 옛 PIconPicker 를 대신한다.
///
/// 트리거 — Input Button large: 앞에 지금 아이콘, 값에 그 한국어 이름("커피"), 뒤 chevron-down. 이름은 "{Field 라벨} 커피".
///   아이콘이 없는 항목([value] 이 null · "")은 태그 + "태그", 세트 밖에 저장된 아이콘은 그 아이콘 + "지금 아이콘" — 지우지도
///   바꾸지도 않는다(격자에 고른 칸이 없고, 고르지 않고 닫으면 알리지 않는다). 서버 시드의 home 은 세트의 house(집)로 본다.
/// 여는 자리 — Bottom Sheet("아이콘", 앱은 시트만 쓴다). 고르면 바로 닫힌다("완료" 없음) — 초점은 트리거로.
class PIconPicker extends StatefulWidget {
  const PIconPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.texts = const PIconPickerTexts(),
    this.disabled,
    this.readOnly,
    this.invalid,
    this.semanticLabel,
    this.focusNode,
  });

  /// 저장된 lucide 이름 — null · "" 이면 태그로 그린다. 세트 밖 이름은 그대로 그린다("지금 아이콘").
  final String? value;

  /// 고르면 — 닫는 것은 스스로 한다. 고르지 않고 닫으면 부르지 않는다.
  final ValueChanged<String>? onChanged;
  final PIconPickerTexts texts;
  final bool? disabled;
  final bool? readOnly;
  final bool? invalid;

  /// 이름 — Field 밖에서 쓸 때. Field 안이면 Field 의 라벨이 이름이다.
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  State<PIconPicker> createState() => _PIconPickerState();
}

class _PIconPickerState extends State<PIconPicker> {
  FocusNode? _own;
  bool _open = false;

  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  Future<void> _openSheet() async {
    final stored = widget.value?.trim() ?? '';
    final entry = findCategoryIcon(stored);
    final selectedId =
        entry?.id ?? (stored.isEmpty ? kDefaultCategoryIcon : null);
    setState(() => _open = true);
    await PBottomSheet.show<void>(
      context,
      builder: (sheetContext) => PBottomSheetContent(
        title: widget.texts.title,
        closeLabel: widget.texts.closeLabel,
        flushBody: true,
        body: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.6,
          child: PIconPickerPanel(
            selectedId: selectedId,
            texts: widget.texts,
            onSelect: (id) {
              widget.onChanged?.call(id);
              PBottomSheet.of(sheetContext).close();
            },
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _open = false);
    // 닫으면 초점은 트리거로
    _node.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final stored = widget.value?.trim() ?? '';
    final entry = findCategoryIcon(stored);
    final empty = stored.isEmpty;
    // 트리거 — 세트 안은 그 아이콘 + 이름, 빈 값은 태그 + "태그", 세트 밖은 그 아이콘 + "지금 아이콘"
    final shownId = entry?.id ?? (empty ? kDefaultCategoryIcon : stored);
    final shownName = entry != null
        ? entry.name
        : empty
        ? (findCategoryIcon(kDefaultCategoryIcon)?.name ?? '태그')
        : widget.texts.currentIconName;
    return PInputButton(
      value: shownName,
      prefixIcon: categoryGlyph(shownId),
      suffixIcon: LucideIcons.chevronDown,
      expanded: _open,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      invalid: widget.invalid,
      semanticLabel: widget.semanticLabel,
      focusNode: _node,
      onPressed: _openSheet,
    );
  }
}
