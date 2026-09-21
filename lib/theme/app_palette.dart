import 'package:flutter/material.dart';

/// Design tokens that aren't part of Flutter's [ColorScheme] but are used
/// consistently across charts, heatmaps, and status badges: a small,
/// validated palette (fixed status colors + chart chrome) rather than ad hoc
/// Material colors sprinkled through the widget tree.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.statusGood,
    required this.statusWarning,
    required this.statusCritical,
    required this.chartAccent,
    required this.mutedInk,
    required this.gridline,
    required this.cardSurface,
  });

  /// Achieved / profit day.
  final Color statusGood;

  /// Breakeven day.
  final Color statusWarning;

  /// Failed / loss day.
  final Color statusCritical;

  /// Target reference line and matching accents (categorical slot 2, orange).
  final Color chartAccent;

  /// Axis labels, "no activity" text, secondary chart ink.
  final Color mutedInk;

  /// Hairline chart gridlines.
  final Color gridline;

  /// Slightly lighter than the page background, used for cards.
  final Color cardSurface;

  static const light = AppPalette(
    statusGood: Color(0xFF0CA30C),
    statusWarning: Color(0xFFFAB219),
    statusCritical: Color(0xFFD03B3B),
    chartAccent: Color(0xFFEB6834),
    mutedInk: Color(0xFF898781),
    gridline: Color(0xFFE1E0D9),
    cardSurface: Color(0xFFFCFCFB),
  );

  static const dark = AppPalette(
    statusGood: Color(0xFF0CA30C),
    statusWarning: Color(0xFFFAB219),
    statusCritical: Color(0xFFD03B3B),
    chartAccent: Color(0xFFD95926),
    mutedInk: Color(0xFF898781),
    gridline: Color(0xFF2C2C2A),
    cardSurface: Color(0xFF1A1A19),
  );

  @override
  AppPalette copyWith({
    Color? statusGood,
    Color? statusWarning,
    Color? statusCritical,
    Color? chartAccent,
    Color? mutedInk,
    Color? gridline,
    Color? cardSurface,
  }) {
    return AppPalette(
      statusGood: statusGood ?? this.statusGood,
      statusWarning: statusWarning ?? this.statusWarning,
      statusCritical: statusCritical ?? this.statusCritical,
      chartAccent: chartAccent ?? this.chartAccent,
      mutedInk: mutedInk ?? this.mutedInk,
      gridline: gridline ?? this.gridline,
      cardSurface: cardSurface ?? this.cardSurface,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      statusGood: Color.lerp(statusGood, other.statusGood, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusCritical: Color.lerp(statusCritical, other.statusCritical, t)!,
      chartAccent: Color.lerp(chartAccent, other.chartAccent, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
      gridline: Color.lerp(gridline, other.gridline, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
