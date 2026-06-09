import 'package:flutter/material.dart';

import '../../../../app/theme/radius.dart';
import '../../../../app/theme/typography.dart';
import '../../../../shared/brand/bank_colors.dart';
import '../../domain/asset.dart';

/// 40×40 round-rect 자산 로고. front `AssetLogo` 1:1 미러.
///
/// 우선순위:
/// - asset.color → 사용자가 지정한 색
/// - getBrandColor(institution → assetName) → 브랜드 매칭
/// - hashColor(assetName) → 해시 fallback
class AssetLogo extends StatelessWidget {
  const AssetLogo({super.key, required this.asset, this.size = 40});

  final Asset asset;
  final double size;

  @override
  Widget build(BuildContext context) {
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
