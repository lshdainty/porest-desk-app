import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/field/p_field.dart';
import 'package:porest_desk_app/shared/ds/textarea/p_textarea.dart';

/// 카탈로그(/dev/ds) — 높이 둘(자동 · 고정) × 상태(기본 · 오류 · 비활성 · 읽기 전용 — 포커스는 직접 눌러 본다),
/// 최대 높이, Field 안(글자 수). 앱은 늘 large 다. 예는 textarea.md 의 것이다.
class TextareaDemo extends StatelessWidget {
  const TextareaDemo({super.key});

  static const _reason = '가족 행사 참석으로 연차를 씁니다.\n결재 뒤 인수인계 문서를 공유할게요.';
  static const _memo = '팀 점심 — 다음 달 회식비에서 정산하기로 했다.\n영수증은 사진으로 올려 둠.';
  static const _long =
      '$_reason\n돌아와서 바로 이어서 할게요.\n급한 건 메신저로 연락 주세요.\n'
      '10월 24일 오후에는 연락이 어려워요.\n대신 처리할 사람은 김포레 님입니다.';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final autoSize in const [true, false])
          DemoBlock(
            title: autoSize
                ? '자동 높이(기본) — 3줄(94)에서 쓴 만큼 자란다(직접 써 본다). 포커스는 직접 눌러 본다'
                : '고정 높이(autoSize off) — 정한 높이(2줄 72 이상), 넘치면 칸 안에서 스크롤',
            children: [
              DemoRow(
                label: '기본 — 빈 칸(예시 글)',
                children: [
                  PTextarea(
                    autoSize: autoSize,
                    height: autoSize ? null : 72,
                    semanticLabel: '휴가 사유',
                    placeholder: '예: 가족 행사 참석',
                  ),
                ],
              ),
              DemoRow(
                label: '기본 — 값',
                children: [
                  PTextarea(
                    autoSize: autoSize,
                    height: autoSize ? null : 72,
                    semanticLabel: '휴가 사유',
                    initialValue: _reason,
                  ),
                ],
              ),
              DemoRow(
                label: '오류 — 포커스해도 빨간 2px 그대로',
                children: [
                  PTextarea(
                    autoSize: autoSize,
                    height: autoSize ? null : 72,
                    semanticLabel: '휴가 사유',
                    initialValue: _reason,
                    invalid: true,
                  ),
                ],
              ),
              DemoRow(
                label: '비활성 — 흐리게 하지 않는다',
                children: [
                  PTextarea(
                    autoSize: autoSize,
                    height: autoSize ? null : 72,
                    semanticLabel: '휴가 사유',
                    initialValue: _reason,
                    disabled: true,
                  ),
                ],
              ),
              DemoRow(
                label: '읽기 전용 — 포커스 · 복사 · 스크롤은 된다',
                children: [
                  PTextarea(
                    autoSize: autoSize,
                    height: autoSize ? null : 72,
                    semanticLabel: '휴가 사유',
                    initialValue: _reason,
                    readOnly: true,
                  ),
                ],
              ),
            ],
          ),
        const DemoBlock(
          title: '최대 높이 — 시트 · 대화상자 안에서는 정한다(그 높이부터 칸 안에서 스크롤)',
          children: [
            PField(
              label: '메모',
              child: PTextarea(initialValue: _long, maxHeight: 140),
            ),
          ],
        ),
        const DemoBlock(
          title: 'Field 안 — 글자 수(자소 · 최대에서 멈춘다) · 선택',
          children: [
            PField(
              label: '휴가 사유',
              maxGraphemeCount: 1000,
              child: PTextarea(placeholder: '예: 가족 행사 참석'),
            ),
            PField(
              label: '메모',
              indicator: PFieldIndicator.optional,
              maxGraphemeCount: 100,
              child: PTextarea(initialValue: _memo),
            ),
          ],
        ),
      ],
    );
  }
}
