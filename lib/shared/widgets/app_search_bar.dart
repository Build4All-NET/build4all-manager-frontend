import 'dart:async';
import 'package:flutter/material.dart';

class AppSearchBar extends StatefulWidget {
  final String? initialQuery;
  final String hint;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onFilterPressed;

  final bool autofocus;
  final bool readOnly;
  final int debounceMs;

  final bool showBack;
  final VoidCallback? onBack;

  final EdgeInsetsGeometry? margin;
  final double? height;

  // ✅ NEW: control the left icon (search) per screen
  final bool showSearchIcon;

  // ✅ NEW: optional custom leading widget (per screen)
  final Widget? leading;

  const AppSearchBar({
    super.key,
    this.initialQuery,
    required this.hint,
    this.onQueryChanged,
    this.onSubmitted,
    this.onClear,
    this.onFilterPressed,
    this.autofocus = false,
    this.readOnly = false,
    this.debounceMs = 220,
    this.showBack = false,
    this.onBack,
    this.margin,
    this.height,

    // ✅ NEW
    this.showSearchIcon = true,
    this.leading,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery ?? '');
    _focus = FocusNode();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _handleChanged(String q) {
    _debounce?.cancel();
    if (widget.debounceMs <= 0) {
      widget.onQueryChanged?.call(q);
      setState(() {});
      return;
    }
    _debounce = Timer(Duration(milliseconds: widget.debounceMs), () {
      widget.onQueryChanged?.call(q);
    });
    setState(() {});
  }

  void _clear() {
    _ctrl.clear();
    widget.onClear?.call();
    widget.onQueryChanged?.call('');
    setState(() {});
    if (!widget.readOnly) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasText = _ctrl.text.trim().isNotEmpty;

    final radius = BorderRadius.circular(18);
    final h = widget.height ?? 52;

    final containerColor = cs.surfaceContainerHighest;
    final stroke = cs.outlineVariant.withOpacity(.6);

    // ✅ prefix logic:
    // 1) showBack => back arrow
    // 2) leading != null => use it
    // 3) showSearchIcon => search icon
    // 4) otherwise => reserve same width so layout stays aligned
    final Widget prefix = widget.showBack
        ? InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: widget.onBack ?? () => Navigator.maybePop(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.arrow_back, color: cs.onSurface, size: 22),
            ),
          )
        : (widget.leading ??
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: widget.showSearchIcon
                  ? Icon(Icons.search_rounded,
                      color: cs.onSurfaceVariant, size: 22)
                  : const SizedBox(width: 22), // ✅ keeps spacing consistent
            ));

    final suffix = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasText)
          IconButton(
            onPressed: _clear,
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
          ),
        if (widget.onFilterPressed != null)
          IconButton(
            onPressed: widget.onFilterPressed,
            tooltip: 'Filters',
            icon: Icon(Icons.tune_rounded, color: cs.onSurfaceVariant),
          ),
      ],
    );

    Widget child = Material(
      color: containerColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: stroke),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: h),
        child: Row(
          children: [
            prefix,
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                autofocus: widget.autofocus,
                readOnly: widget.readOnly,
                textInputAction: TextInputAction.search,
                onChanged: _handleChanged,
                onSubmitted: widget.onSubmitted,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.hint,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurface.withOpacity(.55),
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            suffix,
            const SizedBox(width: 6),
          ],
        ),
      ),
    );

    if (widget.margin != null) {
      child = Padding(padding: widget.margin!, child: child);
    }

    return child;
  }
}

class AppSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? initialQuery;
  final String hint;

  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onFilterPressed;

  final bool autofocus;
  final bool readOnly;
  final int debounceMs;

  final bool showBack;
  final VoidCallback? onBack;

  // ✅ NEW: pass-through controls
  final bool showSearchIcon;
  final Widget? leading;

  const AppSearchAppBar({
    super.key,
    this.initialQuery,
    required this.hint,
    this.onQueryChanged,
    this.onSubmitted,
    this.onClear,
    this.onFilterPressed,
    this.autofocus = false,
    this.readOnly = false,
    this.debounceMs = 220,
    this.showBack = true,
    this.onBack,

    // ✅ NEW
    this.showSearchIcon = true,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      titleSpacing: 0,
      title: AppSearchBar(
        initialQuery: initialQuery,
        hint: hint,
        onQueryChanged: onQueryChanged,
        onSubmitted: onSubmitted,
        onClear: onClear,
        onFilterPressed: onFilterPressed,
        autofocus: autofocus,
        readOnly: readOnly,
        debounceMs: debounceMs,
        showBack: showBack,
        onBack: onBack,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),

        // ✅ pass-through
        showSearchIcon: showSearchIcon,
        leading: leading,
      ),
    );
  }
}
