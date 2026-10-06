import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/checkbox/p_checkbox.dart';

/// 카탈로그(/dev/ds) — 크기 × 모양 × 톤 × 체크 여부, 굵기, 상태, 묶음(부모 · 일부 선택), 칸만(상태를 멈춰 그렸다).
/// 줄은 눌러서 바꿔 본다 — 누름(누름 색 + 칸 축소)은 직접 눌러 본다.
class CheckboxDemo extends StatelessWidget {
  const CheckboxDemo({super.key});

  // 체크 여부 — 선택 안 됨 · 선택 · 일부 선택(묶음의 부모)
  static const List<bool?> _checks = [false, true, null];

  // 스펙의 porest 예(checkbox.md — 코드 · 그림)
  static const Map<bool?, String> _labels = {
    false: '단종된 카드도 보기',
    true: '이 카드 기억하기',
    null: '전체',
  };

  static String _name(bool? checked) => switch (checked) {
    false => '선택 안 됨',
    true => '선택',
    null => '일부 선택',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '모양 × 톤 × 크기 — 선택 안 됨 · 선택 · 일부 선택(눌러서 바꿔 본다)',
          children: [
            for (final shape in PCheckboxShape.values)
              for (final tone in PCheckboxTone.values)
                for (final size in PCheckboxSize.values)
                  DemoRow(
                    label: '${shape.name} · ${tone.name} · ${size.name}',
                    children: [
                      for (final checked in _checks)
                        _LiveCheckbox(
                          initial: checked,
                          label: _labels[checked]!,
                          size: size,
                          shape: shape,
                          tone: tone,
                        ),
                    ],
                  ),
          ],
        ),
        DemoBlock(
          title: '라벨 굵기 — regular 400 · bold 700(강조 · 묶음의 부모)',
          children: [
            for (final size in PCheckboxSize.values)
              DemoRow(
                label: size.name,
                children: [
                  for (final weight in PCheckboxWeight.values)
                    _LiveCheckbox(
                      initial: true,
                      label: '지난 달 거래 숨기기',
                      size: size,
                      weight: weight,
                    ),
                ],
              ),
          ],
        ),
        DemoBlock(
          title: '상태 — 기본 · 비활성(누름은 직접 눌러 본다). 비활성은 전용 색, 라벨도 비활성 색',
          children: [
            for (final shape in PCheckboxShape.values)
              for (final tone in PCheckboxTone.values)
                DemoRow(
                  label: '${shape.name} · ${tone.name}',
                  children: [
                    for (final checked in _checks) ...[
                      _LiveCheckbox(
                        initial: checked,
                        label: _name(checked),
                        shape: shape,
                        tone: tone,
                      ),
                      PCheckbox(
                        label: '비활성',
                        checked: checked,
                        onChanged: null,
                        shape: shape,
                        tone: tone,
                      ),
                    ],
                  ],
                ),
          ],
        ),
        const DemoBlock(
          title: '묶음 — 줄 사이 12. 부모를 누르면 모두 · 모두 풀기, 자식을 일부만 고르면 부모는 일부 선택',
          children: [_ExportGroup()],
        ),
        DemoBlock(
          title: '칸만(PCheckmark) — 목록 행이 누르기를 맡는다. 기본 · 누름 · 비활성을 멈춰 그렸다',
          children: [
            for (final shape in PCheckboxShape.values)
              for (final tone in PCheckboxTone.values)
                for (final size in PCheckboxSize.values)
                  DemoRow(
                    label:
                        '${shape.name} · ${tone.name} · ${size.name} — '
                        '기본 · 누름 · 비활성',
                    children: [
                      for (final checked in _checks)
                        for (final (enabled, pressed) in const [
                          (true, false),
                          (true, true),
                          (false, false),
                        ])
                          PCheckmark(
                            checked: checked,
                            size: size,
                            shape: shape,
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

/// 눌러서 바꿔 보는 견본 — 선택 ↔ 선택 안 됨, 일부 선택이면 선택으로.
class _LiveCheckbox extends StatefulWidget {
  const _LiveCheckbox({
    required this.initial,
    required this.label,
    this.size = PCheckboxSize.medium,
    this.shape = PCheckboxShape.square,
    this.tone = PCheckboxTone.neutral,
    this.weight = PCheckboxWeight.regular,
  });

  final bool? initial;
  final String label;
  final PCheckboxSize size;
  final PCheckboxShape shape;
  final PCheckboxTone tone;
  final PCheckboxWeight weight;

  @override
  State<_LiveCheckbox> createState() => _LiveCheckboxState();
}

class _LiveCheckboxState extends State<_LiveCheckbox> {
  late bool? _checked = widget.initial;

  @override
  Widget build(BuildContext context) {
    return PCheckbox(
      label: widget.label,
      checked: _checked,
      onChanged: (next) => setState(() => _checked = next),
      size: widget.size,
      shape: widget.shape,
      tone: widget.tone,
      weight: widget.weight,
    );
  }
}

/// Desk 데이터 내보내기 — 부모(전체, bold)는 자식을 따라 선택 · 일부 선택 · 선택 안 됨이 된다(checkbox.md 묶음 쓰기).
class _ExportGroup extends StatefulWidget {
  const _ExportGroup();

  @override
  State<_ExportGroup> createState() => _ExportGroupState();
}

class _ExportGroupState extends State<_ExportGroup> {
  static const List<String> _items = ['거래 내역', '예산', '메모'];
  final Set<String> _picked = {'거래 내역'};

  @override
  Widget build(BuildContext context) {
    final all = _picked.length == _items.length;
    final bool? parent = all ? true : (_picked.isEmpty ? false : null);
    return PCheckboxGroup(
      semanticLabel: '내보낼 데이터',
      children: [
        PCheckbox(
          label: '전체',
          weight: PCheckboxWeight.bold,
          checked: parent,
          onChanged: (next) => setState(() {
            _picked
              ..clear()
              ..addAll(next ? _items : const []);
          }),
        ),
        for (final item in _items)
          PCheckbox(
            label: item,
            checked: _picked.contains(item),
            onChanged: (next) =>
                setState(() => next ? _picked.add(item) : _picked.remove(item)),
          ),
      ],
    );
  }
}
