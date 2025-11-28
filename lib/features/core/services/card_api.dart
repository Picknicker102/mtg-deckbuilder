import 'api_client.dart';
import '../models/card_suggestion.dart';

class CardApi {
  CardApi(this._client);

  final ApiClient _client;

  Future<List<String>> autocomplete(String query) async {
    final json = await _client.getJson('/cards/autocomplete', query: {'q': query});
    final suggestions = json['suggestions'];
    if (suggestions is List) {
      return suggestions.cast<String>();
    }
    return [];
  }

  Future<CardSuggestion> fetchByName(String name, {bool fuzzy = true}) async {
    final json = await _client.getJson('/cards/by-name', query: {
      'name': name,
      'fuzzy': fuzzy.toString(),
    });
    return _mapCard(json);
  }

  CardSuggestion _mapCard(Map<String, dynamic> data) {
    final imageUris = data['image_uris'] as Map<String, dynamic>? ?? {};
    return CardSuggestion(
      name: data['name'] as String? ?? '',
      manaCost: data['mana_cost'] as String?,
      manaValue: (data['cmc'] as num?)?.toDouble() ?? (data['mana_value'] as num?)?.toDouble() ?? 0,
      typeLine: data['type_line'] as String?,
      colorIdentity: (data['color_identity'] as List?)?.cast<String>() ?? const [],
      imageUrl: imageUris['small'] as String? ??
          imageUris['normal'] as String? ??
          (data['image']?['small'] as String?) ??
          (data['image']?['normal'] as String?),
    );
  }
}
