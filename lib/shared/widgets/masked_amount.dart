import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/typography.dart';
import '../../core/format/krw.dart';
import '../../core/settings/settings_notifier.dart';

/// 금액을 표시하되 `hideAmounts` 설정이 켜져 있으면 `•••` 으로 마스킹.
///
/// front `MaskAmount` 미러. 호출자가 `settings.hideAmounts` 를 매번 watch 할 필요 없이
/// 위젯이 직접 settings 를 구독한다.
class MaskedAmount extends ConsumerWidget {
  const MaskedAmount(
    this.amount, {
    super.key,
    this.suffix = '원',
    this.sign = false,
    this.abs = false,
    this.style,
    this.maskedText = '••••••',
  });

  final int amount;
  final String? suffix;
  final bool sign;
  final bool abs;
  final TextStyle? style;
  final String maskedText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(settingsProvider).value?.hideAmounts ?? false;
    final body =
        hidden ? maskedText : krw(amount, sign: sign, abs: abs);
    final text = (suffix == null || suffix!.isEmpty) ? body : '$body${suffix!}';
    return Text(text, style: style);
  }
}

/// 임의의 children 를 hideAmounts 시 가린다 (front `HideUnit` 등가).
///
/// 차트 라벨/카운트/비율 등 [krw] 로 표현 안 되는 위젯을 통째로 mask 처리.
class MaskedBlock extends ConsumerWidget {
  const MaskedBlock({
    super.key,
    required this.child,
    this.placeholder,
  });

  final Widget child;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(settingsProvider).value?.hideAmounts ?? false;
    if (!hidden) return child;
    return placeholder ??
        const Text('••••••', style: TextStyle(fontWeight: PFontWeight.bold));
  }
}

/// hideAmounts 일 때 [masked] 함수를 호출해 마스킹된 문자열 반환,
/// 그 외에 [unmasked] 호출. 차트 tooltip 등 inline 사용용.
String formatMaybeMasked(
  WidgetRef ref, {
  required String Function() unmasked,
  String masked = '••••••',
}) {
  final hidden = ref.read(settingsProvider).value?.hideAmounts ?? false;
  return hidden ? masked : unmasked();
}
