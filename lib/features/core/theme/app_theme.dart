import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      textTheme: GoogleFonts.montserratTextTheme(),
    );
    return base.copyWith(
      cardTheme: CardThemeData(
        color: base.colorScheme.surface,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: base.colorScheme.primaryContainer,
        checkmarkColor: base.colorScheme.onPrimaryContainer,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
    );
    return base.copyWith(
      cardTheme: CardThemeData(
        color: base.colorScheme.surface,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: base.colorScheme.primaryContainer,
        checkmarkColor: base.colorScheme.onPrimaryContainer,
      ),
    );
  }
}
