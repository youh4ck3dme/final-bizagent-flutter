// lib/core/ui/biz_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BizTheme {
  // Spacing System (4px base)
  static const double spacingBase = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacing2xl = 48;
  static const double spacing3xl = 64;

  // Border Radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radius2xl = 28;
  
  // Elevation
  static const double elevation = 1;
  
  // Legacy padding constant
  static const double pad = 16;

  // 1. COLOR SYSTEM - SLOVENSKÁ VLAJKA THEME (LIGHT)
  // Primary
  static const Color slovakBlue = Color(0xFF0B4EA2); // Primary Blue
  static const Color nationalRed = Color(0xFFEE1C25); // Primary Red
  static const Color tatraWhite = Color(0xFFFFFFFF); // Primary White
  
  // Secondary
  static const Color blueDark = Color(0xFF083A7A); // Secondary Blue Dark
  static const Color blueLight = Color(0xFF4A90E2); // Secondary Blue Light
  static const Color accentRed = Color(0xFFC41E3A); // Accent Red (CTA)
  static const Color accentRedLight = Color(0xFFFFE5E8); // Accent Red Light
  
  // Supporting
  static const Color successGreen = Color(0xFF52B788);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = nationalRed;
  
  // Legacy color aliases for backward compatibility
  static const Color richCrimson = nationalRed;
  static const Color fusionAzure = blueLight;
  static const Color silverMist = gray100;
  static const Color slate = gray700;
  
  // Gray Scale
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // 2. DARK MODE COLOR SYSTEM
  // Surface
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceVariant = Color(0xFF1E1E1E); // Cards/Elevated
  static const Color darkSurfaceContainerLow = Color(0xFF1A1A1A);
  static const Color darkOutline = Color(0xFF3D3D3D);
  static const Color darkOutlineVariant = Color(0xFF2C2C2C);
  
  // Brand Dark Variants
  static const Color darkPrimaryBlue = Color(0xFF5AA3F0); // Lighter blue for visibility
  static const Color darkPrimaryContainer = Color(0xFF0D3A6B); // Darker blue bg
  static const Color darkSecondaryRed = Color(0xFFFF6B6B); // Lighter red
  static const Color darkSecondaryContainer = Color(0xFF8B0A14); // Darker red bg
  
  // Text Dark
  static const Color darkOnSurface = Color(0xFFE8E8E8); // High emphasis
  static const Color darkOnSurfaceVariant = Color(0xFFC4C4C4); // Medium emphasis
  static const Color darkDisabled = Color(0xFF6B6B6B);


  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: slovakBlue,
      onPrimary: Colors.white,
      primaryContainer: blueLight.withOpacity(0.1),
      onPrimaryContainer: blueDark,
      secondary: nationalRed,
      onSecondary: Colors.white,
      secondaryContainer: accentRedLight,
      onSecondaryContainer: accentRed,
      surface: tatraWhite,
      onSurface: gray900,
      surfaceContainerHighest: gray50, 
      outline: gray300,
      error: errorRed,
      onError: Colors.white,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: darkPrimaryBlue,
      onPrimary: darkSurface, // Black text on light blue looks better, or white depending on contrast. Material specs usually contrast.
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: Color(0xFFC4E0FF),
      
      secondary: darkSecondaryRed,
      onSecondary: darkSurface,
      secondaryContainer: darkSecondaryContainer,
      onSecondaryContainer: Color(0xFFFFD9DB),
      
      surface: darkSurface,
      onSurface: darkOnSurface,
      surfaceContainerHighest: darkSurfaceVariant, // Cards
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      
      error: Color(0xFFCF6679),
      onError: Colors.black,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    
    // Base Text Style
    final baseTextColor = isDark ? darkOnSurface : gray900;
    final secondaryTextColor = isDark ? darkOnSurfaceVariant : gray700;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? darkSurface : gray50,
      
      // Typography
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        displayLarge: GoogleFonts.roboto(fontSize: 57, height: 64 / 57, fontWeight: FontWeight.normal, color: baseTextColor),
        displayMedium: GoogleFonts.roboto(fontSize: 45, height: 52 / 45, fontWeight: FontWeight.normal, color: baseTextColor),
        displaySmall: GoogleFonts.roboto(fontSize: 36, height: 44 / 36, fontWeight: FontWeight.normal, color: baseTextColor),
        
        headlineLarge: GoogleFonts.roboto(fontSize: 32, height: 40 / 32, fontWeight: FontWeight.normal, color: baseTextColor),
        headlineMedium: GoogleFonts.roboto(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.normal, color: baseTextColor),
        headlineSmall: GoogleFonts.roboto(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.normal, color: baseTextColor),
        
        titleLarge: GoogleFonts.roboto(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w500, color: baseTextColor),
        titleMedium: GoogleFonts.roboto(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w500, color: baseTextColor),
        titleSmall: GoogleFonts.roboto(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500, color: baseTextColor),
        
        bodyLarge: GoogleFonts.roboto(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.normal, color: baseTextColor),
        bodyMedium: GoogleFonts.roboto(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.normal, color: secondaryTextColor),
        bodySmall: GoogleFonts.roboto(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.normal, color: isDark ? darkDisabled : gray500),
        
        labelLarge: GoogleFonts.roboto(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.roboto(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.roboto(fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w500),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkSurface : tatraWhite,
        foregroundColor: isDark ? darkOnSurface : slovakBlue,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: GoogleFonts.roboto(
          color: isDark ? darkOnSurface : slovakBlue,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(color: isDark ? darkOnSurface : slovakBlue),
        shape: Border(bottom: BorderSide(color: isDark ? darkOutline : gray200, width: 1)),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? darkPrimaryBlue : slovakBlue, 
          foregroundColor: isDark ? darkSurface : Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
           backgroundColor: isDark ? darkPrimaryBlue : slovakBlue,
           foregroundColor: isDark ? darkSurface : Colors.white,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        )
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? darkPrimaryBlue : slovakBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? darkPrimaryBlue : slovakBlue,
          side: BorderSide(color: isDark ? darkPrimaryBlue : slovakBlue, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? darkSecondaryRed : nationalRed,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),

      // Cards
      // cardTheme: CardTheme(
      //   color: isDark ? darkSurfaceVariant : tatraWhite,
      //   elevation: 1,
      //   margin: const EdgeInsets.all(8),
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(radiusLg),
      //   ),
      //   shadowColor: Colors.black.withOpacity(0.3),
      // ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: false, 
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(color: isDark ? darkOnSurfaceVariant : gray600),
        hintStyle: TextStyle(color: isDark ? darkDisabled : gray400),
        helperStyle: TextStyle(color: isDark ? darkDisabled : gray500, fontSize: 12),
        // Default Border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: isDark ? darkOutline : gray300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: isDark ? darkOutline : gray300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: isDark ? darkPrimaryBlue : slovakBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: isDark ? Color(0xFFCF6679) : errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: isDark ? Color(0xFFCF6679) : errorRed, width: 2),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? darkSurface : tatraWhite,
        selectedItemColor: isDark ? darkPrimaryBlue : slovakBlue,
        unselectedItemColor: isDark ? darkDisabled : gray600,
        elevation: 3,
        type: BottomNavigationBarType.fixed,
      ),
      
      dividerTheme: DividerThemeData(
        color: isDark ? darkOutlineVariant : gray200,
        thickness: 1,
        space: 1,
      ),
      
      iconTheme: IconThemeData(
        color: isDark ? darkOnSurface : gray900,
      )
    );
  }
}
