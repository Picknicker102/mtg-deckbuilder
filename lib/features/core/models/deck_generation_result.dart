class DeckGenerationResult {
  DeckGenerationResult({
    required this.commander,
    required this.colorIdentity,
    required this.deck,
    required this.validation,
    required this.stats,
    required this.notes,
  });

  final String commander;
  final List<String> colorIdentity;
  final List<String> deck;
  final String validation;
  final Map<String, dynamic> stats;
  final List<String> notes;

  factory DeckGenerationResult.fromJson(Map<String, dynamic> json) {
    return DeckGenerationResult(
      commander: json['commander'] as String? ?? '',
      colorIdentity: (json['color_identity'] as List? ?? []).cast<String>(),
      deck: (json['deck'] as List? ?? []).cast<String>(),
      validation: json['validation'] as String? ?? '',
      stats: (json['stats'] as Map?)?.cast<String, dynamic>() ?? {},
      notes: (json['notes'] as List? ?? []).cast<String>(),
    );
  }
}
