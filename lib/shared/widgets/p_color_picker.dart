import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/tokens.dart';
import '../../core/format/color_parse.dart';

/// 색 팔레트 picker — 8색 기본 팔레트.
const kPDefaultPalette = <String>[
  '#16a34a', '#2563eb', '#f59e0b', '#ef4444',
  '#a855f7', '#ec4899', '#06b6d4', '#64748b',
];

class PColorPicker extends StatelessWidget {
  const PColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.palette = kPDefaultPalette,
    this.dotSize = 28,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final List<String> palette;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in palette)
          GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: parseColor(c, fallback: t.fgBrand),
                shape: BoxShape.circle,
                border: Border.all(
                  color: c == selected ? t.fgPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: c == selected
                  ? const Icon(LucideIcons.check,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ),
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
                borderRadius: BorderRadius.circular(8),
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
