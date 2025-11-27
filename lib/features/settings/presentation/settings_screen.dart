import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_settings.dart';
import '../../core/providers.dart';
import '../../core/state/app_theme_mode.dart';
import '../../core/widgets/section_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiController = TextEditingController();
  final _rcModeController = TextEditingController();
  final _outputModeController = TextEditingController();
  final _languageController = TextEditingController();
  final _metaSpeedController = TextEditingController();
  bool _snapshotsStrict = true;
  bool _offlineMode = false;
  String _themeMode = 'system';

  @override
  void dispose() {
    _apiController.dispose();
    _rcModeController.dispose();
    _outputModeController.dispose();
    _languageController.dispose();
    _metaSpeedController.dispose();
    super.dispose();
  }

  void _fillControllers(AppSettings settings) {
    _apiController.text = settings.apiBaseUrl;
    _rcModeController.text = settings.defaultRcMode;
    _outputModeController.text = settings.defaultOutputMode;
    _languageController.text = settings.defaultLanguage;
    _metaSpeedController.text = settings.defaultMetaSpeed;
    _snapshotsStrict = settings.snapshotsStrict;
    _offlineMode = settings.offlineMode;
    _themeMode = settings.themeMode;
  }

  Future<void> _saveSettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    final newSettings = AppSettings(
      apiBaseUrl: _apiController.text,
      defaultRcMode: _rcModeController.text,
      defaultOutputMode: _outputModeController.text,
      defaultLanguage: _languageController.text,
      defaultMetaSpeed: _metaSpeedController.text,
      snapshotsStrict: _snapshotsStrict,
      offlineMode: _offlineMode,
      themeMode: _themeMode,
    );
    await repo.saveSettings(newSettings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings gespeichert (mock)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (_apiController.text.isEmpty) {
            _fillControllers(settings);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SectionCard(
                  title: 'Defaults',
                  child: Column(
                    children: [
                      TextField(
                        controller: _apiController,
                        decoration: const InputDecoration(
                          labelText: 'API Base URL',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildDropdown(
                            label: 'rc_mode',
                            controller: _rcModeController,
                            options: const ['strict', 'hybrid', 'offline'],
                          ),
                          _buildDropdown(
                            label: 'output_mode',
                            controller: _outputModeController,
                            options: const ['deck only', 'deck+analysis', 'analysis only'],
                          ),
                          _buildDropdown(
                            label: 'Sprache',
                            controller: _languageController,
                            options: const ['DE', 'EN'],
                          ),
                          _buildDropdown(
                            label: 'metaSpeed',
                            controller: _metaSpeedController,
                            options: const ['slow', 'mid', 'fast'],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Snapshots strikt einhalten'),
                        value: _snapshotsStrict,
                        onChanged: (value) => setState(() => _snapshotsStrict = value),
                      ),
                      SwitchListTile(
                        title: const Text('Offline-Modus (Backend ohne Web)'),
                        value: _offlineMode,
                        onChanged: (value) => setState(() => _offlineMode = value),
                      ),
                      DropdownButton<String>(
                        value: _themeMode,
                        items: const [
                          DropdownMenuItem(value: 'system', child: Text('System')),
                          DropdownMenuItem(value: 'light', child: Text('Hell')),
                          DropdownMenuItem(value: 'dark', child: Text('Dunkel')),
                        ],
                        onChanged: (value) {
                          final newValue = value ?? _themeMode;
                          setState(() => _themeMode = newValue);
                          final notifier = ref.read(themeModeProvider.notifier);
                          if (newValue == 'dark') {
                            notifier.setMode(ThemeMode.dark);
                          } else if (newValue == 'light') {
                            notifier.setMode(ThemeMode.light);
                          } else {
                            notifier.setMode(ThemeMode.system);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Speichern'),
                        ),
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  title: 'Debug',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          'mtg_master.json Snapshot (Mock): overrides: 42, aliases: 128, banned: 23'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Healthcheck /health (stub) ok'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.health_and_safety),
                        label: const Text('Backend-Healthcheck'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Settings konnten nicht geladen werden: $e')),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required TextEditingController controller,
    required List<String> options,
  }) {
    return DropdownButton<String>(
      value: controller.text.isEmpty ? options.first : controller.text,
      items: options.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
      onChanged: (value) => setState(() => controller.text = value ?? controller.text),
      hint: Text(label),
    );
  }
}
