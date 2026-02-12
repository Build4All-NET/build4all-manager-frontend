import 'package:flutter/material.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

class AppSearchInput extends StatelessWidget {
  final String? hintKey; // e.g. 'owner_home_search_hint'
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool dense;

  /// ✅ NEW: control filter icon visibility
  final bool showFilter;

  /// ✅ OPTIONAL: custom filter action (if you want it clickable somewhere else)
  final VoidCallback? onFilterTap;

  const AppSearchInput({
    super.key,
    this.hintKey,
    this.onChanged,
    this.onTap,
    this.dense = false,
    this.showFilter = true,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final hint = switch (hintKey) {
      'owner_home_search_hint' => l10n.owner_home_search_hint,
      _ => l10n.owner_home_search_hint,
    };

    return TextField(
      onChanged: onChanged,
      readOnly: onTap != null,
      onTap: onTap,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),

        /// ✅ FIX: show/hide filter icon
        suffixIcon: showFilter
            ? (onFilterTap == null
                ? Icon(Icons.tune_rounded, color: cs.onSurface.withOpacity(.55))
                : IconButton(
                    onPressed: onFilterTap,
                    icon: Icon(Icons.tune_rounded,
                        color: cs.onSurface.withOpacity(.75)),
                    tooltip: 'Filters',
                  ))
            : null,

        hintText: hint,
        filled: true,
        fillColor: cs.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: dense ? 10 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: cs.primary.withOpacity(.85), width: 1.3),
        ),
      ),
    );
  }
}
