// ===== Flutter 3.35.x =====
import 'package:flutter/material.dart'; // core Flutter UI

// Button variants (visual styles)
enum AppButtonType { primary, secondary, outline, text }

// Button sizes (semantic sizes)
enum AppButtonSize { sm, md, lg }

// A single responsive, theme-aware button used across the app
class AppButton extends StatelessWidget {
  // text label (nullable → allows icon-only)
  final String? label;
  // tap callback (null → disabled)
  final VoidCallback? onPressed;
  // visual style
  final AppButtonType type;
  // semantic size
  final AppButtonSize size;
  // full-width if true
  final bool expand;
  // show spinner instead of content
  final bool isBusy;
  // leading icon widget
  final Widget? leading;
  // trailing icon widget
  final Widget? trailing;
  // external spacing around the button
  final EdgeInsetsGeometry? margin;
  // optional text style override
  final TextStyle? textStyle;
  // corner radius override
  final double? borderRadius;
  // focus node (for accessibility/keyboard)
  final FocusNode? focusNode;
  // screen reader label
  final String? semanticLabel;

  const AppButton({
    super.key,
    required this.onPressed,
    this.label,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.md,
    this.expand = false,
    this.isBusy = false,
    this.leading,
    this.trailing,
    this.margin,
    this.textStyle,
    this.borderRadius,
    this.focusNode,
    this.semanticLabel,
  });

  // Responsive metrics (padding / font / spinner / min height / radius)
  ({
    EdgeInsets padding,
    double font,
    double spinner,
    double minHeight,
    double radius,
  })
  _metrics(BuildContext ctx) {
    final mq = MediaQuery.of(ctx);
    final size = mq.size;
    final shortest = size.shortestSide;
    final width = size.width;
    final textScale = mq.textScaleFactor;

    // Scale based on width (390 ~ iPhone 12 baseline)
    final widthScale = (width / 390).clamp(0.9, 1.2);

    // Limit text scale factor to avoid huge fonts
    final layoutTextScale = textScale.clamp(1.0, 1.3);

    // Rough heuristic for tablet
    final bool isTablet = shortest >= 600;

    // Base values depending on button size
    double baseH, baseV, baseFont, baseSpinner, baseMinH, baseRadius;
    switch (sizeEnumToString(this.size)) {
      case 'sm':
        baseH = 12;
        baseV = 10;
        baseFont = 13;
        baseSpinner = 16;
        baseMinH = 40;
        baseRadius = 14;
        break;
      case 'lg':
        baseH = 18;
        baseV = 16;
        baseFont = 16;
        baseSpinner = 20;
        baseMinH = 52;
        baseRadius = 18;
        break;
      case 'md':
      default:
        baseH = 16;
        baseV = 14;
        baseFont = 15;
        baseSpinner = 18;
        baseMinH = 48;
        baseRadius = 16;
    }

    // Apply width scaling (slightly larger on tablets)
    final scale = isTablet ? widthScale * 1.06 : widthScale;

    // Final responsive values
    final font = (baseFont * scale * layoutTextScale).clamp(12.0, 20.0);
    final spinner = (baseSpinner * scale).clamp(14.0, 24.0);
    final hPad = (baseH * scale).clamp(10.0, 24.0);
    final vPad = (baseV * scale).clamp(8.0, 20.0);
    final minHeight = (baseMinH * scale).clamp(40.0, 58.0);
    final radius = borderRadius ?? (baseRadius * scale).clamp(12.0, 22.0);

    // Less padding for text-only style
    final EdgeInsets padding = (type == AppButtonType.text)
        ? EdgeInsets.symmetric(horizontal: hPad * 0.6, vertical: vPad * 0.7)
        : EdgeInsets.symmetric(horizontal: hPad, vertical: vPad);

    return (
      padding: padding,
      font: font,
      spinner: spinner,
      minHeight: minHeight,
      radius: radius,
    );
  }

  // Map enum to string
  String sizeEnumToString(AppButtonSize s) {
    switch (s) {
      case AppButtonSize.sm:
        return 'sm';
      case AppButtonSize.lg:
        return 'lg';
      case AppButtonSize.md:
      default:
        return 'md';
    }
  }

  // Compute colors from theme + variant
  ({Color bg, Color fg, Color border, Color overlay}) _colors(
    BuildContext ctx,
  ) {
    final cs = Theme.of(ctx).colorScheme;
    switch (type) {
      case AppButtonType.primary:
        return (
          bg: cs.primary,
          fg: cs.onPrimary,
          border: Colors.transparent,
          overlay: cs.onPrimary.withOpacity(.08),
        );
      case AppButtonType.secondary:
        return (
          bg: cs.secondaryContainer,
          fg: cs.onSecondaryContainer,
          border: Colors.transparent,
          overlay: cs.onSecondaryContainer.withOpacity(.06),
        );
      case AppButtonType.outline:
        return (
          bg: Colors.transparent,
          fg: cs.primary,
          border: cs.outlineVariant,
          overlay: cs.primary.withOpacity(.06),
        );
      case AppButtonType.text:
        return (
          bg: Colors.transparent,
          fg: cs.primary,
          border: Colors.transparent,
          overlay: cs.primary.withOpacity(.06),
        );
    }
  }

  // Build inner content (spinner or label+icons)
  Widget _buildContent(
    BuildContext ctx,
    double font,
    double spinner,
    Color fg,
  ) {
    // Show loading spinner
    if (isBusy) {
      return SizedBox(
        width: spinner,
        height: spinner,
        child: CircularProgressIndicator(strokeWidth: 2, color: fg),
      );
    }

    // Merge provided style with theme
    final style = (textStyle ?? Theme.of(ctx).textTheme.titleMedium)?.copyWith(
      fontSize: font,
      color: fg,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );

    final List<Widget> pieces = [];

    // Leading icon
    if (leading != null) {
      pieces.add(
        Padding(
          padding: EdgeInsets.only(right: (font * 0.55).clamp(6, 10)),
          child: IconTheme.merge(
            data: IconThemeData(color: fg, size: font + 1),
            child: leading!,
          ),
        ),
      );
    }

    // Label text (responsive using FittedBox)
    if (label != null) {
      pieces.add(
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown, // shrink text if too big
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      );
    }

    // Trailing icon
    if (trailing != null) {
      pieces.add(
        Padding(
          padding: EdgeInsets.only(left: (font * 0.55).clamp(6, 10)),
          child: IconTheme.merge(
            data: IconThemeData(color: fg, size: font + 1),
            child: trailing!,
          ),
        ),
      );
    }

    // No content → keep minimum size
    if (pieces.isEmpty) {
      final side = (font + 6).clamp(18, 28);
      return SizedBox(height: side.toDouble(), width: side.toDouble());
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: pieces,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = _metrics(context);
    final c = _colors(context);

    final bool enabled = onPressed != null && !isBusy;

    final Color bg = enabled ? c.bg : cs.surfaceContainerHighest.withOpacity(.6);
    final Color fg = enabled ? c.fg : cs.onSurface.withOpacity(.38);
    final Color br = (type == AppButtonType.outline)
        ? c.border
        : Colors.transparent;

    Widget core = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(m.radius),
        side: type == AppButtonType.outline
            ? BorderSide(color: br, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(m.radius),
        splashColor: c.overlay,
        highlightColor: c.overlay,
        focusNode: focusNode,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: m.minHeight),
          child: Padding(
            padding: m.padding,
            child: Center(child: _buildContent(context, m.font, m.spinner, fg)),
          ),
        ),
      ),
    );

    // Add semantics for accessibility
    core = Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: core,
    );

    if (expand) {
      core = SizedBox(width: double.infinity, child: core);
    }

    if (margin != null) {
      core = Padding(padding: margin!, child: core);
    }

    return core;
  }
}

// Round icon-only button (responsive size)
class AppIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final bool isFilled;
  final double size;
  final bool isBusy;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isFilled = true,
    this.size = 44,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final widthScale = (mq.size.width / 390).clamp(0.9, 1.2);
    final diameter = (size * widthScale).clamp(40.0, 56.0);

    final cs = Theme.of(context).colorScheme;
    final bool enabled = onPressed != null && !isBusy;
    final Color bg = isFilled ? cs.primary : Colors.transparent;
    final Color fg = isFilled ? cs.onPrimary : cs.primary;
    final Color br = isFilled ? Colors.transparent : cs.outlineVariant;

    final Widget content = isBusy
        ? SizedBox(
            width: (diameter * 0.45).clamp(18.0, 22.0),
            height: (diameter * 0.45).clamp(18.0, 22.0),
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : IconTheme.merge(
            data: IconThemeData(
              color: fg,
              size: (diameter * 0.5).clamp(20.0, 26.0),
            ),
            child: icon,
          );

    Widget btn = Material(
      color: enabled ? bg : cs.surfaceContainerHighest.withOpacity(.6),
      shape: CircleBorder(side: BorderSide(color: br, width: 1)),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Center(child: content),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      btn = Tooltip(message: tooltip!, child: btn);
    }

    return btn;
  }
}
