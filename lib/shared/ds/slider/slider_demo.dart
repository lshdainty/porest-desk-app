import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/field/p_field.dart';
import 'package:porest_desk_app/shared/ds/slider/p_slider.dart';

/// 카탈로그(/dev/ds) — 값 하나 · 둘 × 눈금 없음 · 있음 × 기본 · 막힘, 그리고 Field 안의 쓰임 넷(예산 알림 임계값 ·
/// 별점 · 범위 · 막힘). 눌림 · 키보드 포커스는 직접 해 본다(손잡이를 끌면 24 + 말풍선).
class SliderDemo extends StatefulWidget {
  const SliderDemo({super.key});

  @override
  State<SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<SliderDemo> {
  double _threshold = 80;
  int _commits = 0;
  double _score = 3;
  (double, double) _usage = (30, 70);

  static String _percent(double v) => '${v.round()}%';
  static String _point(double v) => '${v.round()}점';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final range in [false, true])
          for (final discrete in [false, true])
            DemoBlock(
              title:
                  '${range ? '값 둘' : '값 하나'} · ${discrete ? '눈금 있음 — 굵은 틈 · 단계 표식' : '눈금 없음 — 양 끝 표식'}',
              children: [
                for (final disabled in [false, true])
                  _Sample(range: range, discrete: discrete, disabled: disabled),
              ],
            ),
        DemoBlock(
          title: '예산 알림 임계값 — 끄는 동안 화면만, 손을 뗄 때 한 번 저장(저장 $_commits번)',
          children: [
            _ValueField(
              label: '예산 알림 임계값',
              value: _percent(_threshold),
              description: '예산 사용률이 이 값을 넘으면 알려줘요.',
              child: PSlider(
                min: 50,
                max: 100,
                step: 5,
                value: _threshold,
                formatValue: _percent,
                onChanged: (v) => setState(() => _threshold = v),
                onChangeEnd: (_) => setState(() => _commits++),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: '별점 1 ~ 5 — 폼의 값이라 손을 떼도 보내지 않는다(onChangeEnd 없음)',
          children: [
            _ValueField(
              label: '만족도',
              value: _point(_score),
              child: PSlider(
                min: 1,
                max: 5,
                value: _score,
                formatValue: _point,
                onChanged: (v) => setState(() => _score = v),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: '범위 — 손잡이 이름은 "예산 사용률 최소" · "예산 사용률 최대"',
          children: [
            _ValueField(
              label: '예산 사용률',
              value: '${_usage.$1.round()}% ~ ${_usage.$2.round()}%',
              child: PRangeSlider(
                step: 10,
                values: _usage,
                formatValue: _percent,
                onChanged: (v) => setState(() => _usage = v),
              ),
            ),
          ],
        ),
        const DemoBlock(
          title: '막힘(Field) — 전용 색, 흐리게 하지 않는다',
          children: [
            _ValueField(
              label: '예산 알림 임계값',
              value: '80%',
              disabled: true,
              child: PSlider(
                min: 50,
                max: 100,
                step: 5,
                value: 80,
                onChanged: null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Sample extends StatelessWidget {
  const _Sample({
    required this.range,
    required this.discrete,
    required this.disabled,
  });

  final bool range;
  final bool discrete;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    // 눈금 없음 — 10 구간 이상, 있음 — 4 구간(별점 1 ~ 5 · 0 ~ 100 · 25 단위)
    final unit = !range && discrete ? '점' : '%';
    String format(double v) => '${v.round()}$unit';
    if (range) {
      return PRangeSlider(
        label: '견본',
        min: 0,
        max: 100,
        step: discrete ? 25 : 10,
        values: discrete ? (50, 75) : (50, 80),
        formatValue: format,
        disabled: disabled,
        onChanged: null,
      );
    }
    return PSlider(
      label: '견본',
      min: discrete ? 1 : 50,
      max: discrete ? 5 : 100,
      step: discrete ? 1 : 5,
      value: discrete ? 3 : 75,
      formatValue: format,
      disabled: disabled,
      onChanged: null,
    );
  }
}

/// Field 머리 오른쪽에 머리 값을 둔다 — PField 의 headerTrailing 자리(머리 값 글은 줄 높이 22 라 머리를 넘치지 않는다).
class _ValueField extends StatelessWidget {
  const _ValueField({
    required this.label,
    required this.value,
    required this.child,
    this.description,
    this.disabled = false,
  });

  final String label;
  final String value;
  final String? description;
  final bool disabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PField(
      label: label,
      description: description,
      disabled: disabled,
      headerTrailing: PSliderValue(value, disabled: disabled),
      child: child,
    );
  }
}
