import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';

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
    this.excluded = false,
  });

  final String name;
  final Color color;
  final IconData icon;
  final bool active;

  /// '빼고' 상태 — 필터에서만 쓴다(칩 3상태: 고름 → 빼고 → 해제).
  /// [active] 와 동시에 참일 수 없다. 취소선과 붉은 테두리로 "이건 뺀다" 를 말한다.
  /// 웹 `CategoryTile` 의 `excluded` 미러.
  final bool excluded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: excluded
              ? t.statusDangerSubtle
              : active
              ? t.bgBrandSubtle
              : Colors.transparent,
          // 비활성 보더 제거(design 신판, 웹 CategoryTile 정합) —
          // transparent 로 두어 active 전환 시 1px 시프트 방지.
          border: Border.all(
            color: excluded
                ? t.statusDanger
                : active
                ? t.borderBrand
                : Colors.transparent,
          ),
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
                borderRadius: PRadius.tile(32),
              ),
              alignment: Alignment.center,
              child: Opacity(
                // 글자만 취소선이면 아이콘이 살아 있는 것처럼 보인다.
                opacity: excluded ? 0.45 : 1,
                child: Icon(icon, size: 18, color: color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PTypo.micro.copyWith(
                color: excluded
                    ? t.fgExpense
                    : active
                    ? t.fgBrandStrong
                    : t.fgSecondary,
                fontWeight: active || excluded
                    ? PFontWeight.bold
                    : PFontWeight.medium,
                decoration: excluded ? TextDecoration.lineThrough : null,
                decorationColor: excluded ? t.fgExpense : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
