import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/analysis_result.dart';
import '../../core/providers.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_chip.dart';

final analysisProvider =
    FutureProvider.family<AnalysisResult, String>((ref, deckId) {
  final repo = ref.read(analysisRepositoryProvider);
  return repo.analyzeDeck(deckId);
});

class DeckAnalysisScreen extends ConsumerStatefulWidget {
  const DeckAnalysisScreen({super.key});

  @override
  ConsumerState<DeckAnalysisScreen> createState() => _DeckAnalysisScreenState();
}

class _DeckAnalysisScreenState extends ConsumerState<DeckAnalysisScreen> {
  String? selectedDeckId;

  @override
  Widget build(BuildContext context) {
    final decksAsync = ref.watch(decksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deck Analyse'),
      ),
      body: decksAsync.when(
        data: (decks) {
          selectedDeckId ??= decks.isNotEmpty ? decks.first.id : null;
          if (selectedDeckId == null) {
            return const Center(child: Text('Keine Decks vorhanden.'));
          }
          final analysisAsync = ref.watch(analysisProvider(selectedDeckId!));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: selectedDeckId,
                  items: decks
                      .map(
                        (deck) => DropdownMenuItem(
                          value: deck.id,
                          child: Text(deck.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedDeckId = value ?? selectedDeckId),
                ),
                const SizedBox(height: 12),
                analysisAsync.when(
                  data: (analysis) => _AnalysisBody(analysis: analysis),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Analyse fehlgeschlagen: $e'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Decks konnten nicht geladen werden: $e')),
      ),
    );
  }
}

class _AnalysisBody extends StatelessWidget {
  const _AnalysisBody({required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: 'Kurvenanalyse',
          child: SizedBox(
            height: 240,
            child: Builder(builder: (context) {
              final buckets = analysis.manaCurveBuckets.entries.toList();
              return BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= buckets.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(buckets[index].key),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: buckets.asMap().entries.map(
                    (entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value.toDouble(),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                        showingTooltipIndicators: const [0],
                      );
                    },
                  ).toList(),
                ),
              );
            }),
          ),
        ),
        SectionCard(
          title: 'Farben',
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: analysis.colorPipsByColor.entries.map((entry) {
                  final total = analysis.colorPipsByColor.values.fold<int>(
                    0,
                    (sum, value) => sum + value,
                  );
                  final percent =
                      total == 0 ? 0 : (entry.value / total * 100).round();
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${entry.key} $percent%',
                    radius: 60,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        SectionCard(
          title: 'Rollen & Slots',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatChip(label: 'Lands', value: '${analysis.landCount}'),
              StatChip(label: 'Ramp', value: '${analysis.rampCount}'),
              StatChip(label: 'Draw', value: '${analysis.drawCount}'),
              StatChip(label: 'Interaction', value: '${analysis.interactionCount}'),
              StatChip(label: 'Protection', value: '${analysis.protectionCount}'),
              StatChip(label: 'Wincons', value: '${analysis.winconCount}'),
            ],
          ),
        ),
        SectionCard(
          title: 'Wahrscheinlichkeiten',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: analysis.probabilityQuestions
                .map((prob) => ListTile(
                      title: Text(prob.question),
                      trailing: Text(prob.value),
                    ))
                .toList(),
          ),
        ),
        SectionCard(
          title: 'Warnungen',
          child: Column(
            children: analysis.warnings
                .map((warning) => ListTile(
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: Text(warning),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
