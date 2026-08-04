import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/shared/brand/bank_colors.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';

/// 40×40 round-rect 자산 로고. front `AssetLogo` 1:1 미러.
///
/// 카드 정식 이미지(카탈로그)가 있으면 그 이미지, 없으면 모노그램 + 회사 primary 색.
/// 카탈로그 이미지는 외부 URL 이라 깨질 수 있어 실패하면 모노그램으로 되돌린다.
///
/// 색 우선순위:
/// - asset.color → 생성 시 저장한 회사 primary (카드는 발급사 색)
/// - getBrandColor(institution → assetName) → 브랜드 매칭
/// - hashColor(assetName) → 해시 fallback
class AssetLogo extends StatelessWidget {
  const AssetLogo({super.key, required this.asset, this.size = 40});

  final Asset asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imgUrl = asset.cardCatalog?.imgUrl;
    if (imgUrl != null && imgUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: PRadius.brLg,
        child: Image.network(
          imgUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _monogram(context),
        ),
      );
    }
    return _monogram(context);
  }

  Widget _monogram(BuildContext context) {
    final brand = getBrandColor([asset.institution, asset.assetName]);
    final bg = _parseHex(asset.color) ?? brand?.bg ?? hashColor(asset.assetName);
    final fg = brand?.fg ?? Colors.white;
    final char = (asset.institution ?? asset.assetName).trim().isEmpty
        ? '?'
        : (asset.institution ?? asset.assetName).trim().characters.first;
    // web AssetLogo font 분기 정합: ≤32 caption / ≥48 bodyLg / else bodySm
    final fontSize = size <= 32
        ? PFontSize.caption
        : size >= 48
            ? PFontSize.bodyLg
            : PFontSize.bodySm;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PRadius.brLg,
      ),
      child: Text(
        char,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: PFontWeight.bold,
          letterSpacing: -0.28,
          height: PLineHeight.tight,
        ),
      ),
    );
  }
}

Color? _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}
