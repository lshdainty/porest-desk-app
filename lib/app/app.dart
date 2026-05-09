import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_notifier.dart';
import '../core/settings/settings_notifier.dart';
import '../features/notification/application/notification_stream_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme/theme_data.dart';

class PorestDeskApp extends ConsumerStatefulWidget {
  const PorestDeskApp({super.key});

  @override
  ConsumerState<PorestDeskApp> createState() => _PorestDeskAppState();
}

class _PorestDeskAppState extends ConsumerState<PorestDeskApp> {
  ProviderSubscription<AsyncValue>? _authSub;

  @override
  void initState() {
    super.initState();
    // 인증 성공 시 알림 폴링 시작, 로그아웃 시 정지.
    _authSub = ref.listenManual<AsyncValue>(
      authProvider,
      (prev, next) {
        final user = next.value;
        final svc = ref.read(notificationStreamServiceProvider);
        if (user != null) {
          svc.start();
        } else {
          svc.stop();
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
