import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';
import 'package:groo_damda_app/shared/ds/color_swatch/p_color_swatch.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';

/// 카탈로그(/dev/ds) — 색 10(눌러 고른다 · 고르면 고리 + 체크), 안 고름 · 고름 × 막힘, 지금 색 · 자동(옆 · 위), 새 항목의 첫 색,
/// Field 안(막힘 · 오류). 누름(2px 축소) · 키보드 포커스 링은 직접 눌러 본다.
class ColorSwatchDemo extends StatefulWidget {
  const ColorSwatchDemo({super.key});

  @override
  State<ColorSwatchDemo> createState() => _ColorSwatchDemoState();
}

class _ColorSwatchDemoState extends State<ColorSwatchDemo> {
  PColorSwatchValue? _pick = const PColorSwatchValue.color(PChartColor.red);
  PColorSwatchValue? _edit = const PColorSwatchValue.current();
  PColorSwatchValue? _auto = const PColorSwatchValue.current();

  // 새 카테고리 — 같은 목록이 쓰지 않은 첫 색으로 시작한다(기본 지출 카테고리 여덟이 쓰고 있다)
  static const _used = [
    PChartColor.blue,
    PChartColor.green,
    PChartColor.orange,
    PChartColor.violet,
    PChartColor.pink,
    PChartColor.indigo,
    PChartColor.red,
    PChartColor.yellow,
  ];
  late PColorSwatchValue? _fresh = PColorSwatchValue.color(
    pFirstUnusedColor(_used),
  );

  static String _text(PColorSwatchValue? v) =>
      v == null ? '없음' : (v.isCurrent ? '그대로(#9E9E9E)' : v.color!.name);

  @override
  Widget build(BuildContext context) {
    const gray = Color(0xFF9E9E9E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '색 10 — 라이트 700 · 다크 800-dark, 눌러 고른다(고리 띄움 2 + 체크)',
          children: [
            PColorSwatchGroup(
              semanticLabel: '색상',
              value: _pick,
              onChanged: (v) => setState(() => _pick = v),
            ),
          ],
        ),
        const DemoBlock(
          title: '안 고름 · 막힘 — 막힘은 색 그대로 + 회색 고리',
          children: [
            DemoRow(
              label: 'unselected',
              children: [
                PColorSwatchGroup(
                  semanticLabel: '색상',
                  value: null,
                  onChanged: null,
                ),
              ],
            ),
            DemoRow(
              label: 'disabled · selected',
              children: [
                PColorSwatchGroup(
                  semanticLabel: '색상',
                  value: PColorSwatchValue.color(PChartColor.blue),
                  onChanged: null,
                  disabled: true,
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '지금 색 · 자동 — 321 이상이면 옆으로, 좁은 자리(360 폰 본문 312)는 격자 위 줄 + 가로 선',
          children: [
            DemoRow(
              label: '지금 색 · 옆(342)',
              children: [
                SizedBox(
                  width: 342,
                  child: PColorSwatchGroup(
                    semanticLabel: '색상',
                    value: _edit,
                    currentColor: gray,
                    onChanged: (v) => setState(() => _edit = v),
                  ),
                ),
                Text(
                  '저장 값: ${_text(_edit)}',
                  style: PTypography.t2.copyWith(
                    color: context.colors.fgNeutralSubtle,
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '지금 색 · 위(312)',
              children: [
                SizedBox(
                  width: 312,
                  child: PColorSwatchGroup(
                    semanticLabel: '색상',
                    value: _edit,
                    currentColor: gray,
                    onChanged: (v) => setState(() => _edit = v),
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '자동',
              children: [
                SizedBox(
                  width: 342,
                  child: PColorSwatchGroup(
                    semanticLabel: '색상',
                    value: _auto,
                    autoColor: PChartColor.brown,
                    onChanged: (v) => setState(() => _auto = v),
                  ),
                ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '새 항목 — 같은 목록이 쓰지 않은 첫 색(여덟을 쓰면 갈색)으로 시작한다',
          children: [
            PField(
              label: '색상',
              child: PColorSwatchGroup(
                value: _fresh,
                onChanged: (v) => setState(() => _fresh = v),
              ),
            ),
          ],
        ),
        const DemoBlock(
          title: 'Field — 막힘 · 오류',
          children: [
            PField(
              label: '색상',
              disabled: true,
              child: PColorSwatchGroup(
                value: PColorSwatchValue.color(PChartColor.blue),
                onChanged: null,
              ),
            ),
            PField(
              label: '색상',
              invalid: true,
              errorMessage: '색을 골라주세요.',
              child: PColorSwatchGroup(value: null, onChanged: null),
            ),
          ],
        ),
      ],
    );
  }
}
