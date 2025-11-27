import 'dart:math';

import '../models/analysis_result.dart';
import '../models/app_settings.dart';
import '../models/card_entry.dart';
import '../models/card_pool_entry.dart';
import '../models/deck.dart';
import 'ai_repository.dart';
import 'analysis_repository.dart';
import 'card_pool_repository.dart';
import 'deck_repository.dart';
import 'settings_repository.dart';

const mockCommanderOptions = [
  'Sonic the Hedgehog',
  'Atraxa, Praetors\' Voice',
  'Norman Osborn',
  'The Ur-Dragon',
  'Gandalf, Friend of the Shire',
  'Korvold, Fae-Cursed King',
];

final _sonicDeckCards = [
  const CardEntry(
    name: 'Sonic the Hedgehog',
    quantity: 1,
    manaValue: 4,
    colorIdentity: ['U', 'R'],
    types: ['Legendary', 'Creature'],
    tags: ['Commander', 'UB Override'],
    isFromOverrides: true,
  ),
  const CardEntry(
    name: 'Lightning Bolt',
    quantity: 3,
    manaValue: 1,
    colorIdentity: ['R'],
    types: ['Instant'],
    tags: ['Removal'],
  ),
  const CardEntry(
    name: 'Island',
    quantity: 35,
    manaValue: 0,
    colorIdentity: ['U'],
    types: ['Land'],
    tags: ['Land'],
  ),
  const CardEntry(
    name: 'Mountain',
    quantity: 35,
    manaValue: 0,
    colorIdentity: ['R'],
    types: ['Land'],
    tags: ['Land'],
  ),
  const CardEntry(
    name: 'Swiftfoot Boots',
    quantity: 1,
    manaValue: 2,
    colorIdentity: [],
    types: ['Artifact'],
    tags: ['Protection'],
  ),
  const CardEntry(
    name: 'Blue Sun\'s Zenith',
    quantity: 1,
    manaValue: 3,
    colorIdentity: ['U'],
    types: ['Instant'],
    tags: ['Draw'],
  ),
  const CardEntry(
    name: 'Tempo Tools',
    quantity: 24,
    manaValue: 2,
    colorIdentity: ['U', 'R'],
    types: ['Sorcery'],
    tags: ['Interaction'],
  ),
];

final _atraxaDeckCards = [
  const CardEntry(
    name: 'Atraxa, Praetors\' Voice',
    quantity: 1,
    manaValue: 4,
    colorIdentity: ['W', 'U', 'B', 'G'],
    types: ['Legendary', 'Creature'],
    tags: ['Commander'],
  ),
  const CardEntry(
    name: 'Plains',
    quantity: 20,
    manaValue: 0,
    colorIdentity: ['W'],
    types: ['Land'],
  ),
  const CardEntry(
    name: 'Island',
    quantity: 20,
    manaValue: 0,
    colorIdentity: ['U'],
    types: ['Land'],
  ),
  const CardEntry(
    name: 'Swamp',
    quantity: 20,
    manaValue: 0,
    colorIdentity: ['B'],
    types: ['Land'],
  ),
  const CardEntry(
    name: 'Forest',
    quantity: 20,
    manaValue: 0,
    colorIdentity: ['G'],
    types: ['Land'],
  ),
  const CardEntry(
    name: 'Cultivate',
    quantity: 4,
    manaValue: 3,
    colorIdentity: ['G'],
    types: ['Sorcery'],
    tags: ['Ramp'],
  ),
  const CardEntry(
    name: 'Supreme Verdict',
    quantity: 3,
    manaValue: 4,
    colorIdentity: ['W', 'U'],
    types: ['Sorcery'],
    tags: ['Interaction'],
  ),
  const CardEntry(
    name: 'Value Engines',
    quantity: 12,
    manaValue: 3,
    colorIdentity: ['W', 'U', 'B', 'G'],
    types: ['Enchantment'],
    tags: ['Draw'],
  ),
];

final _mockDecks = [
  Deck(
    id: 'deck-sonic',
    name: 'Sonic Tempo Rush',
    commanderName: 'Sonic the Hedgehog',
    colors: ['U', 'R'],
    cards: _sonicDeckCards,
    meta: const DeckMeta(
      rcMode: 'hybrid',
      outputMode: 'deck+analysis',
      allowLoops: false,
      metaSpeed: 'fast',
      budget: 'mid',
      language: 'DE',
      powerLevel: '7',
    ),
    counts: const DeckCounts(
      lands: 70,
      ramp: 6,
      draw: 10,
      interaction: 12,
      protection: 3,
      wincons: 4,
    ),
    status: const DeckStatus(
      hasBannedCards: false,
      hasCIViolations: false,
      isValid100: true,
      lastValidationMessage: 'Ready for export',
    ),
    validationLine:
        'Validation: 100/100✔️ RC-Snapshot✔️ RC-Sync AB (Modus: hybrid)✔️ Commander-legal✔️ CI✔️ Moxfield-ready✔️',
    createdAt: DateTime(2024, 11, 1),
    updatedAt: DateTime(2024, 11, 20),
  ),
  Deck(
    id: 'deck-atraxa',
    name: 'Atraxa Value Pile',
    commanderName: 'Atraxa, Praetors\' Voice',
    colors: ['W', 'U', 'B', 'G'],
    cards: _atraxaDeckCards,
    meta: const DeckMeta(
      rcMode: 'strict',
      outputMode: 'deck only',
      allowLoops: false,
      metaSpeed: 'mid',
      budget: 'high',
      language: 'EN',
      powerLevel: '8',
    ),
    counts: const DeckCounts(
      lands: 80,
      ramp: 8,
      draw: 8,
      interaction: 10,
      protection: 4,
      wincons: 5,
    ),
    status: const DeckStatus(
      hasBannedCards: false,
      hasCIViolations: false,
      isValid100: true,
      lastValidationMessage: 'RC snapshot aligned',
    ),
    validationLine:
        'Validation: 100/100✔️ RC-Snapshot✔️ RC-Sync AB (Modus: strict)✔️ Commander-legal✔️ CI✔️ Moxfield-ready✔️',
    createdAt: DateTime(2024, 8, 5),
    updatedAt: DateTime(2024, 11, 10),
  ),
];

final _mockPool = [
  const CardPoolEntry(
    cardName: 'Lightning Bolt',
    totalOwned: 12,
    usedInDecks: 3,
    locationCode: 'B1-F2',
    colors: ['R'],
    types: ['Instant'],
  ),
  const CardPoolEntry(
    cardName: 'Sol Ring',
    totalOwned: 5,
    usedInDecks: 4,
    locationCode: 'B2-F1',
    colors: [],
    types: ['Artifact'],
  ),
  const CardPoolEntry(
    cardName: 'Sonic the Hedgehog',
    totalOwned: 1,
    usedInDecks: 1,
    locationCode: 'Display-UB',
    colors: ['U', 'R'],
    types: ['Legendary', 'Creature'],
  ),
  const CardPoolEntry(
    cardName: 'Forest',
    totalOwned: 80,
    usedInDecks: 60,
    locationCode: 'Lands-G1',
    colors: ['G'],
    types: ['Land'],
  ),
];

class MockDeckRepository implements DeckRepository {
  @override
  Future<List<Deck>> fetchDecks() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _mockDecks;
  }

  @override
  Future<Deck?> fetchDeckById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _mockDecks.firstWhere(
      (deck) => deck.id == id,
      orElse: () => _mockDecks.first,
    );
  }

  @override
  Future<Deck> saveDeck(Deck deck) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return deck;
  }
}

class MockAnalysisRepository implements AnalysisRepository {
  @override
  Future<AnalysisResult> analyzeDeck(String deckId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final random = Random(deckId.hashCode);
    return AnalysisResult(
      manaCurveBuckets: {
        '0': 5 + random.nextInt(3),
        '1': 12 + random.nextInt(3),
        '2': 18 + random.nextInt(3),
        '3': 20 + random.nextInt(3),
        '4': 16 + random.nextInt(3),
        '5': 10 + random.nextInt(3),
        '6': 8 + random.nextInt(3),
        '7+': 11 + random.nextInt(3),
      },
      colorPipsByColor: {
        'W': 15 + random.nextInt(10),
        'U': 25 + random.nextInt(10),
        'B': 12 + random.nextInt(10),
        'R': 18 + random.nextInt(10),
        'G': 20 + random.nextInt(10),
      },
      rampCount: 10,
      drawCount: 9,
      interactionCount: 12,
      protectionCount: 4,
      winconCount: 4,
      landCount: 38,
      probabilityQuestions: const [
        ProbabilityResult(question: '3+ Länder bis Zug 3', value: '68%'),
        ProbabilityResult(question: '1 Ramp in den ersten 10 Karten', value: '74%'),
        ProbabilityResult(question: 'Commander bis Zug 5 casten', value: '81%'),
      ],
      warnings: const [
        'Curve leicht top-heavy.',
        'Wincons könnten klarer definiert werden.',
      ],
    );
  }
}

class MockCardPoolRepository implements CardPoolRepository {
  @override
  Future<List<CardPoolEntry>> fetchCardPool() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _mockPool;
  }
}

class MockSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  Future<AppSettings> loadSettings() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _settings;
  }

  @override
  Future<AppSettings> saveSettings(AppSettings settings) async {
    _settings = settings;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _settings;
  }
}

class MockAiRepository implements AiRepository {
  @override
  Future<List<CardEntry>> suggestCards({
    required String commander,
    required List<String> colors,
    required String rcMode,
    required String outputMode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return [
      CardEntry(
        name: 'Sol Ring',
        quantity: 1,
        manaValue: 1,
        colorIdentity: const [],
        types: const ['Artifact'],
        tags: const ['Ramp'],
        isBanned: false,
        isFromOverrides: false,
        isOutsideColorIdentity: false,
        locationCodeFromPool: 'B2-F1',
      ),
      CardEntry(
        name: 'Arcane Signet',
        quantity: 1,
        manaValue: 2,
        colorIdentity: colors,
        types: const ['Artifact'],
        tags: const ['Ramp'],
      ),
      CardEntry(
        name: 'Chaos Warp',
        quantity: 1,
        manaValue: 3,
        colorIdentity: const ['R'],
        types: const ['Instant'],
        tags: const ['Interaction'],
      ),
    ];
  }
}
