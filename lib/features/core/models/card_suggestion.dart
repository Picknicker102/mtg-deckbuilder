class CardSuggestion {
  CardSuggestion({
    required this.name,
    this.manaCost,
    this.manaValue = 0,
    this.typeLine,
    this.colorIdentity = const [],
    this.imageUrl,
  });

  final String name;
  final String? manaCost;
  final double manaValue;
  final String? typeLine;
  final List<String> colorIdentity;
  final String? imageUrl;
}
