import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/features/settings/presentation/app_lock_row.dart';
import 'package:porest_desk_app/features/settings/presentation/hide_amounts_accordion.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_radio_list.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_tile.dart';
import 'package:porest_desk_app/core/settings/regions.dart';
import 'package:porest_desk_app/features/notification/application/user_preferences_providers.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';

/// 표시 설정 화면 — AppBar + AppearanceSection (설정 메뉴 '표시 설정' 진입).
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key, this.openHideAmounts = false});

  /// 눈 버튼으로 들어오면 금액 가리기를 펼친 채로 연다.
  final bool openHideAmounts;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: t.bgSurface,
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
        children: [AppearanceSection(openHideAmounts: openHideAmounts)],
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
  const AppearanceSection({super.key, this.openHideAmounts = false});

  final bool openHideAmounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final prefs = ref.watch(userPreferencesProvider).value;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 세트 1 — 테마 label + 타일(한 묶음). label↔content x8, 세트끼리 x32.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSectionLabel(l.appearanceTheme,
                variant: PSectionLabelVariant.section),
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
          ],
        ),
        const SizedBox(height: PSpace.x32),
        // 세트 2 — 개인정보 label + 금액 가리기(한 묶음).
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSectionLabel(l.appearancePrivacy,
                variant: PSectionLabelVariant.section),
            // label↔content gap 0(사용자 결정) — 테마·언어만 gap.
            // 앱 잠금 — 로그인과 별개로 실행·복귀 시 생체인증(Face ID·지문) 확인.
            const AppLockRow(),
            // 금액 가리기 — 화면·카드별로 고르는 아코디언. 여기서 바로 펼친다(별도 화면 아님).
            HideAmountsAccordion(initiallyOpen: openHideAmounts),
          ],
        ),
        const SizedBox(height: PSpace.x32),
        // 세트 3 — 언어 label + 선택(한 묶음).
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSectionLabel(l.settingsLanguage,
                variant: PSectionLabelVariant.section),
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
          ],
        ),
        const SizedBox(height: PSpace.x32),
        // 세트 — 표시 기준 지역. 테마·통화와 달리 로컬이 아니라 서버에 저장한다:
        // 서버가 이 값으로 "오늘"을 판단하므로 로컬에만 두면 표기와 계산이 어긋난다.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSectionLabel(l.appearanceRegion,
                variant: PSectionLabelVariant.section),
            const SizedBox(height: PSpace.x8),
            PSelect<String>(
              value: prefs?.timezone,
              enabled: prefs != null,
              placeholder: l.appearanceRegionPlaceholder,
              helperText: l.appearanceRegionDesc,
              items: [
                for (final o in regionOptionsWith(prefs?.timezone))
                  PSelectItem(value: o.value, label: isEn ? o.en : o.ko),
              ],
              onChanged: (tz) {
                if (tz == null || tz == prefs?.timezone) return;
                ref.read(userPreferencesProvider.notifier).patch(
                      {'timezone': tz},
                      optimistic: (prev) => prev.copyWith(timezone: tz),
                    );
              },
            ),
          ],
        ),
        const SizedBox(height: PSpace.x32),
        // 세트 4 — 기본 통화 label + list(한 묶음).
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSectionLabel(l.appearanceCurrency,
                variant: PSectionLabelVariant.section),
            // label↔content gap 0(사용자 결정) — 테마·언어만 gap.
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
