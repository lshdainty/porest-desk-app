import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_notifier.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme/theme_data.dart';

class PorestDeskApp extends ConsumerWidget {
  const PorestDeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    return MaterialApp.router(
      title: 'Porest Desk',
      debugShowCheckedModeBanner: false,
      theme: PorestTheme.light(),
      darkTheme: PorestTheme.dark(),
      themeMode: settings.themeMode,
      // i18n: 사용자가 명시적으로 ko/en 선택하지 않았으면 (locale=null)
      // 시스템 로케일을 따르되, 미지원 시 ko 로 폴백.
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
