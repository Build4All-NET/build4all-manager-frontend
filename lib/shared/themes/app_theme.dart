import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_palette.dart';

class UiTokens extends ThemeExtension<UiTokens> {
  final double radiusLg;
  final double radiusMd;
  final EdgeInsets pagePad;
  final List<BoxShadow> cardShadow;

  const UiTokens({
    required this.radiusLg,
    required this.radiusMd,
    required this.pagePad,
    required this.cardShadow,
  });

  @override
  UiTokens copyWith({
    double? radiusLg,
    double? radiusMd,
    EdgeInsets? pagePad,
    List<BoxShadow>? cardShadow,
  }) =>
      UiTokens(
        radiusLg: radiusLg ?? this.radiusLg,
        radiusMd: radiusMd ?? this.radiusMd,
        pagePad: pagePad ?? this.pagePad,
        cardShadow: cardShadow ?? this.cardShadow,
      );

  @override
  UiTokens lerp(ThemeExtension<UiTokens>? other, double t) {
    if (other is! UiTokens) return this;
    return this;
  }
}

class AppTheme {
  static ThemeData build(
    ThemePalette p, {
    Brightness brightness = Brightness.light,
  }) {
    final isDark = brightness == Brightness.dark;

    // ✅ Strong surfaces for dark mode (actual dark UI)
    const darkSurface = Color(0xFF0F1115);
    const darkSurface2 = Color(0xFF151923);
    const darkSurface3 = Color(0xFF1C2230);

    // ✅ Light surfaces
    const lightSurface = Color(0xFFF8FAFC);
    const lightSurface2 = Color(0xFFF1F5F9);

    // ✅ Build a proper ColorScheme (don’t rely only on fromSeed)
    final cs = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: Colors.white,
      secondary: p.secondary,
      onSecondary: Colors.white,
      error: p.error,
      onError: Colors.white,

      // The magic is here 👇
      surface: isDark ? darkSurface : Colors.white,
      onSurface: isDark ? const Color(0xFFE7EAF0) : const Color(0xFF0B1220),

      surfaceContainerHighest: isDark ? darkSurface3 : lightSurface2,
      outline: isDark ? const Color(0xFF2B3445) : const Color(0xFFCBD5E1),
      outlineVariant:
          isDark ? const Color(0xFF243047) : const Color(0xFFE2E8F0),

      // Material3 expects these too (Flutter will fill missing if needed, but better explicit)
      background: isDark ? darkSurface : lightSurface,
      onBackground: isDark ? const Color(0xFFE7EAF0) : const Color(0xFF0B1220),

      tertiary: p.success,
      onTertiary: Colors.white,

      // required fields for ColorScheme constructor
      surfaceTint: p.primary,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface:
          isDark ? const Color(0xFFE7EAF0) : const Color(0xFF0B1220),
      onInverseSurface:
          isDark ? const Color(0xFF0B1220) : const Color(0xFFE7EAF0),
      inversePrimary: p.primary.withOpacity(.8),
    );

    final tokens = UiTokens(
      radiusLg: 18,
      radiusMd: 14,
      pagePad: const EdgeInsets.all(16),
      cardShadow: isDark
          ? const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ]
          : const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 14,
                offset: Offset(0, 10),
              ),
            ],
    );

    // ✅ Base theme differs for light vs dark
    final base = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: cs,
      brightness: brightness,
      primaryColor: p.primary,
      scaffoldBackgroundColor: cs.background,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: cs.onSurface,
        displayColor: cs.onSurface,
      ),
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
     cardTheme: CardThemeData(
        color: isDark ? darkSurface2 : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
        ),
      ),

      dividerColor: cs.outlineVariant.withOpacity(.6),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: const StadiumBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface2 : cs.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHighest,
        selectedColor: cs.secondary.withOpacity(.15),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
        side: BorderSide(color: cs.outlineVariant),
      ),
    );
  }
}
