import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

/// 고르기 시트 안 한 줄 — [value] 가 돌아온다.
class PickItem<T> {
  const PickItem({
    required this.value,
    required this.title,
    this.detail,
    this.prefix,
    this.enabled = true,
  });

  final T value;
  final String title;

  /// 막힌 줄이면 까닭을 말한다.
  final String? detail;

  /// 앞 붙이개 — 카테고리 타일.
  final Widget? prefix;
  final bool enabled;
}

/// 고르기 시트 안의 한 목록 — 누르면 바로 고르고 시트를 닫는다(웹 `pick-list.tsx`). 고른 줄은 오른쪽 체크 + selected.
/// 시트 본문은 [PBottomSheetContent] 의 `flushBody: true` 안에 둔다(줄이 제 좌우 24 를 갖는다).
class PickList<T> extends StatelessWidget {
  const PickList({
    super.key,
    required this.label,
    required this.items,
    required this.selected,
  });

  final String label;
  final List<PickItem<T>> items;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PList(
      semanticLabel: label,
      children: [
        for (final item in items)
          Semantics(
            selected: selected == item.value,
            child: PListButtonItem(
              title: item.title,
              detail: item.detail,
              prefix: item.prefix,
              suffix: selected == item.value
                  ? Icon(LucideIcons.check500, color: c.fgNeutral)
                  : null,
              onTap: item.enabled
                  ? () => PBottomSheet.of(context).close(item.value)
                  : null,
            ),
          ),
      ],
    );
  }
}
