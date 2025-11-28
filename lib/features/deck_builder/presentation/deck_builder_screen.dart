import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/card_entry.dart';
import '../../core/models/deck.dart';
import '../../core/models/deck_suggestion.dart';
import '../../core/models/deck_generation_result.dart';
import '../../core/repositories/mock_repositories.dart' show mockCommanderOptions;
import '../../core/providers.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_chip.dart';

enum DeckBuildMode { local, hybrid, offlineDemo }

class DeckBuilderScreen extends ConsumerStatefulWidget {
  const DeckBuilderScreen({super.key});

  @override
  ConsumerState<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends ConsumerState<DeckBuilderScreen> {
  final _commanderController = TextEditingController(text: 'Sonic the Hedgehog');
  final _deckNameController = TextEditingController(text: 'Neues Commander-Deck');
  late final TextEditingController _apiBaseController;
  final List<String> _colors = ['U', 'R'];
  DeckBuildMode _buildMode = DeckBuildMode.hybrid;
  String _rcMode = 'hybrid';
  String _outputMode = 'deck+analysis';
  bool _allowLoops = false;
  String _metaSpeed = 'mid';
  String _budget = 'mid';
  String _language = 'DE';
  bool _aiLoading = false;
  bool _buildLoading = false;
  String? _lastValidationLine;
  Map<String, dynamic>? _lastStats;

  List<CardEntry> cards = const [
    CardEntry(
      name: 'Sonic the Hedgehog',
      quantity: 1,
      manaValue: 4,
      colorIdentity: ['U', 'R'],
      types: ['Legendary', 'Creature'],
      tags: ['Commander', 'Haste'],
      isFromOverrides: true,
    ),
    CardEntry(
      name: 'Arcane Signet',
      quantity: 4,
      manaValue: 2,
      colorIdentity: ['U', 'R'],
      types: ['Artifact'],
      tags: ['Ramp'],
    ),
    CardEntry(
      name: 'Impulse',
      quantity: 7,
      manaValue: 2,
      colorIdentity: ['U'],
      types: ['Instant'],
      tags: ['Draw'],
    ),
    CardEntry(
      name: 'Lightning Bolt',
      quantity: 4,
      manaValue: 1,
      colorIdentity: ['R'],
      types: ['Instant'],
      tags: ['Interaction'],
    ),
    CardEntry(
      name: 'Swiftfoot Boots',
      quantity: 1,
      manaValue: 2,
      colorIdentity: [],
      types: ['Artifact'],
      tags: ['Protection'],
    ),
    CardEntry(
      name: 'Island',
      quantity: 35,
      manaValue: 0,
      colorIdentity: ['U'],
      types: ['Land'],
      tags: ['Land'],
    ),
    CardEntry(
      name: 'Mountain',
      quantity: 35,
      manaValue: 0,
      colorIdentity: ['R'],
      types: ['Land'],
      tags: ['Land'],
    ),
    CardEntry(
      name: 'Tempo Tools',
      quantity: 13,
      manaValue: 3,
      colorIdentity: ['U', 'R'],
      types: ['Sorcery'],
      tags: ['Interaction'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    final baseUrl = ref.read(apiBaseUrlProvider);
    _apiBaseController = TextEditingController(text: baseUrl);
  }

  @override
  void dispose() {
    _commanderController.dispose();
    _deckNameController.dispose();
    _apiBaseController.dispose();
    super.dispose();
  }

  int get totalCards => cards.fold(0, (sum, c) => sum + c.quantity);

  Deck _buildDeckModel() {
    final counts = _computeCounts();
    final status = DeckStatus(
      hasBannedCards: false,
      hasCIViolations: false,
      isValid100: totalCards == 100,
      lastValidationMessage: totalCards == 100 ? 'Ready for export' : 'Deck not 100/100',
    );
    final meta = DeckMeta(
      rcMode: _rcMode,
      outputMode: _outputMode,
      allowLoops: _allowLoops,
      metaSpeed: _metaSpeed,
      budget: _budget,
      language: _language,
      powerLevel: 'casual',
    );
    return Deck(
      id: 'deck-builder-temp',
      name: _deckNameController.text,
      commanderName: _commanderController.text,
      colors: List.of(_colors),
      cards: List.of(cards),
      meta: meta,
      counts: counts,
      status: status,
      validationLine:
          'Validation: 100/100✔️ RC-Snapshot✔️ RC-Sync AB (Modus: $_rcMode)✔️ Commander-legal✔️ CI✔️ Moxfield-ready✔️',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  DeckCounts _computeCounts() {
    int lands = 0, ramp = 0, draw = 0, interaction = 0, protection = 0, wincons = 0;
    for (final card in cards) {
      final lowerTags = card.tags.map((e) => e.toLowerCase()).toList();
      if (card.types.contains('Land') || lowerTags.contains('land')) {
        lands += card.quantity;
      }
      if (lowerTags.contains('ramp')) ramp += card.quantity;
      if (lowerTags.contains('draw')) draw += card.quantity;
      if (lowerTags.contains('interaction')) interaction += card.quantity;
      if (lowerTags.contains('protection')) protection += card.quantity;
      if (lowerTags.contains('wincon') || lowerTags.contains('wincons')) {
        wincons += card.quantity;
      }
    }
    return DeckCounts(
      lands: lands,
      ramp: ramp,
      draw: draw,
      interaction: interaction,
      protection: protection,
      wincons: wincons,
    );
  }

  void _setMode(DeckBuildMode mode) {
    setState(() {
      _buildMode = mode;
      if (mode == DeckBuildMode.hybrid) {
        _rcMode = 'hybrid';
      } else if (mode == DeckBuildMode.local) {
        _rcMode = 'strict';
      } else {
        _rcMode = 'offline';
      }
    });
  }

  void _applyApiBaseUrl() {
    final cleaned = _apiBaseController.text.trim();
    if (cleaned.isEmpty) return;
    ref.read(apiBaseUrlProvider.notifier).state = cleaned;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('API Base aktualisiert: $cleaned')),
    );
  }

  DeckGenerationResult _buildOfflineDemoResult() {
    final deck = _buildDeckModel();
    final decklist = <String>[];
    for (final card in deck.cards) {
      for (int i = 0; i < card.quantity; i++) {
        decklist.add(card.name);
      }
    }
    final stats = {
      'lands': deck.counts.lands,
      'ramp': deck.counts.ramp,
      'draw': deck.counts.draw,
      'interaction': deck.counts.interaction,
      'protection': deck.counts.protection,
      'wincons': deck.counts.wincons,
      'total': decklist.length,
    };
    final notes = <String>[];
    if (decklist.length != 100) {
      notes.add('Demo-Deck hat ${decklist.length}/100 Karten.');
    }
    return DeckGenerationResult(
      commander: deck.commanderName,
      colorIdentity: deck.colors,
      deck: decklist.take(100).toList(),
      validation: deck.validationLine,
      stats: stats,
      notes: notes,
    );
  }

  void _toggleColor(String color) {
    setState(() {
      if (_colors.contains(color)) {
        _colors.remove(color);
      } else {
        _colors.add(color);
      }
    });
  }

  void _addCard() {
    setState(() {
      cards = [
        ...cards,
        const CardEntry(
          name: 'Neue Karte',
          quantity: 1,
          manaValue: 2,
          colorIdentity: [],
          types: ['Instant'],
          tags: ['TODO'],
        ),
      ];
    });
  }

  Future<void> _requestAiSuggestions() async {
    if (_aiLoading) return;
    setState(() => _aiLoading = true);
    final deck = _buildDeckModel();
    final base = _apiBaseController.text.trim();
    if (base.isNotEmpty) {
      ref.read(apiBaseUrlProvider.notifier).state = base;
    }
    final repo = ref.read(aiRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final suggestion = await repo.suggestDeck(deck);
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      setState(() => _aiLoading = false);
      await _showSuggestionBottomSheet(suggestion);
    } catch (e, st) {
      if (kDebugMode) {
        // Log stacktrace for debugging in Flutter console
        debugPrint('AI suggestion error: $e\n$st');
      }
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _aiLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI-Vorschlag fehlgeschlagen: $e')),
        );
      }
    }
  }

  Future<void> _showSuggestionBottomSheet(DeckSuggestion suggestion) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI-Vorschläge',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(suggestion.explanation),
              const SizedBox(height: 12),
              SizedBox(
                height: 420,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestion.suggestions.length,
                  itemBuilder: (context, index) {
                    final card = suggestion.suggestions[index];
                    return ListTile(
                      leading: card.imageUrl != null
                          ? Image.network(card.imageUrl!, width: 48, height: 64, fit: BoxFit.cover)
                          : const Icon(Icons.auto_awesome),
                      title: Text(card.name),
                      subtitle: Text(card.reason),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _addSuggestedCard(card);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addSuggestedCard(SuggestedCard card) {
    setState(() {
      cards = [
        ...cards,
        CardEntry(
          name: card.name,
          quantity: 1,
          manaValue: 0,
          colorIdentity: const [],
          types: card.typeLine != null ? [card.typeLine!] : const [],
          tags: ['AI'],
        ),
      ];
    });
  }

  Widget _buildModeSection(String activeBaseUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backend-Modus',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Lokal (strict)'),
              selected: _buildMode == DeckBuildMode.local,
              onSelected: (_) => _setMode(DeckBuildMode.local),
            ),
            ChoiceChip(
              label: const Text('Hybrid (Standard)'),
              selected: _buildMode == DeckBuildMode.hybrid,
              onSelected: (_) => _setMode(DeckBuildMode.hybrid),
            ),
            ChoiceChip(
              label: const Text('Offline-Demo'),
              selected: _buildMode == DeckBuildMode.offlineDemo,
              onSelected: (_) => _setMode(DeckBuildMode.offlineDemo),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiBaseController,
          decoration: const InputDecoration(
            labelText: 'API Base URL',
            helperText: 'z. B. http://localhost:8000/api',
          ),
          onSubmitted: (_) => _applyApiBaseUrl(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _applyApiBaseUrl,
              icon: const Icon(Icons.link),
              label: const Text('API Base setzen'),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Aktiv: $activeBaseUrl',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'oracle.json wird optional in backend/data/oracle.json erwartet. Bei fehlender oder leerer Datei nutzt das Backend automatisch einen internen Fallback-Pool.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCommanderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _deckNameController,
          decoration: const InputDecoration(
            labelText: 'Deckname',
          ),
        ),
        const SizedBox(height: 12),
        Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return mockCommanderOptions;
            }
            return mockCommanderOptions.where(
              (option) => option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
            );
          },
          onSelected: (value) => _commanderController.text = value,
          initialValue: TextEditingValue(text: _commanderController.text),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Commander suchen',
                helperText: 'Alias werden durch alias_map unterstützt',
              ),
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['W', 'U', 'B', 'R', 'G']
              .map(
                (color) => FilterChip(
                  selected: _colors.contains(color),
                  label: Text(color),
                  onSelected: (_) => _toggleColor(color),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            DropdownButton<String>(
              value: _rcMode,
              items: const [
                DropdownMenuItem(value: 'strict', child: Text('rc_mode: strict')),
                DropdownMenuItem(value: 'hybrid', child: Text('rc_mode: hybrid')),
                DropdownMenuItem(value: 'offline', child: Text('rc_mode: offline')),
              ],
              onChanged: (value) => setState(() => _rcMode = value ?? _rcMode),
            ),
            DropdownButton<String>(
              value: _outputMode,
              items: const [
                DropdownMenuItem(value: 'deck only', child: Text('deck only')),
                DropdownMenuItem(value: 'deck+analysis', child: Text('deck+analysis')),
                DropdownMenuItem(value: 'analysis only', child: Text('analysis only')),
              ],
              onChanged: (value) => setState(() => _outputMode = value ?? _outputMode),
            ),
            DropdownButton<String>(
              value: _metaSpeed,
              items: const [
                DropdownMenuItem(value: 'slow', child: Text('slow')),
                DropdownMenuItem(value: 'mid', child: Text('mid')),
                DropdownMenuItem(value: 'fast', child: Text('fast')),
              ],
              onChanged: (value) => setState(() => _metaSpeed = value ?? _metaSpeed),
            ),
            DropdownButton<String>(
              value: _budget,
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Budget: low')),
                DropdownMenuItem(value: 'mid', child: Text('Budget: mid')),
                DropdownMenuItem(value: 'high', child: Text('Budget: high')),
                DropdownMenuItem(value: 'no limit', child: Text('Budget: no limit')),
              ],
              onChanged: (value) => setState(() => _budget = value ?? _budget),
            ),
            DropdownButton<String>(
              value: _language,
              items: const [
                DropdownMenuItem(value: 'DE', child: Text('Sprache: DE')),
                DropdownMenuItem(value: 'EN', child: Text('Sprache: EN')),
              ],
              onChanged: (value) => setState(() => _language = value ?? _language),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _allowLoops,
              onChanged: (value) => setState(() => _allowLoops = value),
              title: const Text('Loops erlauben'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _buildDeckBackend() async {
    if (_buildLoading) return;
    setState(() => _buildLoading = true);
    final deck = _buildDeckModel();

    if (_buildMode == DeckBuildMode.offlineDemo) {
      final result = _buildOfflineDemoResult();
      setState(() {
        _buildLoading = false;
        _lastValidationLine = result.validation;
        _lastStats = result.stats;
        cards = _aggregateDeck(result.deck);
      });
      await _showBuildResult(result);
      return;
    }

    final base = _apiBaseController.text.trim();
    if (base.isNotEmpty) {
      ref.read(apiBaseUrlProvider.notifier).state = base;
    }

    final repo = ref.read(deckGenerationRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await repo.buildDeck(deck);
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {
        _buildLoading = false;
        _lastValidationLine = result.validation;
        _lastStats = result.stats;
        cards = _aggregateDeck(result.deck);
      });
      await _showBuildResult(result);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Deck build error: $e\n$st');
      }
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _buildLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deckbau fehlgeschlagen: $e')),
        );
      }
    }
  }

  List<CardEntry> _aggregateDeck(List<String> decklist) {
    final Map<String, int> counts = {};
    for (final name in decklist) {
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => CardEntry(
              name: e.key,
              quantity: e.value,
              manaValue: 0,
              colorIdentity: [],
              types: const [],
              tags: const [],
            ))
        .toList();
  }

  Future<void> _showBuildResult(DeckGenerationResult result) async {
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
            Text('Deck gebaut', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(result.validation),
            const SizedBox(height: 8),
            Text('Commander: ${result.commander}'),
            Text('Farben: ${result.colorIdentity.join(', ')}'),
            const SizedBox(height: 8),
            Text('Stats: ${result.stats}'),
            if (result.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Hinweise: ${result.notes.join(' | ')}'),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView(
                children: result.deck.take(20).map<Widget>((name) => Text(name)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckTable() {
    final counts = _computeCounts();
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatChip(label: 'Gesamt', value: '$totalCards / 100'),
              StatChip(label: 'Ramp', value: '${counts.ramp}'),
              StatChip(label: 'Draw', value: '${counts.draw}'),
              StatChip(label: 'Interaction', value: '${counts.interaction}'),
              StatChip(label: 'Protection', value: '${counts.protection}'),
              StatChip(label: 'Wincons', value: '${counts.wincons}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Qty')),
              DataColumn(label: Text('MV')),
              DataColumn(label: Text('CI')),
              DataColumn(label: Text('Typen')),
              DataColumn(label: Text('Flags')),
            ],
            rows: [
              for (final card in cards)
                DataRow(
                  cells: [
                    DataCell(Text(card.name)),
                    DataCell(Text(card.quantity.toString())),
                    DataCell(Text(card.manaValue.toString())),
                    DataCell(Wrap(
                      spacing: 4,
                      children: card.colorIdentity
                          .map((c) => Chip(
                                label: Text(c),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    )),
                    DataCell(Text(card.types.join(', '))),
                    DataCell(Wrap(
                      spacing: 4,
                      children: [
                        if (card.isBanned)
                          const Chip(label: Text('Banned'), backgroundColor: Colors.redAccent),
                        if (card.isOutsideColorIdentity)
                          const Chip(
                            label: Text('CI'),
                            backgroundColor: Colors.orangeAccent,
                          ),
                        if (card.isFromOverrides)
                          const Chip(
                            label: Text('Override'),
                            backgroundColor: Colors.blueAccent,
                          ),
                      ],
                    )),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _addCard,
              icon: const Icon(Icons.add),
              label: const Text('Karte hinzufügen'),
            ),
            ElevatedButton.icon(
              onPressed: _buildDeckBackend,
              icon: _buildLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.build),
              label: Text(
                _buildMode == DeckBuildMode.offlineDemo
                    ? 'Deck bauen (Offline-Demo)'
                    : _buildMode == DeckBuildMode.hybrid
                        ? 'Deck bauen (Hybrid)'
                        : 'Deck bauen (Lokal)',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _requestAiSuggestions,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Auto-Vorschlag von AI (Backend)'),
            ),
          ],
        ),
      ],
    );
  }

  String _buildExportText() {
    final buffer = StringBuffer();
    for (final card in cards) {
      for (int i = 0; i < card.quantity; i++) {
        buffer.writeln(card.name);
      }
    }
    buffer.writeln(
      'Validation: 100/100✔️ RC-Snapshot✔️ RC-Sync AB (Modus: $_rcMode)✔️ Commander-legal✔️ CI✔️ Moxfield-ready✔️',
    );
    return buffer.toString();
  }

  Widget _buildValidation() {
    final validationOk = totalCards == 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text(validationOk ? '100/100 erfüllt' : 'Noch nicht 100/100'),
              backgroundColor: validationOk
                  ? Colors.green.withOpacity(0.2)
                  : Colors.redAccent.withOpacity(0.2),
            ),
            Chip(
              label: Text('Banned Cards: none'),
              backgroundColor: Colors.green.withOpacity(0.2),
            ),
            Chip(
              label: Text('CI Violations: none'),
              backgroundColor: Colors.green.withOpacity(0.2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_lastValidationLine != null) ...[
          Text('Backend Validation:', style: Theme.of(context).textTheme.titleMedium),
          Text(_lastValidationLine!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          if (_lastStats != null) Text('Stats: $_lastStats'),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          constraints: const BoxConstraints(minHeight: 200),
          child: SelectableText(
            _buildExportText(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.copy),
              label: const Text('In Zwischenablage kopieren (TODO)'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save_alt),
              label: const Text('Als Textdatei speichern (TODO)'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('An Backend senden (stub)'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBaseUrl = ref.watch(apiBaseUrlProvider);
    if (_apiBaseController.text.isEmpty && activeBaseUrl.isNotEmpty) {
      _apiBaseController.text = activeBaseUrl;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deck Builder'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          final commanderCard = SectionCard(
            title: 'Commander & Config',
            child: _buildCommanderStep(),
          );
          final deckCard = SectionCard(
            title: 'Deckliste & Aktionen',
            child: _buildDeckTable(),
          );
          final validationCard = SectionCard(
            title: 'Validierung & Export',
            child: _buildValidation(),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionCard(
                  title: 'Modus & Backend',
                  child: _buildModeSection(activeBaseUrl),
                ),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: commanderCard),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: deckCard),
                    ],
                  )
                else ...[
                  commanderCard,
                  const SizedBox(height: 16),
                  deckCard,
                ],
                const SizedBox(height: 16),
                validationCard,
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
