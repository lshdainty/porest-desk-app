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
    final iconChar = (asset.icon ?? '').trim().isNotEmpty
        ? asset.icon!.trim().characters.first
        : null;
    final fallbackChar = ((asset.institution ?? asset.assetName).trim().isEmpty
        ? '?'
        : (asset.institution ?? asset.assetName).trim().characters.first);
    final char = iconChar ?? fallbackChar;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PRadius.brTile,
      ),
      child: Text(
        char,
        style: TextStyle(
          color: fg,
          fontSize: PFontSize.body,
          fontWeight: PFontWeight.heavy,
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
