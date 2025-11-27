import 'package:flutter/material.dart';

import '../models/deck.dart';
import 'stat_chip.dart';

class DeckSummaryCard extends StatelessWidget {
  const DeckSummaryCard({
    super.key,
    required this.deck,
    this.onOpen,
    this.onAnalyze,
  });

  final Deck deck;
  final VoidCallback? onOpen;
  final VoidCallback? onAnalyze;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Commander: ${deck.commanderName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Wrap(
                        spacing: 6,
                        children: deck.colors
                            .map((c) => Chip(
                                  label: Text(c),
                                  backgroundColor: scheme.secondaryContainer,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      deck.status.isValid100 ? '100/100' : 'Unvollständig',
                      style: TextStyle(
                        color: deck.status.isValid100
                            ? scheme.primary
                            : scheme.error,
                      ),
                    ),
                    Text(
                      'Updated: ${deck.updatedAt.toLocal().toString().split(' ').first}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatChip(label: 'Lands', value: deck.counts.lands.toString()),
                StatChip(label: 'Ramp', value: deck.counts.ramp.toString()),
                StatChip(label: 'Draw', value: deck.counts.draw.toString()),
                StatChip(label: 'Interaction', value: deck.counts.interaction.toString()),
                StatChip(label: 'Wincons', value: deck.counts.wincons.toString()),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              deck.validationLine,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.edit),
                  label: const Text('Deck bearbeiten'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Analysieren'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
