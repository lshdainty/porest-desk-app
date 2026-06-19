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
/// Content: **드롭다운 overlay**(OverlayPortal + CompositedTransformFollower —
/// Radix Popover Flutter 정합) — trigger 바로 아래(+4), trigger 폭 일치,
/// surface-default + border-default + radius-sm + shadow, max-h 384 scroll.
/// item: 좌측 indicator(선택 시 Check 16) + (선택)leading + label.
/// 스크롤 가능 시 sticky 위/아래 chevron 버튼 노출(shadcn SelectScrollUp/Down).
///
/// 구현 메모: 이전 MenuAnchor.menuChildren 단일 복합 위젯 패턴은 portal 내부
/// constraint 충돌로 RenderTapRegion `RenderBox was not laid out` 에러가 났음.
/// OverlayPortal+LayerLink + Stack/Positioned 명시적 layout 으로 정정.
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
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _triggerKey = GlobalKey();
  double _triggerW = 0;
  bool _openUp = false;
  double _maxH = 384;
  static const double _triggerH = 40;
  static const double _gap = 4;

  void _toggle() {
    if (!widget.enabled) return;
    if (_portal.isShowing) {
      _portal.hide();
      return;
    }
    // 화면 하단/상단 가용 공간을 측정해 flip + maxHeight 결정 (웹 Radix collision
    // detection 정합). trigger 가 하단에 가까우면 위로 펼치거나 높이를 줄여 짤림 방지.
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      _triggerW = box.size.width;
      final mq = MediaQuery.of(context);
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      const margin = 8.0;
      final below = mq.size.height - bottom - mq.padding.bottom - margin - _gap;
      final above = top - mq.padding.top - margin - _gap;
      _openUp = below < 220 && above > below;
      _maxH = (_openUp ? above : below).clamp(120.0, 384.0);
    }
    _portal.show();
  }

  void _select(T v) {
    _portal.hide();
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

    final trigger = Material(
      color: widget.enabled ? t.bgMuted : t.bgDisabled,
      borderRadius: PRadius.brSm,
      child: InkWell(
        onTap: widget.enabled ? _toggle : null,
        borderRadius: PRadius.brSm,
        child: Container(
          key: _triggerKey,
          height: _triggerH,
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

    final field = CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (overlayContext) {
          return Stack(
            children: [
              // outside-tap dismiss — translucent full-screen 영역.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _portal.hide,
                ),
              ),
              // popover — trigger 아래 +gap. trigger 폭 일치(_triggerW).
              CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                // 아래로 펼침(default): trigger 하단에 메뉴 상단 정렬 +gap.
                // 위로 flip(_openUp): trigger 상단에 메뉴 하단 정렬 -gap.
                targetAnchor:
                    _openUp ? Alignment.topLeft : Alignment.bottomLeft,
                followerAnchor:
                    _openUp ? Alignment.bottomLeft : Alignment.topLeft,
                offset: Offset(0, _openUp ? -_gap : _gap),
                child: SizedBox(
                  width: _triggerW,
                  child: _SelectMenu<T>(
                    maxHeight: _maxH,
                    items: widget.items,
                    value: widget.value,
                    onSelect: _select,
                  ),
                ),
              ),
            ],
          );
        },
        child: trigger,
      ),
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

/// 드롭다운 메뉴 — surface-default + border-default + radius-sm + shadow.
/// maxHeight 384(spec max-h-96). 스크롤 가능 시 sticky 위/아래 chevron 버튼
/// (shadcn SelectScrollUp/DownButton 정합).
class _SelectMenu<T> extends StatefulWidget {
  const _SelectMenu({
    required this.maxHeight,
    required this.items,
    required this.value,
    required this.onSelect,
  });

  final double maxHeight;
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
  static const double _btnH = 24; // scroll btn height (py x4 + icon 16)

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _ctrl.removeListener(_sync);
    _ctrl.dispose();
    super.dispose();
  }

  void _sync() {
    if (!mounted || !_ctrl.hasClients) return;
    final pos = _ctrl.position;
    final up = pos.pixels > 0.5;
    final down = pos.pixels < pos.maxScrollExtent - 0.5;
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
    final t = context.tokens;
    return Material(
      color: t.bgSurface,
      borderRadius: PRadius.brSm,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: PRadius.brSm,
          border: Border.all(color: t.borderDefault),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          child: Stack(
            children: [
              // viewport — ListView. shadcn SelectContent Viewport `p-1` 정합:
              // vertical x4 + 스크롤 버튼이 노출되면 그쪽에 _btnH 만큼 inset.
              ListView(
                controller: _ctrl,
                shrinkWrap: true,
                // viewport padding (웹 SelectContent Viewport `p-1` 정합) —
                // 좌우 x4 로 selected bg 가 메뉴 가장자리에 딱 붙지 않게.
                padding: EdgeInsets.only(
                  left: PSpace.x4,
                  right: PSpace.x4,
                  top: _canUp ? _btnH : PSpace.x4,
                  bottom: _canDown ? _btnH : PSpace.x4,
                ),
                children: [
                  for (final it in widget.items)
                    _MenuItem<T>(
                      item: it,
                      selected: it.value == widget.value,
                      onTap: () => widget.onSelect(it.value),
                    ),
                ],
              ),
              if (_canUp)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _ScrollBtn(
                    icon: LucideIcons.chevronUp,
                    onTap: () => _scrollBy(-120),
                  ),
                ),
              if (_canDown)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _ScrollBtn(
                    icon: LucideIcons.chevronDown,
                    onTap: () => _scrollBy(120),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 드롭다운 메뉴 항목 — spec select.md item: 좌측 indicator(pl-8 영역, 선택 시
/// Check 16) + (선택)leading + body label. 선택 시 `surface-input` 채움 + Check
/// (currentColor=text-primary) — 웹 SelectItem `selected+focus` 정합.
class _MenuItem<T> extends StatelessWidget {
  const _MenuItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PSelectItem<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      // 선택 row = surface-input 채움 + rounded-xs (웹 item `rounded-xs` +
      // `focus:bg-surface-input` 정합). 좌우 viewport padding(ListView)으로
      // bg 가 메뉴 가장자리에 딱 붙지 않고 안쪽에 둥글게.
      color: selected ? t.bgMuted : Colors.transparent,
      borderRadius: PRadius.brXs,
      child: InkWell(
        onTap: onTap,
        borderRadius: PRadius.brXs,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x8, vertical: PSpace.x8),
          child: Row(
            children: [
              // 체크 영역(16) + gap(8) — 웹 indicator(left-8)~label(pl-8) 간격 정합.
              SizedBox(
                width: 16,
                // 체크 = text-primary(currentColor) — 웹 정합(다크 흰색).
                child: selected
                    ? Icon(LucideIcons.check, size: 16, color: t.fgPrimary)
                    : null,
              ),
              const SizedBox(width: PSpace.x8),
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
    );
  }
}

/// ScrollUp/ScrollDownButton — shadcn `py-1` + chevron 16 정합. sticky로
/// 메뉴 위/아래에 떠 있어 탭 시 스크롤. 배경은 surface-default 유지(item과
/// 시각 분리, 항목이 살짝 비쳐도 OK).
class _ScrollBtn extends StatelessWidget {
  const _ScrollBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.bgSurface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 24,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: t.fgSecondary),
        ),
      ),
    );
  }
}
