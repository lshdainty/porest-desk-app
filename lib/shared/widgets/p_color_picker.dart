import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../core/format/chart_palette.dart';

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

/// 카테고리/이벤트 라벨용 lucide 아이콘 picker.
const kPDefaultIcons = <(String name, IconData icon)>[
  ('tag', LucideIcons.tag),
  ('star', LucideIcons.star),
  ('heart', LucideIcons.heart),
  ('home', LucideIcons.home),
  ('briefcase', LucideIcons.briefcase),
  ('coffee', LucideIcons.coffee),
  ('utensils', LucideIcons.utensils),
  ('shoppingCart', LucideIcons.shoppingCart),
  ('car', LucideIcons.car),
  ('plane', LucideIcons.plane),
  ('book', LucideIcons.book),
  ('music', LucideIcons.music),
  ('gift', LucideIcons.gift),
  ('award', LucideIcons.award),
  ('zap', LucideIcons.zap),
  ('flame', LucideIcons.flame),
  ('sun', LucideIcons.sun),
  ('moon', LucideIcons.moon),
  ('cloud', LucideIcons.cloud),
  ('umbrella', LucideIcons.umbrella),
  ('mapPin', LucideIcons.mapPin),
  ('phone', LucideIcons.phone),
  ('mail', LucideIcons.mail),
  ('users', LucideIcons.users),
];

class PIconPicker extends StatelessWidget {
  const PIconPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.size = 36,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (name, icon) in kPDefaultIcons)
          GestureDetector(
            onTap: () => onChanged(name),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: name == selected ? t.bgBrandSubtle : t.bgMuted,
                borderRadius: PRadius.brMd,
                border: Border.all(
                  color: name == selected ? t.borderBrand : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: name == selected ? t.fgBrand : t.fgSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
