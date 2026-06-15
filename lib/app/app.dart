import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/features/notification/application/notification_stream_service.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/app/router.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';

class PorestDeskApp extends ConsumerStatefulWidget {
  const PorestDeskApp({super.key});

  @override
  ConsumerState<PorestDeskApp> createState() => _PorestDeskAppState();
}

class _PorestDeskAppState extends ConsumerState<PorestDeskApp>
    with WidgetsBindingObserver {
  ProviderSubscription<AsyncValue>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 포그라운드로 복귀하면 세션 캐시(keepAlive) provider 를 무효화해
    // 백그라운드 동안 다른 클라이언트(웹 등)에서 바뀐 내용을 따라잡는다.
    // 로그인 상태일 때만 — 비로그인 시 불필요한 요청 방지.
    if (state == AppLifecycleState.resumed &&
        ref.read(authProvider).value != null) {
      invalidateKeepAliveProviders(ref);
    }
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
