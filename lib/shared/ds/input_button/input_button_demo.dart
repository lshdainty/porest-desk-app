import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

const _categories = ['식비', '교통', '카페 · 간식', '쇼핑', '문화 · 여가'];

void _noop() {}

/// 카탈로그(/dev/ds) — 상태(기본 · 오류 · 비활성 · 읽기 전용 — 누름 · 포커스는 직접 눌러 본다), 빈 칸 · 붙이개 · 지우기,
/// Field 안, 직접 눌러 여는 시트. 앱은 늘 large(52)다. 예는 input-button.md 의 것이다(웹 `input-button.demo.tsx` 와 같은 구성).
class InputButtonDemo extends StatelessWidget {
  const InputButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const date = '2026년 10월 1일 (목)';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title:
              'large 52 × 상태 — 값이 있는 칸. 누름 · 포커스는 직접 눌러 본다(포커스 링은 키보드 포커스에만)',
          children: [
            DemoRow(
              label: 'enabled',
              children: [
                PInputButton(
                  semanticLabel: '날짜',
                  placeholder: '날짜 선택',
                  value: date,
                  suffixIcon: LucideIcons.calendarDays,
                  onPressed: _noop,
                ),
              ],
            ),
            DemoRow(
              label: 'invalid — 눌러도 빨간 2px 그대로',
              children: [
                PInputButton(
                  semanticLabel: '날짜',
                  placeholder: '날짜 선택',
                  value: date,
                  suffixIcon: LucideIcons.calendarDays,
                  invalid: true,
                  onPressed: _noop,
                ),
              ],
            ),
            const DemoRow(
              label: 'disabled — 흐리게 하지 않는다',
              children: [
                PInputButton(
                  semanticLabel: '날짜',
                  placeholder: '날짜 선택',
                  value: date,
                  suffixIcon: LucideIcons.calendarDays,
                  disabled: true,
                ),
              ],
            ),
            const DemoRow(
              label: 'readonly — 값은 진한 글자 그대로, 열리지 않는다',
              children: [
                PInputButton(
                  semanticLabel: '날짜',
                  placeholder: '날짜 선택',
                  value: date,
                  suffixIcon: LucideIcons.calendarDays,
                  readOnly: true,
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title:
              '빈 칸(placeholder) · 앞 아이콘 · 앞 · 뒤 글자 · 지우기 — 지우기는 값이 있을 때만(막히거나 읽기 전용이면 없다)',
          children: [
            DemoRow(
              label: '빈 칸 — placeholder',
              children: [
                PInputButton(
                  semanticLabel: '날짜',
                  placeholder: '날짜 선택',
                  suffixIcon: LucideIcons.calendarDays,
                  onPressed: _noop,
                ),
              ],
            ),
            const DemoRow(
              label: 'disabled · 빈 칸',
              children: [
                PInputButton(
                  semanticLabel: '날짜',
                  placeholder: '날짜 선택',
                  suffixIcon: LucideIcons.calendarDays,
                  disabled: true,
                ),
              ],
            ),
            DemoRow(
              label: '앞 아이콘 · 값',
              children: [
                PInputButton(
                  semanticLabel: '카테고리',
                  value: '식비 · 점심',
                  prefixIcon: LucideIcons.utensils,
                  suffixIcon: LucideIcons.chevronDown,
                  onPressed: _noop,
                ),
              ],
            ),
            DemoRow(
              label: '앞 · 뒤 글자',
              children: [
                PInputButton(
                  semanticLabel: '나이',
                  prefixText: '만',
                  value: '29',
                  suffixText: '세',
                  suffixIcon: LucideIcons.chevronDown,
                  onPressed: _noop,
                ),
              ],
            ),
            DemoRow(
              label: '지우기',
              children: [
                PInputButton(
                  semanticLabel: '참조자',
                  value: '김하나',
                  suffixIcon: LucideIcons.chevronDown,
                  onPressed: _noop,
                  onClear: _noop,
                ),
              ],
            ),
            DemoRow(
              label: '긴 값 — 말줄임',
              children: [
                PInputButton(
                  semanticLabel: '참조자',
                  value: '가나다라마바사아자차카타파하 가나다라마바사아자차카타파하 가나다라마바사아자차카타파하',
                  suffixIcon: LucideIcons.chevronDown,
                  onPressed: _noop,
                  onClear: _noop,
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: 'Field 안 — 라벨 · 설명 · 오류 · 읽기 전용. 라벨을 눌러도 열리지 않는다(포커스만)',
          children: [
            PField(
              label: '날짜',
              description: '휴가를 시작하는 날이에요.',
              child: PInputButton(
                placeholder: '날짜 선택',
                suffixIcon: LucideIcons.calendarDays,
                onPressed: _noop,
              ),
            ),
            PField(
              label: '날짜',
              invalid: true,
              errorMessage: '날짜를 골라주세요.',
              child: PInputButton(
                placeholder: '날짜 선택',
                suffixIcon: LucideIcons.calendarDays,
                onPressed: _noop,
              ),
            ),
            const PField(
              label: '입사일',
              readOnly: true,
              child: PInputButton(
                value: '2024년 3월 4일 (월)',
                suffixIcon: LucideIcons.calendarDays,
              ),
            ),
            const PField(
              label: '날짜',
              disabled: true,
              child: PInputButton(
                value: date,
                suffixIcon: LucideIcons.calendarDays,
              ),
            ),
          ],
        ),
        const DemoBlock(
          title:
              '직접 눌러 본다 — 시트가 열린다. 목록은 누르면 바로 고르고 닫힌다 · 시각처럼 확정이 필요한 것은 고르는 동안 칸이 안 바뀌고 "완료" 로 넣는다',
          children: [_Pick(confirm: false), _Pick(confirm: true)],
        ),
      ],
    );
  }
}

/// 시트를 여는 칸 — 쓰는 쪽이 값을 들고 시트를 연다(Input Button 은 무엇을 여는지 모른다).
class _Pick extends StatefulWidget {
  const _Pick({required this.confirm});

  /// true 면 "완료" 로 넣는다(고르는 동안 draft 만 바뀐다), false 면 누르면 바로 고르고 닫는다.
  final bool confirm;

  @override
  State<_Pick> createState() => _PickState();
}

class _PickState extends State<_Pick> {
  String? _value;
  bool _open = false;

  String get _label => widget.confirm ? '시각' : '카테고리';

  Future<void> _openSheet() async {
    setState(() => _open = true);
    final result = await PBottomSheet.show<String>(
      context,
      builder: (_) =>
          _PickSheet(label: _label, confirm: widget.confirm, initial: _value),
    );
    if (!mounted) return;
    setState(() {
      _open = false;
      // 바깥 · 끌기로 닫으면 null — 칸의 값은 그대로다
      if (result != null) _value = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PField(
      label: _label,
      indicator: widget.confirm
          ? PFieldIndicator.none
          : PFieldIndicator.optional,
      child: PInputButton(
        placeholder: '$_label 선택',
        value: _value,
        prefixIcon: !widget.confirm && _value != null
            ? LucideIcons.utensils
            : null,
        suffixIcon: widget.confirm
            ? LucideIcons.clock
            : LucideIcons.chevronDown,
        expanded: _open,
        onPressed: _openSheet,
        onClear: widget.confirm ? null : () => setState(() => _value = null),
      ),
    );
  }
}

class _PickSheet extends StatefulWidget {
  const _PickSheet({
    required this.label,
    required this.confirm,
    required this.initial,
  });

  final String label;
  final bool confirm;
  final String? initial;

  @override
  State<_PickSheet> createState() => _PickSheetState();
}

class _PickSheetState extends State<_PickSheet> {
  late String? _draft = widget.initial; // 열 때 칸의 값에서 시작한다

  @override
  Widget build(BuildContext context) {
    return PBottomSheetContent(
      title: '${widget.label} 선택',
      closeLabel: '닫기',
      flushBody: true,
      body: PListRadioGroup<String>(
        semanticLabel: widget.label,
        value: _draft,
        onChanged: (v) {
          if (widget.confirm) {
            setState(() => _draft = v);
          } else {
            PBottomSheet.of(context).close(v);
          }
        },
        children: [
          for (final c in _categories) PListRadioItem(value: c, title: c),
        ],
      ),
      footer: [
        if (widget.confirm)
          PButton(
            label: '완료',
            size: PButtonSize.large,
            variant: PButtonVariant.neutralSolid,
            onPressed: _draft == null
                ? null
                : () => PBottomSheet.of(context).close(_draft),
          ),
      ],
    );
  }
}
