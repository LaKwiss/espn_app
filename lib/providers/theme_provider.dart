import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final lightTheme = ThemeData(
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
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.black;
      }
      return Colors.grey.shade400;
    }),
    trackColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.grey.shade600;
      }
      return Colors.grey.shade300;
    }),
  ),
  dividerTheme: DividerThemeData(color: Colors.grey.shade300, thickness: 1),
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: 0.2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: TextTheme(
    headlineLarge: GoogleFonts.blackOpsOne(
      fontSize: 45,
      color: Colors.black,
      height: 1.0,
    ),
    headlineMedium: GoogleFonts.blackOpsOne(
      fontSize: 32,
      color: Colors.black,
      height: 1.0,
    ),
    titleLarge: GoogleFonts.blackOpsOne(
      fontSize: 24,
      color: Colors.black,
      height: 1.0,
    ),
    titleMedium: GoogleFonts.blackOpsOne(
      fontSize: 18,
      color: Colors.black,
      height: 1.0,
    ),
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

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  primaryColor: Colors.white,
  appBarTheme: const AppBarTheme(
    color: Colors.black,
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
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.white;
      }
      return Colors.grey.shade700;
    }),
    trackColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.grey.shade300;
      }
      return Colors.grey.shade800;
    }),
  ),
  dividerTheme: DividerThemeData(color: Colors.grey.shade800, thickness: 1),
  cardTheme: CardTheme(
    color: Color(0xFF1E1E1E),
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: 0.3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: TextTheme(
    headlineLarge: GoogleFonts.blackOpsOne(
      fontSize: 45,
      color: Colors.white,
      height: 1.0,
    ),
    headlineMedium: GoogleFonts.blackOpsOne(
      fontSize: 32,
      color: Colors.white,
      height: 1.0,
    ),
    titleLarge: GoogleFonts.blackOpsOne(
      fontSize: 24,
      color: Colors.white,
      height: 1.0,
    ),
    titleMedium: GoogleFonts.blackOpsOne(
      fontSize: 18,
      color: Colors.white,
      height: 1.0,
    ),
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
