import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// specs/components/select.md 미러.
///
/// Trigger: h-10(40) + padding sm·md(8·12) + radius-sm(4) + border-default +
/// bg surface-input + 우측 chevron-down 16.
/// Content: **드롭다운 overlay**(MenuAnchor) — trigger 바로 아래(+4), **trigger 폭
/// 일치**, surface-default + border-default + radius-sm + shadow + max-h 384 scroll.
/// item: 좌측 indicator(선택 시 Check 16) + (선택)leading + label.
/// (spec select.md = Radix Select 드롭다운. 이전 showModalBottomSheet 바텀시트 구현은
///  spec 위반이라 드롭다운으로 정정.)
class PSelectItem<T> {
  const PSelectItem({required this.value, required this.label, this.leading});

  /// 항목 좌측 위젯(라벨 색 점 등) — web SelectItem 내 dot 정합 (선택).
  final Widget? leading;
  final T value;
  final String label;
}

class PSelect<T> extends StatefulWidget {
  const PSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.placeholder = '선택',
    this.title,
    this.enabled = true,
    this.errorText,
    this.helperText,
  });

  final T? value;
  final ValueChanged<T?> onChanged;
  final List<PSelectItem<T>> items;
  final String placeholder;

  /// (deprecated) 이전 바텀시트 헤더 제목 — 드롭다운에선 미사용. 호환 위해 유지.
  final String? title;
  final bool enabled;

  /// 검증 실패 메시지 — 있으면 invalid state (border-error + helper color text-error).
  final String? errorText;

  /// idle state 보조 텍스트 — control 아래 caption. errorText 우선.
  final String? helperText;

  @override
  State<PSelect<T>> createState() => _PSelectState<T>();
}

class _PSelectState<T> extends State<PSelect<T>> {
  final MenuController _menu = MenuController();

  void _select(T v) {
    _menu.close();
    if (v != widget.value) widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasValue = widget.value != null;
    final hasError = widget.errorText != null;
    final selectedItem = hasValue
        ? widget.items.firstWhere(
            (i) => i.value == widget.value,
            orElse: () => PSelectItem<T>(value: widget.value as T, label: ''),
          )
        : null;
    final label = selectedItem?.label ?? widget.placeholder;
    final caption = hasError ? widget.errorText! : widget.helperText;

    final field = LayoutBuilder(
      builder: (context, constraints) {
        final menuW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 280.0;
        return MenuAnchor(
          controller: _menu,
          alignmentOffset: const Offset(0, PSpace.x4),
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(t.bgSurface),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: const WidgetStatePropertyAll(Color(0x26000000)),
            elevation: const WidgetStatePropertyAll(8),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: PRadius.brSm,
              side: BorderSide(color: t.borderDefault),
            )),
            // viewport padding 은 _SelectMenu 내부에서 — 여기선 0.
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            minimumSize: WidgetStatePropertyAll(Size(menuW, 0)),
            maximumSize: WidgetStatePropertyAll(Size(menuW, 384)),
          ),
          menuChildren: [
            _SelectMenu<T>(
              width: menuW,
              items: widget.items,
              value: widget.value,
              onSelect: _select,
            ),
          ],
          builder: (context, controller, _) {
            return Material(
              color: widget.enabled ? t.bgMuted : t.bgDisabled,
              borderRadius: PRadius.brSm,
              child: InkWell(
                onTap: widget.enabled
                    ? () =>
                        controller.isOpen ? controller.close() : controller.open()
                    : null,
                borderRadius: PRadius.brSm,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                      horizontal: PSpace.md, vertical: PSpace.sm),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: hasError ? t.statusDanger : t.borderDefault,
                      width: hasError ? 1.5 : 1,
                    ),
                    borderRadius: PRadius.brSm,
                  ),
                  child: Row(
                    children: [
                      if (selectedItem?.leading != null) ...[
                        selectedItem!.leading!,
                        const SizedBox(width: PSpace.x8),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          style: PTypo.bodyLg.copyWith(
                            color: hasValue ? t.fgPrimary : t.fgTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(LucideIcons.chevronDown,
                          size: 16, color: t.fgSecondary),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (caption == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        field,
        const SizedBox(height: PSpace.x4),
        Text(
          caption,
          style: PTypo.caption.copyWith(
            color: hasError ? t.statusDanger : t.fgTertiary,
          ),
        ),
      ],
    );
  }
}

/// 드롭다운 메뉴 항목 — spec select.md item: 좌측 indicator(pl-8 영역, 선택 시 Check 16)
/// + (선택)leading + body label. 메뉴 폭(trigger 폭)에 맞춰 full-width.
class _MenuItem<T> extends StatelessWidget {
  const _MenuItem({
    required this.item,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final PSelectItem<T> item;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: width,
      child: Material(
        // 선택 row = surface-input 채움 (spec select.md item `selected+focus`,
        // 웹 focus:bg-surface-input 정합 — 드롭다운 열림 시 선택값 강조).
        color: selected ? t.bgMuted : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x8, vertical: PSpace.x8),
            child: Row(
              children: [
                SizedBox(
                  width: PSpace.x24,
                  // 체크 = text-primary(currentColor) — 웹 정합(다크 흰색).
                  child: selected
                      ? Icon(LucideIcons.check, size: 16, color: t.fgPrimary)
                      : null,
                ),
                if (item.leading != null) ...[
                  item.leading!,
                  const SizedBox(width: PSpace.x8),
                ],
                Expanded(
                  child: Text(
                    item.label,
                    style: PTypo.body.copyWith(
                      color: t.fgPrimary,
                      fontWeight:
                          selected ? PFontWeight.semi : PFontWeight.regular,
                    ),
                    overflow: TextOverflow.ellipsis,
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

/// 드롭다운 메뉴 내용 — spec select.md / shadcn SelectContent 정합:
/// 스크롤 가능 시 위/아래 chevron 버튼(ScrollUp/DownButton) 자동 노출 +
/// viewport padding(항목이 가장자리/버튼에 딱 붙지 않게).
class _SelectMenu<T> extends StatefulWidget {
  const _SelectMenu({
    required this.width,
    required this.items,
    required this.value,
    required this.onSelect,
  });

  final double width;
  final List<PSelectItem<T>> items;
  final T? value;
  final void Function(T) onSelect;

  @override
  State<_SelectMenu<T>> createState() => _SelectMenuState<T>();
}

class _SelectMenuState<T> extends State<_SelectMenu<T>> {
  final ScrollController _ctrl = ScrollController();
  bool _canUp = false;
  bool _canDown = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _sync() {
    if (!_ctrl.hasClients) return;
    final up = _ctrl.offset > 0.5;
    final down = _ctrl.offset < _ctrl.position.maxScrollExtent - 0.5;
    if (up != _canUp || down != _canDown) {
      setState(() {
        _canUp = up;
        _canDown = down;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_ctrl.hasClients) return;
    final target =
        (_ctrl.offset + delta).clamp(0.0, _ctrl.position.maxScrollExtent);
    _ctrl.animateTo(target, duration: PMotion.fast, curve: PMotion.standard);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 384),
      child: SizedBox(
        width: widget.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_canUp)
              _ScrollBtn(
                  icon: LucideIcons.chevronUp, onTap: () => _scrollBy(-120)),
            Flexible(
              child: ListView(
                controller: _ctrl,
                shrinkWrap: true,
                // viewport padding (웹 SelectContent Viewport `p-1` 정합) —
                // 항목이 가장자리/스크롤 버튼에 딱 붙지 않게.
                padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
                children: [
                  for (final it in widget.items)
                    _MenuItem<T>(
                      item: it,
                      selected: it.value == widget.value,
                      width: widget.width,
                      onTap: () => widget.onSelect(it.value),
                    ),
                ],
              ),
            ),
            if (_canDown)
              _ScrollBtn(
                  icon: LucideIcons.chevronDown, onTap: () => _scrollBy(120)),
          ],
        ),
      ),
    );
  }
}

/// ScrollUp/ScrollDownButton — shadcn `py-1` + chevron 16 정합. 탭 시 스크롤.
class _ScrollBtn extends StatelessWidget {
  const _ScrollBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
        child: Icon(icon, size: 16, color: t.fgSecondary),
      ),
    );
  }
}
