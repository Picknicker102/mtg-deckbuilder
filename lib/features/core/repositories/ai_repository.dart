import '../models/card_entry.dart';

abstract class AiRepository {
  Future<List<CardEntry>> suggestCards({
    required String commander,
    required List<String> colors,
    required String rcMode,
    required String outputMode,
  });
}
