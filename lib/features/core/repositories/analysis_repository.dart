import '../models/analysis_result.dart';

abstract class AnalysisRepository {
  Future<AnalysisResult> analyzeDeck(String deckId);
}
