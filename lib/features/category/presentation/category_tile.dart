import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';

/// 카테고리 줄의 앞 타일 — 40 · 카테고리 색 옅은 바탕 + 아이콘 20. 아이콘이 없거나 세트 밖이면 태그 하나.
Widget categoryTile(BuildContext context, ExpenseCategory cat) {
  final fg = resolveChartColor(
    context,
    cat.color,
    fallback: context.colors.fgBrand,
  );
  return PListTile(
    background: softBg(context, fg),
    color: fg,
    child: Icon(lucideByName(cat.icon)),
  );
}
