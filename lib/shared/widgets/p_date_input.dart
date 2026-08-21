import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_picker_sheet.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// front `<InputDatePicker>` / `<InputTimePicker>` 등가.
///
/// **입력칸은 입력칸대로 쓴다.** 직접 타이핑해서 고칠 수 있고, 접미 아이콘을
/// 누르면 달력·시계 시트가 열린다(웹과 같은 구조). 예전에는 필드 전체가
/// 피커 트리거라 키보드로는 못 고쳤다.
///
/// 타이핑 중에는 값이 계속 반쪽짜리다("2026-0"). 그래서 **완성된 문자열이
/// 파싱되고 범위 안일 때만** onChanged 를 올린다 — 중간 상태로 호출부를
/// 흔들지 않는다.

/// 접미 아이콘 — suffixIcon 은 탭을 받으므로 여기서 피커를 연다.
class _PickerSuffix extends StatelessWidget {
  const _PickerSuffix({
    required this.icon,
    required this.onTap,
    required this.enabled,
    this.onClear,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onClear != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClear,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: PSpace.x4),
              child: Icon(LucideIcons.x, size: 14, color: t.fgTertiary),
            ),
          ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.only(
                left: PSpace.x4, right: PSpace.x12),
            child: Icon(icon,
                size: 16, color: enabled ? t.fgSecondary : t.fgTertiary),
          ),
        ),
      ],
    );
  }
}

/// 날짜 입력 — 텍스트는 `YYYY-MM-DD`, 아이콘은 달력 시트.
class PDateInput extends StatefulWidget {
  const PDateInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.placeholder,
    this.allowClear = false,
    this.enabled = true,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? placeholder;
  final bool allowClear;

  /// false 면 값만 보여 준다 — 시스템이 만들어 못 고치는 값 등. PTextInput.enabled 와 같은 규약.
  final bool enabled;

  @override
  State<PDateInput> createState() => _PDateInputState();
}

class _PDateInputState extends State<PDateInput> {
  late final TextEditingController _ctrl =
      TextEditingController(text: _fmt(widget.value));

  static String _fmt(DateTime? d) => d == null
      ? ''
      : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  DateTime get _first => widget.firstDate ?? DateTime(2020);
  DateTime get _last => widget.lastDate ?? DateTime(2030, 12, 31);

  @override
  void didUpdateWidget(PDateInput old) {
    super.didUpdateWidget(old);
    // 타이핑 중인 문자열을 밖에서 덮어쓰지 않는다 — 값이 실제로 달라졌을 때만 맞춘다.
    if (widget.value != old.value && _parse(_ctrl.text) != widget.value) {
      _ctrl.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 완성된 `YYYY-MM-DD` 만 받는다. DateTime.tryParse 는 "2026-3" 같은 것도
  /// 통과시키므로 길이·자릿수를 먼저 본다.
  DateTime? _parse(String s) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s.trim());
    if (m == null) return null;
    final y = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    final parsed = DateTime(y, mo, d);
    // 2월 31일처럼 넘친 날짜는 DateTime 이 다음 달로 굴려 버린다 — 되돌아온 값으로 확인.
    if (parsed.month != mo || parsed.day != d) return null;
    if (parsed.isBefore(_first) || parsed.isAfter(_last)) return null;
    return parsed;
  }

  void _onTyped(String s) {
    if (s.isEmpty && widget.allowClear) {
      widget.onChanged(null);
      return;
    }
    final d = _parse(s);
    if (d != null) widget.onChanged(d);
  }

  Future<void> _openSheet() async {
    // 시트가 올라올 때 키보드가 남아 있으면 시트를 밀어 올린다.
    FocusScope.of(context).unfocus();
    final p = await showPDatePicker(
      context,
      initial: widget.value ?? DateTime.now(),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    if (p == null || !mounted) return;
    _ctrl.text = _fmt(p);
    widget.onChanged(p);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PTextInput(
      controller: _ctrl,
      enabled: widget.enabled,
      placeholder: widget.placeholder ?? l.pickDate,
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
        LengthLimitingTextInputFormatter(10),
      ],
      onChanged: _onTyped,
      suffix: _PickerSuffix(
        icon: LucideIcons.calendar,
        enabled: widget.enabled,
        onTap: _openSheet,
        onClear: widget.allowClear && widget.enabled && _ctrl.text.isNotEmpty
            ? () {
                _ctrl.clear();
                widget.onChanged(null);
                setState(() {});
              }
            : null,
      ),
    );
  }
}

/// 시각 입력 — 텍스트는 `HH:mm`(24시간), 아이콘은 시계 휠 시트.
class PTimeInput extends StatefulWidget {
  const PTimeInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.enabled = true,
  });

  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final String? placeholder;

  /// false 면 값만 보여 준다 — [PDateInput.enabled] 와 같은 규약.
  final bool enabled;

  @override
  State<PTimeInput> createState() => _PTimeInputState();
}

class _PTimeInputState extends State<PTimeInput> {
  late final TextEditingController _ctrl =
      TextEditingController(text: _fmt(widget.value));

  static String _fmt(TimeOfDay? t) => t == null
      ? ''
      : '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';

  @override
  void didUpdateWidget(PTimeInput old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && _parse(_ctrl.text) != widget.value) {
      _ctrl.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  TimeOfDay? _parse(String s) {
    final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(s.trim());
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return null;
    return TimeOfDay(hour: h, minute: min);
  }

  void _onTyped(String s) {
    final t = _parse(s);
    if (t != null) widget.onChanged(t);
  }

  Future<void> _openSheet() async {
    FocusScope.of(context).unfocus();
    final p = await showPTimePicker(
      context,
      initial: widget.value ?? TimeOfDay.now(),
    );
    if (p == null || !mounted) return;
    _ctrl.text = _fmt(p);
    widget.onChanged(p);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PTextInput(
      controller: _ctrl,
      enabled: widget.enabled,
      placeholder: widget.placeholder ?? l.pickTime,
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
        LengthLimitingTextInputFormatter(5),
      ],
      onChanged: _onTyped,
      suffix: _PickerSuffix(
        icon: LucideIcons.clock,
        enabled: widget.enabled,
        onTap: _openSheet,
      ),
    );
  }
}
