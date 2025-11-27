class SuggestedCard {
  SuggestedCard({
    required this.name,
    required this.reason,
    this.synergyTags,
    this.imageUrl,
    this.manaCost,
    this.typeLine,
  });

  final String name;
  final String reason;
  final List<String>? synergyTags;
  final String? imageUrl;
  final String? manaCost;
  final String? typeLine;

  factory SuggestedCard.fromJson(Map<String, dynamic> json) {
    return SuggestedCard(
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      synergyTags: (json['synergy_tags'] as List?)?.cast<String>(),
      imageUrl: json['image_url'] as String?,
      manaCost: json['mana_cost'] as String?,
      typeLine: json['type_line'] as String?,
    );
  }
}

class DeckSuggestion {
  DeckSuggestion({
    required this.suggestions,
    required this.explanation,
  });

  final List<SuggestedCard> suggestions;
  final String explanation;

  factory DeckSuggestion.fromJson(Map<String, dynamic> json) {
    final suggestionsJson = json['suggestions'] as List? ?? [];
    return DeckSuggestion(
      suggestions: suggestionsJson
          .map((e) => SuggestedCard.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      explanation: json['explanation'] as String? ?? '',
    );
  }
}
