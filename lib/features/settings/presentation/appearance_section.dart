import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_radio_list.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_tile.dart';

/// 표시 설정 화면 — AppBar + AppearanceSection (설정 메뉴 '표시 설정' 진입).
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.appearanceTitle),
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
/// 섹션 구성 (클로드 디자인 표시 설정 정합):
/// 1. 테마 카드 3종 (Light / Dark / System) — Sun / Moon / Monitor 아이콘
/// 2. 개인정보 보호 — 금액 가리기 스위치 (헤더 눈 버튼 제거 후 설정 진입점)
/// 3. 언어 / 통화 리스트 (KRW / USD / EUR / JPY)
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PSectionLabel(l.appearanceTheme),
        const SizedBox(height: PSpace.x8),
        Row(
          children: [
            Expanded(
              child: PTile(
                swatch: _ThemeSwatch(icon: LucideIcons.sun, tokens: t),
                label: l.appearanceThemeLight,
                description: l.appearanceThemeLightDesc,
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
                label: l.appearanceThemeDark,
                description: l.appearanceThemeDarkDesc,
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
                label: l.appearanceThemeSystem,
                description: l.appearanceThemeSystemDesc,
                selected: settings.themeMode == ThemeMode.system,
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.system),
              ),
            ),
          ],
        ),

        const SizedBox(height: PSpace.x24),
        PSectionLabel(l.appearancePrivacy),
        const SizedBox(height: PSpace.x8),
        // 금액 가리기 — 클로드 디자인 settings 행 (아이콘 박스 + 라벨/설명 + 스위치).
        // 켜기는 즉시, 끄기는 비밀번호 인증 (toggleHideAmountsWithUnlock).
        PCard(
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.bgMuted,
                  borderRadius: PRadius.brMd,
                ),
                alignment: Alignment.center,
                child: Icon(
                  settings.hideAmounts ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 17,
                  color: t.fgSecondary,
                ),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.appearanceHideAmount,
                      style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.appearanceHideAmountDesc,
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 24,
                child: PSwitch(
                  value: settings.hideAmounts,
                  onChanged: (_) => toggleHideAmountsWithUnlock(context, ref),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: PSpace.x24),
        PSectionLabel(l.settingsLanguage),
        const SizedBox(height: PSpace.x8),
        PTabs<String>(
          value: settings.locale?.languageCode ?? 'system',
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          items: [
            PTabItem(value: 'system', label: l.languageSystem),
            PTabItem(value: 'ko', label: l.languageKorean),
            PTabItem(value: 'en', label: l.languageEnglish),
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
        PSectionLabel(l.appearanceCurrency),
        const SizedBox(height: PSpace.x8),
        PRadioList<String>(
          value: settings.currency,
          onChanged: (code) =>
              ref.read(settingsProvider.notifier).setCurrency(code),
          items: [
            PRadioListItem(value: 'KRW', label: l.appearanceCurrencyKrw, subLabel: 'KRW', pillText: '₩'),
            PRadioListItem(value: 'USD', label: l.appearanceCurrencyUsd, subLabel: 'USD', pillText: r'$'),
            PRadioListItem(value: 'EUR', label: l.appearanceCurrencyEur, subLabel: 'EUR', pillText: '€'),
            PRadioListItem(value: 'JPY', label: l.appearanceCurrencyJpy, subLabel: 'JPY', pillText: '¥'),
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
