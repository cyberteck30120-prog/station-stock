import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF6366F1); // Indigo plus moderne
  static const Color accent = Color(0xFF10B981); 
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFF1F5F9);
  static const Color error = Color(0xFFEF4444);
  static const Color logoBackground = Color(0xFFFDFDFB); // Couleur exacte du fond du logo

  static ThemeData get lightTheme {
    // ... (on garde le contenu existant)
    return _buildTheme(Brightness.light);
  }

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F172A) : background;
    final Color surfColor = isDark ? const Color(0xFF1E293B) : surface;
    final Color txtColor = isDark ? Colors.white : textPrimary;
    final Color txtSecColor = isDark ? const Color(0xFF94A3B8) : textSecondary;
    final Color brdColor = isDark ? const Color(0xFF334155) : border;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: accent,
        surface: surfColor,
        background: bgColor,
        error: error,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: txtColor, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1.0),
        titleLarge: TextStyle(color: txtColor, fontWeight: FontWeight.w700, fontSize: 24, letterSpacing: -0.5),
        titleMedium: TextStyle(color: txtColor, fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: -0.2),
        bodyLarge: TextStyle(color: txtColor, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: txtSecColor, fontSize: 14, height: 1.4),
        labelLarge: TextStyle(color: txtSecColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: txtColor),
        titleTextStyle: TextStyle(color: txtColor, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: surfColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: brdColor, width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: brdColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: brdColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}

// Extension pour un effet Glassmorphism très léger (pour les cartes)
class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassmorphismContainer({Key? key, required this.child, this.padding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
