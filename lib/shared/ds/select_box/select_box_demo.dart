import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/field/p_field.dart';
import 'package:porest_desk_app/shared/ds/input/p_input.dart';
import 'package:porest_desk_app/shared/ds/select_box/p_select_box.dart';

enum _End { none, count, date }

/// 카탈로그(/dev/ds) — 하나 고르기 · 여럿 고르기 × 열(1 · 2 · 3) × 컨트롤(라디오 · 체크 · 없음), 앞 아이콘, 펼침, 상태(비활성 ·
/// 고른 채 비활성 · 오류), 가장 나쁜 값(긴 제목 · 긴 설명 · 좁은 폭에서 같은 높이). 상자를 눌러 골라 본다 — 누름(바탕 +
/// 누르는 자리 2px)은 직접 눌러 본다. 값은 저장 · 다음 같은 버튼으로 반영한다(상자는 고르기만 한다).
class SelectBoxDemo extends StatelessWidget {
  const SelectBoxDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '하나 고르기 — 1열 가로형(라디오) · 펼침(횟수 지정을 고르면 반복 횟수 칸이 열린다)',
          children: [_EndDemo()],
        ),
        DemoBlock(
          title: '2열 · 3열 세로형 — 앞이 위, 모든 줄이 같은 높이 · 3열은 컨트롤 없음',
          children: [_ColumnsDemo()],
        ),
        DemoBlock(
          title: '여럿 고르기 — 칸 없는 체크(꺼지면 옅은 체크) · 컨트롤 없음',
          children: [_CheckDemo()],
        ),
        DemoBlock(
          title: '상태 — 비활성 · 고른 채 비활성(2px 옅은 선) · 오류(묶음 아래 글)',
          children: [_StatesDemo()],
        ),
        DemoBlock(
          title: '가장 나쁜 값 — 긴 제목 · 긴 설명 · 3열 좁은 폭에서 같은 높이',
          children: [_WorstDemo()],
        ),
      ],
    );
  }
}

class _EndDemo extends StatefulWidget {
  const _EndDemo();

  @override
  State<_EndDemo> createState() => _EndDemoState();
}

class _EndDemoState extends State<_EndDemo> {
  _End value = _End.count;

  @override
  Widget build(BuildContext context) {
    return PField(
      label: '종료',
      child: PRadioSelectBoxGroup<_End>(
        value: value,
        onChanged: (next) => setState(() => value = next),
        children: const [
          PRadioSelectBox<_End>(
            value: _End.none,
            label: '무기한',
            description: '중지할 때까지 계속 반복',
          ),
          PRadioSelectBox<_End>(
            value: _End.count,
            label: '횟수 지정',
            description: '정한 횟수만큼 반복',
            footer: PInput(
              initialValue: '12',
              semanticLabel: '반복 횟수',
              suffixText: '회',
            ),
          ),
          PRadioSelectBox<_End>(
            value: _End.date,
            label: '종료일 지정',
            description: '정한 날까지 반복',
          ),
        ],
      ),
    );
  }
}

class _ColumnsDemo extends StatefulWidget {
  const _ColumnsDemo();

  @override
  State<_ColumnsDemo> createState() => _ColumnsDemoState();
}

class _ColumnsDemoState extends State<_ColumnsDemo> {
  String two = 'split';
  String three = 'csv';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        PField(
          label: '분배 방식',
          child: PRadioSelectBoxGroup<String>(
            columns: 2,
            value: two,
            onChanged: (next) => setState(() => two = next),
            children: const [
              PRadioSelectBox<String>(
                value: 'split',
                prefix: Icon(LucideIcons.equal),
                label: '똑같이 나누기',
                description: '참여자 모두 같은 금액',
              ),
              PRadioSelectBox<String>(
                value: 'ratio',
                prefix: Icon(LucideIcons.percent),
                label: '비율로 나누기',
                description: '정한 비율대로 나눠 내요. 비율 합은 100이어야 해요',
              ),
              PRadioSelectBox<String>(
                value: 'amount',
                prefix: Icon(LucideIcons.hash),
                label: '금액 직접 입력',
                description: '사람마다 낼 금액을 적어요',
              ),
              PRadioSelectBox<String>(
                value: 'payer',
                prefix: Icon(LucideIcons.user),
                label: '한 명이 전부',
                description: '결제한 사람이 모두 부담',
              ),
            ],
          ),
        ),
        PField(
          label: '파일 형식',
          child: PRadioSelectBoxGroup<String>(
            columns: 3,
            value: three,
            onChanged: (next) => setState(() => three = next),
            children: const [
              PRadioSelectBox<String>(
                value: 'csv',
                control: PRadioSelectBoxControl.none,
                prefix: Icon(LucideIcons.fileText),
                label: 'CSV',
                description: '구글시트',
              ),
              PRadioSelectBox<String>(
                value: 'xlsx',
                control: PRadioSelectBoxControl.none,
                prefix: Icon(LucideIcons.sheet),
                label: 'Excel',
                description: '엑셀',
              ),
              PRadioSelectBox<String>(
                value: 'json',
                control: PRadioSelectBoxControl.none,
                prefix: Icon(LucideIcons.braces),
                label: 'JSON',
                description: '백업용',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckDemo extends StatefulWidget {
  const _CheckDemo();

  @override
  State<_CheckDemo> createState() => _CheckDemoState();
}

class _CheckDemoState extends State<_CheckDemo> {
  final Set<String> on = {'read'};
  final Set<String> kinds = {'out'};

  void _toggle(Set<String> set, String key, bool next) =>
      setState(() => next ? set.add(key) : set.remove(key));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        PField(
          label: '휴가 권한',
          description: '여럿 고를 수 있어요. 저장을 눌러야 바뀌어요.',
          child: PCheckSelectBoxGroup(
            children: [
              PCheckSelectBox(
                label: '휴가 조회',
                description: '본인 휴가 내역을 조회할 수 있는 권한입니다.',
                checked: on.contains('read'),
                onChanged: (v) => _toggle(on, 'read', v),
              ),
              PCheckSelectBox(
                label: '휴가 신청',
                description: 'OT, 경조 휴가 등 휴가를 신청할 수 있는 권한입니다.',
                checked: on.contains('apply'),
                onChanged: (v) => _toggle(on, 'apply', v),
              ),
            ],
          ),
        ),
        PField(
          label: '거래 종류',
          description: '2개까지 고를 수 있어요.',
          child: PCheckSelectBoxGroup(
            columns: 3,
            children: [
              for (final (key, label) in const [
                ('out', '지출'),
                ('in', '수입'),
                ('move', '이체'),
              ])
                PCheckSelectBox(
                  control: PCheckSelectBoxControl.none,
                  label: label,
                  checked: kinds.contains(key),
                  onChanged: (v) => _toggle(kinds, key, v),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatesDemo extends StatelessWidget {
  const _StatesDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        PField(
          label: '가변 부여 여부',
          disabled: true,
          child: PRadioSelectBoxGroup<String>(
            value: 'fixed',
            onChanged: (_) {},
            children: const [
              PRadioSelectBox<String>(
                value: 'fixed',
                label: '고정 시간',
                description: '정책에 등록된 부여 시간을 사용합니다.',
              ),
              PRadioSelectBox<String>(
                value: 'flex',
                label: '가변 시간',
                description: '사용자 또는 관리자가 입력한 시간 값으로 부여합니다.',
              ),
            ],
          ),
        ),
        PField(
          label: '종료',
          invalid: true,
          errorMessage: '종료 방식을 골라주세요.',
          child: PRadioSelectBoxGroup<String>(
            value: null,
            onChanged: (_) {},
            children: const [
              PRadioSelectBox<String>(value: 'a', label: '무기한'),
              PRadioSelectBox<String>(value: 'b', label: '횟수 지정'),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorstDemo extends StatefulWidget {
  const _WorstDemo();

  @override
  State<_WorstDemo> createState() => _WorstDemoState();
}

class _WorstDemoState extends State<_WorstDemo> {
  String one = 'a';
  String three = 'a';

  @override
  Widget build(BuildContext context) {
    const longLabel = '해외 결제 수수료가 면제되는 프리미엄 카드의 연회비 환급 대상';
    const longDescription =
        '월 한도 1,234,567,890원까지 합산해서 계산하고, 한도를 넘기면 다음 달로 이월되지 않고 사라져요. 자세한 내용은 약관을 확인해 주세요.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        PField(
          label: '카드',
          child: PRadioSelectBoxGroup<String>(
            value: one,
            onChanged: (next) => setState(() => one = next),
            children: const [
              PRadioSelectBox<String>(
                value: 'a',
                label: longLabel,
                description: longDescription,
              ),
              PRadioSelectBox<String>(value: 'b', label: '짧은 제목'),
            ],
          ),
        ),
        PField(
          label: '3열 좁은 폭',
          child: PRadioSelectBoxGroup<String>(
            columns: 3,
            value: three,
            onChanged: (next) => setState(() => three = next),
            children: const [
              PRadioSelectBox<String>(
                value: 'a',
                control: PRadioSelectBoxControl.none,
                label: '프리미엄 카드의 연회비 환급',
                description: longDescription,
              ),
              PRadioSelectBox<String>(
                value: 'b',
                control: PRadioSelectBoxControl.none,
                label: '짧음',
              ),
              PRadioSelectBox<String>(
                value: 'c',
                control: PRadioSelectBoxControl.none,
                label: '초장문테스트용낱말이한줄보다길어서끊겨야하는경우',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
