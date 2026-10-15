import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/toggle/p_toggle.dart';

/// 눌러서 켜고 끄는 단추 — 값을 이 위젯이 쥐고 [PToggle] 에 준다. [disabled] 면 onChanged 가 없다(막힘).
class _Live extends StatefulWidget {
  const _Live({
    required this.label,
    required this.icon,
    required this.pressedIcon,
    this.initial = false,
    this.tone = PToggleTone.defaultTone,
    this.disabled = false,
  });

  final String label;
  final IconData icon;
  final IconData pressedIcon;
  final bool initial;
  final PToggleTone tone;
  final bool disabled;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late bool _on = widget.initial;

  @override
  Widget build(BuildContext context) {
    return PToggle(
      semanticLabel: widget.label,
      pressed: _on,
      onChanged: widget.disabled ? null : (next) => setState(() => _on = next),
      icon: widget.icon,
      pressedIcon: widget.pressedIcon,
      tone: widget.tone,
    );
  }
}

/// 카탈로그(/dev/ds) — 끔 · 켬 × 상태(기본 · 막힘) × 톤, 모으기 단추(같은 아이콘) · 기능 단추(-off 짝). 눌러서 켜고 끈다 —
/// 누름(바탕 + 단추 전체 2px 축소)은 직접 눌러 본다. 켬 · 끔은 손을 뗄 때 바로 바뀐다.
class ToggleDemo extends StatelessWidget {
  const ToggleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title:
              '끔 · 켬 × 상태 — 켬은 진한 색 + 선 2.5, 끔은 흐린 색 + 선 2. 막히면 아이콘만 회색(켬의 선 2.5 는 그대로)',
          children: [
            for (final (state, disabled) in const [
              ('enabled', false),
              ('disabled', true),
            ])
              DemoRow(
                label: state,
                children: [
                  for (final on in const [false, true])
                    _Live(
                      label: '관심 등록',
                      icon: LucideIcons.star,
                      pressedIcon: LucideIcons.star500,
                      initial: on,
                      disabled: disabled,
                    ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title:
              '모으기 단추(관심 · 고정) — 켬 · 끔이 같은 아이콘(사선 없음) · 기능 단추(눈) — 켬이면 지금 상태의 -off 아이콘',
          children: [
            DemoRow(
              label: '관심 · 고정 · 금액 가리기 · App Key 보기',
              children: const [
                _Live(
                  label: '관심 등록',
                  icon: LucideIcons.star,
                  pressedIcon: LucideIcons.star500,
                ),
                _Live(
                  label: '메모 고정',
                  icon: LucideIcons.pin,
                  pressedIcon: LucideIcons.pin500,
                  initial: true,
                ),
                _Live(
                  label: '금액 가리기',
                  icon: LucideIcons.eye,
                  pressedIcon: LucideIcons.eyeOff500,
                ),
                _Live(
                  label: 'App Key 보기',
                  icon: LucideIcons.eyeOff,
                  pressedIcon: LucideIcons.eye500,
                  initial: true,
                ),
                _Live(
                  label: '알림 받기',
                  icon: LucideIcons.bellOff,
                  pressedIcon: LucideIcons.bell500,
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '톤 inverted — 브랜드 채움 위(순자산 카드), 켬 · 끔 모두 흰 아이콘. 누름 바탕 없이 축소만',
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.bgBrandSolid,
                borderRadius: BorderRadius.circular(PRounded.r4),
              ),
              child: const Padding(
                padding: EdgeInsets.all(PSpacing.x4),
                child: Wrap(
                  spacing: PSpacing.x3,
                  children: [
                    _Live(
                      label: '금액 가리기',
                      icon: LucideIcons.eye,
                      pressedIcon: LucideIcons.eyeOff500,
                      tone: PToggleTone.inverted,
                    ),
                    _Live(
                      label: '금액 가리기',
                      icon: LucideIcons.eye,
                      pressedIcon: LucideIcons.eyeOff500,
                      tone: PToggleTone.inverted,
                      initial: true,
                    ),
                    _Live(
                      label: '금액 가리기',
                      icon: LucideIcons.eye,
                      pressedIcon: LucideIcons.eyeOff500,
                      tone: PToggleTone.inverted,
                      disabled: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
