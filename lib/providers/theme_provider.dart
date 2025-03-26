import 'package:espn_app/providers/provider_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Provider qui fournit le thème actuel de l'application
final themeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(settingsProvider);

  return settings.darkModeEnabled ? _darkTheme : _lightTheme;
});

/// Thème clair de l'application
final _lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  primaryColor: Colors.black,
  appBarTheme: const AppBarTheme(
    color: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black),
  ),
  colorScheme: ColorScheme.light(
    primary: Colors.black,
    secondary: Colors.red.shade800,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
    background: Colors.white,
    onBackground: Colors.black,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.black;
      }
      return Colors.grey.shade400;
    }),
    trackColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.grey.shade600;
      }
      return Colors.grey.shade300;
    }),
  ),
  dividerTheme: DividerThemeData(color: Colors.grey.shade300, thickness: 1),
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: TextTheme(
    // Titres principaux en BlackOpsOne
    headlineLarge: GoogleFonts.blackOpsOne(
      fontSize: 45,
      color: Colors.black,
      height: 1.0,
    ),
    // Titres secondaires en BlackOpsOne
    headlineMedium: GoogleFonts.blackOpsOne(
      fontSize: 32,
      color: Colors.black,
      height: 1.0,
    ),
    // Titres de sections en BlackOpsOne
    titleLarge: GoogleFonts.blackOpsOne(
      fontSize: 24,
      color: Colors.black,
      height: 1.0,
    ),
    // Titres de cartes/widgets en BlackOpsOne
    titleMedium: GoogleFonts.blackOpsOne(
      fontSize: 18,
      color: Colors.black,
      height: 1.0,
    ),
    // Texte courant en Roboto
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Colors.black,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.black87,
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Colors.black54,
    ),
    // Pour les boutons et éléments interactifs
    labelLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.black,
      textStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 16),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    textColor: Colors.black,
    iconColor: Colors.black,
  ),
);

/// Thème sombre de l'application
final _darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Color(0xFF121212),
  primaryColor: Colors.white,
  appBarTheme: const AppBarTheme(
    color: Color(0xFF1E1E1E),
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  colorScheme: ColorScheme.dark(
    primary: Colors.white,
    secondary: Colors.red.shade700,
    onPrimary: Colors.black,
    onSecondary: Colors.white,
    surface: Color(0xFF1E1E1E),
    onSurface: Colors.white,
    background: Color(0xFF121212),
    onBackground: Colors.white,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.white;
      }
      return Colors.grey.shade700;
    }),
    trackColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.grey.shade300;
      }
      return Colors.grey.shade800;
    }),
  ),
  dividerTheme: DividerThemeData(color: Colors.grey.shade800, thickness: 1),
  cardTheme: CardTheme(
    color: Color(0xFF1E1E1E),
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: TextTheme(
    // Titres principaux en BlackOpsOne
    headlineLarge: GoogleFonts.blackOpsOne(
      fontSize: 45,
      color: Colors.white,
      height: 1.0,
    ),
    // Titres secondaires en BlackOpsOne
    headlineMedium: GoogleFonts.blackOpsOne(
      fontSize: 32,
      color: Colors.white,
      height: 1.0,
    ),
    // Titres de sections en BlackOpsOne
    titleLarge: GoogleFonts.blackOpsOne(
      fontSize: 24,
      color: Colors.white,
      height: 1.0,
    ),
    // Titres de cartes/widgets en BlackOpsOne
    titleMedium: GoogleFonts.blackOpsOne(
      fontSize: 18,
      color: Colors.white,
      height: 1.0,
    ),
    // Texte courant en Roboto
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Colors.white,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.white70,
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Colors.white60,
    ),
    // Pour les boutons et éléments interactifs
    labelLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 16),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      textStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    textColor: Colors.white,
    iconColor: Colors.white,
  ),
);
