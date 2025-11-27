import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_settings.dart';
import 'models/deck.dart';
import 'repositories/ai_repository.dart';
import 'repositories/analysis_repository.dart';
import 'repositories/card_pool_repository.dart';
import 'repositories/deck_repository.dart';
import 'repositories/mock_repositories.dart';
import 'repositories/settings_repository.dart';

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

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return MockAiRepository();
});

final decksProvider = FutureProvider<List<Deck>>((ref) async {
  final repo = ref.read(deckRepositoryProvider);
  return repo.fetchDecks();
});

final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final repo = ref.read(settingsRepositoryProvider);
  return repo.loadSettings();
});
