import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/card_pool_entry.dart';
import '../../core/providers.dart';
import '../../core/widgets/section_card.dart';

final cardPoolProvider = FutureProvider<List<CardPoolEntry>>((ref) {
  final repo = ref.read(cardPoolRepositoryProvider);
  return repo.fetchCardPool();
});

class CardPoolScreen extends ConsumerStatefulWidget {
  const CardPoolScreen({super.key});

  @override
  ConsumerState<CardPoolScreen> createState() => _CardPoolScreenState();
}

class _CardPoolScreenState extends ConsumerState<CardPoolScreen> {
  final _searchController = TextEditingController();
  final Set<String> _colorFilter = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poolAsync = ref.watch(cardPoolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartenpool "Verfügbar"'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Nach Name suchen',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 6,
                  children: ['W', 'U', 'B', 'R', 'G']
                      .map(
                        (c) => FilterChip(
                          label: Text(c),
                          selected: _colorFilter.contains(c),
                          onSelected: (_) {
                            setState(() {
                              if (_colorFilter.contains(c)) {
                                _colorFilter.remove(c);
                              } else {
                                _colorFilter.add(c);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Import aus Textdatei (TODO)'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Export als Textdatei (TODO)'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: poolAsync.when(
                data: (entries) {
                  final filtered = entries.where((entry) {
                    final matchesSearch = entry.cardName
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase());
                    final matchesColor = _colorFilter.isEmpty ||
                        entry.colors.any((color) => _colorFilter.contains(color));
                    return matchesSearch && matchesColor;
                  }).toList();

                  final totalCards = filtered.fold<int>(
                      0, (sum, entry) => sum + entry.totalOwned);
                  final distribution = _buildColorDistribution(filtered);

                  return ListView(
                    children: [
                      SectionCard(
                        title: 'Stats',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('Unique: ${filtered.length}')),
                            Chip(label: Text('Total: $totalCards')),
                            Chip(
                              label: Text(
                                'Farben: ${distribution.entries.map((e) => '${e.key}:${e.value}').join(' ')}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SectionCard(
                        title: 'Karten',
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Used')),
                              DataColumn(label: Text('Location')),
                              DataColumn(label: Text('Colors')),
                              DataColumn(label: Text('Typen')),
                            ],
                            rows: [
                              for (final entry in filtered)
                                DataRow(cells: [
                                  DataCell(Text(entry.cardName)),
                                  DataCell(Text(entry.totalOwned.toString())),
                                  DataCell(Text(entry.usedInDecks.toString())),
                                  DataCell(Text(entry.locationCode)),
                                  DataCell(Wrap(
                                    spacing: 4,
                                    children: entry.colors
                                        .map((c) => Chip(label: Text(c)))
                                        .toList(),
                                  )),
                                  DataCell(Text(entry.types.join(', '))),
                                ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Pool konnte nicht geladen werden: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _buildColorDistribution(List<CardPoolEntry> entries) {
    final counts = <String, int>{};
    for (final entry in entries) {
      for (final color in entry.colors) {
        counts[color] = (counts[color] ?? 0) + entry.totalOwned;
      }
    }
    return counts;
  }
}
