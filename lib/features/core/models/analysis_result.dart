class ProbabilityResult {
  const ProbabilityResult({required this.question, required this.value});

  final String question;
  final String value;
}

class AnalysisResult {
  const AnalysisResult({
    this.manaCurveBuckets = const {},
    this.colorPipsByColor = const {},
    this.rampCount = 0,
    this.drawCount = 0,
    this.interactionCount = 0,
    this.protectionCount = 0,
    this.winconCount = 0,
    this.landCount = 0,
    this.probabilityQuestions = const [],
    this.warnings = const [],
  });

  final Map<String, int> manaCurveBuckets;
  final Map<String, int> colorPipsByColor;
  final int rampCount;
  final int drawCount;
  final int interactionCount;
  final int protectionCount;
  final int winconCount;
  final int landCount;
  final List<ProbabilityResult> probabilityQuestions;
  final List<String> warnings;
}
