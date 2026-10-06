import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/field/p_field.dart';
import 'package:porest_desk_app/shared/ds/input/p_input.dart';

/// 카탈로그(/dev/ds) — 모양 둘(상자 · 밑줄) × 상태(기본 · 오류 · 비활성 · 읽기 전용 — 포커스는 직접 눌러 본다),
/// 붙이개, 지우기, 밑줄을 쓰는 자리. 앱은 늘 large(52 · 밑줄 40)다. 예는 input.md 의 것이다.
class InputDemo extends StatelessWidget {
  const InputDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final variant in PInputVariant.values)
          DemoBlock(
            title: switch (variant) {
              PInputVariant.outline =>
                'outline — 상자(기본) 52. 상태 — 포커스는 직접 눌러 본다(안쪽 2px 가 짙어진다)',
              PInputVariant.underline =>
                'underline — 밑줄 40(화면에 입력이 하나뿐일 때). 상태 — 포커스는 직접 눌러 본다',
            },
            children: [
              DemoRow(
                label: '기본 — 빈 칸(예시 글)',
                children: [
                  PInput(
                    variant: variant,
                    semanticLabel: '금액',
                    placeholder: '금액',
                    suffixText: '원',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              DemoRow(
                label: '기본 — 값 · 지우기',
                children: [
                  PInput(
                    variant: variant,
                    semanticLabel: '금액',
                    initialValue: '12,000',
                    suffixText: '원',
                    clearable: true,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              DemoRow(
                label: '오류 — 포커스해도 빨간 2px 그대로',
                children: [
                  PInput(
                    variant: variant,
                    semanticLabel: '금액',
                    initialValue: '12,000',
                    suffixText: '원',
                    invalid: true,
                  ),
                ],
              ),
              DemoRow(
                label: '비활성 — 흐리게 하지 않는다',
                children: [
                  PInput(
                    variant: variant,
                    semanticLabel: '금액',
                    initialValue: '12,000',
                    suffixText: '원',
                    disabled: true,
                  ),
                ],
              ),
              DemoRow(
                label: '읽기 전용 — 포커스 테두리 없음',
                children: [
                  PInput(
                    variant: variant,
                    semanticLabel: '금액',
                    initialValue: '12,000',
                    suffixText: '원',
                    readOnly: true,
                  ),
                ],
              ),
            ],
          ),
        const DemoBlock(
          title: '붙이개 — 앞 · 뒤 글자(단위는 뒤 글자로) · 아이콘(뜻을 돕기만 한다)',
          children: [
            PField(
              label: '블로그 주소',
              child: PInput(
                prefixText: 'https://',
                placeholder: 'example.com',
                keyboardType: TextInputType.url,
              ),
            ),
            PField(
              label: '금액',
              child: PInput(
                initialValue: '12,000',
                suffixText: '원',
                keyboardType: TextInputType.number,
              ),
            ),
            PField(
              label: '나이',
              child: PInput(
                prefixText: '만',
                initialValue: '34',
                suffixText: '세',
                keyboardType: TextInputType.number,
              ),
            ),
            PField(
              label: '메모 검색',
              child: PInput(
                prefixIcon: LucideIcons.search,
                placeholder: '제목 · 본문으로 찾기',
              ),
            ),
          ],
        ),
        const DemoBlock(
          title: '지우기 — 값이 있을 때만(검색칸 · 선택 사항인 칸). 누르면 비우고 입력에 포커스를 둔다',
          children: [
            PField(
              label: '내용',
              indicator: PFieldIndicator.optional,
              child: PInput(initialValue: '점심 식사', clearable: true),
            ),
            PInput(
              semanticLabel: '메모 검색',
              prefixIcon: LucideIcons.search,
              initialValue: '회의록',
              suffixText: '12건',
              clearable: true,
            ),
          ],
        ),
        const DemoBlock(
          title: '밑줄 — 화면에 입력 하나(금액을 먼저 받는 화면 · 목록 위 검색)',
          children: [
            PField(
              label: '얼마를 썼나요?',
              labelWeight: PFieldLabelWeight.bold,
              child: PInput(
                variant: PInputVariant.underline,
                initialValue: '12,000',
                suffixText: '원',
                keyboardType: TextInputType.number,
              ),
            ),
            PInput(
              variant: PInputVariant.underline,
              semanticLabel: '검색',
              prefixIcon: LucideIcons.search,
              initialValue: '회의록',
              clearable: true,
            ),
          ],
        ),
      ],
    );
  }
}
