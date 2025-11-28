import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/card_entry.dart';
import '../../core/models/deck.dart';
import '../../core/models/card_suggestion.dart';
import '../../core/providers.dart';
import '../../core/repositories/card_search_repository.dart';
import '../../core/widgets/section_card.dart';

class DeckBuilderNewScreen extends ConsumerStatefulWidget {
  const DeckBuilderNewScreen({super.key});

  @override
  ConsumerState<DeckBuilderNewScreen> createState() => _DeckBuilderNewScreenState();
}

class _DeckBuilderNewScreenState extends ConsumerState<DeckBuilderNewScreen> {
  final _deckNameController = TextEditingController(text: 'Neues Commander-Deck');
  final _commanderController = TextEditingController();
  final _cardController = TextEditingController();
  final _commanderSuggestions = <String>[];
  final _cardSuggestions = <String>[];

  CardSuggestion? _selectedCommander;
  final List<CardEntry> _deckCards = [];
  bool _loadingCommander = false;
  bool _addingCard = false;
  bool _building = false;
  Map<String, dynamic>? _lastBackendStats;
  String? _lastValidation;

  Timer? _commanderDebounce;
  Timer? _cardDebounce;

  @override
  void dispose() {
    _deckNameController.dispose();
    _commanderController.dispose();
    _cardController.dispose();
    _commanderDebounce?.cancel();
    _cardDebounce?.cancel();
    super.dispose();
  }

  Future<void> _onCommanderQueryChanged(String value) async {
    _commanderDebounce?.cancel();
    _commanderDebounce = Timer(const Duration(milliseconds: 250), () async {
      if (value.trim().isEmpty) {
        setState(() => _commanderSuggestions.clear());
        return;
      }
      final repo = ref.read(cardSearchRepositoryProvider);
      final results = await repo.autocomplete(value.trim());
      setState(() {
        _commanderSuggestions
          ..clear()
          ..addAll(results.take(12));
      });
    });
  }

  Future<void> _selectCommander(String name) async {
    setState(() {
      _loadingCommander = true;
      _commanderSuggestions.clear();
      _commanderController.text = name;
    });
    try {
      final repo = ref.read(cardSearchRepositoryProvider);
      final card = await repo.fetchByName(name);
      setState(() {
        _selectedCommander = card;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Commander konnte nicht geladen werden: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCommander = false);
      }
    }
  }

  Future<void> _onCardQueryChanged(String value) async {
    _cardDebounce?.cancel();
    _cardDebounce = Timer(const Duration(milliseconds: 250), () async {
      if (value.trim().isEmpty) {
        setState(() => _cardSuggestions.clear());
        return;
      }
      final repo = ref.read(cardSearchRepositoryProvider);
      final results = await repo.autocomplete(value.trim());
      setState(() {
        _cardSuggestions
          ..clear()
          ..addAll(results.take(15));
      });
    });
  }

  bool _ciAllows(List<String> ci) {
    if (_selectedCommander == null) return true;
    final cmdCi = _selectedCommander!.colorIdentity;
    return ci.every((c) => cmdCi.contains(c));
  }

  Future<void> _addCardFromSuggestion(String name) async {
    setState(() {
      _addingCard = true;
      _cardSuggestions.clear();
      _cardController.text = name;
    });
    try {
      final repo = ref.read(cardSearchRepositoryProvider);
      final card = await repo.fetchByName(name);
      if (!_ciAllows(card.colorIdentity)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Farbindentität passt nicht zum Commander.')),
          );
        }
        return;
      }
      final index = _deckCards.indexWhere((c) => c.name.toLowerCase() == card.name.toLowerCase());
      if (index >= 0) {
        final existing = _deckCards[index];
        _deckCards[index] = CardEntry(
          name: existing.name,
          quantity: existing.quantity + 1,
          manaValue: existing.manaValue,
          colorIdentity: existing.colorIdentity,
          types: existing.types,
          tags: existing.tags,
          isBanned: existing.isBanned,
          isFromOverrides: existing.isFromOverrides,
          isOutsideColorIdentity: existing.isOutsideColorIdentity,
          locationCodeFromPool: existing.locationCodeFromPool,
        );
      } else {
        _deckCards.add(
          CardEntry(
            name: card.name,
            quantity: 1,
            manaValue: card.manaValue,
            colorIdentity: card.colorIdentity,
            types: card.typeLine?.split(' ') ?? const [],
          ),
        );
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Karte konnte nicht geladen werden: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _addingCard = false);
      }
    }
  }

  void _removeCard(String name) {
    setState(() {
      _deckCards.removeWhere((c) => c.name == name);
    });
  }

  int get _totalCards {
    final deckCount = _deckCards.fold<int>(0, (sum, c) => sum + c.quantity);
    return deckCount + (_selectedCommander != null ? 1 : 0);
  }

  Map<String, int> get _colorCounts {
    final counts = <String, int>{};
    void addColors(List<String> colors) {
      for (final c in colors) {
        counts[c] = (counts[c] ?? 0) + 1;
      }
    }

    if (_selectedCommander != null) {
      addColors(_selectedCommander!.colorIdentity);
    }
    for (final card in _deckCards) {
      addColors(card.colorIdentity);
    }
    return counts;
  }

  Map<String, int> get _manaCurve {
    final buckets = {
      '0': 0,
      '1': 0,
      '2': 0,
      '3': 0,
      '4': 0,
      '5': 0,
      '6+': 0,
    };
    for (final card in _deckCards) {
      final cmc = card.manaValue;
      final qty = card.quantity;
      if (cmc <= 0) {
        buckets['0'] = buckets['0']! + qty;
      } else if (cmc <= 1) {
        buckets['1'] = buckets['1']! + qty;
      } else if (cmc <= 2) {
        buckets['2'] = buckets['2']! + qty;
      } else if (cmc <= 3) {
        buckets['3'] = buckets['3']! + qty;
      } else if (cmc <= 4) {
        buckets['4'] = buckets['4']! + qty;
      } else if (cmc <= 5) {
        buckets['5'] = buckets['5']! + qty;
      } else {
        buckets['6+'] = buckets['6+']! + qty;
      }
    }
    return buckets;
  }

  Future<void> _buildDeckWithBackend() async {
    if (_selectedCommander == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle zuerst einen Commander.')),
      );
      return;
    }
    setState(() => _building = true);
    try {
      final deck = _buildDeckPayload();
      final repo = ref.read(deckGenerationRepositoryProvider);
      final result = await repo.buildDeck(deck);
      if (!mounted) return;
      setState(() {
        _lastBackendStats = result.stats;
        _lastValidation = result.validation;
      });
      await _showBackendResult(result.deck, result.validation, result.stats);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backend-Deckbau fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _building = false);
      }
    }
  }

  Deck _buildDeckPayload() {
    return Deck(
      id: 'temp',
      name: _deckNameController.text.trim().isEmpty ? 'Unbenanntes Deck' : _deckNameController.text.trim(),
      commanderName: _selectedCommander?.name ?? _commanderController.text.trim(),
      colors: _selectedCommander?.colorIdentity ?? const [],
      cards: List.of(_deckCards),
      meta: const DeckMeta(),
      counts: const DeckCounts(),
      status: const DeckStatus(lastValidationMessage: ''),
      validationLine: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _showBackendResult(List<String> deck, String validation, Map<String, dynamic> stats) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backend-Ergebnis', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(validation),
            const SizedBox(height: 8),
            Text('Commander: ${_selectedCommander?.name ?? ''}'),
            Text('Farben: ${( _selectedCommander?.colorIdentity ?? []).join(", ")}'),
            const SizedBox(height: 8),
            Text('Stats: $stats'),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView(
                children: deck.take(30).map((e) => Text(e)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBase = ref.watch(apiBaseUrlProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neues Commander-Deck'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: 'Deck-Info',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _deckNameController,
                    decoration: const InputDecoration(labelText: 'Deckname'),
                  ),
                  const SizedBox(height: 12),
                  Text('API Base: $activeBase', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Commander wählen',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _commanderController,
                    decoration: InputDecoration(
                      labelText: 'Commander-Suche',
                      suffixIcon: _loadingCommander
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    onChanged: _onCommanderQueryChanged,
                  ),
                  if (_commanderSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView(
                        shrinkWrap: true,
                        children: _commanderSuggestions
                            .map(
                              (s) => ListTile(
                                dense: true,
                                title: Text(s),
                                onTap: () => _selectCommander(s),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_selectedCommander != null) _CommanderInfo(card: _selectedCommander!),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Karten hinzufügen',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _cardController,
                    decoration: InputDecoration(
                      labelText: 'Kartensuche',
                      suffixIcon: _addingCard
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    onChanged: _onCardQueryChanged,
                  ),
                  if (_cardSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView(
                        shrinkWrap: true,
                        children: _cardSuggestions
                            .map(
                              (s) => ListTile(
                                dense: true,
                                title: Text(s),
                                onTap: () => _addCardFromSuggestion(s),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _DeckStats(
                    totalCards: _totalCards,
                    colorCounts: _colorCounts,
                    curve: _manaCurve,
                    commanderName: _selectedCommander?.name,
                  ),
                  const SizedBox(height: 12),
                  _DeckList(
                    cards: _deckCards,
                    onRemove: _removeCard,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _building ? null : _buildDeckWithBackend,
                  icon: _building
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.build),
                  label: const Text('Deck erstellen (Backend)'),
                ),
                const SizedBox(width: 12),
                if (_lastValidation != null)
                  Flexible(
                    child: Text(
                      _lastValidation!,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (_lastBackendStats != null) ...[
              const SizedBox(height: 8),
              Text('Backend-Stats: $_lastBackendStats', style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CommanderInfo extends StatelessWidget {
  const _CommanderInfo({required this.card});

  final CardSuggestion card;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: card.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(card.imageUrl!, width: 56, height: 78, fit: BoxFit.cover),
            )
          : const Icon(Icons.shield),
      title: Text(card.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (card.manaCost != null) Text(card.manaCost!),
          if (card.typeLine != null) Text(card.typeLine!),
          Wrap(
            spacing: 6,
            children: card.colorIdentity.map((c) => _ColorBadge(color: c)).toList(),
          ),
        ],
      ),
    );
  }
}

class _DeckStats extends StatelessWidget {
  const _DeckStats({
    required this.totalCards,
    required this.colorCounts,
    required this.curve,
    required this.commanderName,
  });

  final int totalCards;
  final Map<String, int> colorCounts;
  final Map<String, int> curve;
  final String? commanderName;

  @override
  Widget build(BuildContext context) {
    final warning = totalCards < 100 ? 'Noch ${100 - totalCards} Karten fehlen.' : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Commander: ${commanderName ?? '-'}'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          children: [
            Chip(label: Text('Gesamt: $totalCards/100')),
            if (warning != null) Chip(label: Text(warning), backgroundColor: Colors.orange.withOpacity(0.2)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Farben'),
        Wrap(
          spacing: 6,
          children: colorCounts.entries
              .map((e) => Chip(
                    label: Text('${e.key}: ${e.value}'),
                    visualDensity: VisualDensity.compact,
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Text('Mana Curve (Anzahl Karten je Bucket)'),
        Wrap(
          spacing: 6,
          children: curve.entries
              .map((e) => Chip(
                    label: Text('${e.key}: ${e.value}'),
                    visualDensity: VisualDensity.compact,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _DeckList extends StatelessWidget {
  const _DeckList({required this.cards, required this.onRemove});

  final List<CardEntry> cards;
  final void Function(String name) onRemove;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Text('Noch keine Karten hinzugefügt.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Deckliste'),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final card = cards[index];
            return ListTile(
              dense: true,
              title: Text('${card.name} x${card.quantity}'),
              subtitle: Text(card.types.join(' ')),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onRemove(card.name),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ColorBadge extends StatelessWidget {
  const _ColorBadge({required this.color});

  final String color;

  Color _mapColor(String c) {
    switch (c) {
      case 'W':
        return Colors.amber.shade200;
      case 'U':
        return Colors.blue.shade200;
      case 'B':
        return Colors.grey.shade700;
      case 'R':
        return Colors.red.shade200;
      case 'G':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 10,
      backgroundColor: _mapColor(color),
      child: Text(
        color,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
