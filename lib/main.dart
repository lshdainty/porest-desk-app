import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:porest_desk_app/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 날짜 로케일 심볼 초기화(전 로케일). Intl.defaultLocale 배선 후 DateFormat 이
  // 로케일 데이터를 요구하므로(ko/en 모두) runApp 전에 반드시 로드.
  await initializeDateFormatting();
  runApp(const ProviderScope(child: PorestDeskApp()));
}
