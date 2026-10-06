import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/switch/p_switch.dart';

/// 카탈로그(/dev/ds) — 톤 × 크기 × 끔 · 켬, 상태, 막힌 줄(위 설정을 끄면 아래 줄은 값을 지닌 채 막힌다), 스위치만
/// (상태를 멈춰 그렸다). 눌러서 켜고 꺼 본다 — 누름(색은 그대로, 스위치만 축소)은 직접 눌러 본다.
class SwitchDemo extends StatelessWidget {
  const SwitchDemo({super.key});

  static String _sizeName(PSwitchSize size) => switch (size) {
    PSwitchSize.s16 => '16',
    PSwitchSize.s24 => '24(기본)',
    PSwitchSize.s32 => '32',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '톤 × 크기 × 끔 · 켬 — 크기 이름은 트랙 높이(눌러서 켜고 꺼 본다)',
          children: [
            for (final tone in PSwitchTone.values)
              for (final size in PSwitchSize.values)
                DemoRow(
                  label: '${tone.name} · ${_sizeName(size)}',
                  children: [
                    _LiveSwitch(
                      initial: false,
                      label: '결제 알림',
                      size: size,
                      tone: tone,
                    ),
                    _LiveSwitch(
                      initial: true,
                      label: '종일',
                      size: size,
                      tone: tone,
                    ),
                  ],
                ),
          ],
        ),
        DemoBlock(
          title: '상태 — 기본 · 비활성(누름은 직접 눌러 본다 — 색은 바뀌지 않는다). 막히면 라벨도 비활성 색',
          children: [
            for (final tone in PSwitchTone.values)
              for (final checked in const [false, true])
                DemoRow(
                  label: '${tone.name} · ${checked ? '켬' : '끔'}',
                  children: [
                    _LiveSwitch(initial: checked, label: '주간 리포트', tone: tone),
                    PSwitch(
                      label: checked ? '켜진 채 막힘' : '꺼진 채 막힘',
                      checked: checked,
                      onChanged: null,
                      tone: tone,
                    ),
                  ],
                ),
          ],
        ),
        const DemoBlock(
          title: '따로 움직이는 기능 — 푸시 알림을 끄면 아래 줄은 값을 지닌 채 막힌다',
          children: [_DependentSwitches()],
        ),
        DemoBlock(
          title: '스위치만(PSwitchmark) — 설정 줄이 누르기를 맡는다. 기본 · 누름 · 비활성을 멈춰 그렸다',
          children: [
            for (final tone in PSwitchTone.values)
              for (final size in PSwitchSize.values)
                DemoRow(
                  label:
                      '${tone.name} · ${_sizeName(size)} — 끔 · 켬 × 기본 · 누름 · 비활성',
                  children: [
                    for (final checked in const [false, true])
                      for (final (enabled, pressed) in const [
                        (true, false),
                        (true, true),
                        (false, false),
                      ])
                        PSwitchmark(
                          checked: checked,
                          size: size,
                          tone: tone,
                          enabled: enabled,
                          pressed: pressed,
                        ),
                  ],
                ),
          ],
        ),
      ],
    );
  }
}

/// 눌러서 켜고 꺼 보는 견본.
class _LiveSwitch extends StatefulWidget {
  const _LiveSwitch({
    required this.initial,
    required this.label,
    this.size = PSwitchSize.s24,
    this.tone = PSwitchTone.neutral,
  });

  final bool initial;
  final String label;
  final PSwitchSize size;
  final PSwitchTone tone;

  @override
  State<_LiveSwitch> createState() => _LiveSwitchState();
}

class _LiveSwitchState extends State<_LiveSwitch> {
  late bool _on = widget.initial;

  @override
  Widget build(BuildContext context) {
    return PSwitch(
      label: widget.label,
      checked: _on,
      onChanged: (next) => setState(() => _on = next),
      size: widget.size,
      tone: widget.tone,
    );
  }
}

/// 푸시 알림 아래의 결제 · 예산 알림 — 위를 끄면 아래는 값을 지닌 채 막힌다(switch.md 따로 움직이는 기능에만).
class _DependentSwitches extends StatefulWidget {
  const _DependentSwitches();

  @override
  State<_DependentSwitches> createState() => _DependentSwitchesState();
}

class _DependentSwitchesState extends State<_DependentSwitches> {
  bool _push = true;
  bool _payment = true;
  bool _budget = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PSpacing.x3,
      children: [
        PSwitch(
          label: '푸시 알림',
          checked: _push,
          onChanged: (next) => setState(() => _push = next),
        ),
        PSwitch(
          label: '결제 알림',
          checked: _payment,
          onChanged: _push ? (next) => setState(() => _payment = next) : null,
        ),
        PSwitch(
          label: '예산 알림',
          checked: _budget,
          onChanged: _push ? (next) => setState(() => _budget = next) : null,
        ),
      ],
    );
  }
}
