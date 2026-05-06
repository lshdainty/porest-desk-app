import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/theme_data.dart';

class PorestDeskApp extends ConsumerWidget {
  const PorestDeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Porest Desk',
      debugShowCheckedModeBanner: false,
      theme: PorestTheme.light(),
      darkTheme: PorestTheme.dark(),
      themeMode: ThemeMode.system, // Phase 7: SettingsProvider 로 교체
      routerConfig: router,
    );
  }
}
