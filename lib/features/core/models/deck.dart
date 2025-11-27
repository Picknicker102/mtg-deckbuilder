import 'card_entry.dart';

class DeckMeta {
  const DeckMeta({
    this.rcMode = 'hybrid',
    this.outputMode = 'deck+analysis',
    this.allowLoops = false,
    this.metaSpeed = 'mid',
    this.budget = 'mid',
    this.language = 'DE',
    this.powerLevel = 'casual',
  });

  final String rcMode;
  final String outputMode;
  final bool allowLoops;
  final String metaSpeed;
  final String budget;
  final String language;
  final String powerLevel;
}

class DeckCounts {
  const DeckCounts({
    this.lands = 0,
    this.ramp = 0,
    this.draw = 0,
    this.interaction = 0,
    this.protection = 0,
    this.wincons = 0,
  });

  final int lands;
  final int ramp;
  final int draw;
  final int interaction;
  final int protection;
  final int wincons;
}

class DeckStatus {
  const DeckStatus({
    this.hasBannedCards = false,
    this.hasCIViolations = false,
    this.isValid100 = false,
    this.lastValidationMessage = '',
  });

  final bool hasBannedCards;
  final bool hasCIViolations;
  final bool isValid100;
  final String lastValidationMessage;
}

class Deck {
  const Deck({
    required this.id,
    required this.name,
    required this.commanderName,
    required this.colors,
    required this.cards,
    required this.meta,
    required this.counts,
    required this.status,
    required this.validationLine,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String commanderName;
  final List<String> colors;
  final List<CardEntry> cards;
  final DeckMeta meta;
  final DeckCounts counts;
  final DeckStatus status;
  final String validationLine;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get totalCards => cards.fold(0, (sum, card) => sum + card.quantity);
}
