import 'dart:math' as math;

import 'package:flutter/rendering.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/ds/bottom_sheet/bottom_sheet_route.dart';
import 'package:porest_desk_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:porest_desk_app/shared/ds/overlay/p_overlay.dart';
import 'package:porest_desk_app/shared/ds/text/keep_all.dart';

/// 줄의 정렬 — `textWithIcon`(기본) 아이콘 + 글, 글은 왼쪽. `textOnly` 글만, 가운데(줄 설명 · 아이콘을 두지 않는다).
/// 한 시트에서 섞지 않는다.
enum PMenuSheetLayout { textWithIcon, textOnly }

/// 줄의 톤 — `critical` 은 되돌릴 수 없는 동작(삭제 · 나가기). 이름 · 아이콘만 빨갛다.
enum PMenuSheetTone { neutral, critical }

/// 줄 — 앞 아이콘 · 이름 · 설명. 누르면 시트를 닫고 [onSelect] 를 부른다(시트가 다 닫힌 뒤).
class PMenuSheetItem {
  const PMenuSheetItem({
    required this.label,
    this.description,
    this.icon,
    this.tone = PMenuSheetTone.neutral,
    this.enabled = true,
    this.onSelect,
  });

  /// 이름 — 동사로 짧게(2 ~ 6자).
  final String label;

  /// 설명 — 이름이 추상적이라 잘못 누를 수 있을 때만. `textOnly` 에서는 두지 않는다.
  final String? description;

  /// 앞 아이콘 — 모든 줄에 두거나 모두 뺀다. `textOnly` 에서는 두지 않는다.
  final IconData? icon;

  final PMenuSheetTone tone;

  /// false 면 막힌 줄 — 전용 색, 눌러도 실행하지 않고 닫히지 않으며 초점이 서지 않는다.
  final bool enabled;

  /// 시트가 다 닫힌 뒤 부른다 — 확인이 필요한 동작(삭제)은 여기서 Alert Dialog 를 연다.
  final VoidCallback? onSelect;
}

/// 묶음 — 옅은 회색 상자(모서리 16). 묶음 사이는 간격만(10).
class PMenuSheetGroup {
  const PMenuSheetGroup(this.items);

  final List<PMenuSheetItem> items;
}

/// 줄을 누른 채 이만큼(px) 넘게 끌면 실행하지 않는다(끌어 닫기와 헷갈리지 않게).
const double kMenuSheetPressDragSlop = 10;

/// 시트 위 24(손잡이 자리) · 아래 16 + 안전 영역. 좌우는 화면 여백 24.
const double kMenuSheetPaddingTop = PSpacing.x6;
const double kMenuSheetPaddingBottom = PSpacing.x4;

/// Menu Sheet — 화면 아래에서 올라오는 동작 목록. `PMenuSheet.show(context, title: …, groups: […])`.
///
/// 구조는 SEED Swipeable Menu Sheet(2026-10-02), 수치 원본은 porest-design `specs/components/menu-sheet.yaml`(값은
/// `test/fixtures/design_spec/menu-sheet.json`). 웹(desk-front `src/shared/ds/menu-sheet`)과 같은 값이다.
///
/// 1280 미만의 줄 · 화면 동작 목록이다(앱은 Menu 를 만들지 않는다 — 늘 이 시트). 줄 끝 ⋮ · 머리의 더보기 버튼이 열고,
/// 폰의 스와이프는 같은 동작의 지름길로 남는다 — 시트의 줄은 트레이와 같은 동작 · 같은 이름이고 확인도 같은 Alert Dialog
/// 다. 입력 · 고르기 · 상세는 Bottom Sheet, 되돌릴 수 없는 확인은 Alert Dialog 다.
///
/// 딤 · 끌어내리기(0.4px/ms 넘게 · 높이의 25%, 열린 뒤 0.5초는 끌리지 않음) · 뒤로 가기 · Esc · 모션(300ms enter-expressive ·
/// 200ms exit)은 Bottom Sheet 그대로다([PBottomSheetRoute]). 다른 것은 위 모서리 20 · 손잡이가 늘 있음(누르면 닫는다) ·
/// 위 닫기 버튼 · 바닥 취소 버튼이 없음 · 머리가 가운데다. 줄을 누르면 시트를 먼저 닫고 [PMenuSheetItem.onSelect] 는 다 닫힌 뒤
/// 부른다 — 닫히는 시트와 열리는 확인창이 겹치지 않는다. 막힌 줄은 실행하지 않고 닫히지 않는다.
///
/// 이름 — [title] 이 있으면 그것이 시트의 이름이다. 없으면 [semanticLabel](예: "주간 회의 메모 더보기")이 있어야 한다.
abstract final class PMenuSheet {
  /// 시트를 띄운다. 줄을 골라 닫혔으면 그 줄을 돌려주고(그 [PMenuSheetItem.onSelect] 는 다 닫힌 뒤에 부른다), 바깥 · 끌기 ·
  /// 뒤로 가기로 닫혔으면 null.
  static Future<PMenuSheetItem?> show(
    BuildContext context, {
    String? title,
    String? description,
    String? semanticLabel,
    PMenuSheetLayout layout = PMenuSheetLayout.textWithIcon,
    required List<PMenuSheetGroup> groups,
    bool useRootNavigator = true,
  }) async {
    assert(
      title != null || (semanticLabel?.trim().isNotEmpty ?? false),
      '제목이 없으면 semanticLabel 로 이름을 단다(예: "주간 회의 메모 더보기")',
    );
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    final route = PBottomSheetRoute<PMenuSheetItem>(
      themes: captureOverlayThemes(context, navigator),
      reduceMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
      builder: (context) => PMenuSheetContent(
        title: title,
        description: description,
        semanticLabel: semanticLabel,
        layout: layout,
        groups: groups,
      ),
      form: false,
      isDirty: null,
      leaveCopy: null,
      snapPoints: null,
      alwaysHandle: true,
      topRadius: PRounded.r5,
    );
    final picked = await navigator.push<PMenuSheetItem>(route);
    // 시트가 다 닫힌 뒤 — push 의 결과는 닫는 순간에 오므로 내려가는 모션이 끝나 초점이 돌아온 다음까지 기다린다
    await route.completed;
    picked?.onSelect?.call();
    return picked;
  }
}

/// 시트 안 — 머리 · 묶음 · 보조 기술용 닫기. 라우트 안([PMenuSheet.show])에서 쓴다.
///
/// 머리는 가운데 — 제목 t6 18 / 24 · 700, 설명 t4 `fg-neutral-muted`, 사이 4 · 아래 16. 묶음은 `bg-neutral-weak` ·
/// 모서리 16, 사이 10. 화면의 90% 를 넘으면 묶음 목록만 스크롤한다(머리는 그대로).
class PMenuSheetContent extends StatelessWidget {
  PMenuSheetContent({
    super.key,
    this.title,
    this.description,
    this.semanticLabel,
    this.layout = PMenuSheetLayout.textWithIcon,
    required this.groups,
  }) : assert(groups.isNotEmpty, '묶음이 하나는 있어야 한다'),
       assert(
         layout == PMenuSheetLayout.textWithIcon ||
             groups.every(
               (g) => g.items.every(
                 (i) => i.icon == null && i.description == null,
               ),
             ),
         'textOnly 시트의 줄에는 아이콘 · 설명을 두지 않는다',
       );

  /// 무엇의 동작인지("주간 회의 메모"). 없어도 된다 — 그러면 [semanticLabel] 이 이름이다.
  final String? title;

  /// 제목만으로 모자랄 때만.
  final String? description;

  /// 보이는 제목이 없을 때 시트의 이름.
  final String? semanticLabel;
  final PMenuSheetLayout layout;
  final List<PMenuSheetGroup> groups;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasHeader = title != null || description != null;
    final controller = PBottomSheetScope.maybeOf(context);

    final header = hasHeader
        ? Padding(
            padding: const EdgeInsets.only(bottom: PSpacing.x4),
            child: Column(
              key: const ValueKey('p-menu-sheet-header'),
              mainAxisSize: MainAxisSize.min,
              spacing: PSpacing.x1,
              children: [
                if (title != null)
                  // 제목은 시트의 이름이 읽는다 — 다시 읽지 않는다
                  ExcludeSemantics(
                    child: Text(
                      keepAll(title!),
                      key: const ValueKey('p-menu-sheet-title'),
                      textAlign: TextAlign.center,
                      style: PTypography.t6.copyWith(
                        color: c.fgNeutral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (description != null)
                  Text(
                    keepAll(description!),
                    key: const ValueKey('p-menu-sheet-description'),
                    textAlign: TextAlign.center,
                    semanticsLabel: description,
                    style: PTypography.t4.copyWith(color: c.fgNeutralMuted),
                  ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final list = SingleChildScrollView(
      controller: controller?.bodyController,
      child: Column(
        key: const ValueKey('p-menu-sheet-list'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x2_5,
        children: [
          for (final group in groups)
            _Group(
              layout: layout,
              group: group,
              onSelect: (item) => controller?.close(item),
            ),
        ],
      ),
    );

    return Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      role: SemanticsRole.dialog,
      label: title ?? semanticLabel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PSpacing.globalGutter,
          kMenuSheetPaddingTop,
          PSpacing.globalGutter,
          kMenuSheetPaddingBottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Flexible(child: list),
            _AssistiveClose(onClose: () => controller?.requestClose()),
          ],
        ),
      ),
    );
  }
}

/// Menu Sheet 의 모습 — 라우트 없이 시트 표면만 그린다(카탈로그의 정지한 견본 · 테스트). 실제로는 [PMenuSheet.show] 가 띄운다.
class PMenuSheetView extends StatelessWidget {
  const PMenuSheetView({super.key, required this.content});

  final PMenuSheetContent content;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: PBottomSheetSurface(
        showHandle: true,
        topRadius: PRounded.r5,
        maxHeightFactor: kBottomSheetMaxHeightFactor,
        child: content,
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.layout,
    required this.group,
    required this.onSelect,
  });

  final PMenuSheetLayout layout;
  final PMenuSheetGroup group;
  final ValueChanged<PMenuSheetItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = group.items;
    return DecoratedBox(
      key: const ValueKey('p-menu-sheet-group'),
      decoration: BoxDecoration(
        color: c.bgNeutralWeak,
        borderRadius: BorderRadius.circular(PRounded.r4),
      ),
      // 줄의 링은 줄 안쪽이라 상자가 자르지 않는다 — 모서리만 자른다
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PRounded.r4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++)
              _ItemTile(
                item: items[i],
                layout: layout,
                last: i == items.length - 1,
                onSelect: onSelect,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivateIntent extends Intent {
  const _ActivateIntent();
}

/// 줄 — 최소 52 · 위아래 14 · 좌우 16, 아이콘 22 ↔ 이름 14. 호버 · 누름은 `bg-neutral-weak-pressed`, 누르면 아이콘 · 글만
/// 2px 거리 줄고(기준 max(높이, 폭 ÷ 4, 24) — 모션 줄이기면 줄지 않는다) 설명은 `fg-neutral-muted`, 위험한 줄은
/// `fg-critical-contrast` 가 된다(누름 바탕 위 4.5:1). 줄 사이 선은 안쪽 아래 1px — 묶음의 마지막 줄에는 없다.
class _ItemTile extends StatefulWidget {
  const _ItemTile({
    required this.item,
    required this.layout,
    required this.last,
    required this.onSelect,
  });

  final PMenuSheetItem item;
  final PMenuSheetLayout layout;
  final bool last;
  final ValueChanged<PMenuSheetItem> onSelect;

  @override
  State<_ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<_ItemTile> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;
  double _basis = 24;
  Offset? _down;
  bool _dragged = false;

  bool get _enabled => widget.item.enabled;

  void _activate() {
    if (!_enabled) return;
    widget.onSelect(widget.item);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    if (value) {
      final size = context.size;
      if (size != null) {
        _basis = math.max(size.height, math.max(size.width / 4, 24));
      }
    }
    setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(_ItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 누르는 사이 막히면 누름이 남지 않게
    if (!_enabled) {
      _pressed = false;
      _hovered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final item = widget.item;
    final textOnly = widget.layout == PMenuSheetLayout.textOnly;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final enabled = _enabled;
    final active = enabled && (_pressed || _hovered);
    final critical = item.tone == PMenuSheetTone.critical;

    final Color nameColor;
    final Color descriptionColor;
    if (!enabled) {
      nameColor = c.fgDisabled;
      descriptionColor = c.fgDisabled;
    } else {
      nameColor = critical
          ? (active ? c.fgCriticalContrast : c.fgCritical)
          : c.fgNeutral;
      descriptionColor = active ? c.fgNeutralMuted : c.fgNeutralSubtle;
    }

    final label = Text(
      keepAll(item.label),
      key: const ValueKey('p-menu-sheet-item-label'),
      semanticsLabel: item.label,
      textAlign: textOnly ? TextAlign.center : TextAlign.start,
      style: PTypography.t5.copyWith(color: nameColor),
    );
    final texts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: textOnly
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      spacing: PSpacing.x0_5,
      children: [
        label,
        if (!textOnly && item.description != null)
          Text(
            keepAll(item.description!),
            key: const ValueKey('p-menu-sheet-item-description'),
            semanticsLabel: item.description,
            style: PTypography.t3.copyWith(
              fontWeight: FontWeight.w500,
              color: descriptionColor,
            ),
          ),
      ],
    );

    Widget content = Row(
      key: const ValueKey('p-menu-sheet-item-content'),
      mainAxisAlignment: textOnly
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      spacing: PSpacing.x3_5,
      children: [
        if (!textOnly && item.icon != null)
          Icon(
            item.icon,
            key: const ValueKey('p-menu-sheet-item-icon'),
            size: 22,
            color: nameColor,
          ),
        Flexible(child: texts),
      ],
    );
    content = AnimatedScale(
      key: const ValueKey('p-menu-sheet-item-scale'),
      scale: _pressed && enabled && !reduceMotion ? (_basis - 2) / _basis : 1,
      duration: PDuration.pressedScale,
      curve: PEasing.pressedScale,
      child: content,
    );

    Widget tile = Stack(
      children: [
        AnimatedContainer(
          key: const ValueKey('p-menu-sheet-item'),
          duration: PDuration.colorTransition,
          curve: PEasing.easing,
          constraints: const BoxConstraints(minHeight: PSpacing.x13),
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.x4,
            vertical: PSpacing.x3_5,
          ),
          alignment: Alignment.centerLeft,
          color: active ? c.bgNeutralWeakPressed : const Color(0x00000000),
          child: SizedBox(width: double.infinity, child: content),
        ),
        if (!widget.last)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 1,
            child: ColoredBox(
              key: const ValueKey('p-menu-sheet-divider'),
              color: c.strokeNeutralWeak,
            ),
          ),
        // 키보드 포커스 — 줄 안쪽 2px 링
        if (_focused)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('p-menu-sheet-focus-ring'),
                decoration: BoxDecoration(
                  border: Border.all(color: c.strokeFocusRing, width: 2),
                ),
              ),
            ),
          ),
      ],
    );

    tile = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _down = e.position;
        _dragged = false;
      },
      onPointerMove: (e) {
        final down = _down;
        if (down != null &&
            (e.position - down).distance > kMenuSheetPressDragSlop) {
          _dragged = true;
          _setPressed(false);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        // 10px 넘게 끌었으면(시트를 끌어내리다 놓음) 실행하지 않는다 — 줄 밖에서 뗐으면 탭이 아니라 취소다
        onTap: enabled
            ? () {
                if (!_dragged) _activate();
              }
            : null,
        child: tile,
      ),
    );
    tile = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: tile,
    );
    tile = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): _ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): _ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): _ActivateIntent(),
      },
      child: Actions(
        actions: {
          _ActivateIntent: CallbackAction<_ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: Focus(
          canRequestFocus: enabled,
          onFocusChange: (focused) => setState(
            () => _focused =
                focused &&
                FocusManager.instance.highlightMode ==
                    FocusHighlightMode.traditional,
          ),
          child: tile,
        ),
      ),
    );
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      focusable: enabled,
      label: item.label,
      hint: textOnly ? null : item.description,
      onTap: enabled ? _activate : null,
      excludeSemantics: true,
      child: tile,
    );
  }
}

/// 보조 기술용 닫기 — 목록 뒤에 서고 평소에는 보이지 않는다(화면 읽기는 읽는다). 키보드 초점이 오면 위 10 · 최소 52 ·
/// 좌우 20 · 모서리 12 · `bg-neutral-weak` · t5 500 의 폭 전체 버튼으로 보인다. 목록에서 Tab 으로 닿는다.
class _AssistiveClose extends StatefulWidget {
  const _AssistiveClose({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_AssistiveClose> createState() => _AssistiveCloseState();
}

class _AssistiveCloseState extends State<_AssistiveClose> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = AppLocalizations.of(context).actionClose;
    final button = _focused
        ? Padding(
            padding: const EdgeInsets.only(top: PSpacing.x2_5),
            child: DecoratedBox(
              key: const ValueKey('p-menu-sheet-close'),
              decoration: BoxDecoration(
                color: _hovered ? c.bgNeutralWeakPressed : c.bgNeutralWeak,
                borderRadius: BorderRadius.circular(PRounded.r3),
                // 묶음 밖이라 바깥 2
                border: Border.all(color: c.strokeFocusRing, width: 2),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: PSpacing.x13),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: PSpacing.x5),
                  child: Center(
                    child: Text(
                      label,
                      style: PTypography.t5.copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.fgNeutral,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        : const SizedBox(
            key: ValueKey('p-menu-sheet-close'),
            width: 0,
            height: 0,
          );
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: widget.onClose,
      excludeSemantics: true,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.space): _ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): _ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): _ActivateIntent(),
        },
        child: Actions(
          actions: {
            _ActivateIntent: CallbackAction<_ActivateIntent>(
              onInvoke: (_) {
                widget.onClose();
                return null;
              },
            ),
          },
          child: Focus(
            onFocusChange: (focused) => setState(
              () => _focused =
                  focused &&
                  FocusManager.instance.highlightMode ==
                      FocusHighlightMode.traditional,
            ),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: widget.onClose,
                child: button,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
