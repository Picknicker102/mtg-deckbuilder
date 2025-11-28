import '../models/deck.dart';
import '../models/deck_generation_result.dart';
import '../services/api_client.dart';

class DeckGenerationRepository {
  DeckGenerationRepository(this.apiClient);

  final ApiClient apiClient;

  Future<DeckGenerationResult> buildDeck(Deck deck) async {
    final payload = {
      'commanderName': deck.commanderName,
      'rc_mode': deck.meta.rcMode,
      'language': deck.meta.language,
      'allowLoops': deck.meta.allowLoops,
      'colors': deck.colors,
      'playstyle': deck.meta.metaSpeed,
    };
    final json = await apiClient.postJson('/decks/build', payload);
    return DeckGenerationResult.fromJson(json);
  }
}
