import 'package:flutter/services.dart';

import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// 보유 종목 유형·수량 표기 공용 헬퍼 — 편집(투자 다이얼로그)·읽기(자산 상세) 양쪽에서 쓴다.
/// front `HOLDING_UNIT_KEY` / `HOLDING_TYPES` / `sanitizeQty` / `qtyNumber` 미러.

/// 유형 섹션 제목 — 주식 / 금 / 코인.
String holdingTypeLabel(AppLocalizations l, AssetHoldingType type) =>
    switch (type) {
      AssetHoldingType.stock => l.assetHoldingTypeStock,
      AssetHoldingType.gold => l.assetHoldingTypeGold,
      AssetHoldingType.crypto => l.assetHoldingTypeCrypto,
    };

/// 유형별 수량 단위 — 주식 주 / 금 g / 코인 개.
String holdingUnitLabel(AppLocalizations l, AssetHoldingType type) =>
    switch (type) {
      AssetHoldingType.stock => l.assetSharesUnit,
      AssetHoldingType.gold => l.assetHoldingUnitGram,
      AssetHoldingType.crypto => l.assetHoldingUnitCount,
    };

/// 수량 표기 — 수량은 문자열로 들고 있으므로(정밀도 보존) 그대로 쓰되,
/// 소수 허용이라 의미 없는 0 만 떼어 낸다 (3 / 3.75 / 0.05). 없으면 '0'.
String formatHoldingQty(String? q) {
  var s = (q ?? '').trim();
  if (s.isEmpty) return '0';
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  return s.isEmpty ? '0' : s;
}

/// 수량 입력 정규화 — 숫자와 소수점 1개만 남긴다.
/// 입력 중 '3.' 같은 중간 상태는 지우지 않는다(지우면 소수점을 못 찍는다).
String sanitizeHoldingQty(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
  final dot = cleaned.indexOf('.');
  if (dot < 0) return cleaned;
  return cleaned.substring(0, dot + 1) +
      cleaned.substring(dot + 1).replaceAll('.', '');
}

/// 입력 문자열 → 저장/전송용 수량 문자열. double 을 거치지 않는다 — 거치는 순간 정밀도가 깎인다.
/// 비었거나 숫자가 없으면 null. 서버(BigDecimal)가 그대로 파싱할 수 있는 표기로 다듬는다
/// ('3.' → '3', '.5' → '0.5').
String? holdingQtyText(String raw) {
  var s = sanitizeHoldingQty(raw);
  if (s.isEmpty || s == '.') return null;
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  if (s.startsWith('.')) s = '0$s';
  return s.isEmpty ? null : s;
}

/// 수량 입력 formatter — [sanitizeHoldingQty] 를 키 입력마다 적용.
class HoldingQtyInputFormatter extends TextInputFormatter {
  const HoldingQtyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = sanitizeHoldingQty(newValue.text);
    if (cleaned == newValue.text) return newValue;
    final removed = newValue.text.length - cleaned.length;
    final offset =
        (newValue.selection.baseOffset - removed).clamp(0, cleaned.length);
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
