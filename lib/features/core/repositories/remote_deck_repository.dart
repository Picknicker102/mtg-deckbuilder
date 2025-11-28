import '../models/card_entry.dart';
import '../models/deck.dart';
import '../services/api_client.dart';
import 'deck_repository.dart';

class RemoteDeckRepository implements DeckRepository {
  RemoteDeckRepository(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<Deck>> fetchDecks() async {
    final data = await apiClient.getDynamic('/decks');
    if (data is List) {
      return data.map<Deck>((e) => _mapDeck((e as Map).cast<String, dynamic>())).toList();
    }
    return [];
  }

  @override
  Future<Deck?> fetchDeckById(String id) async {
    final decks = await fetchDecks();
    try {
      return decks.firstWhere((d) => d.id == id);
    } catch (_) {
      return decks.isNotEmpty ? decks.first : null;
    }
  }

  @override
  Future<Deck> saveDeck(Deck deck) async {
    // Placeholder: no backend save endpoint yet
    return deck;
  }

  Deck _mapDeck(Map<String, dynamic> json) {
    final cardsJson = (json['cards'] as List?) ?? [];
    final cards = cardsJson
        .map((c) => CardEntry(
              name: c['name'] as String? ?? '',
              quantity: c['quantity'] as int? ?? 1,
              manaValue: (c['mana_value'] as num?)?.toDouble() ?? 0,
              colorIdentity: (c['color_identity'] as List?)?.cast<String>() ?? const [],
              types: (c['types'] as List?)?.cast<String>() ?? const [],
              tags: (c['tags'] as List?)?.cast<String>() ?? const [],
              isBanned: c['is_banned'] as bool? ?? false,
              isFromOverrides: c['is_from_overrides'] as bool? ?? false,
              isOutsideColorIdentity: c['is_outside_color_identity'] as bool? ?? false,
              locationCodeFromPool: c['location_code_from_pool'] as String?,
            ))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final counts = json['counts'] as Map<String, dynamic>? ?? {};
    final status = json['status'] as Map<String, dynamic>? ?? {};

    return Deck(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      commanderName: json['commander_name'] as String? ?? '',
      colors: (json['colors'] as List?)?.cast<String>() ?? const [],
      cards: cards,
      meta: DeckMeta(
        rcMode: meta['rc_mode'] as String? ?? 'hybrid',
        outputMode: meta['output_mode'] as String? ?? 'deck+analysis',
        allowLoops: meta['allow_loops'] as bool? ?? false,
        metaSpeed: meta['meta_speed'] as String? ?? 'mid',
        budget: meta['budget'] as String? ?? 'mid',
        language: meta['language'] as String? ?? 'DE',
        powerLevel: meta['power_level'] as String? ?? '7',
      ),
      counts: DeckCounts(
        lands: counts['lands'] as int? ?? 0,
        ramp: counts['ramp'] as int? ?? 0,
        draw: counts['draw'] as int? ?? 0,
        interaction: counts['interaction'] as int? ?? 0,
        protection: counts['protection'] as int? ?? 0,
        wincons: counts['wincons'] as int? ?? 0,
      ),
      status: DeckStatus(
        hasBannedCards: status['has_banned_cards'] as bool? ?? false,
        hasCIViolations: status['has_ci_violations'] as bool? ?? false,
        isValid100: status['is_valid_100'] as bool? ?? false,
        lastValidationMessage: status['last_validation_message'] as String? ?? '',
      ),
      validationLine: json['validation_line'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
