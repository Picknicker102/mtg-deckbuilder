import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/core/state/app_theme_mode.dart';
import 'features/core/theme/app_theme.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: MtgCommanderApp()));
}

class MtgCommanderApp extends ConsumerWidget {
  const MtgCommanderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'MTG Commander Deckbuilder',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
