import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';

// 스펙의 groo 예(select.md — 결제 수단 · 통화 · 반복 요일)
const List<PSelectGroup<String>> _pay = [
  PSelectGroup(
    items: [
      PSelectItem(
        value: 'none',
        label: '결제 수단 없음',
        prefixIcon: LucideIcons.circleSlash,
      ),
    ],
  ),
  PSelectGroup(
    label: '카드',
    items: [
      PSelectItem(
        value: 'hyundai',
        label: '현대카드 M',
        prefixIcon: LucideIcons.creditCard,
      ),
      PSelectItem(
        value: 'shinhan',
        label: '신한카드 Deep',
        prefixIcon: LucideIcons.creditCard,
      ),
    ],
  ),
  PSelectGroup(
    label: '계좌 · 현금',
    items: [
      PSelectItem(
        value: 'kb',
        label: '국민 주계좌',
        description: '123-45-6789',
        prefixIcon: LucideIcons.landmark,
      ),
      PSelectItem(value: 'cash', label: '현금', prefixIcon: LucideIcons.banknote),
      PSelectItem(
        value: 'locked',
        label: '해지한 계좌',
        description: '고를 수 없어요',
        prefixIcon: LucideIcons.landmark,
        enabled: false,
      ),
    ],
  ),
];

const List<PSelectGroup<String>> _currency = [
  PSelectGroup(
    items: [
      PSelectItem(value: 'KRW', label: '원', description: 'KRW'),
      PSelectItem(value: 'USD', label: '미국 달러', description: 'USD'),
      PSelectItem(value: 'JPY', label: '일본 엔', description: 'JPY'),
      PSelectItem(value: 'EUR', label: '유로', description: 'EUR'),
      PSelectItem(value: 'CNY', label: '중국 위안', description: 'CNY'),
    ],
  ),
];

const List<PSelectGroup<String>> _days = [
  PSelectGroup(
    items: [
      PSelectItem(value: 'mon', label: '월요일'),
      PSelectItem(value: 'tue', label: '화요일'),
      PSelectItem(value: 'wed', label: '수요일'),
      PSelectItem(value: 'thu', label: '목요일'),
      PSelectItem(value: 'fri', label: '금요일'),
      PSelectItem(value: 'sat', label: '토요일'),
      PSelectItem(value: 'sun', label: '일요일'),
    ],
  ),
];

// 가장 나쁜 값 — 긴 선택지 이름 · 선택지 20개
final List<PSelectGroup<int>> _twenty = [
  PSelectGroup(
    items: [
      for (var i = 1; i <= 20; i++)
        PSelectItem(
          value: i,
          label: i == 3 ? '해외 결제 수수료가 면제되는 프리미엄 카드의 연회비 환급 대상 항목' : '카테고리 $i',
          description: i == 5 ? '월 한도 1,234,567,890원까지 합산해서 계산해요' : null,
        ),
    ],
  ),
];

String _more(String first, int others) => '$first 외 $others개';

/// 카탈로그(/dev/ds) — 칸의 상태(기본 · 오류 · 비활성 · 읽기 전용 — 누름은 직접 눌러 본다), 하나 고르기 · 묶음 · 앞 아이콘 ·
/// "없음", 여럿 고르기(첫 값 외 N개), 가장 나쁜 값(긴 선택지 이름 · 선택지 20개 · 좁은 폭). 눌러서 칸 아래 목록을 열어 본다
/// (아래가 모자라면 위로 열린다 — 화면 맨 아래 견본으로 본다).
class SelectDemo extends StatelessWidget {
  const SelectDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '칸 상태 — 기본(고르기 전 · 고른 뒤) · 오류 · 비활성 · 읽기 전용(누름은 직접 눌러 본다)',
          children: [
            _Live(
              label: '통화',
              placeholder: '통화 선택',
              groups: _currency,
              initial: null,
            ),
            _Live(
              label: '통화',
              placeholder: '통화 선택',
              groups: _currency,
              initial: 'USD',
            ),
            _Live(
              label: '휴가 정책',
              placeholder: '휴가 정책 선택',
              groups: _currency,
              initial: null,
              invalid: true,
              error: '휴가 정책을 골라주세요.',
            ),
            _Live(
              label: '통화',
              placeholder: '통화 선택',
              groups: _currency,
              initial: 'KRW',
              disabled: true,
            ),
            _Live(
              label: '부서',
              placeholder: '부서 선택',
              groups: _currency,
              initial: 'KRW',
              readOnly: true,
            ),
          ],
        ),
        DemoBlock(
          title:
              '하나 고르기 — 묶음 · 앞 아이콘(고르면 칸의 아이콘이 바뀐다) · "{칸 이름} 없음" · 설명 · 막힌 선택지',
          children: [
            _Live(
              label: '결제 수단',
              placeholder: '결제 수단 선택',
              groups: _pay,
              initial: 'kb',
              prefixIcon: LucideIcons.wallet,
            ),
          ],
        ),
        DemoBlock(
          title: '여럿 고르기 — 열린 채 켜고 끈다 · 고른 순서대로 이어 쓰고 칸 폭을 넘으면 "첫 값 외 N개"',
          children: [
            const _LiveMulti(initial: ['mon', 'wed', 'fri']),
            const _LiveMulti(
              initial: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
            ),
          ],
        ),
        DemoBlock(
          title:
              '가장 나쁜 값 — 긴 선택지 이름(목록은 줄바꿈 · 칸은 한 줄 말줄임) · 선택지 20개(목록 안에서 스크롤)',
          children: [
            _LiveNumber(),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 160,
                child: _Live(
                  label: '통화',
                  placeholder: '통화 선택',
                  groups: _pay,
                  initial: 'kb',
                ),
              ),
            ),
          ],
        ),
        // 화면 맨 아래 — 열면 위로 뒤집히는 자리
        DemoBlock(
          title: '아래가 모자라면 위로 열린다',
          children: [
            _Live(
              label: '통화',
              placeholder: '통화 선택',
              groups: _currency,
              initial: null,
            ),
          ],
        ),
      ],
    );
  }
}

class _Live extends StatefulWidget {
  const _Live({
    required this.label,
    required this.placeholder,
    required this.groups,
    required this.initial,
    this.prefixIcon,
    this.invalid = false,
    this.error,
    this.disabled = false,
    this.readOnly = false,
  });

  final String label;
  final String placeholder;
  final List<PSelectGroup<String>> groups;
  final String? initial;
  final IconData? prefixIcon;
  final bool invalid;
  final String? error;
  final bool disabled;
  final bool readOnly;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late String? value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PField(
        label: widget.label,
        invalid: widget.invalid,
        errorMessage: widget.error,
        disabled: widget.disabled,
        readOnly: widget.readOnly,
        child: PSelect<String>(
          groups: widget.groups,
          value: value,
          placeholder: widget.placeholder,
          prefixIcon: widget.prefixIcon,
          onChanged: (next) => setState(() => value = next),
        ),
      ),
    );
  }
}

class _LiveMulti extends StatefulWidget {
  const _LiveMulti({required this.initial});

  final List<String> initial;

  @override
  State<_LiveMulti> createState() => _LiveMultiState();
}

class _LiveMultiState extends State<_LiveMulti> {
  late List<String> values = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PField(
        label: '반복 요일',
        description: '고른 요일마다 거래를 만들어요.',
        child: PSelect<String>.multiple(
          groups: _days,
          values: values,
          placeholder: '요일 선택',
          overflowLabel: _more,
          onChanged: (next) => setState(() => values = next),
        ),
      ),
    );
  }
}

class _LiveNumber extends StatefulWidget {
  @override
  State<_LiveNumber> createState() => _LiveNumberState();
}

class _LiveNumberState extends State<_LiveNumber> {
  int? value = 3;

  @override
  Widget build(BuildContext context) {
    return PField(
      label: '카테고리',
      child: PSelect<int>(
        groups: _twenty,
        value: value,
        placeholder: '카테고리 선택',
        onChanged: (next) => setState(() => value = next),
      ),
    );
  }
}
