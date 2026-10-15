import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/shared/ds/catalog/demo_kit.dart';
import 'package:porest_desk_app/shared/ds/field/p_field.dart';
import 'package:porest_desk_app/shared/ds/icon_picker/category_icons.dart';
import 'package:porest_desk_app/shared/ds/icon_picker/p_icon_picker.dart';

/// 카탈로그(/dev/ds) — 트리거(세트 안 · 빈 값 · 세트 밖 · 옛 이름 home · 막힘 · 오류), 칸(안 고름 · 고름), 시트 안(묶음 격자 ·
/// 찾는 중 · 0건). 트리거를 누르면 시트가 열리고 고르면 바로 닫힌다. 호버 · 누름 · 키보드 포커스는 직접 해 본다.
class IconPickerDemo extends StatefulWidget {
  const IconPickerDemo({super.key});

  @override
  State<IconPickerDemo> createState() => _IconPickerDemoState();
}

class _IconPickerDemoState extends State<IconPickerDemo> {
  String? _live = 'coffee';
  String? _selected = 'utensils';

  @override
  Widget build(BuildContext context) {
    final names = {for (final i in kCategoryIcons) i.id: i.name};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '트리거 — 눌러서 연다. 고르면 바로 닫힌다("완료" 없음)',
          children: [
            PField(
              label: '아이콘',
              child: PIconPicker(
                value: _live,
                onChanged: (id) => setState(() => _live = id),
              ),
            ),
            Text(
              '저장 값: ${_live ?? '없음'} (${names[_live] ?? '세트 밖'})',
              style: PTypography.t2.copyWith(
                color: context.colors.fgNeutralSubtle,
              ),
            ),
          ],
        ),
        DemoBlock(
          title:
              '트리거의 값 — 세트 안 · 빈 값(태그) · 세트 밖(지금 아이콘) · 옛 이름 home(집) · 막힘 · 오류',
          children: [
            PField(
              label: '아이콘',
              child: PIconPicker(value: 'utensils', onChanged: (_) {}),
            ),
            PField(
              label: '아이콘',
              child: PIconPicker(value: null, onChanged: (_) {}),
            ),
            PField(
              label: '아이콘',
              child: PIconPicker(value: 'rocket', onChanged: (_) {}),
            ),
            PField(
              label: '아이콘',
              child: PIconPicker(value: 'home', onChanged: (_) {}),
            ),
            PField(
              label: '아이콘',
              disabled: true,
              child: PIconPicker(value: 'coffee', onChanged: (_) {}),
            ),
            PField(
              label: '아이콘',
              invalid: true,
              errorMessage: '아이콘을 골라주세요.',
              child: PIconPicker(value: null, onChanged: (_) {}),
            ),
          ],
        ),
        DemoBlock(
          title: '칸 — 48 · 모서리 12 · 아이콘 24. 고른 칸은 안쪽 2px + 선 2.5',
          children: [
            DemoRow(
              label: 'unselected · selected',
              children: [
                for (final id in const ['coffee', 'bus', 'house'])
                  PIconPickerCell(
                    icon: findCategoryIcon(id)!,
                    selected: id == _selected,
                    onSelect: (v) => setState(() => _selected = v),
                  ),
              ],
            ),
          ],
        ),
        const DemoBlock(
          title: '시트 안 — 묶음 격자(6열 · 끝 흐림) · 찾는 중 · 0건',
          children: [
            _PanelSurface(
              child: PIconPickerPanel(
                selectedId: 'coffee',
                onSelect: _ignore,
                autofocus: false,
              ),
            ),
            _PanelSurface(
              child: PIconPickerPanel(
                selectedId: 'coffee',
                onSelect: _ignore,
                autofocus: false,
                initialQuery: '커피',
              ),
            ),
            _PanelSurface(
              child: PIconPickerPanel(
                selectedId: 'coffee',
                onSelect: _ignore,
                autofocus: false,
                initialQuery: '유니콘',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

void _ignore(String _) {}

/// 시트 바탕에 놓은 견본 — 폰 시트 본문 높이쯤.
class _PanelSurface extends StatelessWidget {
  const _PanelSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bgLayerFloating,
        borderRadius: BorderRadius.circular(PRounded.r4),
        border: Border.all(color: c.strokeNeutralWeak),
      ),
      child: SizedBox(height: 420, child: child),
    );
  }
}
