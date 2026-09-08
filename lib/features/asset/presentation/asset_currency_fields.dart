import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/currency.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// 통화·환율 칸 — 계좌·카드·투자 편집 폼이 함께 쓴다.
///
/// 웹 `AssetForm` 이 통화 select + 환율 입력의 단일 구현이고, 앱에서는 이 위젯이
/// 그 자리다. 세 폼이 각자 베껴 두면 한쪽만 고쳐졌을 때 "카드에서만 환율이 안 뜬다"
/// 같은 차이가 조용히 생긴다.
///
/// **환율은 통화가 KRW 가 아닐 때만 뜬다.** 원화에 1 을 적게 하는 칸은 의미가 없고,
/// 서버도 KRW 의 환산율은 1 로 정규화한다(`Asset.normalizeRate`).
class AssetCurrencyFields extends StatelessWidget {
  const AssetCurrencyFields({
    super.key,
    required this.currency,
    required this.rateController,
    required this.onCurrencyChanged,
  });

  /// 지금 고른 통화 코드(ISO). 비어 있을 수 없다 — 기본은 [kDefaultCurrency].
  final String currency;

  /// 환율 입력 컨트롤러. 외화가 아닐 때는 칸이 안 그려질 뿐 값은 유지된다 —
  /// 통화를 잘못 눌렀다 되돌렸을 때 적어 둔 환율이 사라지면 곤란하다.
  final TextEditingController rateController;

  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final foreign = isForeignCurrency(currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label(l.assetCurrency),
                  const SizedBox(height: PSpace.x8),
                  PSelect<String>(
                    value: currency,
                    items: [
                      for (final c in kCurrencies)
                        PSelectItem(
                          value: c.code,
                          label: '${c.symbol} ${c.code}',
                        ),
                    ],
                    onChanged: (v) => onCurrencyChanged(v ?? kDefaultCurrency),
                  ),
                ],
              ),
            ),
            if (foreign) ...[
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(l.assetExchangeRate),
                    const SizedBox(height: PSpace.x8),
                    PTextInput(
                      controller: rateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      placeholder: l.assetExchangeRateHint(currency),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (foreign) ...[
          const SizedBox(height: PSpace.x8),
          Text(
            l.assetExchangeRateDesc,
            style: PTypo.micro.copyWith(color: t.fgTertiary),
          ),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(
      text,
      style: PTypo.caption.copyWith(
        color: t.fgPrimary,
        fontWeight: PFontWeight.medium,
      ),
    );
  }
}

/// 1400.000000 을 1400 으로 — 서버가 소수 6자리로 주는 값을 그대로 채워 두면
/// 편집 폼이 지저분하고, 사용자가 고치려고 지웠다 다시 적게 된다.
String trimExchangeRate(double rate) {
  final s = rate.toStringAsFixed(6);
  return s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;
}
