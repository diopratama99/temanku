import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme with Material Design 3 principles and WCAG 2.1 AA compliance
class AppTheme {
  // ============================================================
  // DESIGN TOKENS - Color System
  // ============================================================

  /// Primary color - Financial Growth Green (brand color)
  static const Color primaryColor = Color(0xFF157347); // Brand Green
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Semantic colors for financial transactions
  static const Color incomeColor = Color(
    0xFF16A34A,
  ); // Green 600 - Bright Green (lebih cerah)
  static const Color expenseColor = Color(
    0xFFC62828,
  ); // Red 800 (4.5:1 contrast)
  static const Color neutralColor = Color(0xFF455A64); // Blue Grey 700

  /// Surface & Background colors
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Color(0xFFFFFFFF);

  /// Text colors with accessible contrast ratios
  static const Color textPrimary = Color(0xFF212121); // Grey 900 (15.8:1)
  static const Color textSecondary = Color(0xFF757575); // Grey 600 (4.6:1)
  static const Color textDisabled = Color(0xFFBDBDBD); // Grey 400

  // ============================================================
  // DARK MODE COLORS - Carefully crafted for readability
  // ============================================================

  /// Primary color - Softer green for dark mode
  static const Color darkPrimaryColor = Color(0xFF20C073); // Brighter green
  static const Color darkOnPrimary = Color(0xFF003821);

  /// Semantic colors for dark mode
  static const Color darkIncomeColor = Color(0xFF22C55E); // Green 500 - Vibrant
  static const Color darkExpenseColor = Color(
    0xFFEF5350,
  ); // Red 400 - Softer red

  /// Surface & Background colors - Softer grey tones (not pure black)
  static const Color darkSurfaceColor = Color(0xFF3A3A3C); // Medium grey (card)
  static const Color darkBackgroundColor = Color(
    0xFF2C2C2E,
  ); // Lighter grey (background)
  static const Color darkCardColor = Color(
    0xFF48484A,
  ); // Light grey (elevated card)

  /// Text colors for dark mode - Clean white/grey
  static const Color darkTextPrimary = Color(
    0xFFFFFFFF,
  ); // Pure white for primary text
  static const Color darkTextSecondary = Color(
    0xFFAAAAAA,
  ); // Light grey for secondary
  static const Color darkTextDisabled = Color(
    0xFF6E6E6E,
  ); // Medium grey for disabled

  // ============================================================
  // DESIGN TOKENS - Spacing System (8dp grid)
  // ============================================================
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // ============================================================
  // DESIGN TOKENS - Elevation & Radius
  // ============================================================
  static const double elevation1 = 2.0; // Default cards
  static const double elevation2 = 4.0; // Raised components
  static const double elevation3 = 8.0; // FAB, dialogs

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // ============================================================
  // DESIGN TOKENS - Touch Targets (Accessibility)
  // ============================================================
  static const double minTouchTarget = 48.0; // WCAG minimum

  // ============================================================
  // Theme Builder
  // ============================================================
  static ThemeData theme() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
    );

    // Typography Scale with Plus Jakarta Sans - Premium financial app aesthetic
    // Clean, modern, excellent number readability, minimalist yet professional
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .copyWith(
          // Headline - Hero numbers (financial amounts, key metrics)
          headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: textPrimary,
            letterSpacing: -0.3,
          ),

          // Title - Section headers
          titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: textPrimary,
            letterSpacing: 0,
          ),
          titleSmall: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: textPrimary,
            letterSpacing: 0,
          ),

          // Body - Content text
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: textPrimary,
            letterSpacing: 0,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.6,
            color: textPrimary,
            letterSpacing: 0,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: textSecondary,
            letterSpacing: 0,
          ),

          // Label - Buttons, captions, navigation
          labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: 0.2,
          ),
          labelMedium: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: 0.3,
          ),
          labelSmall: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: 0.3,
          ),
        );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primaryColor,
        secondary: primaryColor,
        error: expenseColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: onPrimary,
          fontSize: 20,
        ),
      ),

      // Text Theme
      textTheme: textTheme,

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.08),
        selectedColor: primaryColor,
        labelStyle: textTheme.labelLarge,
        shape: StadiumBorder(
          side: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: space12,
          vertical: space8,
        ),
      ),

      // Card Theme - Elevated with accessible shadows
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: elevation1,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration Theme - Accessible form fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: textDisabled),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: textDisabled),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: expenseColor),
        ),
        labelStyle: TextStyle(color: textSecondary),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: expenseColor),
      ),

      // Filled Button Theme - Primary actions
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          textStyle: textTheme.labelLarge,
          elevation: elevation1,
        ),
      ),

      // Outlined Button Theme - Secondary actions
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Text Button Theme - Tertiary actions
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space8,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        iconColor: primaryColor,
        minVerticalPadding: space12,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space8,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: textDisabled.withOpacity(0.3),
        thickness: 1,
        space: space16,
      ),

      // Bottom Navigation Bar Theme - Text only, clean minimal design
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        elevation: elevation2,
        height: 60,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return textTheme.titleSmall?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: textSecondary,
            fontSize: 13,
          );
        }),
        indicatorColor: primaryColor.withOpacity(0.1),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
    );
  }

  // ============================================================
  // Dark Theme - Premium dark mode with careful color selection
  // ============================================================
  static ThemeData darkTheme() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimaryColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackgroundColor,
    );

    // Typography Scale with Plus Jakarta Sans
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .copyWith(
          // Headline - Hero numbers
          headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: darkTextPrimary,
            letterSpacing: -0.5,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: darkTextPrimary,
            letterSpacing: -0.3,
          ),

          // Title - Section headers
          titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: darkTextPrimary,
            letterSpacing: -0.2,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: darkTextPrimary,
            letterSpacing: 0,
          ),
          titleSmall: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: darkTextPrimary,
            letterSpacing: 0,
          ),

          // Body - Content text
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: darkTextPrimary,
            letterSpacing: 0,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.6,
            color: darkTextPrimary,
            letterSpacing: 0,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: darkTextSecondary,
            letterSpacing: 0,
          ),

          // Label - Buttons, captions, navigation
          labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: 0.2,
          ),
          labelMedium: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: 0.3,
          ),
          labelSmall: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: 0.3,
          ),
        );

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: darkPrimaryColor,
        onPrimary: darkOnPrimary,
        secondary: darkPrimaryColor,
        error: darkExpenseColor,
        surface: darkSurfaceColor,
        onSurface: darkTextPrimary, // Text otomatis putih di surface
        background: darkBackgroundColor,
        onBackground: darkTextPrimary, // Text otomatis putih di background
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextPrimary,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: darkTextPrimary,
          fontSize: 20,
        ),
      ),

      // Text Theme
      textTheme: textTheme,

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkCardColor,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: darkPrimaryColor.withOpacity(0.15),
        selectedColor: darkPrimaryColor,
        labelStyle: textTheme.labelLarge,
        shape: StadiumBorder(
          side: BorderSide(color: darkPrimaryColor.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: space12,
          vertical: space8,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: darkTextDisabled.withOpacity(0.1), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: darkTextDisabled),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: darkTextDisabled.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkPrimaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkExpenseColor),
        ),
        labelStyle: TextStyle(color: darkTextSecondary),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: darkExpenseColor),
      ),

      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimaryColor,
          foregroundColor: darkOnPrimary,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimaryColor,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          side: const BorderSide(color: darkPrimaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimaryColor,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space8,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        iconColor: darkPrimaryColor,
        minVerticalPadding: space12,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space8,
        ),
        tileColor: darkSurfaceColor,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: darkTextDisabled.withOpacity(0.2),
        thickness: 1,
        space: space16,
      ),

      // Bottom Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCardColor,
        elevation: 0,
        height: 60,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return textTheme.titleSmall?.copyWith(
              color: darkPrimaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: darkTextSecondary,
            fontSize: 13,
          );
        }),
        indicatorColor: darkPrimaryColor.withOpacity(0.15),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkPrimaryColor,
        foregroundColor: darkOnPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
    );
  }
}
