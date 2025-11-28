import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_settings.dart';
import 'models/deck.dart';
import 'repositories/ai_repository.dart';
import 'repositories/analysis_repository.dart';
import 'repositories/card_pool_repository.dart';
import 'repositories/deck_generation_repository.dart';
import 'repositories/deck_repository.dart';
import 'repositories/mock_repositories.dart';
import 'repositories/settings_repository.dart';
import 'services/api_client.dart';

final apiBaseUrlProvider = StateProvider<String>((ref) => 'http://localhost:8000/api');

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return MockDeckRepository();
});

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  return MockAnalysisRepository();
});

final cardPoolRepositoryProvider = Provider<CardPoolRepository>((ref) {
  return MockCardPoolRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return MockSettingsRepository();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiClient(baseUrl: baseUrl);
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(apiClientProvider));
});

final deckGenerationRepositoryProvider = Provider<DeckGenerationRepository>((ref) {
  return DeckGenerationRepository(ref.watch(apiClientProvider));
});

final decksProvider = FutureProvider<List<Deck>>((ref) async {
  final repo = ref.read(deckRepositoryProvider);
  return repo.fetchDecks();
});

final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final repo = ref.read(settingsRepositoryProvider);
  return repo.loadSettings();
});
