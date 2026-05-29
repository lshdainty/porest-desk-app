import 'package:flutter/material.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/format/chart_palette.dart';

/// front FilterDialog/AddTxSheet 의 카테고리 타일 미러.
///
/// 5xN 그리드용 — 아이콘(원형 soft bg) + 라벨. active 상태 표시.
/// 모든 색·radius 는 토큰만 사용 — `--radius-tile (=10)`, `bgBrandSubtle` 등.
class PCategoryTile extends StatelessWidget {
  const PCategoryTile({
    super.key,
    required this.name,
    required this.color,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String name;
  final Color color;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: active ? t.bgBrandSubtle : Colors.transparent,
          border: Border.all(
              color: active ? t.borderBrand : t.borderSubtle),
          borderRadius: PRadius.brLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: softBg(context, color),
                borderRadius: PRadius.brLg,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 4),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypo.micro.copyWith(
                  color: active ? t.fgBrandStrong : t.fgSecondary,
                  fontWeight: active ? PFontWeight.bold : PFontWeight.medium,
                )),
          ],
        ),
      ),
    );
  }
}
