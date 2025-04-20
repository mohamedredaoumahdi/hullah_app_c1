import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFD4A574); // Beige/Gold color for branding
  static const Color accentColor = Color(0xFFFF8FAB); // Pink color for selected items
  static const Color blackColor = Colors.black;
  static const Color greyColor = Color(0xFFEEEEEE); // Gray for input fields
  
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
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
          foregroundColor: Colors.white,
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
        backgroundColor: Colors.white,
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
    );
  }
}