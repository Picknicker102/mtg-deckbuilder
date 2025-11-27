class CardEntry {
  const CardEntry({
    required this.name,
    this.quantity = 1,
    this.manaValue = 0,
    this.colorIdentity = const [],
    this.types = const [],
    this.tags = const [],
    this.isBanned = false,
    this.isFromOverrides = false,
    this.isOutsideColorIdentity = false,
    this.locationCodeFromPool,
  });

  final String name;
  final int quantity;
  final double manaValue;
  final List<String> colorIdentity;
  final List<String> types;
  final List<String> tags;
  final bool isBanned;
  final bool isFromOverrides;
  final bool isOutsideColorIdentity;
  final String? locationCodeFromPool;
}
