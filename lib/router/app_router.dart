import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/card_pool/presentation/card_pool_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/deck_analysis/presentation/deck_analysis_screen.dart';
import '../features/deck_builder/presentation/deck_builder_new_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

class AppRoute {
  static const dashboard = '/';
  static const deckBuilder = '/deck-builder';
  static const deckAnalysis = '/deck-analysis';
  static const cardPool = '/card-pool';
  static const settings = '/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoute.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoute.deckBuilder,
        name: 'deck-builder',
        builder: (context, state) => const DeckBuilderNewScreen(),
      ),
      GoRoute(
        path: AppRoute.deckAnalysis,
        name: 'deck-analysis',
        builder: (context, state) => const DeckAnalysisScreen(),
      ),
      GoRoute(
        path: AppRoute.cardPool,
        name: 'card-pool',
        builder: (context, state) => const CardPoolScreen(),
      ),
      GoRoute(
        path: AppRoute.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
