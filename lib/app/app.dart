import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/features/sms/data/sms_android.dart';
import 'package:porest_desk_app/features/sms/domain/sms_paste_args.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/features/notification/application/notification_stream_service.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/auth/oauth_link_listener.dart';
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
          // 알림을 눌러 앱을 처음 켠 경우도 여기로 온다(콜드 스타트).
          // 로그인 전에 열면 라우터가 로그인 화면으로 되돌리므로 이 시점에 연다.
          _openPendingSms();
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
      _openPendingSms();
    }
  }

  /// 결제 문자 알림을 눌러 들어왔으면 확인 화면을 연다(안드로이드).
  ///
  /// 네이티브가 문자를 들고 있다가 여기서 건네준다 — 가져가면 비우므로
  /// 앱으로 돌아올 때마다 같은 문자가 다시 열리지는 않는다.
  Future<void> _openPendingSms() async {
    final pending = await SmsAndroid.consumePendingSms();
    if (pending == null || !mounted) return;
    // 첫 라우트가 그려지기 전에 밀어 넣으면 스택이 꼬인다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(routerProvider).push(
            '/sms-paste',
            extra: SmsPasteArgs(text: pending.text, inboxId: pending.id),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    // OAuth 콜백 딥링크 리스너 — 앱 수명 내내 켜 둔다(콜드 스타트 복귀 포함).
    ref.watch(oauthLinkListenerProvider);
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
