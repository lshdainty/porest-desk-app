import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input_button/p_input_button.dart';

/// 고르기 시트의 검색 자리 높이 — 시트가 낼 수 있는 높이(화면 90%, 키보드가 올라오면 그 위까지)에서 머리를 뺀 만큼.
///
/// 검색칸이 위에 붙고 결과만 스크롤하려면 본문 높이가 정해져 있어야 한다(searchable-list.md). 머리 높이는 위 24 + 제목 한 줄(글자
/// 배율을 따른다) + 아래 16 이고, 안전 영역은 시트 바닥이 더한다. [fraction] 은 내용이 적은 시트(종목 추가)가 낮게 설 때.
double pickerBodyHeight(BuildContext context, {double fraction = 1}) {
  final media = MediaQuery.of(context);
  final screen = media.size.height;
  final avail = math.min(
    screen * kBottomSheetMaxHeightFactor,
    screen - media.viewInsets.bottom,
  );
  final safeBottom = math.max(
    0.0,
    media.viewPadding.bottom - media.viewInsets.bottom,
  );
  final header =
      PSpacing.x6 + media.textScaler.scale(30) + PSpacing.x4 + safeBottom;
  return math.max(120, (avail - header) * fraction);
}

/// 고르는 칸 — Field 라벨 + Input Button. 누르면 [onOpen] 이 고르기 시트를 열고, 열려 있는 동안 `expanded` 를 알린다.
///
/// 값은 고른 이름 그대로이고 길면 한 줄 말줄임(input-button.md). 뒤에 아래 화살표(`chevron-down`)를 단다.
class PickerField extends StatefulWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.value,
    required this.onOpen,
    this.indicator = PFieldIndicator.none,
    this.description,
    this.invalid = false,
    this.errorMessage,
    this.disabled,
    this.focusNode,
  });

  final String label;
  final String placeholder;
  final String? value;

  /// 시트를 열고 닫힐 때까지 기다린다.
  final Future<void> Function() onOpen;
  final PFieldIndicator indicator;
  final String? description;
  final bool invalid;
  final String? errorMessage;
  final bool? disabled;
  final FocusNode? focusNode;

  @override
  State<PickerField> createState() => _PickerFieldState();
}

class _PickerFieldState extends State<PickerField> {
  bool _open = false;

  Future<void> _show() async {
    setState(() => _open = true);
    try {
      await widget.onOpen();
    } finally {
      if (mounted) setState(() => _open = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PField(
      label: widget.label,
      indicator: widget.indicator,
      description: widget.description,
      invalid: widget.invalid,
      errorMessage: widget.errorMessage,
      child: PInputButton(
        placeholder: widget.placeholder,
        value: widget.value,
        suffixIcon: LucideIcons.chevronDown,
        expanded: _open,
        disabled: widget.disabled,
        focusNode: widget.focusNode,
        onPressed: _show,
      ),
    );
  }
}
