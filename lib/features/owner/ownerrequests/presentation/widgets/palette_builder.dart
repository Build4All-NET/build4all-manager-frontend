import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// ----------------------------
/// THEME DRAFT (what owner edits)
/// ----------------------------
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

/// ----------------------------
/// PRESETS (quick vibes)
/// ----------------------------
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
}

/// ----------------------------
/// BUILDER (draft -> themeJson)
/// ----------------------------
class ThemeJsonBuilder {
  static String toThemeJson(ThemeDraft d) {
    final map = {
      "colors": {
        "primary": _hex(d.primary),
        "secondary": _hex(d.secondary),
        "background": _hex(d.background),
        "onBackground": _hex(d.onBackground),
        "error": _hex(d.error),
      },
      // You can extend later without changing request contract:
      "borders": {"radius": 14},
      "spacing": {"base": 8},
    };
    return jsonEncode(map);
  }

  static String _hex(Color c) {
    // #RRGGBB (ignore alpha for simplicity)
    final r = c.red.toRadixString(16).padLeft(2, '0');
    final g = c.green.toRadixString(16).padLeft(2, '0');
    final b = c.blue.toRadixString(16).padLeft(2, '0');
    return '#${r}${g}${b}'.toUpperCase();
  }
}

/// ----------------------------
/// UI: Palette section widget
/// ----------------------------
class PaletteSection extends StatelessWidget {
  final ThemeDraft draft;
  final String? selectedPresetId;
  final ValueChanged<ThemeDraft> onChanged;
  final ValueChanged<String?> onPresetChanged;

  const PaletteSection({
    super.key,
    required this.draft,
    required this.selectedPresetId,
    required this.onChanged,
    required this.onPresetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Palette', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),

        _PresetGrid(
          selectedId: selectedPresetId,
          onSelect: (preset) {
            onPresetChanged(preset.id);
            onChanged(preset.draft);
          },
        ),

        const SizedBox(height: 12),

        // Custom tiles
        _TileRow(
          label: 'Primary',
          color: draft.primary,
          onTap: () => _pickColor(
            context,
            title: 'Pick Primary',
            start: draft.primary,
            onPicked: (c) {
              onPresetChanged(null); // custom mode
              onChanged(draft.copyWith(primary: c));
            },
          ),
        ),
        _TileRow(
          label: 'Secondary',
          color: draft.secondary,
          onTap: () => _pickColor(
            context,
            title: 'Pick Secondary',
            start: draft.secondary,
            onPicked: (c) {
              onPresetChanged(null);
              onChanged(draft.copyWith(secondary: c));
            },
          ),
        ),
        _TileRow(
          label: 'Background',
          color: draft.background,
          onTap: () => _pickColor(
            context,
            title: 'Pick Background',
            start: draft.background,
            onPicked: (c) {
              onPresetChanged(null);
              onChanged(draft.copyWith(background: c));
            },
          ),
        ),
        _TileRow(
          label: 'Text (onBackground)',
          color: draft.onBackground,
          onTap: () => _pickColor(
            context,
            title: 'Pick Text Color',
            start: draft.onBackground,
            onPicked: (c) {
              onPresetChanged(null);
              onChanged(draft.copyWith(onBackground: c));
            },
          ),
        ),
        _TileRow(
          label: 'Error',
          color: draft.error,
          onTap: () => _pickColor(
            context,
            title: 'Pick Error',
            start: draft.error,
            onPicked: (c) {
              onPresetChanged(null);
              onChanged(draft.copyWith(error: c));
            },
          ),
        ),

        const SizedBox(height: 12),

        _ThemePreview(draft: draft),

        const SizedBox(height: 6),

        // Helpful info line
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Owners pick colors visually. We generate themeJson automatically.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurface.withOpacity(.65)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> _pickColor(
    BuildContext context, {
    required String title,
    required Color start,
    required ValueChanged<Color> onPicked,
  }) async {
    Color temp = start;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: Theme.of(ctx).textTheme.titleMedium),
                    ),
                    Icon(Icons.palette_outlined, color: cs.primary),
                  ],
                ),
                const SizedBox(height: 12),

                ColorPicker(
                  pickerColor: temp,
                  onColorChanged: (c) => temp = c,
                  enableAlpha: false,
                  labelTypes: const [],
                  displayThumbColor: true,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onPicked(temp);
                        },
                        child: const Text('Use'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ----------------------------
/// PRESET GRID
/// ----------------------------
class _PresetGrid extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<ThemePreset> onSelect;

  const _PresetGrid({
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ThemePresets.presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final p = ThemePresets.presets[i];
          final selected = p.id == selectedId;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelect(p),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MiniSwatches(draft: p.draft),
                  const SizedBox(height: 10),
                  Text(
                    p.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected ? 'Selected' : 'Tap to apply',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(.6),
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniSwatches extends StatelessWidget {
  final ThemeDraft draft;
  const _MiniSwatches({required this.draft});

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c) => Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        );

    return Row(
      children: [
        dot(draft.primary),
        const SizedBox(width: 6),
        dot(draft.secondary),
        const SizedBox(width: 6),
        dot(draft.background),
        const SizedBox(width: 6),
        dot(draft.onBackground),
      ],
    );
  }
}

/// ----------------------------
/// TILE ROW
/// ----------------------------
class _TileRow extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TileRow({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
              ),
              Container(
                width: 44,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outlineVariant),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------
/// PREVIEW
/// ----------------------------
class _ThemePreview extends StatelessWidget {
  final ThemeDraft draft;
  const _ThemePreview({required this.draft});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),

          // Fake app bar
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: draft.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.apps_rounded, color: _on(draft.primary), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Your App',
                  style: TextStyle(
                    color: _on(draft.primary),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(Icons.notifications_none_rounded,
                    color: _on(draft.primary), size: 18),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Fake body
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: draft.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello owner 👋',
                  style: TextStyle(
                    color: draft.onBackground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This is how your theme looks.',
                  style: TextStyle(color: draft.onBackground.withOpacity(.85)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: draft.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Primary Button',
                          style: TextStyle(
                            color: _on(draft.primary),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: draft.error.withOpacity(.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: draft.error.withOpacity(.35)),
                      ),
                      child: Text(
                        'Error',
                        style: TextStyle(
                          color: draft.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _on(Color bg) {
    // simple luminance check for readable text
    return bg.computeLuminance() > 0.55 ? Colors.black : Colors.white;
  }
}
