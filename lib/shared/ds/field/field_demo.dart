import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/button/p_button.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/field/p_field.dart';
import 'package:porest_desk_app/shared/ds/input/p_input.dart';
import 'package:porest_desk_app/shared/ds/textarea/p_textarea.dart';

/// 카탈로그(/dev/ds) — 라벨 굵기 × 상태(기본 · 오류), 머리(필수 점 또는 "선택" · 보조 액션), 꼬리(설명 · 오류 · 글자 수),
/// 비활성 · 읽기 전용, 여러 줄, 제출 시 검증(누르면 칸마다 오류 · 첫 오류 칸으로 포커스). 예는 field.md 의 것이다.
class FieldDemo extends StatelessWidget {
  const FieldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    void noop() {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title:
              '라벨 굵기 × 상태 — 한 폼(Field 사이 24)에는 필수 점 또는 “선택” 하나만 쓴다. '
              '오류는 설명 자리를 대신한다',
          children: [
            for (final weight in PFieldLabelWeight.values) ...[
              DemoRow(
                label: '${weight.name} · 필수 점 — 기본 · 오류',
                children: [
                  _Form(
                    children: [
                      PField(
                        label: '카테고리 이름',
                        labelWeight: weight,
                        indicator: PFieldIndicator.required,
                        headerAction: PFieldAction(
                          label: '예시 보기',
                          onPressed: noop,
                        ),
                        description: '목록과 통계에 이 이름으로 보여요.',
                        descriptionIcon: LucideIcons.info,
                        maxGraphemeCount: 12,
                        child: const PInput(
                          initialValue: '반려동물',
                          placeholder: '예: 반려동물, 부수입',
                        ),
                      ),
                      PField(
                        label: '아이디',
                        labelWeight: weight,
                        indicator: PFieldIndicator.required,
                        description: '영문 · 숫자 20자까지',
                        maxGraphemeCount: 20,
                        invalid: true,
                        errorMessage: '이미 쓰고 있는 아이디예요.',
                        child: const PInput(initialValue: 'porest'),
                      ),
                    ],
                  ),
                ],
              ),
              DemoRow(
                label: '${weight.name} · 선택 — 기본 · 오류',
                children: [
                  _Form(
                    children: [
                      PField(
                        label: '메모',
                        labelWeight: weight,
                        indicator: PFieldIndicator.optional,
                        description: '거래 목록에서 이름 아래에 보여요.',
                        child: const PInput(placeholder: '예: 점심 회식'),
                      ),
                      PField(
                        label: '휴대폰 번호',
                        labelWeight: weight,
                        indicator: PFieldIndicator.optional,
                        invalid: true,
                        errorMessage: '휴대폰 번호 10~11자리로 입력해주세요.',
                        child: const PInput(
                          initialValue: '010123',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
        const DemoBlock(
          title:
              '글자 수 — 자소 단위로 센다(국기 이모지도 한 글자) · 비면 최대와 같은 색 · 최대에서 멈춘다(직접 써 본다)',
          children: [
            PField(
              label: '카테고리 이름',
              maxGraphemeCount: 5,
              child: PInput(placeholder: '5자까지'),
            ),
          ],
        ),
        const DemoBlock(
          title: '비활성 · 읽기 전용 — Field 에 주면 입력이 받는다',
          children: [
            _Form(
              children: [
                PField(
                  label: '계좌',
                  disabled: true,
                  child: PInput(initialValue: '국민 123-45-6789'),
                ),
                PField(
                  label: '아이디',
                  readOnly: true,
                  child: PInput(initialValue: 'porest'),
                ),
              ],
            ),
          ],
        ),
        const DemoBlock(
          title: '여러 줄 — Textarea 도 같은 둘레',
          children: [
            PField(
              label: '휴가 사유',
              maxGraphemeCount: 1000,
              child: PTextarea(placeholder: '예: 가족 행사 참석'),
            ),
          ],
        ),
        const DemoBlock(
          title:
              '제출 시 검증 — 버튼은 켜 둔다. 누르면 비어 있는 칸마다 오류, 첫 오류 칸으로 포커스(고치면 그 칸의 오류를 걷는다)',
          children: [_SubmitDemo()],
        ),
      ],
    );
  }
}

/// 폼 — Field 사이 24(field.yaml form.gapY).
class _Form extends StatelessWidget {
  const _Form({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x6,
        children: children,
      ),
    );
  }
}

/// 휴가 신청 — 칸이 모두 필수라 점 없이 required 만(2/3 규칙).
class _SubmitDemo extends StatefulWidget {
  const _SubmitDemo();

  @override
  State<_SubmitDemo> createState() => _SubmitDemoState();
}

class _SubmitDemoState extends State<_SubmitDemo> {
  final _title = TextEditingController();
  final _reason = TextEditingController();
  final _titleFocus = FocusNode();
  final _reasonFocus = FocusNode();
  bool _titleError = false;
  bool _reasonError = false;

  @override
  void dispose() {
    _title.dispose();
    _reason.dispose();
    _titleFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _titleError = _title.text.trim().isEmpty;
      _reasonError = _reason.text.trim().isEmpty;
    });
    if (_titleError) {
      _titleFocus.requestFocus();
    } else if (_reasonError) {
      _reasonFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Form(
      children: [
        PField(
          label: '제목',
          required: true,
          invalid: _titleError,
          errorMessage: '제목을 입력해주세요.',
          child: PInput(
            controller: _title,
            focusNode: _titleFocus,
            placeholder: '예: 개인 사유',
            onChanged: (value) {
              if (_titleError && value.trim().isNotEmpty) {
                setState(() => _titleError = false);
              }
            },
          ),
        ),
        PField(
          label: '휴가 사유',
          required: true,
          maxGraphemeCount: 1000,
          invalid: _reasonError,
          errorMessage: '휴가 사유를 입력해주세요.',
          child: PTextarea(
            controller: _reason,
            focusNode: _reasonFocus,
            placeholder: '예: 가족 행사 참석',
            onChanged: (value) {
              if (_reasonError && value.trim().isNotEmpty) {
                setState(() => _reasonError = false);
              }
            },
          ),
        ),
        PButton(
          label: '신청',
          variant: PButtonVariant.brandSolid,
          size: PButtonSize.large,
          onPressed: _submit,
        ),
      ],
    );
  }
}
