import 'package:flutter/material.dart';

class ThemeDraft {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color onBackground;
  final Color error;

  const ThemeDraft({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.onBackground,
    required this.error,
  });

  ThemeDraft copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? onBackground,
    Color? error,
  }) {
    return ThemeDraft(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      error: error ?? this.error,
    );
  }
}

class ThemePreset {
  final String id;
  final String label;
  final ThemeDraft draft;

  const ThemePreset({
    required this.id,
    required this.label,
    required this.draft,
  });
}

class ThemePresets {
  static const presets = <ThemePreset>[
    ThemePreset(
      id: 'pink_pop',
      label: 'Pink Pop',
      draft: ThemeDraft(
        primary: Color(0xFFEC4899),
        secondary: Color(0xFF111827),
        background: Color(0xFFFFFFFF),
        onBackground: Color(0xFF374151),
        error: Color(0xFFDC2626),
      ),
    ),
    ThemePreset(
      id: 'ocean_blue',
      label: 'Ocean Blue',
      draft: ThemeDraft(
        primary: Color(0xFF2563EB),
        secondary: Color(0xFF0F172A),
        background: Color(0xFFF8FAFC),
        onBackground: Color(0xFF0F172A),
        error: Color(0xFFDC2626),
      ),
    ),
    ThemePreset(
      id: 'forest',
      label: 'Forest',
      draft: ThemeDraft(
        primary: Color(0xFF16A34A),
        secondary: Color(0xFF064E3B),
        background: Color(0xFFFFFFFF),
        onBackground: Color(0xFF14532D),
        error: Color(0xFFDC2626),
      ),
    ),
    ThemePreset(
      id: 'sunset',
      label: 'Sunset',
      draft: ThemeDraft(
        primary: Color(0xFFF97316),
        secondary: Color(0xFF7C2D12),
        background: Color(0xFFFFFBEB),
        onBackground: Color(0xFF1F2937),
        error: Color(0xFFDC2626),
      ),
    ),
    ThemePreset(
      id: 'midnight',
      label: 'Midnight',
      draft: ThemeDraft(
        primary: Color(0xFF8B5CF6),
        secondary: Color(0xFFE5E7EB),
        background: Color(0xFF0B0F14),
        onBackground: Color(0xFFE5E7EB),
        error: Color(0xFFEF4444),
      ),
    ),
  ];

  static ThemePreset byId(String id) =>
      presets.firstWhere((p) => p.id == id, orElse: () => presets.first);
}

String hexOf(Color c) {
  final r = c.red.toRadixString(16).padLeft(2, '0');
  final g = c.green.toRadixString(16).padLeft(2, '0');
  final b = c.blue.toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}
