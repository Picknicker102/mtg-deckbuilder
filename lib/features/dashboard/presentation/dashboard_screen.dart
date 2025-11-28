import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import '../../core/providers.dart';
import '../../core/widgets/deck_summary_card.dart';
import '../../core/widgets/section_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MTG Commander Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoute.settings),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRoute.deckBuilder),
                      icon: const Icon(Icons.add),
                      label: const Text('Neues Deck bauen'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(AppRoute.cardPool),
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Verfuegbaren Kartenpool oeffnen'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(AppRoute.deckAnalysis),
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Deck analysieren'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Deine Decks',
                  child: decksAsync.when(
                    data: (decks) {
                      if (decks.isEmpty) {
                        return const Text('Noch keine Decks vorhanden.');
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 2 : 1,
                          childAspectRatio: isWide ? 1.6 : 1.2,
                        ),
                        itemCount: decks.length,
                        itemBuilder: (context, index) {
                          final deck = decks[index];
                          return DeckSummaryCard(
                            deck: deck,
                            onOpen: () => context.push(AppRoute.deckBuilder),
                            onAnalyze: () => context.push(AppRoute.deckAnalysis),
                          );
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) => Text('Fehler beim Laden: $e'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
