import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:porest_desk_app/app/app.dart';
import 'package:porest_desk_app/core/update/update_notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 날짜 로케일 심볼 초기화(전 로케일). Intl.defaultLocale 배선 후 DateFormat 이
  // 로케일 데이터를 요구하므로(ko/en 모두) runApp 전에 반드시 로드.
  await initializeDateFormatting();
  // 새 버전 알림 — 실패해도 던지지 않는다. 알림을 못 걸었다고 앱을 막을 이유가 없다.
  // await 하지 않는다. 채널 생성과 작업 등록이 첫 화면을 늦출 이유가 없다.
  unawaited(initUpdateNotifications());
  runApp(const ProviderScope(child: PorestDeskApp()));
}
