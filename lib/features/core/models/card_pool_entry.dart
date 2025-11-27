class CardPoolEntry {
  const CardPoolEntry({
    required this.cardName,
    this.totalOwned = 0,
    this.usedInDecks = 0,
    this.locationCode = '',
    this.colors = const [],
    this.types = const [],
  });

  final String cardName;
  final int totalOwned;
  final int usedInDecks;
  final String locationCode;
  final List<String> colors;
  final List<String> types;
}
