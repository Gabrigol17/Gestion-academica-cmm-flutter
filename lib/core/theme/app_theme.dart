import 'package:flutter/material.dart';

class AppTheme {
  // Colores institucionales: Azul y Blanco
  static const Color azulPrimario = Color(0xFF1565C0); // Azul institucional
  static const Color azulOscuro = Color(
    0xFF0D47A1,
  ); // Azul para títulos o acentos
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color fondoClaro = Color(
    0xFFF4F6F9,
  ); // Fondo suave para que resalten las tarjetas
  static const Color bordeGris = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: azulPrimario,
        primary: azulPrimario,
        surface: fondoClaro,
      ),
      scaffoldBackgroundColor: fondoClaro,
      appBarTheme: const AppBarTheme(
        backgroundColor: azulPrimario,
        foregroundColor: blanco,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: blanco,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: bordeGris),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: azulPrimario,
          foregroundColor: blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}
