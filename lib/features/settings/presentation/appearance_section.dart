import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/density.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/shared/widgets/p_radio_list.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_tile.dart';

/// 표시 설정 화면 — AppBar + AppearanceSection (설정 메뉴 '표시 설정' 진입).
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: const Text('표시 설정'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x20,
          vertical: PSpace.x24,
        ),
        children: const [AppearanceSection()],
      ),
    );
  }
}

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
        PSectionLabel('테마'),
        const SizedBox(height: PSpace.x8),
        Row(
          children: [
            Expanded(
              child: PTile(
                swatch: _ThemeSwatch(icon: LucideIcons.sun, tokens: t),
                label: '라이트',
                description: '밝은 배경',
                selected: settings.themeMode == ThemeMode.light,
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: PTile(
                swatch: _ThemeSwatch(icon: LucideIcons.moon, tokens: t),
                label: '다크',
                description: '어두운 배경',
                selected: settings.themeMode == ThemeMode.dark,
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: PTile(
                swatch: _ThemeSwatch(icon: LucideIcons.monitor, tokens: t),
                label: '시스템',
                description: '자동 전환',
                selected: settings.themeMode == ThemeMode.system,
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.system),
              ),
            ),
          ],
        ),

        const SizedBox(height: PSpace.x24),
        PSectionLabel('표시 밀도'),
        const SizedBox(height: PSpace.x8),
        PTabs<PDensity>(
          value: settings.density,
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          items: const [
            PTabItem(value: PDensity.compact, label: '컴팩트'),
            PTabItem(value: PDensity.comfortable, label: '편안'),
            PTabItem(value: PDensity.spacious, label: '여유'),
          ],
          onChanged: (d) => ref.read(settingsProvider.notifier).setDensity(d),
        ),

        const SizedBox(height: PSpace.x24),
        PSectionLabel('언어'),
        const SizedBox(height: PSpace.x8),
        PTabs<String>(
          value: settings.locale?.languageCode ?? 'system',
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          items: const [
            PTabItem(value: 'system', label: '시스템'),
            PTabItem(value: 'ko', label: '한국어'),
            PTabItem(value: 'en', label: 'English'),
          ],
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
        ),

        const SizedBox(height: PSpace.x24),
        PSectionLabel('통화'),
        const SizedBox(height: PSpace.x8),
        PRadioList<String>(
          value: settings.currency,
          onChanged: (code) =>
              ref.read(settingsProvider.notifier).setCurrency(code),
          items: const [
            PRadioListItem(value: 'KRW', label: '대한민국 원', subLabel: 'KRW', pillText: '₩'),
            PRadioListItem(value: 'USD', label: '미국 달러', subLabel: 'USD', pillText: r'$'),
            PRadioListItem(value: 'EUR', label: '유로', subLabel: 'EUR', pillText: '€'),
            PRadioListItem(value: 'JPY', label: '일본 엔', subLabel: 'JPY', pillText: '¥'),
          ],
        ),
      ],
    );
  }
}

/// PTile swatch — 테마 미리보기 영역 (bgMuted bg + 중앙 아이콘).
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.icon, required this.tokens});
  final IconData icon;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tokens.bgMuted,
      alignment: Alignment.center,
      child: Icon(icon, size: 22, color: tokens.fgSecondary),
    );
  }
}
