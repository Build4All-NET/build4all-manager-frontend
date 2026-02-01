import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // ✅ Get the overlay that belongs to the CURRENT route (dialog/bottomsheet/etc.)
    final overlay =
        Overlay.of(context) ?? Overlay.of(context, rootOverlay: true);

    if (overlay == null) return;

    // remove old toast
    _entry?.remove();
    _entry = null;

    final cs = Theme.of(context).colorScheme;

    Color dotColor;
    switch (type) {
      case ToastType.success:
        dotColor = Colors.green.shade300;
        break;
      case ToastType.error:
        dotColor = Colors.red.shade300;
        break;
      case ToastType.warning:
        dotColor = Colors.orange.shade300;
        break;
      case ToastType.info:
      default:
        dotColor = cs.primary.withOpacity(.9);
        break;
    }

    _entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        dotColor: dotColor,
      ),
    );

    // ✅ Insert on top of THAT overlay (so it appears فوق dialog)
    overlay.insert(_entry!);

    Future.delayed(duration, () {
      _entry?.remove();
      _entry = null;
    });
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

class _ToastView extends StatelessWidget {
  final String message;
  final Color dotColor;

  const _ToastView({
    required this.message,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 14, left: 14, right: 14),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(.96),
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
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
