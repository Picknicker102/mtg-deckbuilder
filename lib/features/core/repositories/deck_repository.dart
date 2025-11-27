import '../models/deck.dart';

abstract class DeckRepository {
  Future<List<Deck>> fetchDecks();
  Future<Deck?> fetchDeckById(String id);
  Future<Deck> saveDeck(Deck deck);
}
