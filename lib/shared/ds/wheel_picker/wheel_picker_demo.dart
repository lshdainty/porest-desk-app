import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/button/p_button.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/wheel_picker/p_wheel_picker.dart';

// 연 · 월 — 날짜 표기 그대로("2026년" · "10월"). 연은 처음 · 끝에서 멈추고 월은 반복한다
final List<PWheelPickerOption<int>> _years = [
  for (var i = 0; i < 11; i++)
    PWheelPickerOption(value: 2021 + i, label: '${2021 + i}년'),
];
final List<PWheelPickerOption<int>> _months = [
  for (var i = 1; i <= 12; i++) PWheelPickerOption(value: i, label: '$i월'),
];
// 시 · 분 — 숫자만으로 읽히는 칼럼은 단위를 칼럼 이름으로 알린다
final List<PWheelPickerOption<int>> _hours = [
  for (var i = 1; i <= 12; i++) PWheelPickerOption(value: i, label: '$i'),
];
final List<PWheelPickerOption<int>> _minutes = [
  for (var i = 0; i < 60; i++)
    PWheelPickerOption(value: i, label: i.toString().padLeft(2, '0')),
];

/// 연 | 월 휠 견본 — 연 120 오른쪽 · 월 96 왼쪽 정렬(달력 머리 · 달만 고르기와 같은 모양), 폭 280.
class _MonthWheel extends StatelessWidget {
  const _MonthWheel({
    required this.size,
    required this.visibleItems,
    this.disabled = false,
  });

  final PWheelPickerSize size;
  final int visibleItems;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: PWheelPicker(
        semanticLabel: '월 선택',
        size: size,
        visibleItems: visibleItems,
        disabled: disabled,
        children: [
          PWheelPickerColumn<int>(
            semanticLabel: '연도',
            options: _years,
            initialValue: 2026,
            align: PWheelPickerAlign.right,
            width: 120,
          ),
          PWheelPickerColumn<int>(
            semanticLabel: '월',
            options: _months,
            initialValue: 10,
            align: PWheelPickerAlign.left,
            width: 96,
            loop: true,
          ),
        ],
      ),
    );
  }
}

/// 카탈로그(/dev/ds) — 크기 × 보이는 칸, 막힘, 직접 굴려 보기(끌기 · 누르기 · 키, 값은 멈춘 뒤 한 번 정해진다).
class WheelPickerDemo extends StatelessWidget {
  const WheelPickerDemo({super.key});

  static const _sizes = PWheelPickerSize.values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '크기 × 보이는 칸 — medium 44 · small 36, 5칸 · 7칸(연 | 월)',
          children: [
            for (final size in _sizes.reversed)
              DemoRow(
                label: size.name,
                children: [
                  for (final count in const [5, 7])
                    _MonthWheel(size: size, visibleItems: count),
                ],
              ),
          ],
        ),
        DemoBlock(
          title: '상태 — 막힘(고른 항목도 흐리게, 띠는 남는다)',
          children: [
            for (final size in _sizes.reversed)
              DemoRow(
                label: size.name,
                children: [
                  _MonthWheel(size: size, visibleItems: 5, disabled: true),
                ],
              ),
          ],
        ),
        const DemoBlock(
          title: '직접 굴려 보기 — 밀기 · 누르기 · 값은 멈춘 뒤 한 번 정해진다',
          children: [
            DemoRow(label: '연 | 월', children: [_TryMonth()]),
            DemoRow(label: '시 | 분 (small)', children: [_TryTime()]),
          ],
        ),
      ],
    );
  }
}

/// 직접 굴려 보기 — 멈춘 뒤 값이 정해지고(onChanged), 바깥에서 값을 바꾸면 그 자리로 간다.
class _TryMonth extends StatefulWidget {
  const _TryMonth();

  @override
  State<_TryMonth> createState() => _TryMonthState();
}

class _TryMonthState extends State<_TryMonth> {
  int _year = 2026;
  int _month = 10;
  int _ticks = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x3,
        children: [
          PWheelPicker(
            semanticLabel: '월 선택',
            children: [
              PWheelPickerColumn<int>(
                semanticLabel: '연도',
                options: _years,
                align: PWheelPickerAlign.right,
                width: 120,
                value: _year,
                onChanged: (value, _) => setState(() => _year = value),
                // 굴리는 동안 지나는 칸마다 — 햅틱은 쓰는 쪽이 여기서 준다
                onIndexChange: (_, _) => setState(() => _ticks++),
              ),
              PWheelPickerColumn<int>(
                semanticLabel: '월',
                options: _months,
                align: PWheelPickerAlign.left,
                width: 96,
                loop: true,
                value: _month,
                valueChange: PWheelPickerValueChange.smooth,
                onChanged: (value, _) => setState(() => _month = value),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '고른 값: $_year년 $_month월 · 연을 지나간 칸 $_ticks',
                  style: PTypography.t4.copyWith(color: c.fgNeutral),
                ),
              ),
              PButton(
                label: '2026년 1월로',
                onPressed: () => setState(() {
                  _year = 2026;
                  _month = 1;
                }),
                variant: PButtonVariant.neutralWeak,
                size: PButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 직접 굴려 보기 — 시(오른쪽 정렬 · 반복) | 분(반복), small.
class _TryTime extends StatelessWidget {
  const _TryTime();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: PWheelPicker(
        semanticLabel: '시각 선택',
        size: PWheelPickerSize.small,
        children: [
          PWheelPickerColumn<int>(
            semanticLabel: '시',
            options: _hours,
            initialValue: 9,
            align: PWheelPickerAlign.right,
            loop: true,
          ),
          PWheelPickerColumn<int>(
            semanticLabel: '분',
            options: _minutes,
            initialValue: 30,
            loop: true,
          ),
        ],
      ),
    );
  }
}
