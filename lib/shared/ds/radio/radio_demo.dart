import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/radio/p_radio.dart';

/// 반복 — 캘린더 일정의 반복 선택지(radio-group.md 그림의 예).
enum _Repeat { none, daily, weekly, monthly, yearly }

const Map<_Repeat, String> _repeatLabels = {
  _Repeat.none: '반복 없음',
  _Repeat.daily: '매일',
  _Repeat.weekly: '매주',
  _Repeat.monthly: '매월',
  _Repeat.yearly: '매년',
};

/// 카탈로그(/dev/ds) — 톤 × 크기 묶음, 굵기, 상태(막힌 선택지 · 막힌 묶음), 동그라미만(상태를 멈춰 그렸다).
/// 묶음 안에서 눌러서 골라 본다 — 누름(누름 색 + 동그라미 축소)은 직접 눌러 본다.
class RadioDemo extends StatelessWidget {
  const RadioDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '톤 × 크기 — 하나를 고르면 앞에 고른 것이 풀린다(세로로만 쌓는다)',
          children: [
            for (final tone in PRadioTone.values)
              DemoRow(
                label: '${tone.name} — medium · large',
                children: [
                  for (final size in PRadioSize.values)
                    _LiveGroup(
                      initial: _Repeat.weekly,
                      options: const [
                        _Repeat.none,
                        _Repeat.daily,
                        _Repeat.weekly,
                      ],
                      size: size,
                      tone: tone,
                    ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title: '라벨 굵기 — regular 400 · bold 700(강조)',
          children: [
            for (final size in PRadioSize.values)
              DemoRow(
                label: size.name,
                children: [
                  for (final weight in PRadioWeight.values)
                    _LiveGroup(
                      initial: _Repeat.monthly,
                      options: const [_Repeat.monthly, _Repeat.yearly],
                      size: size,
                      weight: weight,
                    ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title: '상태 — 막힌 선택지(매년) · 막힌 묶음(고른 선택지는 채운 원 그대로 색만)',
          children: [
            for (final tone in PRadioTone.values)
              DemoRow(
                label: tone.name,
                children: [
                  _LiveGroup(
                    initial: _Repeat.monthly,
                    options: const [
                      _Repeat.none,
                      _Repeat.monthly,
                      _Repeat.yearly,
                    ],
                    tone: tone,
                    disabledOption: _Repeat.yearly,
                  ),
                  PRadioGroup<_Repeat>(
                    value: _Repeat.monthly,
                    onChanged: null,
                    semanticLabel: '반복',
                    children: [
                      for (final option in const [
                        _Repeat.none,
                        _Repeat.monthly,
                        _Repeat.yearly,
                      ])
                        PRadio(
                          value: option,
                          label: _repeatLabels[option]!,
                          tone: tone,
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title:
              '동그라미만(PRadiomark) — 라벨이 따로 서는 줄이 누르기를 맡는다. 기본 · 누름 · 비활성을 멈춰 그렸다',
          children: [
            for (final tone in PRadioTone.values)
              for (final size in PRadioSize.values)
                DemoRow(
                  label:
                      '${tone.name} · ${size.name} — 선택 안 됨 · 선택 × 기본 · 누름 · 비활성',
                  children: [
                    for (final checked in const [false, true])
                      for (final (enabled, pressed) in const [
                        (true, false),
                        (true, true),
                        (false, false),
                      ])
                        PRadiomark(
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

/// 눌러서 골라 보는 묶음.
class _LiveGroup extends StatefulWidget {
  const _LiveGroup({
    required this.initial,
    required this.options,
    this.size = PRadioSize.medium,
    this.tone = PRadioTone.neutral,
    this.weight = PRadioWeight.regular,
    this.disabledOption,
  });

  final _Repeat initial;
  final List<_Repeat> options;
  final PRadioSize size;
  final PRadioTone tone;
  final PRadioWeight weight;
  final _Repeat? disabledOption;

  @override
  State<_LiveGroup> createState() => _LiveGroupState();
}

class _LiveGroupState extends State<_LiveGroup> {
  late _Repeat _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return PRadioGroup<_Repeat>(
      value: _value,
      onChanged: (next) => setState(() => _value = next),
      semanticLabel: '반복',
      children: [
        for (final option in widget.options)
          PRadio(
            value: option,
            label: _repeatLabels[option]!,
            size: widget.size,
            tone: widget.tone,
            weight: widget.weight,
            enabled: option != widget.disabledOption,
          ),
      ],
    );
  }
}
