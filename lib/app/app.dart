import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_notifier.dart';
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
      routerConfig: router,
    );
  }
}
