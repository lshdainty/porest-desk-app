import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_names.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// 전체 Lucide 아이콘(1,100+)에서 하나를 검색·선택하는 필드 트리거 —
/// porest-design `icon-picker.md` / 웹 `shared/ui/icon-picker.tsx` 미러.
///
/// 웹은 popover, 모바일은 검색 키보드가 올라오므로 표준 시트(showPSheet)로 연다.
/// 웹과 달리 매칭 limit·점진 로드가 없는 이유: 아이콘은 내장 폰트 글리프라 로딩이
/// 없고, GridView.builder 가 보이는 셀만 빌드한다(웹 STEP 증분은 DOM 성능 사유).
class PIconPicker extends StatelessWidget {
  const PIconPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// 현재 선택된 lucide kebab 이름. 빈 값이면 미선택(placeholder).
  final String value;

  /// 선택 콜백. '없음' 선택 시 빈 문자열 — 기본 아이콘 대체는 호출처 책임(웹 정합).
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // trigger 40×40 — input-md 높이 정합(icon-picker.md md size).
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: PRadius.brMd,
        onTap: () => _openSheet(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: t.bgSurface,
            borderRadius: PRadius.brMd,
            border: Border.all(color: t.borderDefault),
            boxShadow: t.shadowSm,
          ),
          alignment: Alignment.center,
          child: value.isEmpty
              ? Text('—',
                  style: PTypo.bodySm.copyWith(color: t.fgSecondary))
              : Icon(lucideByName(value), size: 18, color: t.fgPrimary),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    final l = AppLocalizations.of(context);
    showPSheet<void>(
      context,
      title: l.iconPickerTitle,
      contentBuilder: (ctx, scrollCtrl) => _IconPickerSheet(
        value: value,
        scrollController: scrollCtrl,
        onSelect: (name) {
          // showPSheet 는 root navigator 에 뜬다 — caller context pop 금지.
          Navigator.of(ctx, rootNavigator: true).pop();
          onChanged(name);
        },
      ),
    );
  }
}

class _IconPickerSheet extends StatefulWidget {
  const _IconPickerSheet({
    required this.value,
    required this.scrollController,
    required this.onSelect,
  });
  final String value;
  final ScrollController scrollController;
  final ValueChanged<String> onSelect;

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _matched {
    final query = _searchCtrl.text.toLowerCase().trim();
    if (query.isEmpty) return kLucideIconNames;
    return kLucideIconNames.where((n) => n.contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final matched = _matched;
    final searching = _searchCtrl.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PTextInput(
            controller: _searchCtrl,
            autofocus: true,
            placeholder: l.iconPickerSearchHint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: PSpace.x8),
          // '없음' 옵션 — 웹 IconPicker 정합(선택 해제).
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: PRadius.brSm,
              onTap: () => widget.onSelect(''),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: PSpace.x8, vertical: PSpace.x4),
                decoration: BoxDecoration(
                  color: widget.value.isEmpty ? t.bgMuted : Colors.transparent,
                  borderRadius: PRadius.brSm,
                ),
                child: Text(l.iconPickerNone,
                    style: PTypo.caption.copyWith(color: t.fgSecondary)),
              ),
            ),
          ),
          const SizedBox(height: PSpace.x8),
          const PDivider(),
          Expanded(
            child: matched.isEmpty
                ? Center(
                    child: Text(l.iconPickerNoResults,
                        style: PTypo.caption.copyWith(color: t.fgSecondary)),
                  )
                : GridView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
                    // 8-col grid — icon-picker.md 정합. 셀은 폭 나눔 정사각.
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: PSpace.x4,
                      crossAxisSpacing: PSpace.x4,
                    ),
                    itemCount: matched.length,
                    itemBuilder: (_, i) {
                      final name = matched[i];
                      final active = name == widget.value;
                      return InkWell(
                        borderRadius: PRadius.brSm,
                        onTap: () => widget.onSelect(name),
                        child: Container(
                          decoration: BoxDecoration(
                            color: active ? t.bgBrandSubtle : null,
                            borderRadius: PRadius.brSm,
                            border: active
                                ? Border.all(color: t.borderBrand, width: 1.5)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Icon(lucideByName(name),
                              size: 16,
                              color: active ? t.fgBrand : t.fgSecondary),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
            child: Text(
              searching
                  ? l.iconPickerResultCount(matched.length)
                  : l.iconPickerTotalHint(kLucideIconNames.length),
              textAlign: TextAlign.center,
              style: PTypo.micro.copyWith(color: t.fgTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
