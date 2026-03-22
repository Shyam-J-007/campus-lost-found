import 'package:flutter/material.dart';

class AppTheme {
  // ── Core colors ───────────────────────────────────────────
  static const Color goldLight = Color(0xFFFFD97D);
  static const Color gold = Color(0xFFD4A437);
  static const Color goldDark = Color(0xFF9B7209);

  // Dark mode
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF2A2A2A);
  static const Color darkElevated = Color(0xFF333333);

  // Light mode
  static const Color lightBg = Color(0xFFFAF7F2);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF0EAD6);
  static const Color lightElevated = Color(0xFFE8DFC8);

  // Semantic
  static const Color stillMissing = Color(0xFFB8860B);
  static const Color foundMatch = Color(0xFF2E7D32);
  static const Color errorRed = Color(0xFFCF6679);

  // ── Gradients ─────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD97D), Color(0xFFD4A437), Color(0xFF9B7209)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradientVertical = LinearGradient(
    colors: [Color(0xFFFFD97D), Color(0xFFD4A437)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF121212), Color(0xFF0D0D0D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightBgGradient = LinearGradient(
    colors: [Color(0xFFFAF7F2), Color(0xFFF5EDD8), Color(0xFFEDE0C4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF2A2520), Color(0xFF1E1B16)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFDF8EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ───────────────────────────────────────────────
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: const Color(0xFFD4A437).withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> goldGlowSoft = [
    BoxShadow(
      color: const Color(0xFFD4A437).withOpacity(0.2),
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: const Color(0xFFD4A437).withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ── Themes ────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: gold,
    fontFamily: 'SF Pro Display',
    colorScheme: const ColorScheme.dark(
      primary: gold,
      surface: darkCard,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Colors.white38),
      labelStyle: const TextStyle(color: Colors.white54),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold),
        padding: EdgeInsets.zero,
      ).copyWith(
        backgroundColor:
            WidgetStateProperty.all(Colors.transparent),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
      ),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    primaryColor: gold,
    fontFamily: 'SF Pro Display',
    colorScheme: const ColorScheme.light(
      primary: gold,
      surface: lightCard,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8DFC8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8DFC8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Colors.black38),
      labelStyle: const TextStyle(color: Colors.black54),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold),
        padding: EdgeInsets.zero,
      ).copyWith(
        backgroundColor:
            WidgetStateProperty.all(Colors.transparent),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
      ),
    ),
  );
}

// ── Reusable gradient button ──────────────────────────────────
class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final double height;

  const GoldButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppTheme.goldGlowSoft,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2.5),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Gradient text ─────────────────────────────────────────────
class GoldGradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  const GoldGradientText(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          AppTheme.goldGradient.createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
      ),
    );
  }
}