import '../models/card_suggestion.dart';
import '../services/card_api.dart';

class CardSearchRepository {
  CardSearchRepository(this.api);

  final CardApi api;

  Future<List<String>> autocomplete(String query) => api.autocomplete(query);

  Future<CardSuggestion> fetchByName(String name) => api.fetchByName(name);
}
