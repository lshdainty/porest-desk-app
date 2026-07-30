import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';

/// 색 팔레트 picker — 차트 10색(공유 `kChartBaseHexes`)만 노출.
const kPDefaultPalette = kChartBaseHexes;

class PColorPicker extends StatelessWidget {
  // web `ColorSwatchGroup`(spec color-swatch.md) 정합:
  // 5열 grid + aspect-square 타일 / soft 틴트 bg + fg 색 체크(14) /
  // 선택 시 fg 색(currentColor) 2px border / radius-tile(=lg 12).
  // (구 28px solid 채움 + fgPrimary border 타일은 spec 일탈이라 폐기)
  const PColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.palette = kPDefaultPalette,
    this.columns = 5,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final List<String> palette;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // 미지정 시 MediaQuery(safe-area) 패딩이 자동 적용돼 아래 간격이 벌어짐
      padding: EdgeInsets.zero,
      mainAxisSpacing: PSpace.x8,
      crossAxisSpacing: PSpace.x8,
      children: [
        for (final c in palette)
          Builder(builder: (context) {
            final fg = resolveChartColor(context, c, fallback: t.fgBrand);
            final isSelected = c == selected;
            return GestureDetector(
              onTap: () => onChanged(c),
              child: Container(
                decoration: BoxDecoration(
                  color: softBg(context, fg),
                  borderRadius: PRadius.brLg,
                  border: Border.all(
                    color: isSelected ? fg : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Icon(LucideIcons.check, size: 14, color: fg))
                    : null,
              ),
            );
          }),
      ],
    );
  }
}

// 종전 이 파일의 고정 24종 PIconPicker(kPDefaultIcons)는 사용처가 없는 dead code 라
// 제거함 — 전체 아이콘 검색 픽커는 p_icon_picker.dart 의 PIconPicker 를 사용한다.
