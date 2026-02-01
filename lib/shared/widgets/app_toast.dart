import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Color bg;
    Color fg = cs.onSurface;

    switch (type) {
      case ToastType.success:
        bg = Colors.green.withOpacity(.18);
        fg = Colors.green.shade200;
        break;
      case ToastType.error:
        bg = Colors.red.withOpacity(.18);
        fg = Colors.red.shade200;
        break;
      case ToastType.warning:
        bg = Colors.orange.withOpacity(.18);
        fg = Colors.orange.shade200;
        break;
      case ToastType.info:
      default:
        bg = cs.surfaceVariant.withOpacity(.45);
        fg = cs.onSurface.withOpacity(.9);
        break;
    }

    final snack = SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snack);
  }

  static void success(BuildContext c, String msg) =>
      show(c, msg, type: ToastType.success);

  static void error(BuildContext c, String msg) =>
      show(c, msg, type: ToastType.error);

  static void info(BuildContext c, String msg) =>
      show(c, msg, type: ToastType.info);

  static void warn(BuildContext c, String msg) =>
      show(c, msg, type: ToastType.warning);
}
