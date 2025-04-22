import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Main colors extracted from the screenshot
  static const Color primaryColor = Color(0xFFE5A2C6); // Medium pink
  static const Color accentColor = Color(0xFFFF8FAB); // Soft pink for selected items
  static const Color blackColor = Colors.black; // For abaya and text
  static const Color greyColor = Color(0xFFF4E0E2); // Very light pink for input fields
  
  // Gradient colors from the screenshot
  static const Color topGradientColor = Color(0xFFEFD5D5); // Light nude/pink at top
  static const Color middleGradientColor = Color(0xFFE5A2C6); // Medium pink in middle
  static const Color bottomGradientColor = Color(0xFFBE6FAA); // Deeper pink/purple at bottom
  
  // Text colors
  static const Color lightTextColor = Colors.white; // For text on dark backgrounds
  
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: topGradientColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: Colors.red,
      ),
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cairo(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: blackColor,
        ),
        displayMedium: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: blackColor,
        ),
        displaySmall: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: blackColor,
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: 16,
          color: blackColor,
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: 14,
          color: blackColor,
        ),
        labelLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: blackColor,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: greyColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: GoogleFonts.cairo(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: lightTextColor,
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      iconTheme: IconThemeData(
        color: blackColor,
        size: 24,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: topGradientColor,
        elevation: 0,
        iconTheme: IconThemeData(color: blackColor),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: blackColor,
        ),
      ),
      
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        }),
      ),
      
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        }),
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
      ),
    );
  }
  
  // Method to create the exact gradient background from the screenshot
  static BoxDecoration get fullScreenGradient {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          topGradientColor,
          middleGradientColor,
          bottomGradientColor,
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }
  
  // Method for splash screen or special pages gradient
  static BoxDecoration get splashGradient {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          topGradientColor,
          middleGradientColor,
          bottomGradientColor,
        ],
        stops: [0.0, 0.6, 1.0],
      ),
    );
  }
  
  // Method for button gradients
  static Gradient get buttonGradient {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        primaryColor,
        bottomGradientColor,
      ],
    );
  }
}