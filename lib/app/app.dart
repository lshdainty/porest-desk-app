import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

class PorestDeskApp extends ConsumerWidget {
  const PorestDeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Porest Desk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true), // Phase 3 에서 PorestTheme 으로 교체
      routerConfig: router,
    );
  }
}
