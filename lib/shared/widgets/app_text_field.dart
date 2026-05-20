// ===== Flutter 3.35.x =====
import 'package:flutter/material.dart'; // core UI
import 'package:flutter/services.dart'; // TextInputFormatter

// semantic sizes for the input (small / medium / large)
enum AppInputSize { sm, md, lg } // three sizes

// main reusable text field (outline/filled by theme)
class AppTextField extends StatelessWidget {
  // controller to read/write text (nullable if you just use initialValue)
  final TextEditingController? controller; // external controller
  // label text above/beside field (Material label)
  final String? label; // label
  // hint text inside the field when empty
  final String? hint; // hint
  // helper text under the field (optional guidance)
  final String? helper; // helper
  // error text (if null, uses validator result)
  final String? errorText; // explicit error
  // prefix icon widget (leading)
  final Widget? prefix; // prefix icon
  // suffix icon/widget (trailing)
  final Widget? suffix; // suffix icon
  // whether to hide text (for passwords; set true to obscure)
  final bool obscure; // hide text
  // toggle to show/hide text via eye icon (only if obscure == true)
  final bool enableObscureToggle; // show eye button
  // keyboard type (email, number, text, etc.)
  final TextInputType keyboardType; // input type
  // return/next/done action on keyboard
  final TextInputAction? textInputAction; // keyboard action
  // min/max lines (for multiline fields)
  final int? minLines; // min lines
  final int? maxLines; // max lines
  // expands to fill height (use with maxLines = null)
  final bool expands; // expand vertically
  // read-only flag (no editing)
  final bool readOnly; // readOnly
  // enabled flag (null -> enabled, false -> disabled)
  final bool? enabled; // enabled
  // max characters (shows counter if provided)
  final int? maxLength; // character limit
  // initial value if controller not used
  final String? initialValue; // initial text
  // validator for Form (returns error string or null)
  final String? Function(String?)? validator; // validator
  // on change callback
  final ValueChanged<String>? onChanged; // onChange
  // on submit (pressed done)
  final ValueChanged<String>? onSubmitted; // onSubmitted
  // focus node for keyboard/focus control
  final FocusNode? focusNode; // focus
  // autofill hints (email, username, etc.)
  final Iterable<String>? autofillHints; // autofill
  // content padding override (if you want custom)
  final EdgeInsetsGeometry? contentPadding; // custom padding
  // size token (sm / md / lg)
  final AppInputSize size; // size
  // outer margin
  final EdgeInsetsGeometry? margin; // outside spacing
  // border radius override
  final double? borderRadius; // corners
  // filled background (true) or outline-only (false)
  final bool filled; // filled style
  // text direction (null = inherit)
  final TextDirection? textDirection; // rtl/ltr override
  // input formatters (e.g. uppercase, digits only)
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.prefix,
    this.suffix,
    this.obscure = false,
    this.enableObscureToggle = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
    this.expands = false,
    this.readOnly = false,
    this.enabled,
    this.maxLength,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofillHints,
    this.contentPadding,
    this.size = AppInputSize.md,
    this.margin,
    this.borderRadius,
    this.filled = false,
    this.textDirection,
    this.inputFormatters,
  });

  ({
    EdgeInsets contentPad,
    double font,
    double labelFont,
    double radius,
    double iconSize,
  })
  _metrics(BuildContext ctx) {
    final mq = MediaQuery.of(ctx);
    final sizePx = mq.size;
    final width = sizePx.width;
    final shortest = sizePx.shortestSide;
    final textScale = mq.textScaleFactor;

    final isTablet = shortest >= 600;
    final widthScale = (width / 390).clamp(0.9, 1.22);
    final scale = isTablet ? widthScale * 1.06 : widthScale;
    final ts = textScale.clamp(1.0, 1.3);

    double hPad, vPad, font, labelFont, baseRadius, icon;
    switch (size) {
      case AppInputSize.sm:
        hPad = 12;
        vPad = 10;
        font = 14;
        labelFont = 12.5;
        baseRadius = 12;
        icon = 18;
        break;
      case AppInputSize.lg:
        hPad = 18;
        vPad = 16;
        font = 16.5;
        labelFont = 14;
        baseRadius = 16;
        icon = 22;
        break;
      case AppInputSize.md:
      default:
        hPad = 16;
        vPad = 14;
        font = 15;
        labelFont = 13.5;
        baseRadius = 14;
        icon = 20;
    }

    final contentPad = EdgeInsets.symmetric(
      horizontal: (hPad * scale).clamp(12, 24),
      vertical: (vPad * scale).clamp(10, 20),
    );
    final r = (borderRadius ?? baseRadius * scale).clamp(10, 20).toDouble();
    final f = (font * scale * ts).clamp(13, 20).toDouble();
    final lf = (labelFont * scale * ts).clamp(12, 18).toDouble();
    final ic = (icon * scale).clamp(18, 24).toDouble();

    return (
      contentPad: contentPad,
      font: f,
      labelFont: lf,
      radius: r,
      iconSize: ic,
    );
  }

  Widget? _buildSuffix(BuildContext ctx, double iconSize, Color color) {
    if (enableObscureToggle && obscure) {
      return _ObscureToggle(iconSize: iconSize, color: color);
    }
    return suffix;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final m = _metrics(context);

    final Color borderColor = cs.outlineVariant;
    final Color focusColor = cs.primary;
    final Color fillColor = cs.surfaceContainerHighest;
    final Color textColor =
        theme.inputDecorationTheme.labelStyle?.color ??
        theme.textTheme.bodyLarge?.color ??
        cs.onSurface;
    final Color hintColor = cs.onSurface.withOpacity(0.5);

    final shape = OutlineInputBorder(
      borderRadius: BorderRadius.circular(m.radius),
      borderSide: BorderSide(color: borderColor, width: 1),
    );

    final decoration = InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      errorText: errorText,
      isDense: true,
      filled: filled,
      fillColor: filled ? fillColor : null,
      contentPadding: contentPadding ?? m.contentPad,
      prefixIcon: prefix == null
          ? null
          : IconTheme.merge(
              data: IconThemeData(size: m.iconSize, color: hintColor),
              child: prefix!,
            ),
      suffixIcon: _buildSuffix(context, m.iconSize, hintColor),
      border: shape,
      enabledBorder: shape,
      focusedBorder: shape.copyWith(
        borderSide: BorderSide(color: focusColor, width: 1.6),
      ),
      errorBorder: shape.copyWith(
        borderSide: BorderSide(color: cs.error, width: 1.2),
      ),
      focusedErrorBorder: shape.copyWith(
        borderSide: BorderSide(color: cs.error, width: 1.6),
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        fontSize: m.labelFont,
        color: hintColor,
      ),
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        fontSize: m.font,
        color: hintColor,
      ),
      helperStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: (m.font * 0.85).clamp(11, 14),
      ),
      errorStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: (m.font * 0.85).clamp(11, 14),
        color: cs.error,
      ),
      counterText: maxLength != null ? null : '',
    );

    Widget field = TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: expands ? null : maxLines,
      expands: expands,
      readOnly: readOnly,
      enabled: enabled,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      focusNode: focusNode,
      autofillHints: autofillHints,
      textDirection: textDirection,
      inputFormatters: inputFormatters,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: m.font,
        color: textColor,
      ),
      decoration: decoration,
    );

    if (margin != null) {
      field = Padding(padding: margin!, child: field);
    }
    return field;
  }
}

class _ObscureToggle extends StatefulWidget {
  final double iconSize;
  final Color color;
  const _ObscureToggle({required this.iconSize, required this.color});

  @override
  State<_ObscureToggle> createState() => _ObscureToggleState();
}

class _ObscureToggleState extends State<_ObscureToggle> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: widget.iconSize,
      color: widget.color,
      visualDensity: VisualDensity.compact,
      onPressed: () => setState(() => _obscured = !_obscured),
      icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
    );
  }
}

/// Convenience password field that owns its own obscure state.
class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final Widget? prefix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final EdgeInsetsGeometry? contentPadding;
  final AppInputSize size;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final bool filled;
  final bool? enabled;
  final String? Function(String?)? validator;
  final int? maxLength;

  const AppPasswordField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.prefix,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofillHints,
    this.contentPadding,
    this.size = AppInputSize.md,
    this.margin,
    this.borderRadius,
    this.filled = false,
    this.enabled,
    this.validator,
    this.maxLength,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      helper: widget.helper,
      errorText: widget.errorText,
      prefix: widget.prefix,
      suffix: IconButton(
        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
      obscure: _obscure,
      enableObscureToggle: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      minLines: 1,
      maxLines: 1,
      expands: false,
      readOnly: false,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      autofillHints: widget.autofillHints ?? const [AutofillHints.password],
      contentPadding: widget.contentPadding,
      size: widget.size,
      margin: widget.margin,
      borderRadius: widget.borderRadius,
      filled: widget.filled,
    );
  }
}
