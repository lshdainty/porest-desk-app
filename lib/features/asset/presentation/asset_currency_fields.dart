import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 통화·환율 칸 — 계좌·카드·투자 편집 폼이 함께 쓴다.
///
/// 웹 `AssetForm` 이 통화 select + 환율 입력의 단일 구현이고, 앱에서는 이 위젯이
/// 그 자리다. 세 폼이 각자 베껴 두면 한쪽만 고쳐졌을 때 "카드에서만 환율이 안 뜬다"
/// 같은 차이가 조용히 생긴다.
///
/// **환율은 통화가 KRW 가 아닐 때만 뜬다.** 원화에 1 을 적게 하는 칸은 의미가 없고,
/// 서버도 KRW 의 환산율은 1 로 정규화한다(`Asset.normalizeRate`).
///
/// 두 칸을 나란히 둔다(라벨과 값이 짧을 때만 — field.yaml). 안내 글은 칸 아래 한 줄이다. 글자가 커지면(150% 넘게) 환율 칸은 아래
/// 줄로 내려 값이 가려지지 않게 한다.
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
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final foreign = isForeignCurrency(currency);
    final currencyField = PField(
      label: l.assetCurrency,
      child: PSelect<String>(
        groups: [
          PSelectGroup(
            items: [
              for (final o in kCurrencies)
                PSelectItem(value: o.code, label: '${o.symbol} ${o.code}'),
            ],
          ),
        ],
        value: currency,
        placeholder: l.assetCurrency,
        onChanged: onCurrencyChanged,
      ),
    );
    final rateField = PField(
      label: l.assetExchangeRate,
      child: PInput(
        controller: rateController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        placeholder: l.assetExchangeRateHint(currency),
        tabularFigures: true,
      ),
    );
    final wide = MediaQuery.textScalerOf(context).scale(16) <= 24;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PSpacing.x2,
      children: [
        if (!foreign)
          currencyField
        else if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x3,
            children: [
              Expanded(child: currencyField),
              Expanded(child: rateField),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PSpacing.x3,
            children: [currencyField, rateField],
          ),
        if (foreign)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x0_5),
            child: Text(
              keepAll(l.assetExchangeRateDesc),
              style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
            ),
          ),
      ],
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
