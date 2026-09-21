import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Brand blue (categorical slot 1) drives the primary color and doubles as
/// the "Actual balance" line color in charts, so the same hue means the same
/// thing everywhere in the app.
class AppTheme {
  AppTheme._();

  static const _primaryLight = Color(0xFF2A78D6);
  static const _primaryDark = Color(0xFF3987E5);

  static ThemeData light() => _build(
        brightness: Brightness.light,
        primary: _primaryLight,
        palette: AppPalette.light,
        pagePlane: const Color(0xFFF9F9F7),
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        primary: _primaryDark,
        palette: AppPalette.dark,
        pagePlane: const Color(0xFF0D0D0D),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required AppPalette palette,
    required Color pagePlane,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      surface: palette.cardSurface,
      tertiary: palette.chartAccent,
    );

    final radius = BorderRadius.circular(16);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: pagePlane,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: pagePlane,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.cardSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.cardSurface,
        selectedColor: scheme.primaryContainer,
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        labelStyle: TextStyle(color: scheme.onSurface),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
