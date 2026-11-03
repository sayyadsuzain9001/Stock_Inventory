import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Midnight, Indigo & Gold" premium palette.
class AppColors {
  static const midnight = Color(0xFF0E1330);
  static const indigo = Color(0xFF2B2F77);
  static const violet = Color(0xFF5B4FE0);
  static const gold = Color(0xFFD4A24C);
  static const canvas = Color(0xFFF5F6FA);
  static const emerald = Color(0xFF1FA97A);
  static const crimson = Color(0xFFE5484D);
  static const ink = Color(0xFF1B1F3B);
  static const muted = Color(0xFF6B7090);
  static const line = Color(0xFFE3E5F0);

  static const heroGradient = LinearGradient(
    colors: [midnight, indigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const goldGradient = LinearGradient(
    colors: [Color(0xFFE9C46A), gold, Color(0xFFB9852F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const actionGradient = LinearGradient(
    colors: [indigo, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// Visual identity for each of the four permitted categories.
class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle(this.icon, this.color);
}

const Map<String, CategoryStyle> kCategoryStyles = {
  'Electronics': CategoryStyle(Icons.bolt_rounded, Color(0xFF3B82F6)),
  'Stationery': CategoryStyle(Icons.edit_note_rounded, Color(0xFF8B5CF6)),
  'Hardware': CategoryStyle(Icons.handyman_rounded, Color(0xFFF59E0B)),
  'Grocery': CategoryStyle(
    Icons.local_grocery_store_rounded,
    Color(0xFF10B981),
  ),
};

CategoryStyle styleFor(String category) =>
    kCategoryStyles[category] ??
    const CategoryStyle(Icons.inventory_2_rounded, AppColors.muted);

/// Online imagery (always rendered with a gradient fallback).
class AppImages {
  static const warehouseHero =
      'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=1400&q=80&auto=format&fit=crop';
  static const shelves =
      'https://images.unsplash.com/photo-1553413077-190dd305871c?w=1200&q=80&auto=format&fit=crop';
}

ThemeData buildTheme({bool useGoogleFonts = true}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    primary: AppColors.indigo,
    secondary: AppColors.gold,
    error: AppColors.crimson,
    surface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
  );
  final textTheme = useGoogleFonts
      ? GoogleFonts.interTextTheme(base.textTheme).copyWith(
          headlineLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titleLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          titleMedium: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        )
      : base.textTheme;

  return base.copyWith(
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8F9FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.indigo, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.crimson),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.crimson, width: 1.6),
      ),
      errorMaxLines: 2,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      side: const BorderSide(color: AppColors.line),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.gold.withValues(alpha: 0.22),
      elevation: 8,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
