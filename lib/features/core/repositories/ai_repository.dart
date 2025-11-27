import '../models/card_entry.dart';
import '../models/deck.dart';
import '../models/deck_suggestion.dart';
import '../services/api_client.dart';

class AiRepository {
  AiRepository(this.apiClient);

  final ApiClient apiClient;

  Future<DeckSuggestion> suggestDeck(Deck deck) async {
    final payload = _deckToJson(deck);
    final json = await apiClient.postJson('/ai/suggest-deck', payload);
    return DeckSuggestion.fromJson(json);
  }

  Map<String, dynamic> _deckToJson(Deck deck) {
    return {
      'commander_name': deck.commanderName,
      'colors': deck.colors,
      'cards': deck.cards.map(_cardToJson).toList(),
      'meta': {
        'rc_mode': deck.meta.rcMode,
        'output_mode': deck.meta.outputMode,
        'allow_loops': deck.meta.allowLoops,
        'power_level': deck.meta.powerLevel,
        'meta_speed': deck.meta.metaSpeed,
        'budget': deck.meta.budget,
        'language': deck.meta.language,
      },
    };
  }

  Map<String, dynamic> _cardToJson(CardEntry card) {
    return {
      'name': card.name,
      'quantity': card.quantity,
      'mana_value': card.manaValue,
      'color_identity': card.colorIdentity,
      'types': card.types,
    };
  }
}
