class AppSettings {
  const AppSettings({
    this.apiBaseUrl = 'http://localhost:8000',
    this.defaultRcMode = 'hybrid',
    this.defaultOutputMode = 'deck+analysis',
    this.defaultLanguage = 'DE',
    this.defaultMetaSpeed = 'mid',
    this.snapshotsStrict = true,
    this.offlineMode = false,
    this.themeMode = 'system',
  });

  final String apiBaseUrl;
  final String defaultRcMode;
  final String defaultOutputMode;
  final String defaultLanguage;
  final String defaultMetaSpeed;
  final bool snapshotsStrict;
  final bool offlineMode;
  final String themeMode;

  AppSettings copyWith({
    String? apiBaseUrl,
    String? defaultRcMode,
    String? defaultOutputMode,
    String? defaultLanguage,
    String? defaultMetaSpeed,
    bool? snapshotsStrict,
    bool? offlineMode,
    String? themeMode,
  }) {
    return AppSettings(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      defaultRcMode: defaultRcMode ?? this.defaultRcMode,
      defaultOutputMode: defaultOutputMode ?? this.defaultOutputMode,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      defaultMetaSpeed: defaultMetaSpeed ?? this.defaultMetaSpeed,
      snapshotsStrict: snapshotsStrict ?? this.snapshotsStrict,
      offlineMode: offlineMode ?? this.offlineMode,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
