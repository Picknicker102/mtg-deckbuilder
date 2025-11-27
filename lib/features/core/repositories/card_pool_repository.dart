import '../models/card_pool_entry.dart';

abstract class CardPoolRepository {
  Future<List<CardPoolEntry>> fetchCardPool();
}
