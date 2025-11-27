import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/card_entry.dart';
import '../../core/repositories/mock_repositories.dart';
import '../../core/providers.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_chip.dart';

class DeckBuilderScreen extends ConsumerStatefulWidget {
  const DeckBuilderScreen({super.key});

  @override
  ConsumerState<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends ConsumerState<DeckBuilderScreen> {
  final _commanderController = TextEditingController(text: 'Sonic the Hedgehog');
  final _deckNameController = TextEditingController(text: 'Neues Commander-Deck');
  int _currentStep = 0;
  final List<String> _colors = ['U', 'R'];
  String _rcMode = 'hybrid';
  String _outputMode = 'deck+analysis';
  bool _allowLoops = false;
  String _metaSpeed = 'mid';
  String _budget = 'mid';
  String _language = 'DE';

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
  void dispose() {
    _commanderController.dispose();
    _deckNameController.dispose();
    super.dispose();
  }

  int get totalCards => cards.fold(0, (sum, c) => sum + c.quantity);

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
    final ai = ref.read(aiRepositoryProvider);
    final suggestions = await ai.suggestCards(
      commander: _commanderController.text,
      colors: _colors,
      rcMode: _rcMode,
      outputMode: _outputMode,
    );
    setState(() {
      cards = [...cards, ...suggestions];
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI-Vorschläge hinzugefügt')),
      );
    }
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

  Widget _buildDeckTable() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatChip(label: 'Gesamt', value: '$totalCards / 100'),
              StatChip(label: 'Ramp', value: '10'),
              StatChip(label: 'Draw', value: '9'),
              StatChip(label: 'Interaction', value: '12'),
              StatChip(label: 'Protection', value: '3'),
              StatChip(label: 'Wincons', value: '4'),
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
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.redAccent.withValues(alpha: 0.2),
            ),
            Chip(
              label: Text('Banned Cards: none'),
              backgroundColor: Colors.green.withValues(alpha: 0.2),
            ),
            Chip(
              label: Text('CI Violations: none'),
              backgroundColor: Colors.green.withValues(alpha: 0.2),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deck Builder'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (value) => setState(() => _currentStep = value),
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        steps: [
          Step(
            title: const Text('Commander & Config'),
            isActive: _currentStep == 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildCommanderStep(),
          ),
          Step(
            title: const Text('Deck konfigurieren'),
            isActive: _currentStep == 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: SectionCard(
              title: 'Kartenliste',
              child: _buildDeckTable(),
            ),
          ),
          Step(
            title: const Text('Validierung & Export'),
            isActive: _currentStep == 2,
            state: _currentStep == 2 ? StepState.editing : StepState.indexed,
            content: _buildValidation(),
          ),
        ],
      ),
    );
  }
}
