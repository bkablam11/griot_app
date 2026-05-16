import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GriotTheme {
  // Palette de couleurs définie dans le cahier des charges
  static const Color ink = Color(0xFF141414);
  static const Color bg = Color(0xFFF5F5F0);
  static const Color olive = Color(0xFF5A5A40);
  static const Color earth = Color(0xFF8C6239);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.light(
      primary: earth,
      onPrimary: Colors.white,
      secondary: olive,
      surface: bg,
    ),
    textTheme: TextTheme(
      // Titres en Serif (Cormorant Garamond)
      displayLarge: GoogleFonts.cormorantGaramond(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: ink,
        fontStyle: FontStyle.italic,
      ),
      // Corps de texte en Sans-Serif (Inter)
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: ink),
    ),
  );
}
