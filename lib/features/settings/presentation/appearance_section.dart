import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/density.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/settings/settings_notifier.dart';

/// porest-desk-front `AppearanceSection.tsx` 의 모바일 이식.
///
/// 3개 섹션:
/// 1. 테마 카드 3종 (Light / Dark / System) — Sun / Moon / Monitor 아이콘
/// 2. 표시 밀도 세그먼트 (compact / comfortable / spacious)
/// 3. 통화 리스트 (KRW / USD / EUR / JPY)
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('테마'),
        const SizedBox(height: PSpace.x8),
        Row(
          children: [
            _ThemeCard(
              label: '라이트',
              icon: LucideIcons.sun,
              selected: settings.themeMode == ThemeMode.light,
              onTap: () =>
                  ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.light),
              tokens: t,
            ),
            const SizedBox(width: PSpace.x8),
            _ThemeCard(
              label: '다크',
              icon: LucideIcons.moon,
              selected: settings.themeMode == ThemeMode.dark,
              onTap: () =>
                  ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark),
              tokens: t,
            ),
            const SizedBox(width: PSpace.x8),
            _ThemeCard(
              label: '시스템',
              icon: LucideIcons.monitor,
              selected: settings.themeMode == ThemeMode.system,
              onTap: () =>
                  ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.system),
              tokens: t,
            ),
          ],
        ),

        const SizedBox(height: PSpace.x24),
        _SectionLabel('표시 밀도'),
        const SizedBox(height: PSpace.x8),
        _Segment<PDensity>(
          options: const [
            (PDensity.compact, '컴팩트'),
            (PDensity.comfortable, '편안'),
            (PDensity.spacious, '여유'),
          ],
          selected: settings.density,
          onChanged: (d) => ref.read(settingsProvider.notifier).setDensity(d),
          tokens: t,
        ),

        const SizedBox(height: PSpace.x24),
        _SectionLabel('언어'),
        const SizedBox(height: PSpace.x8),
        _Segment<String>(
          options: const [
            ('system', '시스템'),
            ('ko', '한국어'),
            ('en', 'English'),
          ],
          selected: settings.locale?.languageCode ?? 'system',
          onChanged: (v) {
            final notifier = ref.read(settingsProvider.notifier);
            switch (v) {
              case 'ko':
                notifier.setLocale(const Locale('ko'));
                break;
              case 'en':
                notifier.setLocale(const Locale('en'));
                break;
              default:
                notifier.setLocale(null);
            }
          },
          tokens: t,
        ),

        const SizedBox(height: PSpace.x24),
        _SectionLabel('통화'),
        const SizedBox(height: PSpace.x8),
        _CurrencyList(
          selected: settings.currency,
          onChanged: (code) =>
              ref.read(settingsProvider.notifier).setCurrency(code),
          tokens: t,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(text, style: PTypo.caption.copyWith(color: t.fgSecondary));
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: PRadius.brLg,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
          decoration: BoxDecoration(
            color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
            border: Border.all(
              color: selected ? tokens.borderBrand : tokens.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: PRadius.brLg,
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 22,
                      color: selected ? tokens.fgBrand : tokens.fgSecondary),
                  if (selected)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: tokens.bgBrand,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Icon(LucideIcons.check,
                            size: 10, color: tokens.fgOnBrand),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: PSpace.x8),
              Text(label,
                  style: PTypo.bodySm.copyWith(
                    color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.tokens,
  });

  final List<(T value, String label)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.bgMuted,
        borderRadius: PRadius.brMd,
      ),
      child: Row(
        children: [
          for (final opt in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(opt.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: opt.$1 == selected ? tokens.bgSurface : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(
                    opt.$2,
                    textAlign: TextAlign.center,
                    style: PTypo.bodySm.copyWith(
                      color: opt.$1 == selected ? tokens.fgPrimary : tokens.fgTertiary,
                      fontWeight:
                          opt.$1 == selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CurrencyList extends StatelessWidget {
  const _CurrencyList({
    required this.selected,
    required this.onChanged,
    required this.tokens,
  });

  static const _options = [
    ('KRW', '대한민국 원', '₩'),
    ('USD', '미국 달러', r'$'),
    ('EUR', '유로', '€'),
    ('JPY', '일본 엔', '¥'),
  ];

  final String selected;
  final ValueChanged<String> onChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        border: Border.all(color: tokens.borderSubtle),
        borderRadius: PRadius.brLg,
      ),
      child: Column(
        children: [
          for (int i = 0; i < _options.length; i++) ...[
            _CurrencyRow(
              code: _options[i].$1,
              label: _options[i].$2,
              symbol: _options[i].$3,
              selected: selected == _options[i].$1,
              onTap: () => onChanged(_options[i].$1),
              tokens: tokens,
            ),
            if (i < _options.length - 1)
              Divider(height: 1, color: tokens.borderSubtle, indent: 60),
          ],
        ],
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.code,
    required this.label,
    required this.symbol,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });

  final String code;
  final String label;
  final String symbol;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.bgMuted,
                borderRadius: PRadius.brSm,
              ),
              child: Text(symbol,
                  style: PTypo.bodyLg.copyWith(
                      color: tokens.fgPrimary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code, style: PTypo.body.copyWith(color: tokens.fgPrimary, fontWeight: FontWeight.w600)),
                  Text(label, style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
                ],
              ),
            ),
            if (selected)
              Icon(LucideIcons.check, size: 18, color: tokens.fgBrand),
          ],
        ),
      ),
    );
  }
}
