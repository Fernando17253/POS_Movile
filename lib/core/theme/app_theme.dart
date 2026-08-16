import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores Base
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color backgroundColor = Color(0xFFF2F2F7);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFB00020);

  // Nuevos colores para feedback interactivo (Éxito, Alertas)
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);

  // Sistema de Tipografías ampliado y más grande
  static final TextTheme textTheme = GoogleFonts.ibmPlexSansTextTheme().copyWith(
    // Para totales a cobrar (Ej. $1,500.00)
    displayLarge: GoogleFonts.ibmPlexSans(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
    displayMedium: GoogleFonts.ibmPlexSans(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
    
    // Para Títulos de AppBar y Secciones
    titleLarge: GoogleFonts.ibmPlexSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
    titleMedium: GoogleFonts.ibmPlexSans(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
    
    // Textos normales más legibles (Cambiado de 15 a 18)
    bodyLarge: GoogleFonts.ibmPlexSans(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
    bodyMedium: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black87),
    
    // Para los textos de los botones (Aumentado para mayor legibilidad)
    labelLarge: GoogleFonts.ibmPlexSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      textTheme: textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor, // Mejor fondo sólido para no perder legibilidad
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: Colors.black, size: 28), // Íconos un poco más grandes
      ),
      
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceColor,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        // Hint text más grande (cambiado de 13 a 16)
        hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal, fontSize: 16),
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w500),
        
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        // Campos de texto más amplios (touch target más grande)
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          // Botones más altos y anchos para no fallar al tocarlos
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Agregamos feedback visual en Snacks para notificaciones de error/éxito
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}